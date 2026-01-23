import 'package:equatable/equatable.dart';

enum TransactionType { sale, paymentIn, purchase, paymentOut }

class Transaction extends Equatable {
  final String? id;
  final String? customerId;
  final String? supplierId;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? details;
  final DateTime? createdAt;

  const Transaction({
    this.id,
    this.customerId,
    this.supplierId,
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
    supplierId,
    amount,
    type,
    date,
    details,
    createdAt,
  ];
}
