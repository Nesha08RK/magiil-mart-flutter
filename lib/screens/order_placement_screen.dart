import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'services/profile_readonly_service.dart';
import 'services/order_placement_service.dart';

class OrderPlacementScreen extends StatefulWidget {
  const OrderPlacementScreen({super.key});

  @override
  State<OrderPlacementScreen> createState() => _OrderPlacementScreenState();
}

class _OrderPlacementScreenState extends State<OrderPlacementScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _profileService = ProfileReadonlyService();
  final _orderService = OrderPlacementService();
  bool _loading = true;
  bool _placing = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final profile = await _profileService.fetchDeliveryProfile();
      if (profile != null) {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone;
        _addressController.text = profile.addressLine;
        _cityController.text = profile.city;
        _pincodeController.text = profile.pincode;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  bool _valid() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_addressController.text.trim().isEmpty) return false;
    if (_cityController.text.trim().isEmpty) return false;
    if (_pincodeController.text.trim().isEmpty) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(_pincodeController.text.trim())) return false;
    if (!RegExp(r'^[0-9]{10,}$').hasMatch(_phoneController.text.trim())) return false;
    return true;
  }

  Future<void> _placeOrder() async {
    if (!_valid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill valid delivery details')),
      );
      return;
    }
    final cart = context.read<CartProvider>();
    final items = cart.items.map((e) => e.toMap()).toList();
    final totalAmount = cart.totalAmount;
    setState(() {
      _placing = true;
    });
    try {
      await _orderService.placeOrderSnapshot(
        deliveryName: _nameController.text.trim(),
        deliveryPhone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        deliveryCity: _cityController.text.trim(),
        deliveryPincode: _pincodeController.text.trim(),
        items: items,
        totalAmount: totalAmount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _placing = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.lock_open : Icons.edit),
            onPressed: _loading ? null : () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                    readOnly: !_editing,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Place Order'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
