import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';

class SupplierModel extends Supplier {
  const SupplierModel({
    super.id,
    required super.name,
    required super.phone,
    super.gstNumber,
    super.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
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
      // 'created_at': createdAt?.toIso8601String(),
    };
  }

  factory SupplierModel.fromEntity(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      name: supplier.name,
      phone: supplier.phone,
      gstNumber: supplier.gstNumber,
      createdAt: supplier.createdAt,
    );
  }
}
