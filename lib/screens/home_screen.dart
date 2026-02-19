import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../providers/user_provider.dart';
import 'budget_detail_screen.dart';
import '../widgets/currency_selection_dialog.dart';
import '../theme/design_system.dart';
import 'all_transactions_screen.dart';
import 'budget_trends_screen.dart';
import 'budget_pdf_preview_screen.dart';
import '../services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:budget_tracker/widgets/crop_image_dialog.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadReminderTime();
  }

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour');
    final minute = prefs.getInt('reminder_minute');
    if (hour != null && minute != null) {
      setState(() {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
    setState(() {
      _reminderTime = time;
    });
    final username = Provider.of<UserProvider>(context, listen: false).username;
    
    // Request permissions first to ensure Exact Alarm is allowed
    await NotificationService().requestPermissions();
    
    await NotificationService().scheduleDailyNotification(time, username);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily reminder set for ${time.format(context)}')),
      );
    }
  }

  Future<void> _clearReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_hour');
    await prefs.remove('reminder_minute');
    setState(() {
      _reminderTime = null;
    });
    await NotificationService().cancelNotifications();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reminder disabled')),
      );
    }
  }

  Future<void> _pickImage() async {
    // Step 1: Ask user to pick source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library_rounded, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.blue),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    // Step 2: Pick image from selected source
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile == null) return;

    // Step 3: Read bytes and show custom crop dialog
    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CropImageDialog(imageBytes: bytes),
    );

    if (croppedBytes != null && mounted) {
      await Provider.of<UserProvider>(context, listen: false)
          .setProfileImageBytes(croppedBytes);
    }
  }

  Future<void> _handleReminderTap() async {
    if (_reminderTime == null) {
      await _pickReminderTime();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daily Reminder'),
          content: Text('Reminder currently set for ${_reminderTime!.format(context)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearReminder();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Clear Reminder'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickReminderTime();
              },
              child: const Text('Change Time'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      await _saveReminderTime(picked);
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
         await Permission.notification.request();
      } else {
        // Android < 13
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  ImageProvider? _getProfileImage(UserProvider user) {
    // Priority 1: In-memory bytes (immediate update after picking / web default)
    if (user.profileImageBytes != null) {
      return MemoryImage(user.profileImageBytes!);
    }
    // Priority 2: File path (persisted data on mobile)
    if (user.profileImagePath.isNotEmpty) {
      // kIsWeb check is technically redundant if we ensure path is empty on web, 
      // but good for safety.
      if (!kIsWeb) {
        return FileImage(File(user.profileImagePath));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    } else {
      greeting = 'Good Evening,';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Or AppColors.background if you want solid
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Budget Tracker',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: GestureDetector(
                onTap: _pickImage,
                child: Consumer<UserProvider>(
                  builder: (context, user, child) {
                    final imageProvider = _getProfileImage(user);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 20, color: AppColors.primary)
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
               UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primary),
                accountName: Text(Provider.of<UserProvider>(context).username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                accountEmail: const Text('Keep tracking your expenses!'),
                currentAccountPicture: Consumer<UserProvider>(
                  builder: (context, user, child) {
                    final imageProvider = _getProfileImage(user);
                    return GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        backgroundColor: AppColors.background,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                 leading: const Icon(Icons.notifications_active_outlined, color: AppColors.textPrimary),
                 title: const Text('Daily Expense Reminder', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                 subtitle: Text(_reminderTime != null ? 'Set for ${_reminderTime!.format(context)}' : 'Not set', style: const TextStyle(color: AppColors.textSecondary)),
                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                 onTap: _handleReminderTap,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // 2. Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.md), // Reduced top padding since AppBar takes space
                
                // Greeting Header (Modified for Body)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  greeting,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14, // Slightly larger
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getGreetingEmoji(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Proper spacing
                            Text(
                              Provider.of<UserProvider>(context).username,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28, // Prominent
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Add Budget Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: () => _showAddBudgetDialog(context),
                          tooltip: 'Add Budget',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                  
                  // Budget List (Horizontal)
                  SizedBox(
                    height: 200, 
                    child: Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        final budgets = provider.budgets;
                        if (budgets.isEmpty) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 48),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No budgets yet',
                                    style: TextStyle(color: AppColors.textPrimary,  fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Tap + to create your first budget',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return PageView.builder(
                          controller: PageController(viewportFraction: 0.85),
                          padEnds: false,
                          itemCount: budgets.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? AppSpacing.lg : AppSpacing.sm,
                                right: index == budgets.length - 1 ? AppSpacing.lg : 0,
                              ),
                              child: _BudgetCard(budget: budgets[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                // Recent Activity Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text('View All', style: TextStyle(color: AppColors.primaryLight, fontFamily: 'Inter')),
                      ),
                    ],
                  ),
                ),

                // Transaction List
                Expanded(
                  child: Consumer<BudgetProvider>(
                    builder: (context, provider, child) {
                       List<Transaction> allTransactions = [];
                       for (var budget in provider.budgets) {
                         allTransactions.addAll(budget.transactions);
                       }
                       allTransactions.sort((a, b) => b.date.compareTo(a.date));
                       
                       final recentTransactions = allTransactions.take(10).toList();

                       if (recentTransactions.isEmpty) {
                         return Center(
                           child: Text(
                             'No recent transactions',
                             style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                           ),
                         );
                       }

                       return ListView.separated(
                         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                         itemCount: recentTransactions.length,
                         separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                         itemBuilder: (context, index) {
                            final transaction = recentTransactions[index];
                            final budget = provider.budgets.firstWhere((b) => b.transactions.contains(transaction));
                            final currencySymbol = provider.getCurrencySymbol(budget.currency);
                            
                           return Container(
                             padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                             decoration: BoxDecoration(
                               color: AppColors.cardBackground,
                               borderRadius: BorderRadius.circular(AppRadius.md),
                               boxShadow: [AppShadows.cardShadow],
                             ),
                             child: ListTile(
                               leading: Container(
                                 padding: const EdgeInsets.all(AppSpacing.sm),
                                 decoration: BoxDecoration(
                                   color: transaction.isExpense 
                                       ? AppColors.danger.withValues(alpha: 0.1) 
                                       : AppColors.success.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(AppRadius.sm),
                                 ),
                                 child: Icon(
                                   transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                   color: transaction.isExpense ? AppColors.danger : AppColors.success,
                                   size: 20,
                                 ),
                               ),
                               title: Text(
                                 transaction.title,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,  color: AppColors.textPrimary),
                               ),
                               subtitle: Text(
                                 DateFormat('MMM d, y').format(transaction.date),
                                 style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                               ),
                               trailing: Text(
                                 '${currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16,
                                   color: transaction.isExpense ? AppColors.danger : AppColors.success,
                                   
                                 ),
                               ),
                               onTap: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BudgetDetailScreen(budgetId: budget.id),
                                  ),
                                );
                               },
                             ),
                           );
                         },
                       );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedCurrencyCode = 'INR';
    final currencyController = TextEditingController(text: 'India (INR)');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          backgroundColor: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Budget',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
                    hintText: 'e.g. Monthly Expenses',
                    prefixIcon: Icon(Icons.label_outline, color: AppColors.textSecondary),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: currencyController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary),
                    suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => CurrencySelectionDialog(
                        onSelect: (country, code) {
                          setState(() {
                            selectedCurrencyCode = code;
                            currencyController.text = '$country ($code)';
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: budgetController,
                  decoration: InputDecoration(
                    labelText: 'Initial Amount',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
                    prefixText: '${Provider.of<BudgetProvider>(context, listen: false).getCurrencySymbol(selectedCurrencyCode)} ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textLight),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final budget = double.tryParse(budgetController.text) ?? 0.0;
                          
                          if (name.isNotEmpty && budget > 0) {
                            Provider.of<BudgetProvider>(context, listen: false).addBudget(name, budget, selectedCurrencyCode);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Create', style: TextStyle(fontFamily: 'Inter')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final currencySymbol = provider.getCurrencySymbol(budget.currency);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol); 
    // Calculate raw progress (can > 1.0)
    final totalBudget = budget.budget + budget.totalIncome;
    final rawProgress = totalBudget > 0 ? (budget.totalExpenses / totalBudget) : 0.0;
    // Clamped progress for UI elements (0.0 - 1.0)
    final clampedProgress = rawProgress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BudgetDetailScreen(budgetId: budget.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currencyFormat.format(budget.balance),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                       if (value == 'trends') {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => BudgetTrendsScreen(budget: budget)),
                         );
                       } else if (value == 'pdf') {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => BudgetPdfPreviewScreen(budget: budget, currencySymbol: currencySymbol)),
                         );
                       }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'trends',
                         child: Row(
                           children: [
                             Icon(Icons.show_chart, color: AppColors.primary),
                             SizedBox(width: 8),
                             Text('Show Trends'),
                           ],
                         ),
                      ),
                      const PopupMenuItem(
                        value: 'pdf',
                         child: Row(
                           children: [
                             Icon(Icons.picture_as_pdf, color: AppColors.primary),
                             SizedBox(width: 8),
                             Text('Download PDF'),
                           ],
                         ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      child: const Icon(Icons.more_horiz, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24, // Increased size from 20 to 24
                          color: AppColors.primary, // Primary color
                          
                        ),
                      ),
                      Text(
                        '${((clampedProgress) * 100).toStringAsFixed(0)}%',
                        style: TextStyle( // Removed const to allow dynamic color if needed, though accent is fine
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(rawProgress), // Match progress color
                          
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      backgroundColor: AppColors.progressBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(rawProgress)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                   Text(
                    _getStatusText(rawProgress), 
                    style: TextStyle(
                      color: _getProgressColor(rawProgress), // Match color for emphasis? Or keep secondary? Let's use color.
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 1.0) {
      return AppColors.dangerDark; // Dark Red (> 100%)
    } else if (progress >= 1.0) {
      return AppColors.danger; // Light Red (100% - Limit Reached)
    } else if (progress > 0.8) {
      return AppColors.danger; // Light Red (80% - 99%)
    } else if (progress > 0.5) {
      return AppColors.warning; // Orange/Yellow (50% - 80%)
    } else {
      return AppColors.success; // Green (<= 50%)
    }
  }

  String _getStatusText(double progress) {
    if (progress > 1.0) {
      return "Critical: You've exceeded your budget!";
    } else if (progress >= 1.0) {
       return "Limit Reached: You've hit 100% of your budget.";
    } else if (progress > 0.8) {
      return "Alert: You are nearing your budget limit.";
    } else if (progress > 0.5) {
      return "Heads up: You've used over 50% of your budget.";
    } else {
      return "Excellent! Spending is well under control.";
    }
  }
}
