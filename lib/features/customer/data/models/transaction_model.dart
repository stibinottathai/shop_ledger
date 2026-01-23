import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    super.id,
    super.customerId,
    super.supplierId,
    required super.amount,
    required super.type,
    required super.date,
    super.details,
    super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String).toLowerCase();
    late TransactionType type;
    if (typeStr == 'sale') {
      type = TransactionType.sale;
    } else if (typeStr == 'paymentin') {
      type = TransactionType.paymentIn;
    } else if (typeStr == 'purchase') {
      type = TransactionType.purchase;
    } else if (typeStr == 'paymentout') {
      type = TransactionType.paymentOut;
    } else {
      // Fallback for legacy 'payment'
      type = TransactionType.paymentIn;
    }

    return TransactionModel(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: type,
      date: DateTime.parse(json['date'] as String),
      details: json['details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr;
    switch (type) {
      case TransactionType.sale:
        typeStr = 'sale';
        break;
      case TransactionType.paymentIn:
        typeStr = 'paymentin';
        break;
      case TransactionType.purchase:
        typeStr = 'purchase';
        break;
      case TransactionType.paymentOut:
        typeStr = 'paymentout';
        break;
    }

    return {
      'customer_id': customerId,
      'supplier_id': supplierId,
      'amount': amount,
      'type': typeStr,
      'date': date.toIso8601String(),
      'details': details,
      // 'created_at': createdAt?.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      customerId: transaction.customerId,
      supplierId: transaction.supplierId,
      amount: transaction.amount,
      type: transaction.type,
      date: transaction.date,
      details: transaction.details,
      createdAt: transaction.createdAt,
    );
  }
}
