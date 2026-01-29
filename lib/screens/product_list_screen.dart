import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'services/customer_product_service.dart';

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

  return 1.0;
}

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({
    super.key,
    required this.category,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final CustomerProductService _service;
  bool _loading = true;
  List<CustomerProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _service = CustomerProductService();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });
    try {
      final products = await _service.fetchProductsByCategory(widget.category);
      setState(() {
        _products = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3DE), // warm neutral
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Color(0xFF5A2E4A), // plum
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? const Center(child: Text('No products available in this category'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          name: product.name,
                          basePrice: product.basePrice.toInt(),
                          baseUnit: product.baseUnit,
                          icon: Icons.shopping_bag,
                          isOutOfStock: product.isOutOfStock,
                          stock: product.stock,
                          units: _getUnitsForBaseUnit(product.baseUnit),
                        );
                      },
                    ),
            ),
    );
  }

  List<String> _getUnitsForBaseUnit(String baseUnit) {
    switch (baseUnit) {
      case 'kg':
        return ['1kg', '500g', '250g', '5kg', '10kg'];
      case '1L':
        return ['1L', '500ml', '250ml', '5L'];
      case 'ml':
        return ['1L', '500ml', '250ml'];
      case 'g':
        return ['100g', '250g', '500g', '1kg'];
      case 'piece':
        return ['piece', 'bunch'];
      case 'pack':
        return ['pack', '5-pack'];
      default:
        return ['1'];
    }
  }
}

class ProductCard extends StatefulWidget {
  final String name;
  final int basePrice;
  final String baseUnit;
  final IconData icon;
  final List<String> units;
  final bool isOutOfStock;
  final int stock;

  const ProductCard({
    super.key,
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    required this.icon,
    required this.units,
    required this.isOutOfStock,
    required this.stock,
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
    selectedUnit = widget.units.isNotEmpty ? widget.units.first : '1';
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
          child: Opacity(
            opacity: widget.isOutOfStock ? 0.6 : 1.0,
            child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼 PRODUCT IMAGE SECTION
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isOutOfStock
                            ? [
                                Colors.grey.shade300,
                                Colors.grey.shade200,
                              ]
                            : const [
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
                          if (count > 0 && !widget.isOutOfStock)
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
                        const SizedBox(height: 8),

                        // Stock info
                        Text(
                          'Stock: ${widget.stock} ${widget.baseUnit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                            disabledHint: Text(selectedUnit),
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
                            onChanged: widget.isOutOfStock
                                ? null
                                : (String? newUnit) {
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
                        if (!widget.isOutOfStock)
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

                            // ➕ ADD TO CART BUTTON or OUT OF STOCK
                            if (widget.isOutOfStock)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                )..copyWith(
                                    enableFeedback: false,
                                  ),
                                onPressed: null,
                                child: const Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: count == 0
                                      ? const Color(0xFF5A2E4A)
                                      : const Color(0xFFC9A347),
                                  foregroundColor:
                                      count == 0 ? Colors.white : Colors.black,
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
              // Out of Stock overlay
              if (widget.isOutOfStock)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
            ),
          );
      },
    );
  }
}
