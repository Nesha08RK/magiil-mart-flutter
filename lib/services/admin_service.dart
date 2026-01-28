import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_product.dart';

/// Service for admin inventory management
class AdminService {
  final _supabase = Supabase.instance.client;

  /// Fetch all products (admin view)
  Future<List<AdminProduct>> fetchAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => AdminProduct.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Add new product
  Future<AdminProduct> addProduct({
    required String name,
    required int basePrice,
    required String baseUnit,
    required int stock,
    String? category,
  }) async {
    try {
      // Build payload only with columns likely present in DB.
      final Map<String, dynamic> payload = {
        'name': name,
        'base_price': basePrice,
        'base_unit': baseUnit,
        'stock': stock,
        'is_out_of_stock': stock == 0,
      };

      if (category != null && category.trim().isNotEmpty) {
        payload['category'] = category.trim();
      }

      final response = await _supabase.from('products').insert(payload).select().single();
      return AdminProduct.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // If Postgres complains about an unexpected column, retry without optional keys
      final msg = e.toString();
      if (msg.contains("Could not find the 'category'") || msg.contains('column "category" does not exist')) {
        try {
          final payload = {
            'name': name,
            'base_price': basePrice,
            'base_unit': baseUnit,
            'stock': stock,
            'is_out_of_stock': stock == 0,
          };
          final response = await _supabase.from('products').insert(payload).select().single();
          return AdminProduct.fromJson(response as Map<String, dynamic>);
        } catch (e2) {
          throw Exception('Failed to add product (retry): $e2');
        }
      }

      throw Exception('Failed to add product: $e');
    }
  }

  /// Update product stock
  Future<void> updateProductStock({
    required String productId,
    required int newStock,
  }) async {
    try {
      final payload = {
        'stock': newStock,
        'is_out_of_stock': newStock == 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        // Request the updated row back for debugging if needed
        await _supabase.from('products').update(payload).eq('id', productId).select().maybeSingle();
      } catch (e) {
        final msg = e.toString();
        // Debug log
        // ignore: avoid_print
        print('updateProductStock failed for payload=$payload error=$msg');
        if (msg.contains('column "updated_at" does not exist') || msg.contains('Could not find the')) {
          // Retry without updated_at
          final retryPayload = {
            'stock': newStock,
            'is_out_of_stock': newStock == 0,
          };
          // ignore: avoid_print
          print('Retrying updateProductStock with payload=$retryPayload');
          await _supabase.from('products').update(retryPayload).eq('id', productId).select().maybeSingle();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  /// Toggle out of stock status
  Future<void> toggleOutOfStock({
    required String productId,
    required bool isOutOfStock,
  }) async {
    try {
      final payload = {
        'is_out_of_stock': isOutOfStock,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await _supabase.from('products').update(payload).eq('id', productId).select().maybeSingle();
      } catch (e) {
        final msg = e.toString();
        // ignore: avoid_print
        print('toggleOutOfStock failed for payload=$payload error=$msg');
        if (msg.contains('column "updated_at" does not exist') || msg.contains('Could not find the')) {
          final retryPayload = {'is_out_of_stock': isOutOfStock};
          // ignore: avoid_print
          print('Retrying toggleOutOfStock with payload=$retryPayload');
          await _supabase.from('products').update(retryPayload).eq('id', productId).select().maybeSingle();
        } else {
          rethrow;
        }
      }
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
      final payload = {
        'name': name,
        'base_price': basePrice,
        'base_unit': baseUnit,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await _supabase.from('products').update(payload).eq('id', productId).select().maybeSingle();
      } catch (e) {
        final msg = e.toString();
        // ignore: avoid_print
        print('updateProduct failed for payload=$payload error=$msg');
        if (msg.contains('column "updated_at" does not exist') || msg.contains('Could not find the')) {
          final retryPayload = {
            'name': name,
            'base_price': basePrice,
            'base_unit': baseUnit,
          };
          // ignore: avoid_print
          print('Retrying updateProduct with payload=$retryPayload');
          await _supabase.from('products').update(retryPayload).eq('id', productId).select().maybeSingle();
        } else {
          rethrow;
        }
      }
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

      if (response == null) return null;
      return response['role'] as String?;
    } catch (e) {
      throw Exception('Failed to fetch user role: $e');
    }
  }
}
