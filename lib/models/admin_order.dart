/// Model representing an order for admin operations.
class AdminOrder {
  final String id;
  final String userId;
  final String userEmail;
  final double totalAmount;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase row (Map)
  factory AdminOrder.fromMap(Map<String, dynamic> map) {
    return AdminOrder(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userEmail: map['user_email'] ?? 'N/A',
      totalAmount: (map['total_amount'] is num) ? (map['total_amount'] as num).toDouble() : double.tryParse('${map['total_amount']}') ?? 0.0,
      status: map['status'] ?? 'Placed',
      items: (map['items'] is List)
          ? (map['items'] as List)
              .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      createdAt: map['created_at'] is String ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] is String ? DateTime.parse(map['updated_at']) : null,
    );
  }

  /// Convert to map suitable for Supabase update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'total_amount': totalAmount,
      'status': status,
      'items': items.map((e) => e.toMap()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get formatted created date
  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (createdAt.isAfter(today)) {
      // Today - show time only
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (createdAt.isAfter(yesterday)) {
      // Yesterday
      return 'Yesterday ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      // Earlier - show date
      return '${createdAt.day}/${createdAt.month}/${createdAt.year.toString().substring(2)}';
    }
  }

  /// Copy with modifications
  AdminOrder copyWith({
    String? id,
    String? userId,
    String? userEmail,
    double? totalAmount,
    String? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model representing an item in an order.
class OrderItem {
  final String name;
  final double basePrice;
  final String baseUnit;
  final String selectedUnit;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    required this.selectedUnit,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  /// Create from map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      basePrice: (map['base_price'] is num) ? (map['base_price'] as num).toDouble() : double.tryParse('${map['base_price']}') ?? 0.0,
      baseUnit: map['base_unit'] ?? '',
      selectedUnit: map['selected_unit'] ?? '',
      unitPrice: (map['unit_price'] is num) ? (map['unit_price'] as num).toDouble() : double.tryParse('${map['unit_price']}') ?? 0.0,
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : int.tryParse('${map['quantity']}') ?? 0,
      totalPrice: (map['total_price'] is num) ? (map['total_price'] as num).toDouble() : double.tryParse('${map['total_price']}') ?? 0.0,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'base_price': basePrice,
      'base_unit': baseUnit,
      'selected_unit': selectedUnit,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}
