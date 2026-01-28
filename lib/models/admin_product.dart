/// Admin Product Model
/// Used by admin to manage inventory
class AdminProduct {
  final String id;
  final String name;
  final int basePrice; // Price per base unit
  final String baseUnit; // kg, L, piece, etc.
  final int stock; // Current stock quantity
  final bool isOutOfStock;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminProduct({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    required this.stock,
    required this.isOutOfStock,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: Supabase may return nulls or DateTime objects
    String id = json['id']?.toString() ?? '';
    String name = json['name']?.toString() ?? '';

    // base_price can be int or num
    final basePriceNum = json['base_price'];
    int basePrice = 0;
    if (basePriceNum is int) {
      basePrice = basePriceNum;
    } else if (basePriceNum is double) {
      basePrice = basePriceNum.toInt();
    } else if (basePriceNum is String) {
      basePrice = int.tryParse(basePriceNum) ?? 0;
    }

    String baseUnit = json['base_unit']?.toString() ?? '';
    int stock = (json['stock'] is int)
        ? json['stock'] as int
        : (json['stock'] is num ? (json['stock'] as num).toInt() : 0);
    bool isOutOfStock = json['is_out_of_stock'] is bool
        ? json['is_out_of_stock'] as bool
        : (stock == 0);

    String? category = json['category']?.toString();

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) {
        final dt = DateTime.tryParse(v);
        return dt ?? DateTime.now();
      }
      return DateTime.now();
    }

    final createdAt = parseDate(json['created_at']);
    final updatedAt = parseDate(json['updated_at']);

    return AdminProduct(
      id: id,
      name: name,
      basePrice: basePrice,
      baseUnit: baseUnit,
      stock: stock,
      isOutOfStock: isOutOfStock,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'base_price': basePrice,
      'base_unit': baseUnit,
      'stock': stock,
      'is_out_of_stock': isOutOfStock,
      'category': category,
    };
  }

  /// Copy with modifications
  AdminProduct copyWith({
    String? id,
    String? name,
    int? basePrice,
    String? baseUnit,
    int? stock,
    bool? isOutOfStock,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      baseUnit: baseUnit ?? this.baseUnit,
      stock: stock ?? this.stock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
