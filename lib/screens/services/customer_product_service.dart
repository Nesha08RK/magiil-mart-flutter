import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for customer product view
class CustomerProduct {
  final String? id;
  final String name;
  final String category;
  final double basePrice;
  final String baseUnit;
  final int stock;
  final String? imageUrl;
  final bool isOutOfStock;
  final String? description;

  CustomerProduct({
    this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.baseUnit,
    required this.stock,
    this.imageUrl,
    this.isOutOfStock = false,
    this.description,
  });

  factory CustomerProduct.fromMap(Map<String, dynamic> map) {
    return CustomerProduct(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      basePrice: (map['base_price'] is num) ? (map['base_price'] as num).toDouble() : double.tryParse('${map['base_price']}') ?? 0.0,
      baseUnit: map['base_unit'] ?? '',
      stock: (map['stock'] is num) ? (map['stock'] as num).toInt() : int.tryParse('${map['stock']}') ?? 0,
      imageUrl: map['image_url'],
      isOutOfStock: (map['is_out_of_stock'] is bool) ? map['is_out_of_stock'] : '${map['is_out_of_stock']}' == 'true',
      description: map['description'],
    );
  }
}

/// Service responsible for customer product operations using Supabase.
class CustomerProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all products for customer (only available products)
  Future<List<CustomerProduct>> fetchProductsByCategory(String category) async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('category', category)
          .order('name', ascending: true) as List<dynamic>;

      return data
          .map((e) => CustomerProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch all available products (not out of stock)
  Future<List<CustomerProduct>> fetchAllAvailableProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('is_out_of_stock', false)
          .order('category', ascending: true) as List<dynamic>;

      return data
          .map((e) => CustomerProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch product by name
  Future<CustomerProduct?> fetchProductByName(String name) async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('name', name)
          .limit(1) as List<dynamic>;

      if (data.isEmpty) return null;

      return CustomerProduct.fromMap(Map<String, dynamic>.from(data.first as Map));
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Search products by name (customer side)
  Future<List<CustomerProduct>> searchProducts(String query) async {
    if (query.isEmpty) {
      return await fetchAllAvailableProducts();
    }

    try {
      final searchTerm = '%$query%';
      final data = await _supabase
          .from('products')
          .select()
          .ilike('name', searchTerm)
          .eq('is_out_of_stock', false)
          .order('name', ascending: true) as List<dynamic>;

      return data
          .map((e) => CustomerProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product details by ID
  Future<CustomerProduct?> getProductDetails(String productId) async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .limit(1) as List<dynamic>;

      if (data.isEmpty) return null;

      return CustomerProduct.fromMap(Map<String, dynamic>.from(data.first as Map));
    } catch (e) {
      throw Exception('Failed to fetch product details: $e');
    }
  }
}