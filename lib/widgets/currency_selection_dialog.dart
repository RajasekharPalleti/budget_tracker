import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../theme/design_system.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final Function(String country, String currencyCode) onSelect;

  const CurrencySelectionDialog({super.key, required this.onSelect});

  @override
  State<CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: AppColors.cardBackground,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Currency',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Country',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Builder(
                builder: (context) {
                  final searchTerm = _searchController.text.toLowerCase();
                  final entries = provider.countryToCurrency.entries.where((entry) {
                    return entry.key.toLowerCase().contains(searchTerm) || entry.value.toLowerCase().contains(searchTerm);
                  }).toList();

                  if (entries.isEmpty) {
                    return Center(child: Text('No results found', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')));
                  }

                  return ListView.separated(
                    shrinkWrap: false,
                    itemCount: entries.length,
                    separatorBuilder: (ctx, index) => const Divider(color: AppColors.divider),
                    itemBuilder: (ctx, index) {
                      final entry = entries[index];
                      return ListTile(
                        title: Text(entry.key, style: const TextStyle( color: AppColors.textPrimary)),
                        subtitle: Text(entry.value, style: const TextStyle( color: AppColors.textSecondary)),
                        onTap: () {
                          widget.onSelect(entry.key, entry.value);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
