class Item {
  final String? id;
  final String name;
  final double pricePerKg; // This is now pricePerUnit generically
  final double? totalQuantity;
  final String unit; // 'kg' or 'pcs'
  final DateTime? createdAt;
  final String? barcode;
  final double? lowStockThreshold; // Threshold for low stock alerts

  Item({
    this.id,
    required this.name,
    required this.pricePerKg,
    this.totalQuantity,
    this.unit = 'kg',
    this.createdAt,
    this.barcode,
    this.lowStockThreshold,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String?,
      name: json['name'] as String,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      totalQuantity: json['total_quantity'] != null
          ? (json['total_quantity'] as num).toDouble()
          : null,
      unit: json['unit'] as String? ?? 'kg',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      barcode: json['barcode'] as String?,
      lowStockThreshold: json['low_stock_threshold'] != null
          ? (json['low_stock_threshold'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price_per_kg': pricePerKg,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      'unit': unit,
      if (barcode != null) 'barcode': barcode,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
    };
  }

  Item copyWith({
    String? id,
    String? name,
    double? pricePerKg,
    double? totalQuantity,
    String? unit,
    DateTime? createdAt,
    String? barcode,
    double? lowStockThreshold,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      barcode: barcode ?? this.barcode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
