import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling order cancellation and stock reversion
class OrderCancellationService {
  final _supabase = Supabase.instance.client;

  /// Customer requests cancellation (only for 'Placed' status)
  Future<void> requestCancellation(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'cancel_requested': true,
            'cancel_requested_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to request cancellation: $e');
    }
  }

  /// Admin rejects cancellation request
  Future<void> rejectCancellation(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'cancel_requested': false,
            'cancel_requested_at': null,
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to reject cancellation: $e');
    }
  }

  /// Admin approves cancellation and restores stock
  Future<void> approveCancellation(String orderId) async {
    try {
      // 1. Fetch the order to get items
      final orderData = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single() as Map<String, dynamic>;

      final items = orderData['items'] as List<dynamic>;

      // 2. Restore stock for each item
      for (final item in items) {
        final itemMap = item as Map<String, dynamic>;
        final productName = itemMap['name'] as String;
        final quantityOrdered = (itemMap['quantity'] is num)
            ? (itemMap['quantity'] as num).toInt()
            : int.tryParse('${itemMap['quantity']}') ?? 0;

        // 3. Fetch current product
        final productData = await _supabase
            .from('products')
            .select('id, stock, is_out_of_stock')
            .eq('name', productName)
            .limit(1) as List<dynamic>;

        if (productData.isEmpty) continue;

        final productId = productData.first['id'];
        final currentStock = (productData.first['stock'] is num)
            ? (productData.first['stock'] as num).toInt()
            : int.tryParse('${productData.first['stock']}') ?? 0;

        // 4. Restore stock
        final restoredStock = currentStock + quantityOrdered;
        final isOutOfStock = restoredStock <= 0;

        await _supabase
            .from('products')
            .update({
              'stock': restoredStock,
              'is_out_of_stock': isOutOfStock,
            })
            .eq('id', productId);
      }

      // 5. Update order status to cancelled
      await _supabase
          .from('orders')
          .update({
            'status': 'Cancelled',
            'cancel_requested': false,
            'cancel_requested_at': null,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to approve cancellation: $e');
    }
  }

  /// Get orders with pending cancellation requests (for admin)
  Future<List<Map<String, dynamic>>> getPendingCancellations() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('cancel_requested', true)
          .order('created_at', ascending: false) as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch pending cancellations: $e');
    }
  }

  /// Check if order can be cancelled (status must be 'Placed')
  bool canRequestCancellation(String status) {
    return status == 'Placed';
  }
}
