# 📊 Order Cancellation - Visual Flow Diagrams

## Customer Cancellation Flow

```
Customer Views Order
       ↓
Status == 'Placed'?
       ├─ YES → Show "Request Cancellation" button
       └─ NO → No button shown
       
       ↓
Click "Request Cancellation"
       ↓
Show ConfirmCancellationDialog
       ├─ Cancel → Dialog closes, no change
       └─ Confirm → 
            ↓
         OrderCancellationService.requestCancellation(orderId)
            ↓
         Update order.cancel_requested = true
         Update order.cancel_requested_at = NOW()
            ↓
         Show snackbar: "Cancellation request sent"
            ↓
         Order awaits admin review
```

---

## Admin Cancellation Approval Flow

```
Admin Views Orders
       ↓
Find order with cancel_requested = true
       ↓
Visual Indicator: Amber badge "Cancellation Requested"
       ↓
Click "Approve Cancellation"
       ↓
Show AdminCancellationDialog (confirm action)
       ├─ Reject → Just close, no changes
       └─ Approve →
            ↓
         OrderCancellationService.approveCancellation(orderId)
            ↓
         TRANSACTION START:
         
         1. Fetch order from database
         2. For each item in order.items:
              a. Get product by name
              b. Get current stock
              c. Calculate: newStock = current + orderedQuantity
              d. Update product:
                 - stock = newStock
                 - is_out_of_stock = (newStock <= 0)
         3. Update order:
              - status = 'Cancelled'
              - cancel_requested = false
              - cancelled_at = NOW()
         
         TRANSACTION END
            ↓
         Show snackbar: "Cancellation approved. Stock restored."
            ↓
         Refresh orders list
            ↓
         Order shows as "Cancelled" with timestamp
```

---

## Admin Cancellation Rejection Flow

```
Admin Views Orders
       ↓
Find order with cancel_requested = true
       ↓
Click "Reject Cancellation"
       ↓
Show rejection confirmation dialog
       ├─ Cancel → Dialog closes, no change
       └─ Reject →
            ↓
         OrderCancellationService.rejectCancellation(orderId)
            ↓
         Update order:
         - cancel_requested = false
         - cancel_requested_at = null
            ↓
         Show snackbar: "Cancellation request rejected"
            ↓
         Order remains ACTIVE with original status
```

---

## Stock Restoration Detailed Flow

```
Admin approves cancellation
       ↓
ORDER: id=123, items=[{name: "Tomato", quantity: 3}, {name: "Potato", quantity: 2}]
       ↓
FOR EACH ITEM:
       
       Item 1: Tomato, quantity=3
       ├─ Query: SELECT stock FROM products WHERE name='Tomato'
       ├─ Current stock: 5
       ├─ Calculate: 5 + 3 = 8
       └─ Update: stock=8, is_out_of_stock=false
       
       Item 2: Potato, quantity=2
       ├─ Query: SELECT stock FROM products WHERE name='Potato'
       ├─ Current stock: 0
       ├─ Calculate: 0 + 2 = 2
       └─ Update: stock=2, is_out_of_stock=false
       
       ↓
UPDATE ORDER:
       ├─ status: 'Placed' → 'Cancelled'
       ├─ cancel_requested: true → false
       └─ cancelled_at: null → 2026-01-29T15:30:00.000Z
       ↓
All items restored ✅
Order cancelled ✅
```

---

## Database State Changes

```
BEFORE Customer Orders:
┌─────────────────────────────────────────┐
│ Products Table                          │
├────────┬──────┬─────────────────────────┤
│ name   │ stock│ is_out_of_stock        │
├────────┼──────┼─────────────────────────┤
│ Tomato │  10  │ false                  │
│ Potato │   5  │ false                  │
└────────┴──────┴─────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Orders Table                                                 │
├────────┬────────┬─────────────┬──────────────┬─────────────┤
│ id     │ status │ items       │ cancel_req   │ cancelled_at │
├────────┼────────┼─────────────┼──────────────┼─────────────┤
│ ord123 │Placed  │[Tom:3,Pot:2]│ false        │ null        │
└────────┴────────┴─────────────┴──────────────┴─────────────┘

       ↓ Customer orders 3 Tomato + 2 Potato
       
AFTER Order Placed:
┌─────────────────────────────────────────┐
│ Products Table                          │
├────────┬──────┬─────────────────────────┤
│ name   │ stock│ is_out_of_stock        │
├────────┼──────┼─────────────────────────┤
│ Tomato │  7   │ false          ← reduced│
│ Potato │  3   │ false          ← reduced│
└────────┴──────┴─────────────────────────┘

       ↓ Customer requests cancellation
       
AFTER Cancellation Requested:
┌──────────────────────────────────────────────────────────────┐
│ Orders Table                                                 │
├────────┬────────┬─────────────┬──────────────┬─────────────┤
│ id     │ status │ items       │ cancel_req   │ cancel_time │
├────────┼────────┼─────────────┼──────────────┼─────────────┤
│ ord123 │Placed  │[Tom:3,Pot:2]│ true   ←req  │2026-01-29...│
└────────┴────────┴─────────────┴──────────────┴─────────────┘

       ↓ Admin approves cancellation
       
AFTER Admin Approval:
┌─────────────────────────────────────────┐
│ Products Table                          │
├────────┬──────┬─────────────────────────┤
│ name   │ stock│ is_out_of_stock        │
├────────┼──────┼─────────────────────────┤
│ Tomato │  10  │ false          ← restored│
│ Potato │  5   │ false          ← restored│
└────────┴──────┴─────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Orders Table                                                     │
├────────┬──────────┬──────────────┬─────────────┬─────────────────┤
│ id     │ status   │ cancel_req   │cancel_req_at│ cancelled_at    │
├────────┼──────────┼──────────────┼─────────────┼─────────────────┤
│ ord123 │Cancelled │ false        │ null        │2026-01-29T15:30 │
└────────┴──────────┴──────────────┴─────────────┴─────────────────┘
```

---

## UI Flow - Customer

```
┌─────────────────────────────────────────┐
│ My Orders Screen                         │
├─────────────────────────────────────────┤
│ Order #123                              │
│ Status: Placed  ✓                       │
│ Total: ₹500                             │
│ ┌─────────────────────────────────────┐ │
│ │ [Request Cancellation]  [View Items] │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
         ↓ Click button
┌─────────────────────────────────────────┐
│ Confirm Cancellation Request?            │
├─────────────────────────────────────────┤
│ Are you sure you want to request        │
│ cancellation for this order?             │
│                                          │
│ Order email: customer@email.com         │
│ Admin will review and restore stock     │
│                                          │
│ [No, Keep Order] [Yes, Request Cancel]  │
└─────────────────────────────────────────┘
         ↓ Confirm
┌─────────────────────────────────────────┐
│ ✓ Cancellation request sent. Admin will │
│   review shortly.                        │
└─────────────────────────────────────────┘

New View:
┌─────────────────────────────────────────┐
│ My Orders Screen                         │
├─────────────────────────────────────────┤
│ Order #123                              │
│ Status: Placed  ✓                       │
│ Total: ₹500                             │
│ Cancellation Requested ⏳                 │
│                                          │
│ (Button hidden until admin reviews)     │
└─────────────────────────────────────────┘
```

---

## UI Flow - Admin

```
┌────────────────────────────────────────────────────────┐
│ Admin Orders Screen                                     │
├────────────────────────────────────────────────────────┤
│ Order #123                                             │
│ Customer: customer@email.com  Total: ₹500             │
│ Status: Placed                                         │
│ ⚠️ CANCELLATION REQUESTED ⚠️  (Amber badge)            │
│                                                        │
│ [⋮ Menu]                                               │
│   ├─ View Details                                      │
│   ├─ Update Status                                     │
│   ├─ ─────────────────────                            │
│   ├─ ✓ Approve Cancellation                           │
│   └─ ✗ Reject Cancellation                            │
└────────────────────────────────────────────────────────┘

         ↓ Click "Approve Cancellation"

┌────────────────────────────────────────────────────────┐
│ Cancellation Request                                   │
├────────────────────────────────────────────────────────┤
│ Customer: customer@email.com                           │
│ Amount: ₹500                                           │
│                                                        │
│ Approving will:                                        │
│ • Cancel the order                                     │
│ • Restore all product stock                           │
│ • Notify customer                                      │
│                                                        │
│ [Reject Request] [Approve Cancellation]               │
└────────────────────────────────────────────────────────┘

         ↓ Confirm

┌────────────────────────────────────────────────────────┐
│ ✓ Cancellation approved. Stock has been restored.      │
└────────────────────────────────────────────────────────┘

New View:
┌────────────────────────────────────────────────────────┐
│ Admin Orders Screen                                     │
├────────────────────────────────────────────────────────┤
│ Order #123                                             │
│ Customer: customer@email.com  Total: ₹500             │
│ Status: Cancelled ✗                                    │
│ Cancelled at: 2026-01-29 15:30:00                     │
│                                                        │
│ [⋮ Menu] - Cancellation buttons hidden                │
└────────────────────────────────────────────────────────┘
```

---

## Service Methods Call Chain

```
Customer Action: requestCancellation()
    ↓
OrderCancellationService.requestCancellation(orderId)
    ├─ UPDATE orders SET cancel_requested=true, cancel_requested_at=NOW()
    └─ RETURN (success or exception)

Admin Action: approveCancellation()
    ↓
OrderCancellationService.approveCancellation(orderId)
    ├─ SELECT order FROM orders WHERE id=orderId
    ├─ FOR each item in order.items:
    │   ├─ SELECT product FROM products WHERE name=item.name
    │   ├─ Calculate newStock = current + quantity
    │   └─ UPDATE products SET stock=newStock, is_out_of_stock=(newStock<=0)
    ├─ UPDATE orders SET status='Cancelled', cancel_requested=false, cancelled_at=NOW()
    └─ RETURN (success or exception)

Admin Action: rejectCancellation()
    ↓
OrderCancellationService.rejectCancellation(orderId)
    ├─ UPDATE orders SET cancel_requested=false, cancel_requested_at=null
    └─ RETURN (success or exception)
```

---

## Error Handling Flow

```
Any Action
    ↓
Try {
    Service Method
    ├─ Success → Show snackbar ✓ + Refresh UI
    └─ Exception:
        ├─ Network error → Show error message
        ├─ Missing product → Skip + continue
        ├─ Missing order → Show error message
        └─ Database error → Show error message
}
    ↓
User sees feedback immediately
```

---

## Summary

1. **Customer requests** → Flag set, awaits admin
2. **Admin sees warning** → Amber badge visible
3. **Admin approves** → Stock restored, order cancelled
4. **Admin rejects** → Flag removed, order continues
5. **Stock restored** → Exact quantities added back
6. **History preserved** → Cancelled orders kept as records

All flows handle errors gracefully with user feedback!
