import 'package:flutter/material.dart';

import '../../models/admin_order.dart';
import '../../services/admin_orders_service.dart';

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
      await _service.updateOrderStatus(order.id, newStatus);
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
            Text('Customer: ${order.userEmail}',
                style: const TextStyle(fontSize: 12)),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12)),
            Text('Items: ${order.items.length}',
                style: const TextStyle(fontSize: 12)),
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
                  value: 'Out for Delivery',
                  child: Text('Mark Out for Delivery')),
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
              Text('Customer Email: ${order.userEmail}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Status: ${order.status}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Orders'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? const Center(
                      child: Text('No orders yet'),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Orders: ${_orders.length}',
                              style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          ...List.generate(
                            _orders.length,
                            (idx) => _buildOrderCard(_orders[idx]),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
