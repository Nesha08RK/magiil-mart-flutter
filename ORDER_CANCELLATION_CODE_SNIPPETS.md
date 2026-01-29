# 📋 Order Cancellation - Copy-Paste Code Snippets

## For Customer Orders Screen

### Import at Top
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Add these imports
import '../dialogs/cancellation_dialogs.dart';
import '../../services/order_cancellation_service.dart';
```

### In Order List/Card Widget
Find where you display the order status/details. Add this button in the card/row:

```dart
// Inside your order card build method, add this:
Padding(
  padding: const EdgeInsets.only(top: 12),
  child: Row(
    children: [
      // Other buttons here...
      
      // Add this button:
      if (order['status'] == 'Placed' && order['cancel_requested'] != true)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCancellationDialog(context, order),
            icon: const Icon(Icons.cancel),
            label: const Text('Request Cancellation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ),
    ],
  ),
)
```

### State Methods to Add
Add these methods to your screen's State class:

```dart
void _showCancellationDialog(BuildContext context, Map<String, dynamic> order) {
  showDialog(
    context: context,
    builder: (context) => ConfirmCancellationDialog(
      orderEmail: order['user_email'] ?? 'unknown@email.com',
      onConfirm: () async {
        Navigator.pop(context);
        await _requestCancellation(order['id']);
      },
      onCancel: () => Navigator.pop(context),
    ),
  );
}

Future<void> _requestCancellation(String orderId) async {
  try {
    final service = OrderCancellationService();
    await service.requestCancellation(orderId);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cancellation request sent to admin for review.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Refresh the screen to show updated order status
    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to request cancellation: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## For Admin Orders Screen

### Import at Top
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Add these imports
import '../../services/order_cancellation_service.dart';
import '../dialogs/cancellation_dialogs.dart';
```

### In Order Card - Add Visual Indicator
Find where you build the order card. Add this near the status badge:

```dart
// In your order card build, add this indicator:
if (order.cancelRequested)
  Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.amber[100],
      border: Border.all(color: Colors.amber, width: 2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 18),
        const SizedBox(width: 8),
        Text(
          'Cancellation Requested',
          style: TextStyle(
            color: Colors.amber[700],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  ),
```

### In Popup Menu - Add Actions
Find your popup menu or action buttons. Add these:

```dart
// In your popup menu, add these items:
if (order.cancelRequested) ...[
  const PopupMenuDivider(),
  PopupMenuItem(
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 18),
        SizedBox(width: 12),
        Text('Approve Cancellation'),
      ],
    ),
    onTap: () => Future.delayed(
      const Duration(milliseconds: 200),
      () => _approveCancellation(context, order),
    ),
  ),
  PopupMenuItem(
    child: const Row(
      children: [
        Icon(Icons.cancel, color: Colors.red, size: 18),
        SizedBox(width: 12),
        Text('Reject Cancellation'),
      ],
    ),
    onTap: () => Future.delayed(
      const Duration(milliseconds: 200),
      () => _rejectCancellation(context, order),
    ),
  ),
],
```

### State Methods to Add
Add these methods to your admin screen's State class:

```dart
void _approveCancellation(BuildContext context, AdminOrder order) {
  showDialog(
    context: context,
    builder: (context) => AdminCancellationDialog(
      customerEmail: order.userEmail,
      totalAmount: order.totalAmount,
      onApprove: () async {
        Navigator.pop(context);
        await _processCancellationApproval(context, order.id);
      },
      onReject: () => Navigator.pop(context),
    ),
  );
}

void _rejectCancellation(BuildContext context, AdminOrder order) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject Cancellation Request?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer: ${order.userEmail}'),
          const SizedBox(height: 12),
          const Text(
            'The order will remain active and no stock will be restored.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _processCancellationRejection(context, order.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Reject Request'),
        ),
      ],
    ),
  );
}

Future<void> _processCancellationApproval(BuildContext context, String orderId) async {
  try {
    final service = OrderCancellationService();
    await service.approveCancellation(orderId);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Cancellation approved. Stock has been restored.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Refresh orders list
    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error approving cancellation: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Future<void> _processCancellationRejection(BuildContext context, String orderId) async {
  try {
    final service = OrderCancellationService();
    await service.rejectCancellation(orderId);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Cancellation request rejected.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Refresh orders list
    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error rejecting cancellation: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## AdminOrder Model Update (Optional but Recommended)

If using the AdminOrder model, update `lib/models/admin_order.dart`:

### Add Fields to Class
```dart
class AdminOrder {
  final String id;
  final String userId;
  final String userEmail;
  final double totalAmount;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Add these three fields:
  final bool cancelRequested;
  final DateTime? cancelRequestedAt;
  final DateTime? cancelledAt;

  AdminOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
    this.updatedAt,
    // Add these three parameters:
    this.cancelRequested = false,
    this.cancelRequestedAt,
    this.cancelledAt,
  });
```

### Update fromMap Factory
```dart
  factory AdminOrder.fromMap(Map<String, dynamic> map) {
    return AdminOrder(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userEmail: map['user_email'] as String,
      totalAmount: (map['total_amount'] is num)
          ? (map['total_amount'] as num).toDouble()
          : double.tryParse('${map['total_amount']}') ?? 0.0,
      status: map['status'] as String? ?? 'Placed',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      // Add these:
      cancelRequested: map['cancel_requested'] as bool? ?? false,
      cancelRequestedAt: map['cancel_requested_at'] != null
          ? DateTime.parse(map['cancel_requested_at'] as String)
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'] as String)
          : null,
    );
  }
```

### Update toMap Method
```dart
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'total_amount': totalAmount,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Add these:
      'cancel_requested': cancelRequested,
      'cancel_requested_at': cancelRequestedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }
```

---

## Supabase SQL - Run in SQL Editor

```sql
-- Add columns to orders table
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS cancel_requested BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS cancel_requested_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_orders_cancel_requested 
ON orders(cancel_requested) 
WHERE cancel_requested = true;

CREATE INDEX IF NOT EXISTS idx_orders_cancelled_at 
ON orders(cancelled_at) 
WHERE cancelled_at IS NOT NULL;
```

---

## Common Issues & Solutions

### Issue: Can't find cancellation_dialogs.dart

**Solution:** Make sure directory exists:
```
lib/screens/dialogs/
```

Create the folder if it doesn't exist, then the file will be there.

### Issue: OrderCancellationService shows error

**Solution:** Verify import path in your screens:
```dart
import '../../services/order_cancellation_service.dart';
// Adjust '../../' based on your file location
```

### Issue: State is null errors

**Solution:** Check these conditions before using setState:
```dart
if (!mounted) return;
setState(() {});
```

### Issue: Stock not restoring

**Solution:** Check that:
1. `cancel_requested = true` was set
2. Admin approved (not just rejected)
3. Product names match exactly between order.items and products table
4. Supabase tables are accessible

---

## Testing Flow

### Customer Test
1. Login as customer
2. View orders
3. Find order with status 'Placed'
4. Click "Request Cancellation"
5. Confirm in dialog
6. See success snackbar ✓
7. Button disappears ✓

### Admin Test
1. Login as admin
2. Go to Orders
3. See order with amber warning "Cancellation Requested"
4. Click "Approve Cancellation"
5. See confirmation dialog
6. Confirm
7. See success snackbar ✓
8. Order status changes to 'Cancelled' ✓
9. Go to admin dashboard/products
10. Check product stock increased ✓

---

## All Done! 🎉

New files created:
- ✅ `lib/services/order_cancellation_service.dart`
- ✅ `lib/screens/dialogs/cancellation_dialogs.dart`

Documentation:
- ✅ `ORDER_CANCELLATION_SETUP.md`
- ✅ `ORDER_CANCELLATION_INTEGRATION.md`
- ✅ `SETUP_ORDER_CANCELLATION_DB.sql`
- ✅ This file (CODE_SNIPPETS.md)

Next: Copy-paste the code snippets above into your existing customer and admin order screens!
