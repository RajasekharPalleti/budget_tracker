import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isExpense: json['isExpense'],
    );
  }
}
