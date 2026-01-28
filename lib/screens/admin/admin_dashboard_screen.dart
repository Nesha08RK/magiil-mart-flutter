import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_product.dart';
import '../../services/admin_service.dart';
import '../auth/login_screen.dart';
import 'add_product_dialog.dart';
import 'edit_product_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  late Future<List<AdminProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _adminService.fetchAllProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _adminService.fetchAllProducts();
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _deleteProduct(AdminProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _adminService.deleteProduct(product.id);
    _refreshProducts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  Future<void> _toggleOutOfStock(AdminProduct product) async {
    await _adminService.toggleOutOfStock(
      productId: product.id,
      isOutOfStock: !product.isOutOfStock,
    );

    _refreshProducts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          product.isOutOfStock
              ? 'Product marked as available'
              : 'Product marked as out of stock',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF5A2E4A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5A2E4A)),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<AdminProduct>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No products yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => AddProductDialog(
                          onProductAdded: _refreshProducts,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            // ✅ FIXED HERE
            onRefresh: () async => _refreshProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => AddProductDialog(
                            onProductAdded: _refreshProducts,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Product'),
                    ),
                  );
                }

                final product = products[index - 1];

                return ProductTile(
                  product: product,
                  onEdit: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => EditProductDialog(
                        product: product,
                        onProductUpdated: _refreshProducts,
                      ),
                    );
                  },
                  onToggleOutOfStock: () => _toggleOutOfStock(product),
                  onDelete: () => _deleteProduct(product),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final AdminProduct product;
  final VoidCallback onEdit;
  final VoidCallback onToggleOutOfStock;
  final VoidCallback onDelete;

  const ProductTile({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onToggleOutOfStock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: product.isOutOfStock
            ? Border.all(color: Colors.red.shade200, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${product.basePrice}/${product.baseUnit}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock: ${product.stock}',
              style: TextStyle(
                color: product.stock == 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onToggleOutOfStock,
                  icon: const Icon(Icons.local_shipping, size: 16),
                  label: Text(
                    product.isOutOfStock ? 'Available' : 'Out Stock',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
