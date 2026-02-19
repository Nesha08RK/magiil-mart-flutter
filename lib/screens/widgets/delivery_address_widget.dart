import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../checkout/osm_address_picker.dart';

/// 🏠 Delivery Address Display Widget for Home Screen
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

  /// Load delivery address from SharedPreferences
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Open OSM map picker to select new address
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const OSMAddressPicker(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_delivery_address', result['address'] ?? '');
        await prefs.setDouble('last_delivery_lat', result['lat'] as double? ?? 0.0);
        await prefs.setDouble('last_delivery_lng', result['lng'] as double? ?? 0.0);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _deliveryAddress = result['address'];
        });

        // Notify parent widget of address change
        widget.onAddressChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery location updated: ${result['address']}'),
            duration: const Duration(seconds: 2),
          ),
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
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ShimmerLoader(),
        ),
      );
    }

    return GestureDetector(
      onTap: _openMapPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deliver to',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _deliveryAddress ?? 'Select Delivery Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.expand_more,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔄 Shimmer Loading Effect
class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({super.key});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade300,
      ),
    );
  }
}
