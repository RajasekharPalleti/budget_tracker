import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/design_system.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final String currencySymbol;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onEdit,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol);
    final dateFormat = DateFormat('MMM d, y');

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (onDelete == null) return false;
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction?', style: TextStyle( fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(fontFamily: 'Inter')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle( color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Delete', style: TextStyle(fontFamily: 'Inter')),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [AppShadows.cardShadow],
        ),
        child: ListTile(
          onTap: onEdit,
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
            dateFormat.format(transaction.date),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
          ),
          trailing: Text(
            currencyFormat.format(transaction.amount),
            style: TextStyle(
              color: transaction.isExpense ? AppColors.danger : AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              
            ),
          ),
        ),
      ),
    );
  }
}
