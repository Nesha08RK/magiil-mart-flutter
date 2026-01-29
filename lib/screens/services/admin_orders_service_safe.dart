import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_order.dart';

/// Service responsible for admin order operations using Supabase.
/// This version retries without timestamp fields if the DB schema lacks them.
class AdminOrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AdminOrder>> fetchAllOrders() async {
    try {
      final data = await _supabase.from('orders').select().order('created_at', ascending: false) as List<dynamic>;
      return data.map((e) => AdminOrder.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Stream<List<AdminOrder>> streamAllOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => AdminOrder.fromMap(Map<String, dynamic>.from(e as Map))).toList())
        .handleError((error) => throw Exception('Failed to stream orders: $error'));
  }

  Future<AdminOrder?> fetchOrderById(String orderId) async {
    try {
      final data = await _supabase.from('orders').select().eq('id', orderId).limit(1) as List<dynamic>;
      if (data.isEmpty) return null;
      return AdminOrder.fromMap(Map<String, dynamic>.from(data.first as Map));
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase.from('orders').update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()}).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Helper to detect missing-column errors in Postgrest responses
  bool _isMissingColumnError(Object e, String columnName) {
    final msg = e.toString().toLowerCase();
    return msg.contains('could not find') && msg.contains(columnName.toLowerCase());
  }

  Future<void> markPacked(String orderId) async {
    final now = DateTime.now().toIso8601String();
    try {
      await _supabase.from('orders').update({'status': 'Packed', 'packed_at': now, 'updated_at': now}).eq('id', orderId);
    } catch (e) {
      if (_isMissingColumnError(e, 'packed_at')) {
        // Retry without the timestamp column
        try {
          await _supabase.from('orders').update({'status': 'Packed', 'updated_at': now}).eq('id', orderId);
          return;
        } catch (e2) {
          throw Exception('Failed to mark order packed (retry without packed_at): $e2');
        }
      }
      throw Exception('Failed to mark order packed: $e');
    }
  }

  Future<void> markOutForDelivery(String orderId) async {
    final now = DateTime.now().toIso8601String();
    try {
      await _supabase.from('orders').update({'status': 'Out for Delivery', 'out_for_delivery_at': now, 'updated_at': now}).eq('id', orderId);
    } catch (e) {
      if (_isMissingColumnError(e, 'out_for_delivery_at')) {
        try {
          await _supabase.from('orders').update({'status': 'Out for Delivery', 'updated_at': now}).eq('id', orderId);
          return;
        } catch (e2) {
          throw Exception('Failed to mark out for delivery (retry without out_for_delivery_at): $e2');
        }
      }
      throw Exception('Failed to mark out for delivery: $e');
    }
  }

  Future<void> markDelivered(String orderId) async {
    final now = DateTime.now().toIso8601String();
    try {
      await _supabase.from('orders').update({'status': 'Delivered', 'delivered_at': now, 'updated_at': now}).eq('id', orderId);
    } catch (e) {
      if (_isMissingColumnError(e, 'delivered_at')) {
        try {
          await _supabase.from('orders').update({'status': 'Delivered', 'updated_at': now}).eq('id', orderId);
          return;
        } catch (e2) {
          throw Exception('Failed to mark delivered (retry without delivered_at): $e2');
        }
      }
      throw Exception('Failed to mark delivered: $e');
    }
  }

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
    }).handleError((error) => throw Exception('Failed to stream order stats: $error'));
  }
}
