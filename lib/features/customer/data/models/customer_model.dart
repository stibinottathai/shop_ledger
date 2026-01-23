import 'package:shop_ledger/features/customer/domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    super.id,
    required super.name,
    required super.phone,
    super.gstNumber,
    super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      gstNumber: json['gst_number'] as String?,
      createdAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'gst_number': gstNumber,
      // 'created_at': createdAt?.toIso8601String(), // Usually handled by DB
    };
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      gstNumber: customer.gstNumber,
      createdAt: customer.createdAt,
    );
  }
}
