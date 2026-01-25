class Item {
  final String? id;
  final String name;
  final double pricePerKg;
  final double? totalQuantity;
  final DateTime? createdAt;

  Item({
    this.id,
    required this.name,
    required this.pricePerKg,
    this.totalQuantity,
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
    };
  }

  Item copyWith({
    String? id,
    String? name,
    double? pricePerKg,
    double? totalQuantity,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
