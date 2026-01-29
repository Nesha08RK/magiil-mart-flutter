import 'package:flutter/material.dart';

/// Dialog for confirming order cancellation request
class ConfirmCancellationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String orderEmail;

  const ConfirmCancellationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.orderEmail,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Cancellation?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to request cancellation for this order?',
          ),
          const SizedBox(height: 12),
          Text(
            'Order email: $orderEmail',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Admin will review your request and restore your stock if approved.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('No, Keep Order'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Yes, Request Cancellation'),
        ),
      ],
    );
  }
}

/// Dialog for admin to approve/reject cancellation
class AdminCancellationDialog extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String customerEmail;
  final double totalAmount;

  const AdminCancellationDialog({
    super.key,
    required this.onApprove,
    required this.onReject,
    required this.customerEmail,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancellation Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer: $customerEmail'),
          const SizedBox(height: 8),
          Text('Amount: ₹${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Text(
            'Approving will:\n• Cancel the order\n• Restore all product stock\n• Notify customer',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Reject Request'),
        ),
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Approve Cancellation'),
        ),
      ],
    );
  }
}
