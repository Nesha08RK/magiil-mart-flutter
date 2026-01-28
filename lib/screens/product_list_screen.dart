import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

// Helper function to calculate unit conversion ratio
double getUnitConversion(String baseUnit, String selectedUnit) {
  // kg conversions
  if (baseUnit == 'kg') {
    if (selectedUnit == '1kg') return 1.0;
    if (selectedUnit == '500g') return 0.5;
    if (selectedUnit == '250g') return 0.25;
    if (selectedUnit == '5kg') return 5.0;
    if (selectedUnit == '10kg') return 10.0;
  }
  
  // Litre conversions
  if (baseUnit == '1L') {
    if (selectedUnit == '1L') return 1.0;
    if (selectedUnit == '500ml') return 0.5;
    if (selectedUnit == '250ml') return 0.25;
    if (selectedUnit == '5L') return 5.0;
  }
  
  // Millilitre conversions
  if (baseUnit == 'ml') {
    if (selectedUnit.endsWith('ml')) {
      return double.parse(selectedUnit.replaceAll('ml', '')) / 1000;
    }
    if (selectedUnit.endsWith('L')) {
      return double.parse(selectedUnit.replaceAll('L', ''));
    }
  }
  
  // Gram conversions
  if (baseUnit == 'g') {
    if (selectedUnit.endsWith('g')) return double.parse(selectedUnit.replaceAll('g', '')) / 1000;
    if (selectedUnit.endsWith('kg')) return double.parse(selectedUnit.replaceAll('kg', ''));
  }
  
  // Piece/pack conversions
  if (baseUnit == 'piece' || baseUnit == 'pack') {
    if (selectedUnit == 'piece' || selectedUnit == 'pack') return 1.0;
    if (selectedUnit == '5-pack') return 5.0;
    if (selectedUnit == 'bunch') return 1.0;
  }
  
  // Item count conversions
  if (baseUnit == 'pcs' || baseUnit == 'pcs') {
    if (selectedUnit.contains('30')) return 1.0;
    if (selectedUnit.contains('40')) return 1.0;
    if (selectedUnit.contains('50')) return 1.0;
    if (selectedUnit.contains('100')) return 1.0;
  }
  
  return 1.0; // Default
}

class ProductListScreen extends StatelessWidget {
  final String category;

  const ProductListScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final products = _products[category] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE8E3DE), // warm neutral
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(
            color: Color(0xFF5A2E4A), // plum
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            name: product['name'],
            basePrice: product['basePrice'],
            baseUnit: product['baseUnit'],
            icon: product['icon'],
            units: product['units'] ?? [],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final String name;
  final int basePrice;
  final String baseUnit;
  final IconData icon;
  final List<String> units;

  const ProductCard({
    super.key,
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    required this.icon,
    required this.units,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late String selectedUnit;
  int selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    selectedUnit = widget.units.isNotEmpty ? widget.units.first : 'kg';
  }

  @override
  Widget build(BuildContext context) {
    final unitConversion = getUnitConversion(widget.baseUnit, selectedUnit);
    final unitPrice = (widget.basePrice * unitConversion).toInt();

    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final item = cart.items
            .where((element) => element.name == widget.name && element.selectedUnit == selectedUnit)
            .toList();

        final count = item.isEmpty ? 0 : item.first.quantity;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B3E5E).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 PRODUCT IMAGE SECTION
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B3E5E), // rich plum
                      Color(0xFFA0789A), // dusty mauve
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🌟 PRODUCT ICON/IMAGE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 📦 QUANTITY DISPLAY (Dynamic from Cart)
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A347),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Qty: $count',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 🏷 PRODUCT DETAILS SECTION
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 📊 UNIT DROPDOWN
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFC9A347),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: selectedUnit,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF5A2E4A),
                        ),
                        items: widget.units.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newUnit) {
                          if (newUnit != null) {
                            setState(() {
                              selectedUnit = newUnit;
                              selectedQuantity = 1;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ➖ QUANTITY +/- BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ➖ Minus Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A2E4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: selectedQuantity > 1
                              ? () {
                                  setState(() {
                                    selectedQuantity--;
                                  });
                                }
                              : null,
                          child: const Text(
                            '−',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 🔢 Quantity Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFC9A347),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$selectedQuantity $selectedUnit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ),

                        // ➕ Plus Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A2E4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedQuantity++;
                            });
                          },
                          child: const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 💰 Price and Add Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price per unit
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price per unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₹ $unitPrice',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC9A347),
                              ),
                            ),
                          ],
                        ),

                        // ➕ ADD TO CART BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: count == 0
                                ? const Color(0xFF5A2E4A)
                                : const Color(0xFFC9A347),
                            foregroundColor: count == 0 ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            cart.addItem(
                              name: widget.name,
                              basePrice: widget.basePrice,
                              baseUnit: widget.baseUnit,
                              selectedUnit: selectedUnit,
                              unitConversion: unitConversion,
                            );
                            setState(() {
                              selectedQuantity = 1;
                            });
                          },
                          child: Text(
                            count == 0 ? 'Add' : '+$count',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 🔹 PRODUCT DATA WITH BASE PRICING
final Map<String, List<Map<String, dynamic>>> _products = {
  'Vegetables': [
    {'name': 'Tomato', 'basePrice': 60, 'baseUnit': 'kg', 'icon': Icons.eco, 'units': ['kg', '500g', 'piece']},
    {'name': 'Potato', 'basePrice': 50, 'baseUnit': 'kg', 'icon': Icons.agriculture, 'units': ['kg', '500g']},
    {'name': 'Onion', 'basePrice': 70, 'baseUnit': 'kg', 'icon': Icons.eco, 'units': ['kg', '500g']},
    {'name': 'Carrot', 'basePrice': 80, 'baseUnit': 'kg', 'icon': Icons.agriculture, 'units': ['kg', '500g']},
    {'name': 'Cabbage', 'basePrice': 40, 'baseUnit': 'kg', 'icon': Icons.eco, 'units': ['kg', 'piece']},
    {'name': 'Cucumber', 'basePrice': 50, 'baseUnit': 'kg', 'icon': Icons.agriculture, 'units': ['kg', 'piece']},
    {'name': 'Bell Pepper', 'basePrice': 100, 'baseUnit': 'kg', 'icon': Icons.eco, 'units': ['kg', 'piece']},
    {'name': 'Spinach', 'basePrice': 60, 'baseUnit': 'kg', 'icon': Icons.agriculture, 'units': ['kg', '500g']},
  ],
  'Fruits': [
    {'name': 'Apple', 'basePrice': 240, 'baseUnit': 'kg', 'icon': Icons.apple, 'units': ['kg', '500g', 'piece']},
    {'name': 'Banana', 'basePrice': 100, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['kg', 'bunch', 'piece']},
    {'name': 'Orange', 'basePrice': 160, 'baseUnit': 'kg', 'icon': Icons.apple, 'units': ['kg', 'piece']},
    {'name': 'Mango', 'basePrice': 120, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['kg', 'piece']},
    {'name': 'Grapes', 'basePrice': 200, 'baseUnit': 'kg', 'icon': Icons.apple, 'units': ['kg', '500g']},
    {'name': 'Papaya', 'basePrice': 90, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['kg', 'piece']},
    {'name': 'Pineapple', 'basePrice': 140, 'baseUnit': 'kg', 'icon': Icons.apple, 'units': ['piece', 'kg']},
    {'name': 'Guava', 'basePrice': 80, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['kg', 'piece']},
  ],
  'Rice & Grains': [
    {'name': 'Ponni Raw Rice', 'basePrice': 75, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg', '10kg']},
    {'name': 'Ponni Boiled Rice', 'basePrice': 85, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg', '10kg']},
    {'name': 'Sona Masoori Rice', 'basePrice': 95, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg', '10kg']},
    {'name': 'Idli Rice', 'basePrice': 80, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Seeraga Samba Rice', 'basePrice': 120, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Basmati Rice Regular', 'basePrice': 140, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Basmati Rice Premium', 'basePrice': 180, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Brown Rice', 'basePrice': 110, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Matta Rice Kerala', 'basePrice': 125, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
    {'name': 'Old Rice', 'basePrice': 150, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg']},
  ],
  'Pulses & Dals': [
    {'name': 'Toor Dal', 'basePrice': 120, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Chana Dal', 'basePrice': 130, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Moong Dal', 'basePrice': 140, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Masoor Dal', 'basePrice': 110, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Urad Dal', 'basePrice': 150, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Chickpeas', 'basePrice': 100, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Black Gram', 'basePrice': 135, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Red Kidney Beans', 'basePrice': 125, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
  ],
  'Cooking Oils': [
    {'name': 'Sunflower Oil 1L', 'basePrice': 200, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['1L', '500ml', '250ml']},
    {'name': 'Coconut Oil 500ml', 'basePrice': 560, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['500ml', '250ml', '1L']},
    {'name': 'Groundnut Oil 1L', 'basePrice': 320, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['1L', '500ml', '250ml']},
    {'name': 'Mustard Oil 1L', 'basePrice': 240, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['1L', '500ml']},
    {'name': 'Sesame Oil 500ml', 'basePrice': 760, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['500ml', '250ml']},
    {'name': 'Olive Oil 500ml', 'basePrice': 840, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['500ml', '250ml']},
    {'name': 'Rice Bran Oil 1L', 'basePrice': 350, 'baseUnit': '1L', 'icon': Icons.opacity, 'units': ['1L', '500ml']},
  ],
  'Spices & Masalas': [
    {'name': 'Turmeric Powder 100g', 'basePrice': 600, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g', '500g']},
    {'name': 'Red Chilli Powder 100g', 'basePrice': 800, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g', '500g']},
    {'name': 'Cumin Seeds 100g', 'basePrice': 900, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g', '500g']},
    {'name': 'Coriander Powder 100g', 'basePrice': 850, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g', '500g']},
    {'name': 'Garam Masala 100g', 'basePrice': 1200, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g']},
    {'name': 'Fenugreek Seeds 100g', 'basePrice': 750, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g']},
    {'name': 'Black Pepper 100g', 'basePrice': 1100, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['100g', '250g']},
    {'name': 'Cardamom Green 50g', 'basePrice': 3600, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['50g', '100g']},
    {'name': 'Cloves 50g', 'basePrice': 3200, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['50g', '100g']},
    {'name': 'Cinnamon Sticks 50g', 'basePrice': 2800, 'baseUnit': 'kg', 'icon': Icons.local_fire_department, 'units': ['50g', '100g']},
  ],
  'Flours & Atta': [
    {'name': 'Wheat Flour 5kg', 'basePrice': 56, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['5kg', '10kg', '1kg']},
    {'name': 'Rice Flour 1kg', 'basePrice': 120, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Besan Flour 1kg', 'basePrice': 140, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Ragi Flour 1kg', 'basePrice': 150, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Jowar Flour 1kg', 'basePrice': 130, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Maida 1kg', 'basePrice': 100, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['1kg', '500g']},
    {'name': 'Corn Flour 500g', 'basePrice': 160, 'baseUnit': 'kg', 'icon': Icons.grain, 'units': ['500g', '250g']},
  ],
  'Snacks & Biscuits': [
    {'name': 'Biscuits', 'basePrice': 20, 'baseUnit': 'pack', 'icon': Icons.cookie, 'units': ['pack', '200g', '500g']},
    {'name': 'Namkeen Mix 200g', 'basePrice': 400, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['200g', '500g', '1kg']},
    {'name': 'Potato Chips 150g', 'basePrice': 333, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['150g', '300g']},
    {'name': 'Murukku 200g', 'basePrice': 450, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['200g', '500g', '1kg']},
    {'name': 'Chikhalwali 200g', 'basePrice': 350, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['200g', '500g']},
    {'name': 'Mixture 250g', 'basePrice': 400, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['250g', '500g', '1kg']},
    {'name': 'Banana Chips 150g', 'basePrice': 400, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['150g', '300g', '500g']},
    {'name': 'Cashew Cookies 200g', 'basePrice': 700, 'baseUnit': 'kg', 'icon': Icons.cookie, 'units': ['200g', '500g']},
  ],
  'Beverages': [
    {'name': 'Tea Leaves 500g', 'basePrice': 360, 'baseUnit': 'kg', 'icon': Icons.local_cafe, 'units': ['500g', '250g', '1kg']},
    {'name': 'Coffee Powder 250g', 'basePrice': 800, 'baseUnit': 'kg', 'icon': Icons.local_cafe, 'units': ['250g', '500g', '1kg']},
    {'name': 'Milk Powder 400g', 'basePrice': 400, 'baseUnit': 'kg', 'icon': Icons.local_cafe, 'units': ['400g', '800g']},
    {'name': 'Coconut Milk 400ml', 'basePrice': 300, 'baseUnit': '1L', 'icon': Icons.local_cafe, 'units': ['400ml', '200ml']},
    {'name': 'Lemon Juice 750ml', 'basePrice': 113, 'baseUnit': '1L', 'icon': Icons.local_cafe, 'units': ['750ml', '1L']},
    {'name': 'Drinking Water 2L', 'basePrice': 17, 'baseUnit': '1L', 'icon': Icons.local_cafe, 'units': ['2L', '1L', '5L']},
    {'name': 'Energy Drink 250ml', 'basePrice': 180, 'baseUnit': '1L', 'icon': Icons.local_cafe, 'units': ['250ml', '500ml']},
  ],
  'Personal Care': [
    {'name': 'Soap 100g', 'basePrice': 300, 'baseUnit': 'kg', 'icon': Icons.spa, 'units': ['100g', 'pack']},
    {'name': 'Shampoo 200ml', 'basePrice': 400, 'baseUnit': '1L', 'icon': Icons.spa, 'units': ['200ml', '400ml', '1L']},
    {'name': 'Toothpaste 100g', 'basePrice': 450, 'baseUnit': 'kg', 'icon': Icons.spa, 'units': ['100g', '150g']},
    {'name': 'Toothbrush', 'basePrice': 25, 'baseUnit': 'piece', 'icon': Icons.spa, 'units': ['piece', 'pack']},
    {'name': 'Hair Oil 100ml', 'basePrice': 700, 'baseUnit': '1L', 'icon': Icons.spa, 'units': ['100ml', '200ml', '500ml']},
    {'name': 'Deodorant 150ml', 'basePrice': 800, 'baseUnit': '1L', 'icon': Icons.spa, 'units': ['150ml', '250ml']},
    {'name': 'Face Wash 100ml', 'basePrice': 850, 'baseUnit': '1L', 'icon': Icons.spa, 'units': ['100ml', '200ml']},
    {'name': 'Sanitary Pads 30s', 'basePrice': 160, 'baseUnit': 'pack', 'icon': Icons.spa, 'units': ['30pcs', '40pcs']},
  ],
  'Household Essentials': [
    {'name': 'Dish Wash Liquid 500ml', 'basePrice': 120, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['500ml', '1L', '250ml']},
    {'name': 'Laundry Detergent 1kg', 'basePrice': 180, 'baseUnit': 'kg', 'icon': Icons.home_repair_service, 'units': ['1kg', '500g', '2kg']},
    {'name': 'Floor Cleaner 500ml', 'basePrice': 160, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['500ml', '1L']},
    {'name': 'Glass Cleaner 500ml', 'basePrice': 150, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['500ml', '1L']},
    {'name': 'Air Freshener 300ml', 'basePrice': 400, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['300ml', '500ml']},
    {'name': 'Toilet Cleaner 500ml', 'basePrice': 180, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['500ml', '1L']},
    {'name': 'Disinfectant 1L', 'basePrice': 100, 'baseUnit': '1L', 'icon': Icons.home_repair_service, 'units': ['1L', '500ml', '5L']},
    {'name': 'Garbage Bags 30s', 'basePrice': 85, 'baseUnit': 'pack', 'icon': Icons.home_repair_service, 'units': ['30pcs', '50pcs', '100pcs']},
  ],
  'Groceries': [
    {'name': 'Rice', 'basePrice': 60, 'baseUnit': 'kg', 'icon': Icons.rice_bowl, 'units': ['1kg', '5kg', '10kg']},
    {'name': 'Sugar 1kg', 'basePrice': 55, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['1kg', '500g', '2kg']},
    {'name': 'Salt 1kg', 'basePrice': 25, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['1kg', '500g']},
    {'name': 'Honey 500ml', 'basePrice': 560, 'baseUnit': '1L', 'icon': Icons.restaurant, 'units': ['500ml', '250ml', '1L']},
    {'name': 'Jam 500g', 'basePrice': 240, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['500g', '250g']},
    {'name': 'Peanut Butter 500g', 'basePrice': 360, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['500g', '250g', '1kg']},
    {'name': 'Cornflakes 400g', 'basePrice': 350, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['400g', '800g']},
    {'name': 'Pasta 500g', 'basePrice': 180, 'baseUnit': 'kg', 'icon': Icons.restaurant, 'units': ['500g', '250g', '1kg']},
    {'name': 'Noodles Pack', 'basePrice': 25, 'baseUnit': 'pack', 'icon': Icons.restaurant, 'units': ['pack', '5-pack']},
  ],
};
