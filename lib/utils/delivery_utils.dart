import 'package:latlong2/latlong.dart';

/// 🏪 Magiil Mart Store Configuration
class MagiilMartStore {
  // Store coordinates
  static const double storeLatitude = 11.370333090754086;
  static const double storeLongitude = 77.74837219507778;
  static const LatLng storeLocation = LatLng(storeLatitude, storeLongitude);

  // Store operating hours
  static const int openHour = 9; // 9:00 AM
  static const int openMinute = 0;
  static const int closeHour = 22; // 10:00 PM
  static const int closeMinute = 0;

  // Delivery configuration
  static const double maxDeliveryRadiusKm = 8.0;
}

/// 📏 Distance Calculation using Haversine formula (latlong2)
class DeliveryDistanceCalculator {
  static const Distance _distanceCalculator = Distance();

  /// Calculate distance between two coordinates in kilometers
  /// Returns the distance in kilometers (double)
  static double calculateDistanceKm(LatLng from, LatLng to) {
    final distanceInMeters = _distanceCalculator(from, to);
    return distanceInMeters / 1000.0; // Convert meters to km
  }

  /// Check if delivery location is within 8 km radius from store
  static bool isWithinDeliveryRadius(double deliveryLat, double deliveryLng) {
    final deliveryLocation = LatLng(deliveryLat, deliveryLng);
    final distanceKm = calculateDistanceKm(
      MagiilMartStore.storeLocation,
      deliveryLocation,
    );
    return distanceKm <= MagiilMartStore.maxDeliveryRadiusKm;
  }

  /// Get distance in km (for display)
  static double getDistanceFromStore(double deliveryLat, double deliveryLng) {
    final deliveryLocation = LatLng(deliveryLat, deliveryLng);
    return calculateDistanceKm(
      MagiilMartStore.storeLocation,
      deliveryLocation,
    );
  }
}

/// 💰 Dynamic Delivery Fee Calculator
class DeliveryFeeCalculator {
  /// Calculate delivery fee based on distance in km
  /// 0 - 3 km → ₹20
  /// 3 - 6 km → ₹40
  /// 6 - 8 km → ₹60
  static int calculateDeliveryFee(double distanceKm) {
    if (distanceKm <= 3.0) {
      return 20;
    } else if (distanceKm <= 6.0) {
      return 40;
    } else if (distanceKm <= 8.0) {
      return 60;
    }
    // Beyond 8 km (should not reach here due to radius validation)
    return 0;
  }

  /// Get delivery fee tier description
  static String getFeeDescription(double distanceKm) {
    if (distanceKm <= 3.0) {
      return '₹20 (≤3 km)';
    } else if (distanceKm <= 6.0) {
      return '₹40 (3-6 km)';
    } else if (distanceKm <= 8.0) {
      return '₹60 (6-8 km)';
    }
    return '₹0';
  }
}

/// ⏰ Store Availability Checker
class StoreAvailabilityChecker {
  /// Check if store is currently open
  static bool isStoreOpen() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Convert to minutes for easier comparison
    final currentTotalMinutes = currentHour * 60 + currentMinute;
    final openTotalMinutes =
        MagiilMartStore.openHour * 60 + MagiilMartStore.openMinute;
    final closeTotalMinutes =
        MagiilMartStore.closeHour * 60 + MagiilMartStore.closeMinute;

    return currentTotalMinutes >= openTotalMinutes &&
        currentTotalMinutes < closeTotalMinutes;
  }

  /// Get store status message
  static String getStoreStatus() {
    return isStoreOpen() ? '🟢 Open Now' : '🔴 Closed';
  }

  /// Get store hours message
  static String getStoreHoursMessage() {
    return 'Orders accepted between ${MagiilMartStore.openHour}:00 AM – ${MagiilMartStore.closeHour % 12 == 0 ? 12 : MagiilMartStore.closeHour % 12}:00 ${MagiilMartStore.closeHour >= 12 ? 'PM' : 'AM'} only';
  }

  /// Get time until store opens (if closed)
  static Duration? getTimeUntilStoreOpens() {
    if (isStoreOpen()) return null;

    final now = DateTime.now();
    final todayOpen = DateTime(
      now.year,
      now.month,
      now.day,
      MagiilMartStore.openHour,
      MagiilMartStore.openMinute,
    );

    if (now.isBefore(todayOpen)) {
      return todayOpen.difference(now);
    } else {
      // Store opens tomorrow
      return todayOpen.add(const Duration(days: 1)).difference(now);
    }
  }

  /// Get time until store closes (if open)
  static Duration? getTimeUntilStoreCloses() {
    if (!isStoreOpen()) return null;

    final now = DateTime.now();
    final todayClose = DateTime(
      now.year,
      now.month,
      now.day,
      MagiilMartStore.closeHour,
      MagiilMartStore.closeMinute,
    );

    return todayClose.difference(now);
  }
}

/// 🎯 Delivery Validation Result
class DeliveryValidationResult {
  final bool isValid;
  final String message;
  final double? distanceKm;
  final int? deliveryFee;

  const DeliveryValidationResult({
    required this.isValid,
    required this.message,
    this.distanceKm,
    this.deliveryFee,
  });

  @override
  String toString() =>
      'DeliveryValidationResult(isValid: $isValid, message: $message, distanceKm: $distanceKm, deliveryFee: $deliveryFee)';
}

/// 🔍 Complete Delivery Validator
class DeliveryValidator {
  /// Comprehensive validation before order placement
  static DeliveryValidationResult validateDelivery(
    double? deliveryLatitude,
    double? deliveryLongitude,
  ) {
    // Check if coordinates are provided
    if (deliveryLatitude == null || deliveryLongitude == null) {
      return const DeliveryValidationResult(
        isValid: false,
        message: 'Please select a delivery address on the map',
      );
    }

    // Check store availability
    if (!StoreAvailabilityChecker.isStoreOpen()) {
      return DeliveryValidationResult(
        isValid: false,
        message: StoreAvailabilityChecker.getStoreHoursMessage(),
      );
    }

    // Check delivery radius
    if (!DeliveryDistanceCalculator.isWithinDeliveryRadius(
      deliveryLatitude,
      deliveryLongitude,
    )) {
      return const DeliveryValidationResult(
        isValid: false,
        message: 'Delivery available within 8 km from Magiil Mart only',
      );
    }

    // All validations passed - calculate distance and fee
    final distanceKm =
        DeliveryDistanceCalculator.getDistanceFromStore(
          deliveryLatitude,
          deliveryLongitude,
        );
    final deliveryFee = DeliveryFeeCalculator.calculateDeliveryFee(distanceKm);

    return DeliveryValidationResult(
      isValid: true,
      message: 'Delivery validation successful',
      distanceKm: distanceKm,
      deliveryFee: deliveryFee,
    );
  }
}
