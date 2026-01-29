# 📚 API Reference & Code Examples

## Service Classes

### AdminOrdersService

**Location:** `lib/services/admin_orders_service.dart`

#### fetchAllOrders()
```dart
Future<List<AdminOrder>> fetchAllOrders()

// Usage:
final service = AdminOrdersService();
final orders = await service.fetchAllOrders();

// Returns:
// List of AdminOrder objects sorted by newest first
// Each contains: id, userId, userEmail, totalAmount, status, items, dates
```

#### fetchOrderById(String orderId)
```dart
Future<AdminOrder?> fetchOrderById(String orderId)

// Usage:
final order = await service.fetchOrderById('order-uuid-123');

// Returns:
// Single AdminOrder or null if not found
```

#### updateOrderStatus(String orderId, String newStatus)
```dart
Future<void> updateOrderStatus(String orderId, String newStatus)

// Usage:
await service.updateOrderStatus('order-123', 'Packed');

// Status options: "Placed", "Packed", "Out for Delivery", "Delivered"
// Updates: status field + updated_at timestamp
```

#### getOrderStats()
```dart
Future<Map<String, dynamic>> getOrderStats()

// Usage:
final stats = await service.getOrderStats();

// Returns:
// {
//   'total_orders': 45,
//   'total_revenue': 15000.50,
//   'today_orders': 8,
//   'today_revenue': 2300.00,
//   'order_status_counts': {
//     'Placed': 12,
//     'Packed': 8,
//     'Out for Delivery': 15,
//     'Delivered': 10,
//   }
// }
```

---

### AdminProductService

**Location:** `lib/services/admin_product_service.dart`

#### fetchAllProducts()
```dart
Future<List<AdminProduct>> fetchAllProducts()

// Usage:
final service = AdminProductService();
final products = await service.fetchAllProducts();

// Returns:
// List of all AdminProduct objects
// Sorted by id descending (newest first)
```

#### getProductCounts()
```dart
Future<Map<String, int>> getProductCounts()

// Usage:
final counts = await service.getProductCounts();

// Returns:
// {
//   'total': 45,
//   'in_stock': 42,
//   'out_of_stock': 3
// }
```

#### updateProduct(AdminProduct product)
```dart
Future<void> updateProduct(AdminProduct product)

// Usage:
final updatedProduct = product.copyWith(
  stock: 25,
  isOutOfStock: false,
);
await service.updateProduct(updatedProduct);

// Requirements:
// - product.id must not be null
// - Updates all fields (name, price, stock, etc.)
```

#### deleteProduct(int id)
```dart
Future<void> deleteProduct(int id)

// Usage:
await service.deleteProduct(123);

// Removes product from database permanently
```

#### upsertProduct(AdminProduct product)
```dart
Future<void> upsertProduct(AdminProduct product)

// Usage:
await service.upsertProduct(newProduct);

// Behavior:
// - If product with same name + category exists: UPDATE
// - Otherwise: INSERT new product
```

---

### CustomerProductService

**Location:** `lib/services/customer_product_service.dart`

#### fetchProductsByCategory(String category)
```dart
Future<List<CustomerProduct>> fetchProductsByCategory(String category)

// Usage:
final products = await CustomerProductService()
    .fetchProductsByCategory('Vegetables');

// Returns:
// List of products in category, sorted by name
// Includes out-of-stock items
```

#### fetchAllAvailableProducts()
```dart
Future<List<CustomerProduct>> fetchAllAvailableProducts()

// Usage:
final available = await service.fetchAllAvailableProducts();

// Returns:
// List of products where is_out_of_stock = false
```

#### fetchProductByName(String name)
```dart
Future<CustomerProduct?> fetchProductByName(String name)

// Usage:
final product = await service.fetchProductByName('Tomato');

// Returns:
// Single product or null
```

---

## Model Classes

### AdminOrder

**Location:** `lib/models/admin_order.dart`

```dart
class AdminOrder {
  final String id;                    // UUID
  final String userId;                // User UUID
  final String userEmail;             // Customer email
  final double totalAmount;           // Order total in ₹
  final String status;                // Placed/Packed/Out for Delivery/Delivered
  final List<OrderItem> items;        // Order items
  final DateTime createdAt;           // Order creation time
  final DateTime? updatedAt;          // Last update time
  
  // Factory constructor from Supabase
  factory AdminOrder.fromMap(Map<String, dynamic> map)
  
  // Convert to Supabase format
  Map<String, dynamic> toMap()
  
  // Get formatted date string
  String getFormattedDate()
  
  // Create copy with modifications
  AdminOrder copyWith({...})
}

class OrderItem {
  final String name;
  final double basePrice;
  final String baseUnit;              // kg, L, piece, etc.
  final String selectedUnit;          // 500g, 1L, etc.
  final double unitPrice;
  final int quantity;
  final double totalPrice;
}
```

### AdminProduct

**Location:** `lib/models/admin_product.dart`

```dart
class AdminProduct {
  final int? id;
  final String name;
  final String category;              // Vegetables, Fruits, etc.
  final double basePrice;             // Price for baseUnit
  final String baseUnit;              // kg, L, piece, g, ml
  final int stock;                    // Quantity available
  final String? imageUrl;
  final bool isOutOfStock;
  
  // Factory from Supabase
  factory AdminProduct.fromMap(Map<String, dynamic> map)
  
  // Convert to Supabase
  Map<String, dynamic> toMap()
  
  // Create copy with modifications
  AdminProduct copyWith({...})
}
```

### CustomerProduct

**Location:** `lib/services/customer_product_service.dart`

```dart
class CustomerProduct {
  final int? id;
  final String name;
  final String category;
  final double basePrice;
  final String baseUnit;
  final int stock;
  final String? imageUrl;
  final bool isOutOfStock;
  
  // Factory from Supabase
  factory CustomerProduct.fromMap(Map<String, dynamic> map)
}
```

---

## UI Components

### Admin Dashboard Screen

**Location:** `lib/screens/admin/admin_dashboard_screen.dart`

```dart
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);
}

// Features:
// - Product statistics card
// - Product list with actions
// - Drawer menu navigation
// - Import XLSX button
// - Pull-to-refresh
```

**Drawer Menu Actions:**
```
ADMIN PANEL
├─ Products (refresh products)
├─ Orders (navigate to AdminOrdersScreen)
├─ Analytics (navigate to AdminAnalyticsScreen)
├─ ─────────────────
└─ Logout (sign out + redirect to login)
```

### Admin Orders Screen

**Location:** `lib/screens/admin/admin_orders_screen.dart`

```dart
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);
}

// Features:
// - Order list with status badges
// - Tap to view order details
// - Menu to update status
// - Total orders counter
// - Pull-to-refresh
// - Color-coded status badges
```

**Status Update Flow:**
```
Order Tap Menu
├─ If status == "Placed" → Show "Mark as Packed"
├─ If status == "Packed" → Show "Mark Out for Delivery"
├─ If status == "Out for Delivery" → Show "Mark Delivered"
└─ If status == "Delivered" → No options
```

### Admin Analytics Screen

**Location:** `lib/screens/admin/admin_analytics_screen.dart`

```dart
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);
}

// Sections:
// 1. Product Inventory (3 cards: total, in stock, out of stock)
// 2. Order Analytics (4 cards: total orders, today orders, revenue metrics)
// 3. Order Status Breakdown (visual list with counts)
```

---

## Stock Reduction Logic

**Location:** `lib/screens/checkout_screen.dart`

### Code Flow:

```dart
Future<void> _placeOrder() async {
  try {
    // 1. Get authenticated user
    final user = supabase.auth.currentUser;
    
    // 2. Create order in Supabase
    await supabase.from('orders').insert({
      'user_id': user.id,
      'user_email': user.email,
      'total_amount': cart.totalAmount,
      'status': 'Placed',
      'items': cart.items.map((item) => item.toMap()).toList(),
    });
    
    // 3. Reduce stock for each item
    await _reduceProductStock(cart.items);
    
    // 4. Clear cart and show success
    cart.clearCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed successfully'))
    );
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e'))
    );
  }
}

Future<void> _reduceProductStock(List<CartItem> cartItems) async {
  final supabase = Supabase.instance.client;
  
  for (final item in cartItems) {
    // 1. Fetch current product stock
    final data = await supabase
        .from('products')
        .select('id, stock, is_out_of_stock')
        .eq('name', item.name)
        .limit(1) as List<dynamic>;
    
    if (data.isEmpty) continue;
    
    final productId = data.first['id'];
    final currentStock = data.first['stock'] as int;
    
    // 2. Calculate new stock
    final newStock = (currentStock - item.quantity).clamp(0, 999999);
    final isOutOfStock = newStock <= 0;
    
    // 3. Update product
    await supabase
        .from('products')
        .update({
          'stock': newStock,
          'is_out_of_stock': isOutOfStock,
        })
        .eq('id', productId);
  }
}
```

---

## Product List (Customer View)

**Location:** `lib/screens/product_list_screen.dart`

### Fetching Products:

```dart
class _ProductListScreenState extends State<ProductListScreen> {
  late final CustomerProductService _service;
  
  Future<void> _loadProducts() async {
    try {
      final products = await _service
          .fetchProductsByCategory(widget.category);
      
      setState(() {
        _products = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e'))
      );
    }
  }
}
```

### Out-of-Stock Display:

```dart
if (widget.isOutOfStock) {
  // Disabled button
  ElevatedButton(
    onPressed: null,
    child: Text('Out of Stock'),
  );
} else {
  // Enabled add button
  ElevatedButton(
    onPressed: () {
      cart.addItem(
        name: widget.name,
        basePrice: widget.basePrice,
        baseUnit: widget.baseUnit,
        selectedUnit: selectedUnit,
        unitConversion: unitConversion,
      );
    },
    child: Text('Add'),
  );
}

// Overlay for visual indication
if (widget.isOutOfStock)
  Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Text(
          'OUT OF STOCK',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ),
  ),
```

---

## Supabase Queries

### Direct Supabase Calls:

```dart
final supabase = Supabase.instance.client;

// Get all products
final products = await supabase
    .from('products')
    .select()
    .order('id', ascending: false) as List<dynamic>;

// Get orders for admin
final orders = await supabase
    .from('orders')
    .select()
    .order('created_at', ascending: false) as List<dynamic>;

// Update product
await supabase
    .from('products')
    .update({'stock': 25, 'is_out_of_stock': false})
    .eq('id', productId);

// Create order
await supabase
    .from('orders')
    .insert({
      'user_id': userId,
      'user_email': email,
      'total_amount': 500.50,
      'status': 'Placed',
      'items': itemsJson,
    });

// Update order status
await supabase
    .from('orders')
    .update({
      'status': 'Packed',
      'updated_at': DateTime.now().toIso8601String(),
    })
    .eq('id', orderId);
```

---

## Error Handling Patterns

```dart
// Pattern 1: Try-Catch with SnackBar
try {
  await service.someMethod();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}

// Pattern 2: Future error handling
service.someMethod().then((result) {
  // Handle success
}).catchError((error) {
  // Handle error
  print('Error: $error');
});

// Pattern 3: Async-await with mounted check
try {
  final result = await service.someMethod();
  if (!mounted) return;
  // Use result
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

---

## Testing Examples

```dart
// Test order creation
test('Order creation', () async {
  final service = AdminOrdersService();
  
  // Mock data (when using real Supabase)
  final order = await service.fetchAllOrders();
  expect(order, isNotEmpty);
});

// Test stock reduction
test('Stock reduction on order', () async {
  // Place order with item quantity 5
  // Check product stock reduced by 5
  
  final products = await AdminProductService().fetchAllProducts();
  final product = products.firstWhere((p) => p.name == 'Tomato');
  
  expect(product.stock, equals(previousStock - 5));
  expect(product.isOutOfStock, equals(product.stock <= 0));
});

// Test out-of-stock filtering
test('Out of stock products disabled', () async {
  final products = await CustomerProductService()
      .fetchProductsByCategory('Vegetables');
  
  final outOfStock = products.where((p) => p.isOutOfStock).toList();
  
  // Verify UI disables these
  expect(outOfStock, isNotEmpty);
});
```

---

## Summary

### Key Methods to Know:

```
Admin Operations:
├─ AdminOrdersService.fetchAllOrders()
├─ AdminOrdersService.updateOrderStatus()
├─ AdminProductService.fetchAllProducts()
├─ AdminProductService.updateProduct()
└─ AdminProductService.getProductCounts()

Customer Operations:
├─ CustomerProductService.fetchProductsByCategory()
└─ Stock reduction in checkout

UI Screens:
├─ AdminDashboardScreen
├─ AdminOrdersScreen
└─ AdminAnalyticsScreen
```

All documented and ready to use! ✅
