import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final screens = const [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}
