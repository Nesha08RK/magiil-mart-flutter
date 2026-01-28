import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility to check user role
class RoleUtil {
  static const String adminRole = 'admin';
  static const String customerRole = 'customer';

  /// Get current user role from profiles table
  static Future<String?> getUserRole() async {
    try {
      final client = Supabase.instance.client;

      final currentUser = client.auth.currentUser;
      if (currentUser == null) return null;

      // Shortcut: treat this specific email as admin (fallback)
      // This allows logging in as admin@magiilmart.com to gain admin access
      // without changing existing customer logic or DB entries.
      final email = currentUser.email?.toLowerCase();
      if (email == 'admin@magiilmart.com') return adminRole;

      final userId = currentUser.id;

      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['role'] as String?;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == adminRole;
  }

  /// Check if current user is customer
  static Future<bool> isCustomer() async {
    final role = await getUserRole();
    return role == customerRole;
  }
}
