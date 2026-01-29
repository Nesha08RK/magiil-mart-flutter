import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Expose items safely (read-only)
  List<CartItem> get items => List.unmodifiable(_items);

  /// ✅ Initialize cart from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCart();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing cart: $e');
      _isInitialized = true;
    }
  }

  /// ✅ Load cart from local storage
  Future<void> _loadCart() async {
    try {
      final cartJson = _prefs.getString('cart_items');
      if (cartJson != null) {
        final decoded = jsonDecode(cartJson) as List;
        _items.clear();
        for (final item in decoded) {
          _items.add(CartItem(
            name: item['name'] ?? '',
            basePrice: (item['basePrice'] is int) 
              ? item['basePrice'] 
              : int.tryParse('${item['basePrice']}') ?? 0,
            baseUnit: item['baseUnit'] ?? 'kg',
            selectedUnit: item['selectedUnit'] ?? 'kg',
            unitConversion: (item['unitConversion'] is num)
              ? (item['unitConversion'] as num).toDouble()
              : double.tryParse('${item['unitConversion']}') ?? 1.0,
            quantity: (item['quantity'] is int)
              ? item['quantity']
              : int.tryParse('${item['quantity']}') ?? 1,
          ));
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
      _items.clear();
    }
  }

  /// ✅ Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final cartJson = jsonEncode(
        _items.map((item) => {
          'name': item.name,
          'basePrice': item.basePrice,
          'baseUnit': item.baseUnit,
          'selectedUnit': item.selectedUnit,
          'unitConversion': item.unitConversion,
          'quantity': item.quantity,
        }).toList(),
      );
      await _prefs.setString('cart_items', cartJson);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

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

    _saveCart();
    notifyListeners();
  }

  /// ➕ Increase quantity
  void increaseItem(String name, String selectedUnit) {
    final index = _items.indexWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );

    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
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
      _saveCart();
      notifyListeners();
    }
  }

  /// 🗑 Remove item completely
  void removeItem(String name, String selectedUnit) {
    _items.removeWhere(
      (item) => item.name == name && item.selectedUnit == selectedUnit,
    );
    _saveCart();
    notifyListeners();
  }

  /// 💰 TOTAL AMOUNT (DOUBLE-SAFE ✅)
  double get totalAmount {
    return _items.fold<double>(
      0.0, // MUST be double
      (sum, item) => sum + item.totalPrice.toDouble(),
    );
  }

  /// 🧹 Clear cart after order (ONLY after successful checkout)
  void clearCart() {
    _items.clear();
    _prefs.remove('cart_items').catchError(
      (e) {
        print('Error clearing cart: $e');
        return true;
      },
    );
    notifyListeners();
  }
}
