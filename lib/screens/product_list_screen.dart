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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C2C2C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A2E4A)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF5A2E4A),
              child: _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 600 ? 2 : 1,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: widget.isOutOfStock ? 0.7 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 PRODUCT IMAGE SECTION
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isOutOfStock
                          ? [
                              Colors.grey.shade200,
                              Colors.grey.shade100,
                            ]
                          : const [
                              Color(0xFF6B3E5E),
                              Color(0xFF8B5A7E),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🌟 PRODUCT ICON/IMAGE
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                size: 48,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 📦 QUANTITY BADGE
                      if (count > 0 && !widget.isOutOfStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A347),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      // Out of Stock overlay
                      if (widget.isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 🏷 PRODUCT DETAILS SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Stock info
                        Text(
                          'Stock: ${widget.stock} ${widget.baseUnit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 📊 UNIT DROPDOWN
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE8E3DE),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFFAF9F7),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 36,
                          child: DropdownButton<String>(
                            value: selectedUnit,
                            isExpanded: true,
                            underline: const SizedBox(),
                            disabledHint: Text(
                              selectedUnit,
                              style: const TextStyle(fontSize: 12),
                            ),
                            icon: const Icon(
                              Icons.expand_more,
                              color: Color(0xFF5A2E4A),
                              size: 18,
                            ),
                            items: widget.units.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 12,
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
                        const Spacer(),

                        // ➖ QUANTITY +/- BUTTONS
                        if (!widget.isOutOfStock)
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE8E3DE),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // ➖ Minus Button
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: selectedQuantity > 1
                                          ? () {
                                              setState(() {
                                                selectedQuantity--;
                                              });
                                            }
                                          : null,
                                      child: Center(
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: selectedQuantity > 1
                                              ? const Color(0xFF5A2E4A)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // 🔢 Quantity Display
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      selectedQuantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ),
                                ),
                                // ➕ Plus Button
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedQuantity++;
                                        });
                                      },
                                      child: const Center(
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Color(0xFF5A2E4A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),

                        // 💰 Price and Add Button Row
                        Row(
                          children: [
                            // Price per unit
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹ $unitPrice',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC9A347),
                                  ),
                                ),
                                Text(
                                  'per $selectedUnit',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // ➕ ADD TO CART BUTTON or OUT OF STOCK
                            if (widget.isOutOfStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: count == 0
                                          ? const Color(0xFF5A2E4A)
                                          : const Color(0xFFC9A347),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      count == 0 ? 'Add' : '+$count',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: count == 0
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
