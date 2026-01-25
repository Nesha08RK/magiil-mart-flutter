import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductListScreen extends StatelessWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final products = _products[category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            name: product['name'],
            price: product['price'],
            icon: product['icon'],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final IconData icon;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.green),
          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹ $price',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // ADD / - COUNT + CONTROLS
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final item = cart.items
                  .where((element) => element.name == name)
                  .toList();

              final count = item.isEmpty ? 0 : item.first.quantity;

              // SHOW ADD BUTTON
              if (count == 0) {
                return ElevatedButton(
                  onPressed: () {
                    cart.addItem(name, int.parse(price));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }

              // SHOW - COUNT +
              return Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        cart.decreaseItem(name);
                      },
                    ),
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        cart.addItem(name, int.parse(price));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Dummy products (replace with Firebase later)
final Map<String, List<Map<String, dynamic>>> _products = {
  'Vegetables': [
    {'name': 'Tomato', 'price': '30', 'icon': Icons.eco},
    {'name': 'Potato', 'price': '25', 'icon': Icons.agriculture},
  ],
  'Fruits': [
    {'name': 'Apple', 'price': '120', 'icon': Icons.apple},
    {'name': 'Banana', 'price': '50', 'icon': Icons.restaurant},
  ],
  'Groceries': [
    {'name': 'Rice', 'price': '60', 'icon': Icons.rice_bowl},
  ],
  'Snacks': [
    {'name': 'Biscuits', 'price': '20', 'icon': Icons.cookie},
  ],
};
