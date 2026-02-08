/// Model representing an order for admin operations.
class AdminOrder {
  final String id;
  final String userId;
  final String userEmail;
  final String? customerName; // ✅ NEW
  final String? phoneNumber; // ✅ NEW
  final String? deliveryAddress; // ✅ NEW
  final double totalAmount;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.customerName,
    this.phoneNumber,
    this.deliveryAddress,
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
      customerName: map['customer_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      deliveryAddress: map['delivery_address'] as String?,
      totalAmount: (map['total_amount'] is num) ? (map['total_amount'] as num).toDouble() : double.tryParse('${map['total_amount']}') ?? 0.0,
      status: map['status'] ?? 'Placed',
      items: (map['items'] is List)
          ? (map['items'] as List)
              .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['created_at'] is DateTime ? map['created_at'] as DateTime : DateTime.now()),
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : (map['updated_at'] is DateTime ? map['updated_at'] as DateTime : null),
    );
  }

  /// Convert to map suitable for Supabase update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'delivery_address': deliveryAddress,
      'total_amount': totalAmount,
      'status': status,
      'items': items.map((e) => e.toMap()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get formatted created date
  String getFormattedDate() {
    final dt = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dt.isAfter(today)) {
      // Today - show time only
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.isAfter(yesterday)) {
      // Yesterday
      return 'Yesterday ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      // Earlier - show date
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    }
  }

  /// Copy with modifications
  AdminOrder copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? customerName,
    String? phoneNumber,
    String? deliveryAddress,
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
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
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
