import 'package:uuid/uuid.dart';
import 'transaction.dart';

class Budget {
  final String id;
  String name;
  double budget;
  List<Transaction> transactions;
  String currency; // Currency code, e.g., 'USD', 'INR'

  Budget({
    String? id,
    required this.name,
    required this.budget,
    List<Transaction>? transactions,
    this.currency = 'INR', // Default to INR
  })  : id = id ?? const Uuid().v4(),
        transactions = transactions ?? [];

  double get totalExpenses {
    return transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalIncome {
    return transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance {
    return (budget + totalIncome) - totalExpenses;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'budget': budget,
      'currency': currency,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'] ?? json['monthName'], // Handle migration from old 'monthName'
      budget: json['budget'],
      currency: json['currency'] ?? 'INR',
      transactions: ((json['transactions'] as List?) ?? [])
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }
}
