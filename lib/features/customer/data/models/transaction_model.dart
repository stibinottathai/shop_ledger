import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    super.id,
    required super.customerId,
    required super.amount,
    required super.type,
    required super.date,
    super.details,
    super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: (json['type'] as String).toLowerCase() == 'sale'
          ? TransactionType.sale
          : TransactionType.payment,
      date: DateTime.parse(json['date'] as String),
      details: json['details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'amount': amount,
      'type': type == TransactionType.sale ? 'sale' : 'payment',
      'date': date.toIso8601String(),
      'details': details,
      // 'created_at': createdAt?.toIso8601String(), // Handle by DB or default
    };
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      customerId: transaction.customerId,
      amount: transaction.amount,
      type: transaction.type,
      date: transaction.date,
      details: transaction.details,
      createdAt: transaction.createdAt,
    );
  }
}
