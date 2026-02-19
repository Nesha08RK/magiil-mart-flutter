import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/cart_provider.dart';
import 'services/profile_readonly_service.dart';
import 'checkout/osm_address_picker.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPlacingOrder = false;
  bool _editing = false;
  bool _loadingProfile = true;
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _profileService = ProfileReadonlyService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
    });
    try {
      final profile = await _profileService.fetchDeliveryProfile();
      if (profile != null) {
        _customerNameController.text = profile.fullName;
        _phoneController.text = profile.phone;
        _addressController.text = profile.addressLine;
        _cityController.text = profile.city;
        _pincodeController.text = profile.pincode;
      }
    } catch (_) {} finally {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
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

  /// Open OSM map picker for address selection
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const OSMAddressPicker(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      // Update address field with selected address
      _addressController.text = result['address'] ?? '';
      // Store coordinates for order placement
      _deliveryLatitude = result['lat'] as double?;
      _deliveryLongitude = result['lng'] as double?;
      
      // Show confirmation snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address updated: ${result['address']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

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
    if (!RegExp(r'^[0-9]{10,}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address')),
      );
      return;
    }
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your city')),
      );
      return;
    }
    if (_pincodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pincode')),
      );
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_pincodeController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit pincode')),
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

      final payload = {
        'user_id': user.id,
        'user_email': userEmail,
        'items': cart.items.map((item) => item.toMap()).toList(),
        'total_amount': cart.totalAmount,
        'status': 'Placed',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'delivery_name': _customerNameController.text.trim(),
        'delivery_phone': _phoneController.text.trim(),
        'delivery_address': _addressController.text.trim(),
        'delivery_city': _cityController.text.trim(),
        'delivery_pincode': _pincodeController.text.trim(),
        // Add latitude and longitude if available from map picker
        if (_deliveryLatitude != null) 'delivery_latitude': _deliveryLatitude,
        if (_deliveryLongitude != null) 'delivery_longitude': _deliveryLongitude,
      };
      try {
        await supabase.from('orders').insert(payload);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('column') || msg.contains('does not exist') || msg.contains('delivery_latitude')) {
          // Fallback: remove lat/lng if columns don't exist
          await supabase.from('orders').insert({
            'user_id': user.id,
            'user_email': userEmail,
            'customer_name': _customerNameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'delivery_address': _addressController.text.trim(),
            'total_amount': cart.totalAmount,
            'status': 'Placed',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'items': cart.items.map((item) => item.toMap()).toList(),
            // Note: Not including delivery_latitude/longitude here to support older schemas
          });
        } else {
          rethrow;
        }
      }

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
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.lock_open : Icons.edit),
            onPressed: _loadingProfile ? null : () => setState(() => _editing = !_editing),
          ),
        ],
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  
                  // 📍 ADDRESS WITH MAP PICKER
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          readOnly: !_editing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 🗺️ MAP PICKER BUTTON
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: _openMapPicker,
                            tooltip: 'Pick on Map',
                          ),
                          const Text(
                            'Map',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.markunread_mailbox),
                    ),
                    readOnly: !_editing,
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

