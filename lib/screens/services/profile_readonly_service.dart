import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryProfile {
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String pincode;

  DeliveryProfile({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.pincode,
  });
}

class ProfileReadonlyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DeliveryProfile?> fetchDeliveryProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    Map<String, dynamic>? res;
    try {
      final first = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      res = first == null ? null : Map<String, dynamic>.from(first as Map);
      if (res == null) {
        final second = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        res = second == null ? null : Map<String, dynamic>.from(second as Map);
      }
    } catch (_) {
      final second = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      res = second == null ? null : Map<String, dynamic>.from(second as Map);
    }
    if (res == null) return null;
    final data = res;
    return DeliveryProfile(
      fullName: '${data['full_name'] ?? ''}',
      phone: '${data['phone'] ?? ''}',
      addressLine: '${(data['address_line'] ?? data['address']) ?? ''}',
      city: '${data['city'] ?? ''}',
      pincode: '${data['pincode'] ?? ''}',
    );
  }
}
