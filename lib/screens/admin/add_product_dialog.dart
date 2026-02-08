import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin_product.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AdminProduct>> fetchAllProducts() async {
    final data = await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => AdminProduct.fromMap(e))
        .toList();
  }

  Future<AdminProduct> addProduct({
    required String name,
    required int basePrice,
    required String baseUnit,
    required int stock,
    String? category,
  }) async {
    final payload = {
      'name': name.trim(),
      'base_price': basePrice,
      'base_unit': baseUnit,
      'stock': stock,
      'is_out_of_stock': stock == 0,
      if (category != null) 'category': category.trim(),
    };

    final res =
        await _supabase.from('products').insert(payload).select().single();

    return AdminProduct.fromMap(res);
  }

  /// ✅ ANDROID-SAFE UPDATE
  Future<void> updateProduct({
    required dynamic productId, // UUID ONLY
    required String name,
    required int basePrice,
    required String baseUnit,
  }) async {
    await _supabase.rpc(
      'update_product_safe',
      params: {
        'p_id': productId,
        'p_name': name.trim(),
        'p_price': basePrice,
        'p_unit': baseUnit,
      },
    );
  }

  Future<void> updateProductStock({
    required dynamic productId,
    required int newStock,
  }) async {
    await _supabase.from('products').update({
      'stock': newStock,
      'is_out_of_stock': newStock == 0,
    }).eq('id', productId);
  }

  Future<void> toggleOutOfStock({
    required dynamic productId,
    required bool isOutOfStock,
  }) async {
    await _supabase
        .from('products')
        .update({'is_out_of_stock': isOutOfStock})
        .eq('id', productId);
  }

  Future<void> deleteProduct(dynamic productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }
}
