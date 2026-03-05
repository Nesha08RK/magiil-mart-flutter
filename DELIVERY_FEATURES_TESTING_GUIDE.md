# 🧪 Magiil Mart Delivery Features - Testing Guide

## 📱 Test Environment Setup

### Prerequisites
- Flutter installed and configured
- Supabase project active and connected
- Emulator or physical device/browser ready
- Test user account with valid delivery profile

### Test Platforms
- ✅ Flutter Web (Chrome/Edge)
- ✅ Android Emulator/Device
- ✅ iOS (if applicable)

---

## 🔹 Test Suite 1: Distance Calculation & Validation

### Test Case 1.1: Store Location Configuration
**Objective**: Verify store coordinates are correctly set

```dart
// Location: lib/utils/delivery_utils.dart
void test_store_location_configuration() {
  assert(MagiilMartStore.storeLatitude == 11.370333090754086);
  assert(MagiilMartStore.storeLongitude == 77.74837219507778);
  assert(MagiilMartStore.maxDeliveryRadiusKm == 8.0);
  print('✅ Store location configured correctly');
}
```

**Manual Steps:**
1. Check `lib/utils/delivery_utils.dart` line 6-8
2. Verify coordinates match: 11.370333090754086, 77.74837219507778
3. **Expected**: Coordinates displayed in code ✅

---

### Test Case 1.2: Distance Within 3 km (Fee: ₹20)
**Objective**: Validate order within 3 km radius

**Manual Steps:**
1. Open app and navigate to Checkout
2. Click "Map" button to open map picker
3. Navigate to location approximately **2-3 km** from store
   - Example coordinates: ~11.355, 77.755
4. Select location, confirm address
5. **Expected Results:**
   - ✅ Distance shown: ~2-3 km
   - ✅ Delivery fee shown: ₹20
   - ✅ "Place Order" button enabled
   - ✅ Can place order successfully

**Verification in Supabase:**
```sql
SELECT delivery_distance_km, delivery_fee, total_amount 
FROM orders 
WHERE id = 'test_order_id' 
LIMIT 1;

-- Expected: delivery_distance_km ≈ 2.5, delivery_fee = 20
```

---

### Test Case 1.3: Distance Within 3-6 km (Fee: ₹40)
**Objective**: Validate order with fee tier 2

**Manual Steps:**
1. Open app → Checkout
2. Open map picker
3. Navigate to location approximately **4-5 km** from store
   - Example coordinates: ~11.375, 77.760
4. Select location
5. **Expected Results:**
   - ✅ Distance shown: ~4-5 km
   - ✅ Delivery fee shown: ₹40
   - ✅ "Place Order" button enabled
   - ✅ Can place order successfully

---

### Test Case 1.4: Distance Within 6-8 km (Fee: ₹60)
**Objective**: Validate order with maximum fee tier

**Manual Steps:**
1. Open app → Checkout
2. Open map picker
3. Navigate to location approximately **7 km** from store
   - Example coordinates: ~11.385, 77.765
4. Select location
5. **Expected Results:**
   - ✅ Distance shown: ~7 km
   - ✅ Delivery fee shown: ₹60
   - ✅ "Place Order" button enabled
   - ✅ Can place order successfully

---

### Test Case 1.5: Distance Beyond 8 km (Rejected)
**Objective**: Validate delivery rejection outside radius

**Manual Steps:**
1. Open app → Checkout
2. Click "Place Order" button (without selecting address first)
3. **Expected Results:**
   - ✅ Snackbar appears: "Please select a delivery address on the map"
   - ✅ Order NOT placed

**Manual Steps (Alternative - with out-of-range address):**
1. Open app → Checkout
2. Open map picker
3. Navigate to location **10+ km** from store
   - Example coordinates: ~11.40, 77.80
4. Select location
5. Click "Place Order"
6. **Expected Results:**
   - ✅ Snackbar appears: "Delivery available within 8 km from Magiil Mart only"
   - ✅ "Place Order" button remains visible (not processing)
   - ✅ Order NOT placed in Supabase

**Verification:**
```sql
-- Verify no order was created for out-of-range location
SELECT COUNT(*) FROM orders 
WHERE created_at > NOW() - INTERVAL '5 minutes' 
AND delivery_distance_km > 8;
-- Should return: 0
```

---

## 🔹 Test Suite 2: Delivery Fee Calculation

### Test Case 2.1: Fee Structure Correctness
**Objective**: Verify all fee tiers calculate correctly

**Unit Test (Dart):**
```dart
void test_delivery_fee_calculation() {
  // 0-3 km → ₹20
  assert(DeliveryFeeCalculator.calculateDeliveryFee(1.0) == 20);
  assert(DeliveryFeeCalculator.calculateDeliveryFee(3.0) == 20);
  
  // 3-6 km → ₹40
  assert(DeliveryFeeCalculator.calculateDeliveryFee(3.5) == 40);
  assert(DeliveryFeeCalculator.calculateDeliveryFee(5.99) == 40);
  
  // 6-8 km → ₹60
  assert(DeliveryFeeCalculator.calculateDeliveryFee(6.0) == 60);
  assert(DeliveryFeeCalculator.calculateDeliveryFee(7.99) == 60);
  
  // Beyond 8 km → ₹0
  assert(DeliveryFeeCalculator.calculateDeliveryFee(8.1) == 0);
  
  print('✅ All fee calculations correct');
}
```

**Run Unit Test:**
```bash
flutter test --verbose
```

---

### Test Case 2.2: Fee Automatically Updates After Address Selection
**Objective**: Fee updates in real-time on map selection

**Manual Steps:**
1. Open app → Checkout
2. Observe "Delivery Fee" shows "TBD" initially
3. Click "Map" button
4. Select a location (e.g., 2 km away)
5. Return to checkout
6. **Expected Results:**
   - ✅ Distance displays next to "Delivery Fee": "(2.00 km)"
   - ✅ Fee updates: "₹20"
   - ✅ Total price updates immediately

---

### Test Case 2.3: Fee Included in Total Amount
**Objective**: Verify total = subtotal + fee

**Manual Steps:**
1. Add items to cart with subtotal = ₹500
2. Go to Checkout
3. Select address 5 km away
4. **Expected Results:**
   - ✅ Subtotal: ₹500
   - ✅ Delivery Fee: ₹40 (3-6 km)
   - ✅ Total: ₹540
5. Place order
6. **Verify in Supabase:**
   ```sql
   SELECT subtotal_amount, delivery_fee, total_amount 
   FROM orders 
   ORDER BY created_at DESC 
   LIMIT 1;
   -- Expected: 500, 40, 540
   ```

---

## 🔹 Test Suite 3: Store Availability Hours

### Test Case 3.1: Store Status Display During Open Hours
**Objective**: Verify green indicator when store is open

**Manual Steps (During 9 AM - 10 PM):**
1. Open app → Go to Checkout
2. **Expected Results:**
   - ✅ Green store indicator at top: "🟢 Open Now"
   - ✅ "Place Order" button ENABLED
   - ✅ No error message about closing time

---

### Test Case 3.2: Store Status Display During Closed Hours
**Objective**: Verify red indicator when store is closed

**Manual Steps (Before 9 AM or After 10 PM - adjust system time if needed):**
1. Set device time to 11:00 PM (23:00)
2. Open app → Go to Checkout
3. **Expected Results:**
   - ✅ Red store indicator: "🔴 Closed"
   - ✅ Closing time message displays: "Orders accepted between 9:00 AM – 10:00 PM only"
   - ✅ "Place Order" button DISABLED (greyed out)
   - ✅ Button text shows "Store Closed" instead of "Place Order"

---

### Test Case 3.3: Cannot Place Order Outside Hours
**Objective**: Verify order rejection when store is closed

**Manual Steps:**
1. Set device time to 8:00 AM (before opening)
2. Add items to cart
3. Go to Checkout
4. Select delivery address
5. Try to click "Place Order" button
6. **Expected Results:**
   - ✅ Button is disabled (cannot click)
   - ✅ No order submission attempt
   - ✅ Display shows "Store Closed"

**Verify (place order attempt during 10:01 PM):**
1. Set time to 10:01 PM
2. Select all delivery details
3. Click "Place Order"
4. **Expected Results:**
   - ✅ Snackbar error: "Orders accepted between 9:00 AM – 10:00 PM only"
   - ✅ No order created in database

---

### Test Case 3.4: Programmatic Open Hours Check
**Objective**: Verify time checking logic

**Dart Code Test:**
```dart
void test_store_availability_checker() {
  // Mock times (you'll need to adjust for actual testing)
  // 9:30 AM → Open
  // 10:15 PM → Closed
  
  final isOpen = StoreAvailabilityChecker.isStoreOpen();
  final status = StoreAvailabilityChecker.getStoreStatus();
  final message = StoreAvailabilityChecker.getStoreHoursMessage();
  
  print('Open: $isOpen, Status: $status, Message: $message');
  // Verify values based on current time
}
```

---

## 🔹 Test Suite 4: Delivery Address Display (Home Screen)

### Test Case 4.1: Widget Displays After Checkout Selection
**Objective**: Address persists on home screen after checkout

**Manual Steps:**
1. Go to app home screen
2. Navigate to Checkout
3. Select address from map: "PERUNDURAI, 638060"
4. Return to Home screen
5. **Expected Results:**
   - ✅ Address widget shows at top: "📍 Deliver to PERUNDURAI, 638060 ▼"
   - ✅ Widget has blue background color
   - ✅ Address is clickable

---

### Test Case 4.2: Default Text When No Address
**Objective**: Show placeholder when no address selected

**Manual Steps (Fresh install or cleared preferences):**
1. Clear app preferences/cache
2. Open app home screen
3. **Expected Results:**
   - ✅ Address widget shows at top
   - ✅ Text displays: "📍 Deliver to Select Delivery Location ▼"
   - ✅ Widget is clickable

---

### Test Case 4.3: Tap Widget to Change Address
**Objective**: Opening map picker from address widget

**Manual Steps:**
1. Home screen shows an address
2. Tap the address widget
3. **Expected Results:**
   - ✅ OSM map picker opens
   - ✅ Can select new location
   - ✅ Selecting confirms and returns

---

### Test Case 4.4: Address Widget Updates After Selection
**Objective**: Widget reflects new address immediately

**Manual Steps:**
1. Home screen shows address "LOCATION A"
2. Tap widget to open map picker
3. Select new location "LOCATION B"
4. Map picker closes
5. **Expected Results:**
   - ✅ Widget immediately updates to "LOCATION B"
   - ✅ Snackbar confirms: "Delivery location updated: LOCATION B"
   - ✅ Data persisted to SharedPreferences

**Verify in SharedPreferences:**
```dart
// Check saved values
final prefs = await SharedPreferences.getInstance();
final address = prefs.getString('last_delivery_address');
final lat = prefs.getDouble('last_delivery_lat');
final lng = prefs.getDouble('last_delivery_lng');

print('Address: $address');
print('Lat: $lat, Lng: $lng');
```

---

### Test Case 4.5: Data Persists After App Restart
**Objective**: Address remains after closing and reopening app

**Manual Steps:**
1. Select address on home screen: "PERUNDURAI, 638060"
2. Close app completely
3. Reopen app
4. **Expected Results:**
   - ✅ Home screen immediately shows same address
   - ✅ No need to re-select
   - ✅ SharedPreferences loaded correctly

---

## 🔹 Test Suite 5: Checkout Screen Integration

### Test Case 5.1: Price Breakdown Visibility
**Objective**: All pricing components visible and correct

**Manual Steps:**
1. Add items (e.g., ₹500 total) to cart
2. Go to Checkout
3. Select address 4 km away
4. **Expected Results:**
   - ✅ Section titled "Price Breakdown" visible
   - ✅ Shows "Subtotal: ₹500"
   - ✅ Shows "Delivery Fee: ₹40 (4.00 km)"
   - ✅ Shows "Total: ₹540"
   - ✅ Total is in purple/highlighted color
   - ✅ Delivery fee line shows distance in parentheses

---

### Test Case 5.2: Store Status and Place Order Button
**Objective**: Button state matches store availability

**Manual Steps (During store hours):**
1. Go to Checkout
2. **Expected Results:**
   - ✅ Store status shows "🟢 Open Now" in green box
   - ✅ "Place Order" button is enabled (blue, clickable)
   - ✅ Button text: "Place Order"

**Manual Steps (After store hours - adjust time):**
1. Set device time to 11 PM
2. Go to Checkout
3. **Expected Results:**
   - ✅ Store status shows "🔴 Closed" in red box
   - ✅ Shows message: "Orders accepted between 9:00 AM – 10:00 PM only"
   - ✅ "Place Order" button is disabled (grey, not clickable)
   - ✅ Button text: "Store Closed"

---

### Test Case 5.3: Complete Order Flow
**Objective**: Full checkout with all new features

**Manual Steps:**
1. Add items to cart (subtotal: ₹300)
2. Navigate to Checkout
3. Verify store is open (🟢)
4. Fill delivery details (auto-loaded)
5. Click map button
6. Select address 2.5 km away
7. **After selection:**
   - ✅ Address field updates
   - ✅ Distance shows: "(2.50 km)"
   - ✅ Delivery fee shows: "₹20"
   - ✅ Total shows: "₹320"
8. Click "Place Order"
9. **Expected Results:**
   - ✅ Order placed successfully
   - ✅ Snackbar: "Order placed successfully" (green)
   - ✅ Checkout closes, back to previous screen

**Verify in Supabase:**
```sql
SELECT 
  delivery_address,
  subtotal_amount,
  delivery_fee,
  total_amount,
  delivery_distance_km
FROM orders
WHERE status = 'Placed'
ORDER BY created_at DESC
LIMIT 1;

-- Expected values:
-- delivery_address: Selected address
-- subtotal_amount: 300
-- delivery_fee: 20
-- total_amount: 320
-- delivery_distance_km: ~2.5
```

---

## 🔹 Test Suite 6: Edge Cases & Error Handling

### Test Case 6.1: No Coordinates Selected
**Objective**: Proper error when address not picked

**Manual Steps:**
1. Go to Checkout
2. Don't click map to select address
3. Click "Place Order"
4. **Expected Results:**
   - ✅ Snackbar error: "Please select a delivery address on the map"
   - ✅ Order not placed
   - ✅ No network request to Supabase

---

### Test Case 6.2: Network Error During Order Placement
**Objective**: Error handling when Supabase fails

**Manual Steps (Simulate offline):**
1. Turn off WiFi/Mobile data
2. Go to Checkout, select address
3. Click "Place Order"
4. **Expected Results:**
   - ✅ Loading spinner shows on button
   - ✅ Error snackbar: "Failed to place order: [network error]"
   - ✅ Button becomes clickable again
   - ✅ No order in database

---

### Test Case 6.3: Very Close Delivery (< 100m)
**Objective**: Minimum distance handling

**Manual Steps:**
1. Select address extremely close to store (same location)
2. **Expected Results:**
   - ✅ Distance shows: "~0.01 km"
   - ✅ Delivery fee: ₹20 (0-3 km tier)
   - ✅ Order places successfully

---

### Test Case 6.4: Boundary Distance (Exactly 3 km, 6 km, 8 km)
**Objective**: Fee tier boundary conditions

**Manual Steps:**
1. Select exactly 3.0 km away
   - **Expected**: Fee = ₹20
2. Select exactly 3.01 km away
   - **Expected**: Fee = ₹40
3. Select exactly 6.0 km away
   - **Expected**: Fee = ₹40
4. Select exactly 6.01 km away
   - **Expected**: Fee = ₹60
5. Select exactly 8.0 km away
   - **Expected**: Fee = ₹60
6. Select exactly 8.01 km away
   - **Expected**: Error, outside radius

---

## 📊 Performance & Stress Tests

### Test Case 7.1: Repeated Address Selection
**Objective**: Widget handles rapid selections

**Manual Steps:**
1. Tap address widget multiple times in succession
2. Select different addresses 3-4 times
3. **Expected Results:**
   - ✅ No lag or crashes
   - ✅ Final selection persists correctly
   - ✅ UI smoothly transitions

---

### Test Case 7.2: Large Cart with Delivery Fee Calculation
**Objective**: Performance with many items

**Manual Steps:**
1. Add 50+ items to cart
2. Go to Checkout
3. Select address
4. **Expected Results:**
   - ✅ Fee calculates instantly
   - ✅ Total updates smoothly
   - ✅ No performance lag
   - ✅ Order places successfully

---

## 🔐 Security & Validation Tests

### Test Case 8.1: SQL Injection Prevention
**Objective**: Delivery address safe from injection

**Manual Steps:**
1. Open map picker
2. Address should auto-generate from location
3. **Expected**: No way for user to inject SQL
   - ✅ Address read-only until map selection
   - ✅ Coordinates validated as numbers

---

### Test Case 8.2: Invalid Coordinates Handling
**Objective**: Non-numeric coordinates don't break app

**Dart Code (Unit Test):**
```dart
void test_invalid_coordinates() {
  // Null values
  final result1 = DeliveryValidator.validateDelivery(null, null);
  assert(!result1.isValid);
  
  // Non-existent location
  final result2 = DeliveryValidator.validateDelivery(-90.0, 200.0);
  // Should still validate distance, though location is unrealistic
  
  print('✅ Invalid coordinates handled gracefully');
}
```

---

## 📋 Test Execution Checklist

### Pre-Test Setup
- [ ] Fresh app install or cleared cache
- [ ] Logged in with test account
- [ ] Supabase database accessible
- [ ] System time correctly set (for store hours tests)
- [ ] Test data in cart ready

### Test Execution Order
- [ ] Run Unit Tests: `flutter test`
- [ ] Test Distance Calculation (Suite 1)
- [ ] Test Delivery Fee (Suite 2)
- [ ] Test Store Hours (Suite 3)
- [ ] Test Address Widget (Suite 4)
- [ ] Test Checkout Integration (Suite 5)
- [ ] Test Edge Cases (Suite 6)
- [ ] Test Performance (Suite 7)
- [ ] Test Security (Suite 8)

### Post-Test Verification
- [ ] Check Supabase orders table for all test orders
- [ ] Verify order fields populated correctly
- [ ] Check logs for any errors
- [ ] Validate no data corruption
- [ ] Confirm SharedPreferences data integrity

---

## 🐛 Known Issues & Workarounds

### Issue: Time-based tests fail at boundary
**Workaround**: Use `await Future.delayed(Duration(minutes: 1))` to cross boundaries

### Issue: Coordinates precision variation
**Workaround**: Use ±0.01 km tolerance in assertions

### Issue: SharedPreferences null on first run
**Workaround**: Check for null and default to "Select Location"

---

## 📞 Test Failure Reporting

If a test fails, capture:
1. **Test case name**
2. **Device/Platform**: Web, Android, iOS
3. **Expected vs Actual** results
4. **Screenshots** of UI state
5. **Supabase query results** (if applicable)
6. **Device time** (for store hours tests)
7. **Steps to reproduce**

---

**Test Guide Version**: 1.0.0
**Last Updated**: February 19, 2026
**Status**: Ready for Testing ✅
