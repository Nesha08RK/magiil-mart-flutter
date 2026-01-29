import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_product.dart';

/// Service responsible for admin product operations using Supabase.
class AdminProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all products (admin view)
  Future<List<AdminProduct>> fetchAllProducts() async {
    try {
      final data = await _supabase.from('products').select().order('id', ascending: false) as List<dynamic>;
      return data.map((e) => AdminProduct.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get counts: total, inStock, outOfStock
  Future<Map<String, int>> getProductCounts() async {
    final all = await fetchAllProducts();
    final total = all.length;
    final outOfStock = all.where((p) => p.isOutOfStock || p.stock <= 0).length;
    final inStock = total - outOfStock;
    return {'total': total, 'in_stock': inStock, 'out_of_stock': outOfStock};
  }

  /// Insert new product or update existing (match by name + category)
  Future<void> upsertProduct(AdminProduct product) async {
    try {
      // Check if a product with same name + category exists
      final rows = await _supabase
          .from('products')
          .select('id')
          .eq('name', product.name)
          .eq('category', product.category)
          .limit(1) as List<dynamic>;

      if (rows.isNotEmpty) {
        final id = rows.first['id'];
        await _supabase.from('products').update(product.toMap()).eq('id', id);
        return;
      }

      // Insert new
      await _supabase.from('products').insert(product.toMap());
    } catch (e) {
      throw Exception('Failed to upsert product: $e');
    }
  }

  /// Update product by id
  Future<void> updateProduct(AdminProduct product) async {
    if (product.id == null) throw ArgumentError('Product id is required for update');
    try {
      await _supabase.from('products').update(product.toMap()).eq('id', product.id!);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product by id
  Future<void> deleteProduct(int id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
