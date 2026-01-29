# 📋 Order Cancellation Feature - Integration Guide

## New Files Created

1. **`lib/services/order_cancellation_service.dart`** - Service for all cancellation operations
2. **`lib/screens/dialogs/cancellation_dialogs.dart`** - Confirmation dialogs for cancellation

## Supabase Schema Changes

**Required:** Add these columns to your `orders` table:

```sql
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS cancel_requested BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS cancel_requested_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;
```

Or via Supabase UI:
1. Go to **Database** → **Tables** → **orders**
2. Click **+ Add Column** three times:
   - `cancel_requested` (boolean, default: false)
   - `cancel_requested_at` (timestamp, nullable)
   - `cancelled_at` (timestamp, nullable)

---

## Integration into Existing Screens

### 1. Customer Orders Screen (for cancellation request)

**Location:** Your customer orders viewing screen (likely in `lib/screens/` or `lib/screens/orders/`)

**Find the order list/detail display** and add this button:

```dart
// Add import at top
import '../dialogs/cancellation_dialogs.dart';
import '../../services/order_cancellation_service.dart';

// Inside your order card/detail widget, add this button:
if (order['status'] == 'Placed' && order['cancel_requested'] != true)
  ElevatedButton.icon(
    onPressed: () => _showCancellationDialog(context, order),
    icon: const Icon(Icons.cancel),
    label: const Text('Request Cancellation'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
    ),
  ),

// Add this method to your state class:
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
        content: Text('Cancellation request sent. Admin will review shortly.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Refresh order list
    setState(() {});
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### 2. Admin Orders Screen (for approval/rejection)

**Location:** `lib/screens/admin/admin_orders_screen.dart`

**Find where you build the order card** and update it:

```dart
// Add import at top
import '../../screens/dialogs/cancellation_dialogs.dart';
import '../../services/order_cancellation_service.dart';

// In your order card build, add a visual indicator:
if (order.cancelRequested)
  Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.amber[100],
      border: Border.all(color: Colors.amber),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Row(
      children: [
        Icon(Icons.warning, color: Colors.amber, size: 16),
        SizedBox(width: 8),
        Text(
          'Cancellation Requested',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  ),

// Add these buttons to order action menu (your popup menu or action buttons):
if (order.cancelRequested) ...[
  PopupMenuItem(
    child: const Text('Approve Cancellation'),
    onTap: () => _approveCancellation(context, order),
  ),
  PopupMenuItem(
    child: const Text('Reject Cancellation'),
    onTap: () => _rejectCancellation(context, order),
  ),
],

// Add these methods to your AdminOrdersScreen state:
void _approveCancellation(BuildContext context, AdminOrder order) {
  showDialog(
    context: context,
    builder: (context) => AdminCancellationDialog(
      customerEmail: order.userEmail,
      totalAmount: order.totalAmount,
      onApprove: () async {
        Navigator.pop(context);
        await _processCancellationApproval(order.id);
      },
      onReject: () => Navigator.pop(context),
    ),
  );
}

void _rejectCancellation(BuildContext context, AdminOrder order) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject Cancellation?'),
      content: const Text('Order will remain active. Customer will be notified.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Active'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _processCancellationRejection(order.id);
          },
          child: const Text('Reject Request'),
        ),
      ],
    ),
  );
}

Future<void> _processCancellationApproval(String orderId) async {
  try {
    final service = OrderCancellationService();
    await service.approveCancellation(orderId);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cancellation approved. Stock restored.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Refresh orders
    setState(() {});
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _processCancellationRejection(String orderId) async {
  try {
    final service = OrderCancellationService();
    await service.rejectCancellation(orderId);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cancellation request rejected.'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // Refresh orders
    setState(() {});
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Models Update

If you're using typed AdminOrder models, add these fields:

```dart
// In lib/models/admin_order.dart, add to AdminOrder class:

final bool cancelRequested;        // Add this
final DateTime? cancelRequestedAt; // Add this
final DateTime? cancelledAt;       // Add this

// Update constructor:
AdminOrder({
  required this.id,
  required this.userId,
  required this.userEmail,
  required this.totalAmount,
  required this.status,
  required this.items,
  required this.createdAt,
  this.updatedAt,
  this.cancelRequested = false,     // Add this
  this.cancelRequestedAt,            // Add this
  this.cancelledAt,                  // Add this
});

// Update fromMap factory:
factory AdminOrder.fromMap(Map<String, dynamic> map) {
  return AdminOrder(
    // ... existing fields ...
    cancelRequested: map['cancel_requested'] as bool? ?? false,
    cancelRequestedAt: map['cancel_requested_at'] != null 
      ? DateTime.parse(map['cancel_requested_at'] as String)
      : null,
    cancelledAt: map['cancelled_at'] != null
      ? DateTime.parse(map['cancelled_at'] as String)
      : null,
  );
}

// Update toMap factory:
Map<String, dynamic> toMap() {
  return {
    // ... existing fields ...
    'cancel_requested': cancelRequested,
    'cancel_requested_at': cancelRequestedAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
  };
}
```

---

## Feature Flow

### Customer Side
1. Customer views their orders
2. If order status = "Placed" and not already requested cancellation:
   - Show "Request Cancellation" button
3. Click button → confirmation dialog
4. On confirm → cancellation requested (admin review needed)
5. Snackbar shows "Cancellation request sent"

### Admin Side
1. In Orders screen, orders with `cancel_requested = true` are highlighted in amber
2. Yellow "Cancellation Requested" badge appears on the order card
3. Popup menu shows:
   - "Approve Cancellation" → Restores stock, sets status to 'Cancelled'
   - "Reject Cancellation" → Keeps order active, removes flag
4. Snackbar shows confirmation

### Stock Restoration
When admin approves cancellation:
- For each item in order.items:
  - Fetch product by name
  - Add ordered quantity back to stock
  - If stock > 0, set is_out_of_stock = false
  - Save to Supabase

---

## RLS Policies (Recommended)

Add these to your Supabase RLS policies for orders table:

```sql
-- Customers can request cancellation on their own orders
CREATE POLICY "Customers can request cancellation"
ON orders FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id AND
  (status = 'Placed' OR status = 'Packed') AND
  cancel_requested IS NOT NULL
);

-- Admins can approve/reject cancellations
CREATE POLICY "Admins can process cancellations"
ON orders FOR UPDATE
USING (auth.jwt() ->> 'email' = 'admin@magiilmart.com')
WITH CHECK (
  auth.jwt() ->> 'email' = 'admin@magiilmart.com'
);
```

---

## Testing Checklist

- [ ] Database columns added to orders table
- [ ] OrderCancellationService file created
- [ ] CancellationDialogs file created
- [ ] Added imports to customer orders screen
- [ ] Added imports to admin orders screen
- [ ] Added "Request Cancellation" button to customer orders
- [ ] Added cancellation status indicator to admin orders
- [ ] Added approval/rejection buttons to admin orders
- [ ] Tested customer requesting cancellation
- [ ] Tested admin approving (verify stock restored)
- [ ] Tested admin rejecting (verify order stays active)
- [ ] Verified cancelled orders show status = 'Cancelled'
- [ ] Verified products marked back in stock
- [ ] Verified is_out_of_stock flag updated correctly

---

## What Changed (Summary)

**New Files:**
- ✅ `lib/services/order_cancellation_service.dart`
- ✅ `lib/screens/dialogs/cancellation_dialogs.dart`

**Modified Files (minimal changes):**
- Update your customer orders screen (add 1 button)
- Update your admin orders screen (add indicators + 2 buttons)
- Update AdminOrder model (optional, for type safety)

**Existing Code Touched:**
- ❌ Cart logic - untouched
- ❌ Checkout logic - untouched
- ❌ Stock reduction on order - untouched
- ❌ Authentication - untouched
- ✅ Only added new cancellation features

---

## Notes

- Customers can only request cancellation on 'Placed' orders
- Cancellation requests go to admin for review
- Admin must approve before stock is actually restored
- Cancelled orders show status = 'Cancelled' (permanent record)
- All stock restoration happens in one transaction (admin approve action)
- Existing order history is preserved with cancelled_at timestamp
