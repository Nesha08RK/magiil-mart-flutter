import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin_product.dart';

/// Service for admin inventory management
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all products (admin view)
  Future<List<AdminProduct>> fetchAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => AdminProduct.fromMap(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Add new product (SAFE: int-only base_price)
  Future<AdminProduct> addProduct({
    required String name,
    required int basePrice,
    required String baseUnit,
    required int stock,
    String? category,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'base_price': basePrice, // ALWAYS int
        'base_unit': baseUnit,
        'stock': stock,
        'is_out_of_stock': stock == 0,
      };

      if (category != null && category.trim().isNotEmpty) {
        payload['category'] = category.trim();
      }

      final response =
          await _supabase.from('products').insert(payload).select().single();

      return AdminProduct.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Update product stock (SAFE)
  Future<void> updateProductStock({
    required String productId,
    required int newStock,
  }) async {
    try {
      await _supabase.from('products').update({
        'stock': newStock,
        'is_out_of_stock': newStock == 0,
      }).eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  /// Toggle out-of-stock status (SAFE)
  Future<void> toggleOutOfStock({
    required String productId,
    required bool isOutOfStock,
  }) async {
    try {
      await _supabase.from('products').update({
        'is_out_of_stock': isOutOfStock,
      }).eq('id', productId);
    } catch (e) {
      throw Exception('Failed to toggle out of stock: $e');
    }
  }

  /// Update product details
  Future<void> updateProduct({
    required String productId,
    required String name,
    required int basePrice,
    required String baseUnit,
  }) async {
    try {
      await _supabase
          .from('products')
          .update({
            'name': name.trim(),
            'base_price': basePrice,
            'base_unit': baseUnit,
          })
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Get user role from profiles table
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      throw Exception('Failed to fetch user role: $e');
    }
  }
}
