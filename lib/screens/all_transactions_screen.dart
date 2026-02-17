import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../screens/budget_detail_screen.dart';
import '../theme/design_system.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = '';
  String _selectedType = 'All'; // All, Expense, Income
  String _selectedDateRange = 'Last Year'; // This Month, Last 3 Months, Last Year, Custom
  DateTimeRange? _customDateRange;

  void _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5), // Allow going back further if needed for custom
      lastDate: now,
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 30)), 
        end: now
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateRange = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _buildFilterChip('All', _selectedType == 'All', () => setState(() => _selectedType = 'All')),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Expense', _selectedType == 'Expense', () => setState(() => _selectedType = _selectedType == 'Expense' ? 'All' : 'Expense')),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Income', _selectedType == 'Income', () => setState(() => _selectedType = _selectedType == 'Income' ? 'All' : 'Income')),
                const SizedBox(width: AppSpacing.md),
                Container(width: 1, height: 24, color: AppColors.divider), // Separator
                const SizedBox(width: AppSpacing.md),
                _buildFilterChip('This Month', _selectedDateRange == 'This Month', () => setState(() => _selectedDateRange = _selectedDateRange == 'This Month' ? 'Last Year' : 'This Month')),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Last 3 Months', _selectedDateRange == 'Last 3 Months', () => setState(() => _selectedDateRange = _selectedDateRange == 'Last 3 Months' ? 'Last Year' : 'Last 3 Months')),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Custom', _selectedDateRange == 'Custom', () {
                  if (_selectedDateRange == 'Custom') {
                     setState(() => _selectedDateRange = 'Last Year');
                  } else {
                    _showCustomDateRangePicker();
                  }
                }),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),

          // Transaction List
          Expanded(
            child: Consumer<BudgetProvider>(
              builder: (context, provider, child) {
                // 1. Flatten all transactions
                List<TransactionWrapper> allTransactions = [];
                for (var budget in provider.budgets) {
                  for (var transaction in budget.transactions) {
                    allTransactions.add(TransactionWrapper(transaction, budget.id, budget.currency));
                  }
                }

                // 2. Filter Logic
                final filteredTransactions = allTransactions.where((wrapper) {
                  final t = wrapper.transaction;
                  
                  // Filter by Search
                  if (_searchQuery.isNotEmpty && !t.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }

                  // Filter by Type
                  if (_selectedType == 'Expense' && !t.isExpense) return false;
                  if (_selectedType == 'Income' && t.isExpense) return false;

                  final now = DateTime.now();
                  
                  if (_selectedDateRange == 'Custom' && _customDateRange != null) {
                    // Custom Range: Inclusive of start and end dates
                    // Use start of day for start date and end of day for end date comparison if needed,
                    // but simple IsAfter/IsBefore works if we normalize.
                    // Let's rely on standard logic: date >= start && date <= end
                    
                    final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
                    final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
                    
                    if (t.date.isBefore(start) || t.date.isAfter(end)) return false;
                    
                  } else {
                    // Standard Filters with 1-Year Hard Limit
                     final difference = now.difference(t.date).inDays;
                     if (difference > 365) return false;

                     if (_selectedDateRange == 'This Month') {
                       if (t.date.month != now.month || t.date.year != now.year) return false;
                     } else if (_selectedDateRange == 'Last 3 Months') {
                        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
                        if (t.date.isBefore(threeMonthsAgo)) return false;
                     }
                  }
                  
                  return true;
                }).toList();

                // 3. Sort
                filteredTransactions.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  itemCount: filteredTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final wrapper = filteredTransactions[index];
                    final t = wrapper.transaction;
                    final currencySymbol = provider.getCurrencySymbol(wrapper.currency);

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
                            color: t.isExpense 
                                ? AppColors.danger.withValues(alpha: 0.1) 
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            t.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                            color: t.isExpense ? AppColors.danger : AppColors.success,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          t.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter', color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, y • h:mm a').format(t.date),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                        ),
                        trailing: Text(
                          '${currencySymbol}${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: t.isExpense ? AppColors.danger : AppColors.success,
                            fontFamily: 'Inter',
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudgetDetailScreen(budgetId: wrapper.budgetId),
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
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textLight : AppColors.textSecondary,
            fontFamily: 'Inter',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class TransactionWrapper {
  final Transaction transaction;
  final String budgetId;
  final String currency;

  TransactionWrapper(this.transaction, this.budgetId, this.currency);
}
