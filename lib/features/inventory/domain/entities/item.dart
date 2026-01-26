class Item {
  final String? id;
  final String name;
  final double pricePerKg; // This is now pricePerUnit generically
  final double? totalQuantity;
  final String unit; // 'kg' or 'pcs'
  final DateTime? createdAt;

  Item({
    this.id,
    required this.name,
    required this.pricePerKg,
    this.totalQuantity,
    this.unit = 'kg',
    this.createdAt,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price_per_kg': pricePerKg,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      'unit': unit,
    };
  }

  Item copyWith({
    String? id,
    String? name,
    double? pricePerKg,
    double? totalQuantity,
    String? unit,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
