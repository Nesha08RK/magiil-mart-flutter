class CartItem {
  final String name;

  // Base price per base unit (ex: ₹100 per 1 kg)
  final int basePrice;

  // Base unit (kg, l, pcs)
  final String baseUnit;

  // Selected unit by user (500g, 250g, 1kg, etc.)
  final String selectedUnit;

  // Conversion factor (500g = 0.5, 250g = 0.25)
  final double unitConversion;

  int quantity;

  CartItem({
    required this.name,
    required this.basePrice,
    required this.baseUnit,
    required this.selectedUnit,
    required this.unitConversion,
    this.quantity = 1,
  });

  /// ✅ Price for ONE selected unit
  double get unitPrice => basePrice * unitConversion;

  /// ✅ Total price for this item
  double get totalPrice => unitPrice * quantity;

  /// ✅ Convert item to JSON (for Supabase orders table)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'base_price': basePrice,
      'base_unit': baseUnit,
      'selected_unit': selectedUnit,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}
