import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPlacingOrder = false;
  
  // ✅ Customer form fields
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Reduce product stock after order placement
  Future<void> _reduceProductStock(List<dynamic> cartItems) async {
    final supabase = Supabase.instance.client;
    for (final item in cartItems) {
      try {
        // Robustly find product by name (case-insensitive). Using ilike helps
        // when name casing or minor differences exist.
        final data = await supabase
            .from('products')
            .select('id, stock, is_out_of_stock')
            .ilike('name', item.name)
            .limit(1) as List<dynamic>;

        // Fallback: try exact match if ilike didn't return (rare)
        if (data.isEmpty) {
          final fallback = await supabase
              .from('products')
              .select('id, stock, is_out_of_stock')
              .eq('name', item.name)
              .limit(1) as List<dynamic>;
          if (fallback.isNotEmpty) {
            // process using fallback
            final productId = fallback.first['id']?.toString();
            final currentStock = (fallback.first['stock'] is num)
                ? (fallback.first['stock'] as num).toInt()
                : int.tryParse('${fallback.first['stock']}') ?? 0;

            final newStock = (currentStock - item.quantity).clamp(0, double.infinity).toInt();
            final isOutOfStock = newStock <= 0;

            if (productId == null || productId.isEmpty) continue;

            await supabase
                .from('products')
                .update({'stock': newStock, 'is_out_of_stock': isOutOfStock})
                .eq('id', productId)
                .select()
                .maybeSingle();
            continue;
          }
        }

        if (data.isEmpty) continue;

        final productId = data.first['id']?.toString();
        final currentStock = (data.first['stock'] is num)
            ? (data.first['stock'] as num).toInt()
            : int.tryParse('${data.first['stock']}') ?? 0;

        // Calculate new stock safely
        final newStock = (currentStock - item.quantity).clamp(0, double.infinity).toInt();
        final isOutOfStock = newStock <= 0;

        if (productId == null || productId.isEmpty) continue;

        // Update product stock and out_of_stock status and request maybeSingle() to ensure it runs
        await supabase
            .from('products')
            .update({'stock': newStock, 'is_out_of_stock': isOutOfStock})
            .eq('id', productId)
            .select()
            .maybeSingle();
      } catch (e) {
        // Log error but continue with other items
        // ignore: avoid_print
        print('Exception in _reduceProductStock: $e');
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // ✅ Validate customer fields
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address')),
      );
      return;
    }

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // Get user email
      final userEmail = user.email ?? 'unknown@email.com';

      // ✅ Create order with customer details
      await supabase.from('orders').insert({
        'user_id': user.id,
        'user_email': userEmail,
        'customer_name': _customerNameController.text,
        'phone_number': _phoneController.text,
        'delivery_address': _addressController.text,
        'total_amount': cart.totalAmount,
        'status': 'Placed',
        'items': cart.items.map((item) => item.toMap()).toList(),
      });

      // Reduce stock for each item
      await _reduceProductStock(cart.items);

      cart.clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🛒 CART ITEMS
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '₹${item.unitPrice.toStringAsFixed(2)} × '
                            '${item.quantity} ${item.selectedUnit}',
                          ),
                          trailing: Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 👤 CUSTOMER DETAILS FORM
                  const Text(
                    'Delivery Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      hintText: 'Enter your full delivery address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 💰 TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // PLACE ORDER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      child: _isPlacingOrder
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

