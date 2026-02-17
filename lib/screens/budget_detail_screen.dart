import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/currency_selection_dialog.dart';
import '../theme/design_system.dart';

class BudgetDetailScreen extends StatelessWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        // Find the budget safely
        Budget? budget;
        try {
          budget = provider.budgets.firstWhere((b) => b.id == budgetId);
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Navigator.of(context).pop();
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final currencySymbol = provider.getCurrencySymbol(budget!.currency);
        final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark, // Dark icons for light background
          child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(budget.name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.textPrimary),
                onPressed: () => _updateBudgetDialog(context, budget!),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.textPrimary),
                onPressed: () => _confirmDeleteBudget(context, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryCard(context, budget!, currencyFormat),
              Expanded(
                child: budget!.transactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final sortedTransactions = List<Transaction>.from(budget!.transactions)
                            ..sort((a, b) => b.date.compareTo(a.date));
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            itemCount: sortedTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = sortedTransactions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: TransactionListItem(
                                  transaction: transaction,
                                  onDelete: () {
                                    provider.deleteTransaction(budgetId, transaction.id);
                                  },
                                  onEdit: () {
                                    _showAddTransactionDialog(
                                      context,
                                      isExpense: transaction.isExpense,
                                      existingTransaction: transaction,
                                      currencySymbol: currencySymbol,
                                    );
                                  },
                                  currencySymbol: currencySymbol,
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOptions(context, currencySymbol),
            icon: const Icon(Icons.add), // Color from theme
            label: const Text('Add', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.accent,
          ),
        ));
      },
    );
  }

  void _showAddOptions(BuildContext context, String currencySymbol) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              child: const Icon(Icons.arrow_upward, color: AppColors.success),
            ),
            title: const Text('Add Income', style: TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              _showAddTransactionDialog(context, isExpense: false, currencySymbol: currencySymbol);
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.danger.withValues(alpha: 0.1),
              child: const Icon(Icons.arrow_downward, color: AppColors.danger),
            ),
            title: const Text('Add Expense', style: TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              _showAddTransactionDialog(context, isExpense: true, currencySymbol: currencySymbol);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(
    BuildContext context, {
    required bool isExpense,
    required String currencySymbol,
    Transaction? existingTransaction,
  }) {
    final titleController = TextEditingController(text: existingTransaction?.title);
    final amountController = TextEditingController(
      text: existingTransaction?.amount.toString(),
    );
    DateTime selectedDate = existingTransaction?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existingTransaction != null
                    ? 'Edit ${isExpense ? 'Expense' : 'Income'}'
                    : (isExpense ? 'Add Expense' : 'Add Income'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.danger : AppColors.success,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Tea, Salary',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amountController,
                decoration: InputDecoration( 
                  labelText: 'Amount',
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  ),
                  child: Text(
                    DateFormat('MMM d, y').format(selectedDate),
                    style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense ? AppColors.danger : AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0.0;

                  if (title.isNotEmpty && amount > 0) {
                    final provider = Provider.of<BudgetProvider>(context, listen: false);
                    
                    if (existingTransaction != null) {
                      final updatedTransaction = Transaction(
                        id: existingTransaction.id,
                        title: title,
                        amount: amount,
                        date: selectedDate,
                        isExpense: isExpense,
                      );
                      provider.updateTransaction(budgetId, updatedTransaction);
                    } else {
                      final transaction = Transaction(
                        title: title,
                        amount: amount,
                        date: selectedDate,
                        isExpense: isExpense,
                      );
                      provider.addTransaction(budgetId, transaction);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  existingTransaction != null ? 'Update' : 'Add Transaction', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Budget budget, NumberFormat format) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: AppColors.textSecondary, 
              fontSize: 14,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            format.format(budget.balance),
            style: TextStyle(
              color: budget.balance >= 0 ? AppColors.textPrimary : AppColors.danger,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: 'Income',
                amount: format.format(budget.totalIncome),
                icon: Icons.arrow_upward,
                color: AppColors.success,
                textColor: AppColors.textPrimary,
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              _buildSummaryItem(
                label: 'Expenses',
                amount: format.format(budget.totalExpenses),
                icon: Icons.arrow_downward,
                color: AppColors.danger,
                textColor: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Initial Budget', 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                ),
                Text(
                  format.format(budget.budget), 
                  style: const TextStyle(
                     color: AppColors.textPrimary, 
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontFamily: 'Inter')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          amount,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  void _updateBudgetDialog(BuildContext context, Budget budget) {
    final nameController = TextEditingController(text: budget.name);
    final budgetController = TextEditingController(text: budget.budget.toString());
    final currencyController = TextEditingController(text: budget.currency);
    String selectedCurrencyCode = budget.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Budget', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: currencyController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  suffixIcon: Icon(Icons.arrow_drop_down),
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
                  labelText: 'Budget Amount',
                  prefixText: '${Provider.of<BudgetProvider>(context, listen: false).getCurrencySymbol(selectedCurrencyCode)} ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
            ),
            ElevatedButton(
              child: const Text('Update', style: TextStyle(fontFamily: 'Inter')),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newBudget = double.tryParse(budgetController.text) ?? 0.0;
                
                if (newName.isNotEmpty && newBudget > 0) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Update', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to update the budget details?', style: TextStyle(fontFamily: 'Inter')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Confirm', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    Provider.of<BudgetProvider>(context, listen: false).updateBudget(
                      budgetId, 
                      name: newName, 
                      budgetAmount: newBudget, 
                      currency: selectedCurrencyCode
                    );
                    Navigator.pop(ctx);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: const Text('This will delete all transactions for this budget. This action cannot be undone.', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () {
              provider.deleteBudget(budgetId);
              Navigator.pop(ctx); 
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
