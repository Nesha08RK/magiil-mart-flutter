# 📖 Magiil Mart Delivery Features - Code Snippets Reference

## 🔹 Quick Reference for Distance Calculation

```dart
// Import
import 'package:magiil_mart/utils/delivery_utils.dart';

// Calculate distance between store and delivery location
final distanceKm = DeliveryDistanceCalculator.getDistanceFromStore(
  deliveryLatitude,   // double
  deliveryLongitude,  // double
);

// Check if delivery is within 8 km radius
final isWithinRadius = DeliveryDistanceCalculator.isWithinDeliveryRadius(
  deliveryLatitude,
  deliveryLongitude,
);
// Returns: true or false
```

---

## 💰 Quick Reference for Delivery Fee Calculation

```dart
// Calculate delivery fee based on distance
final deliveryFee = DeliveryFeeCalculator.calculateDeliveryFee(distanceKm);
// Returns: 20 (0-3km), 40 (3-6km), 60 (6-8km), or 0 (beyond 8km)

// Get human-readable fee description
final feeDesc = DeliveryFeeCalculator.getFeeDescription(distanceKm);
// Returns: "₹20 (≤3 km)", "₹40 (3-6 km)", "₹60 (6-8 km)", or "₹0"

// Example usage
final distance = 5.5; // km
final fee = DeliveryFeeCalculator.calculateDeliveryFee(distance);
print('Distance: $distance km, Fee: ₹$fee'); // Output: Distance: 5.5 km, Fee: ₹40
```

---

## ⏰ Quick Reference for Store Availability

```dart
// Check if store is currently open
final isOpen = StoreAvailabilityChecker.isStoreOpen();
// Returns: true if current time is between 9:00 AM - 10:00 PM

// Get store status with emoji
final status = StoreAvailabilityChecker.getStoreStatus();
// Returns: "🟢 Open Now" or "🔴 Closed"

// Get store hours message
final message = StoreAvailabilityChecker.getStoreHoursMessage();
// Returns: "Orders accepted between 9:00 AM – 10:00 PM only"

// Get time until store opens (if closed)
final timeUntilOpen = StoreAvailabilityChecker.getTimeUntilStoreOpens();
// Returns: Duration or null if already open

// Get time until store closes (if open)
final timeUntilClose = StoreAvailabilityChecker.getTimeUntilStoreCloses();
// Returns: Duration or null if already closed
```

---

## 🎯 Complete Validation in One Call

```dart
// Import
import 'package:magiil_mart/utils/delivery_utils.dart';

// Comprehensive validation
final validationResult = DeliveryValidator.validateDelivery(
  deliveryLatitude,   // double?
  deliveryLongitude,  // double?
);

// Check if validation passed
if (validationResult.isValid) {
  print('✅ Delivery is valid');
  print('Distance: ${validationResult.distanceKm} km');
  print('Delivery Fee: ₹${validationResult.deliveryFee}');
} else {
  print('❌ Delivery validation failed');
  print('Reason: ${validationResult.message}');
  // Message examples:
  // - "Please select a delivery address on the map"
  // - "Orders accepted between 9:00 AM – 10:00 PM only"
  // - "Delivery available within 8 km from Magiil Mart only"
}

// Example: In checkout screen
Future<void> _placeOrder() async {
  final validation = DeliveryValidator.validateDelivery(
    _deliveryLatitude,
    _deliveryLongitude,
  );

  if (!validation.isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(validation.message)),
    );
    return;
  }

  // All validations passed
  final subtotal = cart.totalAmount;
  final deliveryFee = validation.deliveryFee ?? 0;
  final total = subtotal + deliveryFee;
  
  // Proceed with order placement
  // ...
}
```

---

## 🏪 Store Configuration Constants

```dart
// Location: lib/utils/delivery_utils.dart

class MagiilMartStore {
  // Store coordinates
  static const double storeLatitude = 11.370333090754086;
  static const double storeLongitude = 77.74837219507778;
  static const LatLng storeLocation = LatLng(storeLatitude, storeLongitude);

  // Store operating hours (24-hour format)
  static const int openHour = 9;    // 9:00 AM
  static const int openMinute = 0;
  static const int closeHour = 22;  // 10:00 PM
  static const int closeMinute = 0;

  // Maximum delivery radius
  static const double maxDeliveryRadiusKm = 8.0;
}

// To modify store settings, edit these constants above
// Example: To change store hours to 8 AM - 11 PM
// Change: static const int openHour = 8;
// Change: static const int closeHour = 23;
```

---

## 🏠 Using Delivery Address Widget

```dart
// In home_screen.dart
import '../screens/widgets/delivery_address_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add this widget at the top
            DeliveryAddressWidget(
              onAddressChanged: () {
                // Called when user selects new address
                setState(() {});
              },
            ),
            // Rest of home screen widgets...
          ],
        ),
      ),
    );
  }
}
```

---

## 💾 Save/Retrieve Delivery Address from SharedPreferences

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Save delivery address
Future<void> saveDeliveryAddress(
  String address,
  double latitude,
  double longitude,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_delivery_address', address);
  await prefs.setDouble('last_delivery_lat', latitude);
  await prefs.setDouble('last_delivery_lng', longitude);
}

// Retrieve delivery address
Future<Map<String, dynamic>?> getDeliveryAddress() async {
  final prefs = await SharedPreferences.getInstance();
  final address = prefs.getString('last_delivery_address');
  final lat = prefs.getDouble('last_delivery_lat');
  final lng = prefs.getDouble('last_delivery_lng');

  if (address == null || lat == null || lng == null) {
    return null;
  }

  return {
    'address': address,
    'lat': lat,
    'lng': lng,
  };
}

// Clear delivery address
Future<void> clearDeliveryAddress() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_delivery_address');
  await prefs.remove('last_delivery_lat');
  await prefs.remove('last_delivery_lng');
}
```

---

## 📤 Order Payload with Delivery Info

```dart
// In checkout_screen.dart _placeOrder() method
final validation = DeliveryValidator.validateDelivery(
  _deliveryLatitude,
  _deliveryLongitude,
);

if (!validation.isValid) {
  // Show error
  return;
}

final subtotal = cart.totalAmount;
final deliveryFee = validation.deliveryFee ?? 0;

final payload = {
  'user_id': user.id,
  'user_email': userEmail,
  'items': cart.items.map((item) => item.toMap()).toList(),
  
  // Pricing breakdown
  'subtotal_amount': subtotal,
  'delivery_fee': deliveryFee,
  'total_amount': subtotal + deliveryFee,
  
  // Delivery location info
  'delivery_latitude': _deliveryLatitude,
  'delivery_longitude': _deliveryLongitude,
  'delivery_distance_km': validation.distanceKm,
  
  // Customer info
  'delivery_name': _customerNameController.text,
  'delivery_phone': _phoneController.text,
  'delivery_address': _addressController.text,
  'delivery_city': _cityController.text,
  'delivery_pincode': _pincodeController.text,
  
  // Order metadata
  'status': 'Placed',
  'created_at': DateTime.now().toUtc().toIso8601String(),
};

await supabase.from('orders').insert(payload);
```

---

## 🎨 UI Components Code

### Store Status Indicator (Checkout Screen Top)

```dart
// In checkout_screen.dart build() method
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: StoreAvailabilityChecker.isStoreOpen()
        ? Colors.green.shade50
        : Colors.red.shade50,
    border: Border.all(
      color: StoreAvailabilityChecker.isStoreOpen()
          ? Colors.green
          : Colors.red,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Expanded(
        child: Text(
          StoreAvailabilityChecker.getStoreStatus(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StoreAvailabilityChecker.isStoreOpen()
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        ),
      ),
      if (!StoreAvailabilityChecker.isStoreOpen())
        Text(
          StoreAvailabilityChecker.getStoreHoursMessage(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.shade700,
          ),
        ),
    ],
  ),
),
```

### Price Breakdown Section (Checkout Screen)

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  ),
  child: Column(
    children: [
      // Subtotal
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
          Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 8),
      
      // Delivery Fee
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Fee', style: TextStyle(fontSize: 14, color: Colors.grey)),
              if (_deliveryDistanceKm != null)
                Text('(${_deliveryDistanceKm!.toStringAsFixed(2)} km)', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
          Text(_deliveryFee > 0 ? '₹${_deliveryFee.toString()}' : 'TBD', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      
      // Total
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('₹${(cart.totalAmount + _deliveryFee).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    ],
  ),
),
```

### Place Order Button (Checkout Screen)

```dart
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: (StoreAvailabilityChecker.isStoreOpen() && !_isPlacingOrder)
        ? _placeOrder
        : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      disabledBackgroundColor: Colors.grey.shade300,
    ),
    child: _isPlacingOrder
        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
        : Text(
            StoreAvailabilityChecker.isStoreOpen() ? 'Place Order' : 'Store Closed',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
  ),
),
```

---

## 🔧 Debugging Tips

### Check Store Status
```dart
print('Is store open? ${StoreAvailabilityChecker.isStoreOpen()}');
print('Store status: ${StoreAvailabilityChecker.getStoreStatus()}');
print('Time until close: ${StoreAvailabilityChecker.getTimeUntilStoreCloses()}');
```

### Check Distance Calculation
```dart
final distance = DeliveryDistanceCalculator.getDistanceFromStore(11.35, 77.75);
print('Distance from store: $distance km');

final isValid = DeliveryDistanceCalculator.isWithinDeliveryRadius(11.35, 77.75);
print('Within radius? $isValid');
```

### Check Delivery Fee
```dart
final fee = DeliveryFeeCalculator.calculateDeliveryFee(5.5);
print('Delivery fee for 5.5 km: ₹$fee');

final description = DeliveryFeeCalculator.getFeeDescription(5.5);
print('Fee description: $description');
```

### Full Validation
```dart
final result = DeliveryValidator.validateDelivery(11.35, 77.75);
print('Validation result: ${result.toString()}');
// Output: DeliveryValidationResult(isValid: true/false, message: ..., distanceKm: ..., deliveryFee: ...)
```

---

## ✨ Testing Examples

```dart
// Test Case 1: Valid delivery within 3 km
final result1 = DeliveryValidator.validateDelivery(11.373, 77.750);
// Expected: isValid = true, deliveryFee = 20

// Test Case 2: Valid delivery 4 km away
final result2 = DeliveryValidator.validateDelivery(11.378, 77.755);
// Expected: isValid = true, deliveryFee = 40

// Test Case 3: Valid delivery 7 km away
final result3 = DeliveryValidator.validateDelivery(11.385, 77.765);
// Expected: isValid = true, deliveryFee = 60

// Test Case 4: Invalid - outside radius
final result4 = DeliveryValidator.validateDelivery(11.400, 77.800);
// Expected: isValid = false, message contains "8 km"

// Test Case 5: Invalid - no coordinates
final result5 = DeliveryValidator.validateDelivery(null, null);
// Expected: isValid = false, message contains "select a delivery address"
```

---

## 📚 Related Documentation Files

- [DELIVERY_FEATURES_IMPLEMENTATION.md](./DELIVERY_FEATURES_IMPLEMENTATION.md) - Full implementation details
- [lib/utils/delivery_utils.dart](./lib/utils/delivery_utils.dart) - Source code with comments
- [lib/screens/checkout_screen.dart](./lib/screens/checkout_screen.dart) - Integration in checkout
- [lib/screens/home_screen.dart](./lib/screens/home_screen.dart) - Integration in home
- [lib/screens/widgets/delivery_address_widget.dart](./lib/screens/widgets/delivery_address_widget.dart) - Address widget

---

**Last Updated**: February 19, 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
