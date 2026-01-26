import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    super.id,
    required super.amount,
    required super.category,
    required super.paymentMethod,
    required super.date,
    super.notes,
    super.recurring,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toString(),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      recurring: map['recurring'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'notes': notes,
      'recurring': recurring,
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      amount: expense.amount,
      category: expense.category,
      paymentMethod: expense.paymentMethod,
      date: expense.date,
      notes: expense.notes,
      recurring: expense.recurring,
    );
  }
}
