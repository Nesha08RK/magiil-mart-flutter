import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../checkout/osm_address_picker.dart';

/// A concise delivery address bar for the home screen.
class DeliveryAddressWidget extends StatefulWidget {
  final VoidCallback? onAddressChanged;

  const DeliveryAddressWidget({
    super.key,
    this.onAddressChanged,
  });

  @override
  State<DeliveryAddressWidget> createState() => _DeliveryAddressWidgetState();
}

class _DeliveryAddressWidgetState extends State<DeliveryAddressWidget> {
  String? _deliveryAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
  }

  Future<void> _loadDeliveryAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final address = prefs.getString('last_delivery_address');
      if (mounted) {
        setState(() {
          _deliveryAddress = address;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (c) => const OSMAddressPicker(), fullscreenDialog: true),
    );

    if (result != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_delivery_address', result['address'] ?? '');
        final lat = (result['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (result['lng'] as num?)?.toDouble() ?? 0.0;
        await prefs.setDouble('last_delivery_lat', lat);
        await prefs.setDouble('last_delivery_lng', lng);
      } catch (_) {}

      if (mounted) {
        setState(() => _deliveryAddress = result['address'] as String?);
        widget.onAddressChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery location updated: ${result['address']}'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: const _DeliveryShimmer(),
        ),
      );
    }

    return GestureDetector(
      onTap: _openMapPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade600, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deliver to', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(_deliveryAddress ?? 'Select Delivery Location', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, color: Colors.blue.shade600, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight shimmer used while loading address.
class _DeliveryShimmer extends StatefulWidget {
  const _DeliveryShimmer({super.key});

  @override
  State<_DeliveryShimmer> createState() => _DeliveryShimmerState();
}

class _DeliveryShimmerState extends State<_DeliveryShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade300));
  }
}
