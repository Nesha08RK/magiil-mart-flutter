import 'package:supabase_flutter/supabase_flutter.dart';

class OrderPlacementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> placeOrderSnapshot({
    required String deliveryName,
    required String deliveryPhone,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPincode,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final payload = {
      'user_id': user.id,
      'items': items,
      'total_amount': totalAmount,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'delivery_name': deliveryName,
      'delivery_phone': deliveryPhone,
      'delivery_address': deliveryAddress,
      'delivery_city': deliveryCity,
      'delivery_pincode': deliveryPincode,
    };
    try {
      await _supabase.from('orders').insert(payload);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('does not exist') || msg.contains('column')) {
        await _supabase.from('orders').insert({
          'user_id': user.id,
          'items': items,
          'total_amount': totalAmount,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        rethrow;
      }
    }
  }
}
