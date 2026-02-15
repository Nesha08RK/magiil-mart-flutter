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
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    required this.category,
    this.searchQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final CustomerProductService _service;
  bool _loading = true;
  List<CustomerProduct> _products = [];
  List<CustomerProduct> _filteredProducts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = CustomerProductService();
    _searchQuery = widget.searchQuery ?? '';
    if (widget.category == 'All' || (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)) {
      _loadAllProducts();
    } else {
      _loadProducts();
    }
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _loading = true;
    });
    try {
      if (_searchQuery.isNotEmpty) {
        final products = await _service.searchProducts(_searchQuery);
        setState(() {
          _products = products;
          _filteredProducts = products;
        });
      } else {
        final products = await _service.fetchAllAvailableProducts();
        setState(() {
          _products = products;
          _filteredProducts = products;
        });
      }
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

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });
    try {
      final products = await _service.fetchProductsByCategory(widget.category);
      setState(() {
        _products = products;
        _filteredProducts = products;
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

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery) &&
              !product.isOutOfStock &&
              product.stock > 0;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          widget.searchQuery != null && widget.searchQuery!.isNotEmpty
              ? 'Search: ${widget.searchQuery}'
              : widget.category == 'All'
                  ? 'All Products'
                  : widget.category,
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C2C2C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B3E5E)),
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF6B3E5E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Search bar with modern styling
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: _filterProducts,
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.category}...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFFA0789A),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFFA0789A),
                                    ),
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      _filterProducts('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Filter out-of-stock products for customers
                    _products
                        .where((p) => !p.isOutOfStock && p.stock > 0)
                        .isEmpty
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6B3E5E).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 56,
                                      color: const Color(0xFF6B3E5E).withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No products available'
                                        : 'No products match your search',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2B2B2B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchQuery.isNotEmpty)
                                    Text(
                                      'Try a different search term',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.55,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              // Only show available products
                              if (product.isOutOfStock || product.stock <= 0) {
                                return const SizedBox.shrink();
                              }
                              return ProductCard(
                                name: product.name,
                                basePrice: product.basePrice.toInt(),
                                baseUnit: product.baseUnit,
                                imageUrl: product.imageUrl,
                                icon: Icons.shopping_bag,
                                isOutOfStock: product.isOutOfStock,
                                stock: product.stock,
                                units: _getUnitsForBaseUnit(product.baseUnit),
                              );
                            },
                          ),
                  ],
                ),
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
  final String? imageUrl;
  final IconData icon;
  final List<String> units;
  final bool isOutOfStock;
  final int stock;

  const ProductCard({
    super.key,
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    this.imageUrl,
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 PRODUCT IMAGE SECTION
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      gradient: widget.imageUrl == null || widget.imageUrl!.isEmpty
                          ? LinearGradient(
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
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Product Image or Fallback Background
                        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6B3E5E),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🌟 PRODUCT ICON
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: 44,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // 📦 QUANTITY BADGE
                        if (count > 0 && !widget.isOutOfStock)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC9A347),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
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
                                color: Colors.black.withOpacity(0.25),
                              ),
                              child: const Center(
                                child: Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                ),

                // 🏷 PRODUCT DETAILS SECTION
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C2C),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Stock info
                            Text(
                              'Stock: ${widget.stock} ${widget.baseUnit}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // 📊 UNIT DROPDOWN & CONTROLS
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Unit Dropdown
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE8E3DE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFFFAF9F7),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              height: 32,
                              child: DropdownButton<String>(
                                value: selectedUnit,
                                isExpanded: true,
                                underline: const SizedBox(),
                                disabledHint: Text(
                                  selectedUnit,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: Color(0xFF6B3E5E),
                                  size: 16,
                                ),
                                items: widget.units.map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(
                                      unit,
                                      style: const TextStyle(
                                        fontSize: 11,
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
                            const SizedBox(height: 6),

                            // Quantity Controls
                            if (!widget.isOutOfStock)
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE8E3DE),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    // ➖ Minus Button (Remove from Cart)
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: count > 0
                                              ? () {
                                                  cart.decreaseItem(widget.name, selectedUnit);
                                                }
                                              : null,
                                          child: Center(
                                            child: Icon(
                                              Icons.remove,
                                              size: 14,
                                              color: count > 0
                                                  ? const Color(0xFF6B3E5E)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 🔢 Quantity Display (Cart Count)
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          count.toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C2C2C),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // ➕ Plus Button (Add to Cart)
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            cart.addItem(
                                              name: widget.name,
                                              basePrice: widget.basePrice,
                                              baseUnit: widget.baseUnit,
                                              selectedUnit: selectedUnit,
                                              unitConversion: unitConversion,
                                            );
                                          },
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              size: 14,
                                              color: Color(0xFF6B3E5E),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // 💰 Price Display
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹ $unitPrice',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC9A347),
                              ),
                            ),
                            Text(
                              'per $selectedUnit',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
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
