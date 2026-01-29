/// Model representing a product for admin operations.
class AdminProduct {
  final int? id;
  final String name;
  final String category;
  final double basePrice;
  final String baseUnit;
  final int stock;
  final String? imageUrl;
  final bool isOutOfStock;

  AdminProduct({
    this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.baseUnit,
    required this.stock,
    this.imageUrl,
    this.isOutOfStock = false,
  });

  /// Create from Supabase row (Map)
  factory AdminProduct.fromMap(Map<String, dynamic> map) {
    return AdminProduct(
      id: map['id'] is int ? map['id'] as int : (map['id'] is String ? int.tryParse(map['id']) : null),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      basePrice: (map['base_price'] is num) ? (map['base_price'] as num).toDouble() : double.tryParse('${map['base_price']}') ?? 0.0,
      baseUnit: map['base_unit'] ?? '',
      stock: (map['stock'] is num) ? (map['stock'] as num).toInt() : int.tryParse('${map['stock']}') ?? 0,
      imageUrl: map['image_url'],
      isOutOfStock: (map['is_out_of_stock'] is bool) ? map['is_out_of_stock'] : '${map['is_out_of_stock']}' == 'true',
    );
  }

  /// Convert to map suitable for Supabase insert/update.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'base_price': basePrice,
      'base_unit': baseUnit,
      'stock': stock,
      'image_url': imageUrl,
      'is_out_of_stock': isOutOfStock,
    };
  }

  AdminProduct copyWith({
    int? id,
    String? name,
    String? category,
    double? basePrice,
    String? baseUnit,
    int? stock,
    String? imageUrl,
    bool? isOutOfStock,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      baseUnit: baseUnit ?? this.baseUnit,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
    );
  }

  @override
  String toString() {
    return 'AdminProduct(id: $id, name: $name, category: $category, basePrice: $basePrice, baseUnit: $baseUnit, stock: $stock, isOutOfStock: $isOutOfStock)';
  }
}

