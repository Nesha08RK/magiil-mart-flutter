import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_product.dart';
import '../services/admin_product_service.dart';
import '../splash_screen.dart';
import 'import_xlsx_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_analytics_screen.dart';

/// Admin dashboard screen showing product counts and list.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminProductService _service = AdminProductService();
  bool _loading = true;
  List<AdminProduct> _products = [];
  List<AdminProduct> _filteredProducts = [];
  String _searchQuery = '';
  int _total = 0;
  int _inStock = 0;
  int _outOfStock = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final counts = await _service.getProductCounts();
      final products = await _service.fetchAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _total = counts['total'] ?? 0;
        _inStock = counts['in_stock'] ?? 0;
        _outOfStock = counts['out_of_stock'] ?? 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final nameMatch = product.name.toLowerCase().contains(_searchQuery);
          final categoryMatch = product.category.toLowerCase().contains(_searchQuery);
          return nameMatch || categoryMatch;
        }).toList();
      }
    });
  }

  Future<void> _deleteProduct(String id, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _service.deleteProduct(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _toggleOutOfStock(AdminProduct p) async {
    try {
      final updated = p.copyWith(isOutOfStock: !p.isOutOfStock);
      await _service.updateProduct(updated);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _editStock(AdminProduct p) async {
    final controller = TextEditingController(text: p.stock.toString());
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock count'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(int.tryParse(controller.text)),
              child: const Text('Save'))
        ],
      ),
    );

    if (result != null) {
      try {
        final updated = p.copyWith(stock: result, isOutOfStock: result <= 0);
        await _service.updateProduct(updated);
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Widget _buildProductCard(AdminProduct p) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: ListTile(
        leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
            ? Image.network(p.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
            : const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported)),
        title: Text(p.name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p.category} • ${p.basePrice.toStringAsFixed(2)} / ${p.baseUnit}'),
            Text('Stock: ${p.stock}'),
            if (p.isOutOfStock || p.stock <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                  child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit_stock') {
              await _editStock(p);
            } else if (value == 'toggle') {
              await _toggleOutOfStock(p);
            } else if (value == 'delete') {
              if (p.id != null) await _deleteProduct(p.id!, p.name);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit_stock', child: Text('Edit stock')),
            PopupMenuItem(value: 'toggle', child: Text(p.isOutOfStock ? 'Mark In Stock' : 'Mark Out of Stock')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import XLSX',
            onPressed: () async {
              // Navigate to import screen and refresh after completion
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportXlsxScreen()));
              await _load();
            },
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total products', style: theme.textTheme.labelSmall),
                                Text('$_total', style: theme.textTheme.headlineSmall),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('In stock', style: theme.textTheme.labelSmall),
                                Text('$_inStock', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.green)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Out of stock', style: theme.textTheme.labelSmall),
                                Text('$_outOfStock', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: _filterProducts,
                      decoration: InputDecoration(
                        hintText: 'Search by name or category...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  _filterProducts('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Products'
                          : 'Search Results (${_filteredProducts.length})',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _filteredProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                _searchQuery.isEmpty ? 'No products available' : 'No products match your search',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _filteredProducts.length,
                            itemBuilder: (_, idx) => _buildProductCard(_filteredProducts[idx]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF5A2E4A),
            ),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Products'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Orders'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }
}