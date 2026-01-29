import 'package:flutter/material.dart';

import '../../services/admin_product_service.dart';
import '../../services/admin_orders_service.dart';

/// Admin analytics screen showing business metrics.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminProductService _productService = AdminProductService();
  final AdminOrdersService _orderService = AdminOrdersService();

  bool _loading = true;
  Map<String, dynamic> _productStats = {};
  Map<String, dynamic> _orderStats = {};

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
      final productCounts = await _productService.getProductCounts();
      final orderStats = await _orderService.getOrderStats();

      setState(() {
        _productStats = productCounts;
        _orderStats = orderStats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
              ],
            ),
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
        title: const Text('Admin - Analytics'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Section
                    Text(
                      'Product Inventory',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          title: 'Total Products',
                          value: '${_productStats['total'] ?? 0}',
                          icon: Icons.inventory,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'In Stock',
                          value: '${_productStats['in_stock'] ?? 0}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          title: 'Out of Stock',
                          value: '${_productStats['out_of_stock'] ?? 0}',
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Orders Section
                    Text(
                      'Order Analytics',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          title: 'Total Orders',
                          value: '${_orderStats['total_orders'] ?? 0}',
                          icon: Icons.receipt,
                          color: Colors.purple,
                        ),
                        _buildStatCard(
                          title: 'Today Orders',
                          value: '${_orderStats['today_orders'] ?? 0}',
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          title: 'Total Revenue',
                          value: '₹${(_orderStats['total_revenue'] ?? 0).toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: Colors.teal,
                        ),
                        _buildStatCard(
                          title: 'Today Revenue',
                          value: '₹${(_orderStats['today_revenue'] ?? 0).toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Order Status Breakdown
                    Text(
                      'Order Status Breakdown',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusRow(
                              'Placed',
                              _orderStats['order_status_counts']?['Placed'] ?? 0,
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                              'Packed',
                              _orderStats['order_status_counts']?['Packed'] ?? 0,
                              Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                              'Out for Delivery',
                              _orderStats['order_status_counts']?['Out for Delivery'] ?? 0,
                              Colors.purple,
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                              'Delivered',
                              _orderStats['order_status_counts']?['Delivered'] ?? 0,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusRow(String status, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
