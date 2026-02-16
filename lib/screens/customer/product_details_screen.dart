import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/cart_item.dart';
import '../../../providers/cart_provider.dart';
import '../services/customer_product_service.dart';

// Helper function to calculate unit conversion ratio
double getUnitConversion(String baseUnit, String selectedUnit) {
  // kg conversions
  if (baseUnit == 'kg') {
    if (selectedUnit == '1kg') return 1.0;
    if (selectedUnit == '500g') return 0.5;
    if (selectedUnit == '250g') return 0.25;
    if (selectedUnit == '5kg') return 5.0;
  }
  
  // l (liter) conversions
  if (baseUnit == 'l') {
    if (selectedUnit == '1l') return 1.0;
    if (selectedUnit == '500ml') return 0.5;
    if (selectedUnit == '250ml') return 0.25;
    if (selectedUnit == '5l') return 5.0;
  }
  
  // pcs (pieces) - no conversion needed
  if (baseUnit == 'pcs') {
    if (selectedUnit == '1pc') return 1.0;
    if (selectedUnit == 'dozen') return 12.0;
    if (selectedUnit == 'pack') return 1.0;
    if (selectedUnit == '5-pack') return 5.0;
  }
  
  // Default to 1 if no conversion found
  return 1.0;
}

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String name;
  final String category;
  final double basePrice;
  final String baseUnit;
  final int stock;
  final String? imageUrl;
  final bool isOutOfStock;
  final List<String> units;
  final String? description;

  const ProductDetailsScreen({
    Key? key,
    required this.productId,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.baseUnit,
    required this.stock,
    this.imageUrl,
    this.isOutOfStock = false,
    this.units = const [],
    this.description,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? selectedUnit;
  bool _isExpanded = false;
  final CustomerProductService _productService = CustomerProductService();
  Map<String, dynamic>? _productDetails;
  bool _isLoading = false; // Initialize as false since we'll load on init

  @override
  void initState() {
    super.initState();
    selectedUnit = widget.units.isNotEmpty ? widget.units.first : null;
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    if (widget.productId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final product = await _productService.getProductDetails(widget.productId);
      if (product != null) {
        setState(() {
          _productDetails = {
            'description': product.description,
            // Add other product details you want to display
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitConversion = getUnitConversion(widget.baseUnit, selectedUnit ?? widget.baseUnit);
    final unitPrice = (widget.basePrice * unitConversion).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      Text(
                        '₹$unitPrice',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC9A347),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Unit Selector
                  if (widget.units.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedUnit,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B3E5E)),
                          items: widget.units.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                '1 $unit',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF2C2C2C)),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newUnit) {
                            if (newUnit != null) {
                              setState(() {
                                selectedUnit = newUnit;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        widget.isOutOfStock || widget.stock <= 0 ? Icons.cancel : Icons.check_circle,
                        color: widget.isOutOfStock || widget.stock <= 0 ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isOutOfStock || widget.stock <= 0
                            ? 'Out of Stock'
                            : 'In Stock (${widget.stock} ${widget.baseUnit} available)',
                        style: TextStyle(
                          color: widget.isOutOfStock || widget.stock <= 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About the Product Section
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'About the Product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          firstChild: Text(
                            _productDetails?['description']?.toString().isNotEmpty == true
                                ? '${_productDetails!['description'].toString().substring(0, _productDetails!['description'].toString().length > 100 ? 100 : null)}${_productDetails!['description'].toString().length > 100 ? '...' : ''}'
                                : 'No description available',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          secondChild: Text(
                            _productDetails?['description']?.toString() ?? 'No description available',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Add to Cart Button
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final cartItem = cart.items.firstWhere(
            (item) => item.name == widget.name && item.selectedUnit == (selectedUnit ?? widget.baseUnit),
            orElse: () => CartItem(
              name: '',
              basePrice: 0,
              baseUnit: '',
              selectedUnit: '',
              unitConversion: 1.0,
              quantity: 0,
            ),
          );
          
          final isInCart = cartItem.quantity > 0;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: isInCart
                ? _buildCartControls(cart, cartItem)
                : ElevatedButton(
                    onPressed: widget.isOutOfStock || widget.stock <= 0
                        ? null
                        : () {
                            cart.addItem(
                              name: widget.name,
                              basePrice: widget.basePrice.toInt(),
                              baseUnit: widget.baseUnit,
                              selectedUnit: selectedUnit ?? widget.baseUnit,
                              unitConversion: unitConversion,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to cart'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B3E5E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCartControls(CartProvider cart, CartItem cartItem) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6B3E5E)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Color(0xFF6B3E5E)),
                  onPressed: () => cart.decreaseItem(widget.name, selectedUnit ?? widget.baseUnit),
                ),
                Text(
                  '${cartItem.quantity} ${cartItem.selectedUnit} in cart',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B3E5E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF6B3E5E)),
                  onPressed: () => cart.increaseItem(widget.name, selectedUnit ?? widget.baseUnit),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
