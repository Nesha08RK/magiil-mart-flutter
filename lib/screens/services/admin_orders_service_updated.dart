import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_order.dart';

/// Service responsible for admin order operations using Supabase.
class AdminOrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all orders (admin view) - sorted by newest first
  Future<List<AdminOrder>> fetchAllOrders() async {
    try {
      final data = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false) as List<dynamic>;

      return data
          .map((e) => AdminOrder.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Stream all orders in real-time (for analytics and live updates)
  Stream<List<AdminOrder>> streamAllOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return data
          .map((e) => AdminOrder.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }).handleError((error) {
      throw Exception('Failed to stream orders: $error');
    });
  }

  /// Fetch order by ID
  Future<AdminOrder?> fetchOrderById(String orderId) async {
    try {
      final data = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .limit(1) as List<dynamic>;

      if (data.isEmpty) return null;

      return AdminOrder.fromMap(Map<String, dynamic>.from(data.first as Map));
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Update order status (generic)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Mark order as Packed and set packed_at timestamp
  Future<void> markPacked(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'Packed',
            'packed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to mark order packed: $e');
    }
  }

  /// Mark order as Out for Delivery and set out_for_delivery_at timestamp
  Future<void> markOutForDelivery(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'Out for Delivery',
            'out_for_delivery_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to mark out for delivery: $e');
    }
  }

  /// Mark order as Delivered and set delivered_at timestamp
  Future<void> markDelivered(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'Delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to mark delivered: $e');
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final orders = await fetchAllOrders();

      final totalOrders = orders.length;
      final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayOrders = orders.where((order) => order.createdAt.isAfter(todayStart)).toList();
      final todayRevenue = todayOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      final orderStatusCounts = {
        'Placed': orders.where((o) => o.status == 'Placed').length,
        'Packed': orders.where((o) => o.status == 'Packed').length,
        'Out for Delivery': orders.where((o) => o.status == 'Out for Delivery').length,
        'Delivered': orders.where((o) => o.status == 'Delivered').length,
      };

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'today_orders': todayOrders.length,
        'today_revenue': todayRevenue,
        'order_status_counts': orderStatusCounts,
      };
    } catch (e) {
      throw Exception('Failed to get order stats: $e');
    }
  }

  /// Stream order statistics in real-time
  Stream<Map<String, dynamic>> streamOrderStats() {
    return streamAllOrders().map((orders) {
      final totalOrders = orders.length;
      final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayOrders = orders.where((order) => order.createdAt.isAfter(todayStart)).toList();
      final todayRevenue = todayOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      final orderStatusCounts = {
        'Placed': orders.where((o) => o.status == 'Placed').length,
        'Packed': orders.where((o) => o.status == 'Packed').length,
        'Out for Delivery': orders.where((o) => o.status == 'Out for Delivery').length,
        'Delivered': orders.where((o) => o.status == 'Delivered').length,
      };

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'today_orders': todayOrders.length,
        'today_revenue': todayRevenue,
        'order_status_counts': orderStatusCounts,
      };
    }).handleError((error) {
      throw Exception('Failed to stream order stats: $error');
    });
  }
}
