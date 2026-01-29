import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Set<String> _cancellingOrderIds = {};

  Future<void> _requestCancellation(String orderId, BuildContext context) async {
    final supabase = Supabase.instance.client;

    setState(() => _cancellingOrderIds.add(orderId));

    try {
      final orderData = await supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single() as Map<String, dynamic>;

      final items = orderData['items'] as List<dynamic>?;
      final currentStatus = orderData['status'] as String?;

      if (currentStatus != 'Placed') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot cancel order with status: $currentStatus'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (items != null) {
        for (final item in items) {
          final itemMap = item as Map<String, dynamic>;
          final productName = itemMap['name'] as String?;
          final quantityOrdered = (itemMap['quantity'] is num)
              ? (itemMap['quantity'] as num).toInt()
              : int.tryParse('${itemMap['quantity']}') ?? 0;

          if (productName == null || quantityOrdered <= 0) continue;

          final productData = await supabase
              .from('products')
              .select('id, stock')
              .eq('name', productName)
              .limit(1) as List<dynamic>;

          if (productData.isNotEmpty) {
            final productId = productData.first['id'];
            final currentStock = (productData.first['stock'] is num)
                ? (productData.first['stock'] as num).toInt()
                : int.tryParse('${productData.first['stock']}') ?? 0;

            final restoredStock = currentStock + quantityOrdered;

            await supabase
                .from('products')
                .update({
                  'stock': restoredStock,
                  'is_out_of_stock': restoredStock <= 0,
                })
                .eq('id', productId);
          }
        }
      }

      await supabase
          .from('orders')
          .update({
            'status': 'Cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled & stock restored'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancellingOrderIds.remove(orderId));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.blue;
      case 'Packed':
        return Colors.orange;
      case 'Out for Delivery':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'Placed':
        return const Icon(Icons.hourglass_empty, color: Colors.blue);
      case 'Packed':
        return const Icon(Icons.inventory, color: Colors.orange);
      case 'Out for Delivery':
        return const Icon(Icons.local_shipping, color: Colors.purple);
      case 'Delivered':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_empty);
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, SupabaseClient supabase) {
    final status = (order['status'] as String?) ?? 'Placed';
    final orderId = order['id'] as String;
    final isCancelling = _cancellingOrderIds.contains(orderId);
    final canCancel = status == 'Placed' && !isCancelling;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹ ${order['total_amount']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Status: $status',
                        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600)),
                  ],
                ),
                _statusIcon(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: canCancel
                      ? ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cancel Order?'),
                                content: const Text('This will cancel your order and restore stock.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _requestCancellation(orderId, context);
                                    },
                                    child: const Text('Cancel Order'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancel Order'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Center(
                            child: isCancelling
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 8),
                                      Text('Cancelling...', style: TextStyle(fontSize: 12)),
                                    ],
                                  )
                                : Text('Cannot Cancel', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ),
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
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login to see orders')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('orders').stream(primaryKey: ['id']).eq('user_id', user.id).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data ?? [];

          if (data.isEmpty) return const Center(child: Text('No orders yet'));

          final activeOrders = data.where((o) => (o['status'] as String?) != 'Cancelled').toList();
          final cancelledOrders = data.where((o) => (o['status'] as String?) == 'Cancelled').toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                if (activeOrders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeOrders.length,
                          itemBuilder: (context, idx) => _buildOrderCard(activeOrders[idx] as Map<String, dynamic>, supabase),
                        ),
                      ],
                    ),
                  ),

                if (cancelledOrders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cancelled Orders (${cancelledOrders.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cancelledOrders.length,
                          itemBuilder: (context, idx) => _buildOrderCard(cancelledOrders[idx] as Map<String, dynamic>, supabase),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

