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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 24),

            Text(
              'Total: ₹${cart.totalAmount}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (_nameController.text.isEmpty ||
                          _phoneController.text.isEmpty ||
                          _addressController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fill all fields')),
                        );
                        return;
                      }

                      setState(() => _loading = true);

                      final supabase = Supabase.instance.client;

                      await supabase.from('orders').insert({
                        'name': _nameController.text,
                        'phone': _phoneController.text,
                        'address': _addressController.text,
                        'total': cart.totalAmount,
                        'items': cart.items
                            .map((item) => {
                                  'name': item.name,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                })
                            .toList(),
                      });

                      cart.clearCart();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order placed successfully')),
                      );

                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
