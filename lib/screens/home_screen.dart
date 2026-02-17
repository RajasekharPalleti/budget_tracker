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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        body: Stack(
          children: [
            // 2. Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + AppSpacing.md),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            Provider.of<UserProvider>(context).username,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: () => _showAddBudgetDialog(context),
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
                                    style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 18),
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
                          fontFamily: 'Inter',
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
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter', color: AppColors.textPrimary),
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
                                   fontFamily: 'Inter',
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold),
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
    final progress = budget.budget > 0 ? (budget.totalExpenses / (budget.budget + budget.totalIncome)).clamp(0.0, 1.0) : 0.0;

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
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currencyFormat.format(budget.balance),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
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
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '${((progress) * 100).toStringAsFixed(0)}%',
                        style: TextStyle( // Removed const to allow dynamic color if needed, though accent is fine
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress), // Match progress color
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.progressBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                   Text(
                    _getStatusText(progress), 
                    style: TextStyle(
                      color: _getProgressColor(progress), // Match color for emphasis? Or keep secondary? Let's use color.
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
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
    if (progress > 0.8) {
      return AppColors.danger; // Red
    } else if (progress > 0.5) {
      return Colors.amber; // Yellow/Amber
    } else {
      return AppColors.success; // Green
    }
  }

  String _getStatusText(double progress) {
    if (progress > 1.0) {
      return "Critical: Budget exceeded!";
    } else if (progress > 0.8) {
      return "Warning: You are approaching your limit.";
    } else if (progress > 0.5) {
      return "On track, but keep an eye on expenses.";
    } else {
      return "Excellent! Spending is well under control.";
    }
  }
}
