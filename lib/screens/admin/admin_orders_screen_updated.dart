import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_order.dart';
import '../services/admin_orders_service.dart';

/// Admin orders screen showing all customer orders.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  _AdminOrdersScreenState createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminOrdersService _service = AdminOrdersService();
  bool _loading = true;
  List<AdminOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtimeListener();
  }

  /// ✅ Setup realtime listener for new orders (StreamBuilder handles realtime)
  void _setupRealtimeListener() {
    debugPrint('Realtime listener setup: StreamBuilder will handle updates');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final orders = await _service.fetchAllOrders();
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(AdminOrder order, String newStatus) async {
    try {
      if (newStatus == 'Packed') {
        await _service.markPacked(order.id);
      } else if (newStatus == 'Out for Delivery') {
        await _service.markOutForDelivery(order.id);
      } else if (newStatus == 'Delivered') {
        await _service.markDelivered(order.id);
      } else {
        await _service.updateOrderStatus(order.id, newStatus);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Placed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case 'Packed':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'Out for Delivery':
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        break;
      case 'Delivered':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'Cancelled': // ✅ NEW
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOrderCard(AdminOrder order) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}',
            style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // ✅ Show customer name if available
            if (order.customerName != null && order.customerName!.isNotEmpty)
              Text('Customer: ${order.customerName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Email: ${order.userEmail}', style: const TextStyle(fontSize: 12)),
            // ✅ Show phone number if available
            if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty)
              Text('Phone: ${order.phoneNumber}', style: const TextStyle(fontSize: 12)),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12)),
            Text('Items: ${order.items.length}', style: const TextStyle(fontSize: 12)),
            Text('Date: ${order.getFormattedDate()}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildStatusBadge(order.status),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _updateOrderStatus(order, value);
          },
          itemBuilder: (ctx) => [
            if (order.status == 'Placed')
              const PopupMenuItem(value: 'Packed', child: Text('Mark as Packed')),
            if (order.status == 'Packed')
              const PopupMenuItem(
                  value: 'Out for Delivery', child: Text('Mark Out for Delivery')),
            if (order.status == 'Out for Delivery')
              const PopupMenuItem(value: 'Delivered', child: Text('Mark Delivered')),
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
              enabled: false,
            ),
          ],
        ),
        onTap: () {
          _showOrderDetails(order);
        },
      ),
    );
  }

  void _showOrderDetails(AdminOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Customer Name
              if (order.customerName != null && order.customerName!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Name: ${order.customerName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                ),
              Text('Customer Email: ${order.userEmail}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              // ✅ Phone Number
              if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Phone: ${order.phoneNumber}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              // ✅ Delivery Address
              if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Delivery Address:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(order.deliveryAddress!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              const SizedBox(height: 8),
              Text('Status: ${order.status}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order.status == 'Cancelled' ? Colors.red : Colors.black,
                  )),
              const SizedBox(height: 8),
              Text('Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Order Date: ${order.getFormattedDate()}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '• ${item.name} (${item.selectedUnit})\n  Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Orders'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          final ordersData = snapshot.data!;
          final orders = ordersData.map((e) => AdminOrder.fromMap(e as Map<String, dynamic>)).toList();

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Real-time order count
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Orders: ${orders.length}', style: theme.textTheme.headlineSmall),
                            Text(
                              "Active: ${orders.where((o) => o.status != 'Delivered' && o.status != 'Cancelled').length}",
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${orders.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Orders list with realtime updates
                  ...List.generate(
                    orders.length,
                    (idx) => _buildOrderCard(orders[idx]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
