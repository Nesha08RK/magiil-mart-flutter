import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  /// Expose items safely (read-only)
  List<CartItem> get items => List.unmodifiable(_items);

  /// ➕ Add item to cart
  void addItem({
    required String name,
    required int basePrice,
    required String baseUnit,
    required String selectedUnit,
    required double unitConversion,
  }) {
    final index = _items.indexWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          name: name,
          basePrice: basePrice,
          baseUnit: baseUnit,
          selectedUnit: selectedUnit,
          unitConversion: unitConversion,
        ),
      );
    }

    notifyListeners();
  }

  /// ➕ Increase quantity
  void increaseItem(String name, String selectedUnit) {
    final index = _items.indexWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );

    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  /// ➖ Decrease quantity or remove
  void decreaseItem(String name, String selectedUnit) {
    final index = _items.indexWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// 🗑 Remove item completely
  void removeItem(String name, String selectedUnit) {
    _items.removeWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );
    notifyListeners();
  }

  /// 💰 TOTAL AMOUNT (DOUBLE-SAFE ✅)
  double get totalAmount {
    return _items.fold<double>(
      0.0, // MUST be double
      (sum, item) => sum + item.totalPrice.toDouble(),
    );
  }

  /// 🧹 Clear cart after order
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
