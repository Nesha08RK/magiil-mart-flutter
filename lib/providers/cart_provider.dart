import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // ADD ITEM (or increase if exists)
  void addItem(String name, int price) {
    final index = _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(name: name, price: price),
      );
    }
    notifyListeners();
  }

  // INCREASE ITEM (used in Cart screen ➕)
  void increaseItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  // DECREASE ITEM (used in Product & Cart screen ➖)
  void decreaseItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // REMOVE ITEM COMPLETELY
  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // TOTAL AMOUNT
  int get totalAmount {
    return _items.fold(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );
  }

  // CLEAR CART (for future checkout)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
