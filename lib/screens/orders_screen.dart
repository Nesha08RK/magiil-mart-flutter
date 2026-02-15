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
        return const Color(0xFF6B3E5E);
      case 'Packed':
        return const Color(0xFFC9A347);
      case 'Out for Delivery':
        return const Color(0xFF8B5A7E);
      case 'Delivered':
        return const Color(0xFF4A9D83);
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Placed':
        return Icons.hourglass_empty;
      case 'Packed':
        return Icons.inventory_2;
      case 'Out for Delivery':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, SupabaseClient supabase) {
    final status = (order['status'] as String?) ?? 'Placed';
    final orderId = order['id'] as String;
    final isCancelling = _cancellingOrderIds.contains(orderId);
    final canCancel = status == 'Placed' && !isCancelling;
    final totalAmount = order['total_amount'];
    final createdAt = order['created_at'] as String?;

    // Parse created date
    DateTime orderDate = DateTime.now();
    if (createdAt != null) {
      try {
        orderDate = DateTime.parse(createdAt);
      } catch (e) {
        // Use current time if parsing fails
      }
    }

    final formattedDate =
        '${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _statusColor(status).withOpacity(0.1),
                    _statusColor(status).withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(status),
                      size: 20,
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹ $totalAmount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC9A347),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF6B3E5E).withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFF6B3E5E),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B3E5E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: canCancel
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text(
                                      'Cancel Order?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    content: const Text(
                                      'This will cancel your order and restore the stock.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6E6E6E),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text(
                                          'Keep Order',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B3E5E),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _requestCancellation(orderId, context);
                                        },
                                        child: const Text(
                                          'Cancel Order',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: isCancelling
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6B3E5E),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Cancelling...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6E6E6E),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Cannot Cancel',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                  ),
                ],
              ),
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
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        appBar: AppBar(
          title: const Text('My Orders'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please login to view orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B3E5E)),
              ),
            );
          }
          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B3E5E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: const Color(0xFF6B3E5E).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to place your first order',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final activeOrders =
              data.where((o) => (o['status'] as String?) != 'Cancelled').toList();
          final cancelledOrders =
              data.where((o) => (o['status'] as String?) == 'Cancelled').toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeOrders.isNotEmpty) ...[
                    Text(
                      'Active Orders',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeOrders.length,
                      itemBuilder: (context, idx) =>
                          _buildOrderCard(activeOrders[idx] as Map<String, dynamic>, supabase),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (cancelledOrders.isNotEmpty) ...[
                    Text(
                      'Cancelled Orders (${cancelledOrders.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cancelledOrders.length,
                      itemBuilder: (context, idx) =>
                          _buildOrderCard(cancelledOrders[idx] as Map<String, dynamic>, supabase),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

