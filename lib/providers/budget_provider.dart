import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = [];
  
  List<Budget> get budgets => _budgets;

  // Persistence Key
  static const String _storageKey = 'budget_data';

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _budgets = jsonList.map((json) => Budget.fromJson(json)).toList();
      await _cleanupOldTransactions(); 
    }
    notifyListeners();
  }

  Future<void> _cleanupOldTransactions() async {
    bool changed = false;
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));

    for (var budget in _budgets) {
      final initialCount = budget.transactions.length;
      budget.transactions.removeWhere((t) => t.date.isBefore(oneYearAgo));
      if (budget.transactions.length != initialCount) {
        changed = true;
      }
    }

    if (changed) {
      await saveData();
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_budgets.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  void addBudget(String name, double budgetAmount, String currency) {
    _budgets.insert(0, Budget(name: name, budget: budgetAmount, currency: currency));
    saveData();
    notifyListeners();
  }

  void updateBudget(String budgetId, {required String name, required double budgetAmount, required String currency}) {
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    budget.name = name;
    budget.budget = budgetAmount;
    budget.currency = currency;
    saveData();
    notifyListeners();
  }


  void addTransaction(String budgetId, Transaction transaction) {
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    budget.transactions.insert(0, transaction);
    saveData();
    notifyListeners();
  }

  void updateTransaction(String budgetId, Transaction updatedTransaction) {
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    final index = budget.transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      budget.transactions[index] = updatedTransaction;
      saveData();
      notifyListeners();
    }
  }

  void deleteTransaction(String budgetId, String transactionId) {
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    budget.transactions.removeWhere((t) => t.id == transactionId);
    saveData();
    notifyListeners();
  }
  
  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    saveData();
    notifyListeners();
  }

  // Currency Handling
  // Removed global _currency state.
  
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'CNY': '¥',
    'RUB': '₽',
    'KRW': '₩',
    'BRL': 'R\$',
    'ZAR': 'R',
    'MXN': 'Mex\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NZD': 'NZ\$',
    'CHF': 'Fr',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'TRY': '₺',
    'AED': 'د.إ',
    'SAR': '﷼',
  };

  final Map<String, String> _countryToCurrency = {
    'United States': 'USD',
    'India': 'INR',
    'Europe': 'EUR',
    'United Kingdom': 'GBP',
    'Japan': 'JPY',
    'Canada': 'CAD',
    'Australia': 'AUD',
    'China': 'CNY',
    'Russia': 'RUB',
    'South Korea': 'KRW',
    'Brazil': 'BRL',
    'South Africa': 'ZAR',
    'Mexico': 'MXN',
    'Singapore': 'SGD',
    'Hong Kong': 'HKD',
    'New Zealand': 'NZD',
    'Switzerland': 'CHF',
    'Sweden': 'SEK',
    'Norway': 'NOK',
    'Denmark': 'DKK',
    'Turkey': 'TRY',
    'United Arab Emirates': 'AED',
    'Saudi Arabia': 'SAR',
  };

  Map<String, String> get countryToCurrency => _countryToCurrency;

  String getCurrencySymbol(String currencyCode) => _currencySymbols[currencyCode] ?? currencyCode;
}
