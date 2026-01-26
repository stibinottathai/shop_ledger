import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String? id;
  final double amount;
  final String category; // Food, Travel, Rent, Bills, etc.
  final String paymentMethod; // Cash, UPI, Bank, Credit Card
  final DateTime date;
  final String? notes;
  final String? recurring; // Daily, Weekly, Monthly, or null/None

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.recurring,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    String? recurring,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      recurring: recurring ?? this.recurring,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    category,
    paymentMethod,
    date,
    notes,
    recurring,
  ];
}
