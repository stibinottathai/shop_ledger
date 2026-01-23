import 'package:equatable/equatable.dart';

enum TransactionType { sale, payment }

class Transaction extends Equatable {
  final String? id;
  final String customerId;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? details;
  final DateTime? createdAt;

  const Transaction({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.date,
    this.details,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    customerId,
    amount,
    type,
    date,
    details,
    createdAt,
  ];
}
