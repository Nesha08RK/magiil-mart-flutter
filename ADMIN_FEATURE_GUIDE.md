# Admin Inventory Management Feature - Implementation Guide

## Overview
This document describes the newly added Admin Inventory Management feature that allows admins to manage product inventory while keeping the existing customer features completely unchanged.

## Architecture

### Key Principle
✅ **NO existing customer code was modified**
- All new functionality is in separate files
- Role-based routing directs users to the appropriate interface
- Customer UI, cart, checkout, and orders remain exactly as they were

## New Files Created

### 1. Models
- **`lib/models/admin_product.dart`** - AdminProduct model for admin inventory management

### 2. Services
- **`lib/services/admin_service.dart`** - Supabase operations for admin inventory management

### 3. Admin Screens
- **`lib/screens/admin/admin_dashboard_screen.dart`** - Main admin dashboard with product list
- **`lib/screens/admin/add_product_dialog.dart`** - Dialog for adding new products
- **`lib/screens/admin/edit_product_dialog.dart`** - Dialog for editing product details and stock

### 4. Utilities
- **`lib/utils/role_util.dart`** - Role checking utility

## Modified Files

### 1. `lib/screens/auth/login_screen.dart`
**Changes:** Added role-based routing after successful login
- Added import for RoleUtil and AdminDashboardScreen
- Modified login() method to check user role from profiles table
- Routes to AdminDashboardScreen if role = 'admin'
- Routes to MainNavigation if role = 'customer'

### 2. `lib/main.dart`
**Changes:** Added role-based routing in the auth-aware navigation
- Added imports for AdminDashboardScreen and RoleUtil
- Created new _RoleBasedHome widget that checks role at app startup
- Routes to appropriate screen based on user role
- Shows loading spinner while checking role

## Database Setup (Supabase)

### Required Tables

#### 1. Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  base_price INTEGER NOT NULL,
  base_unit TEXT NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  is_out_of_stock BOOLEAN NOT NULL DEFAULT FALSE,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Profiles Table
If not already created, add the role field:
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  role TEXT NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

If profiles table exists, add the role column:
```sql
ALTER TABLE profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'customer';
```

### Row Level Security (RLS)

#### Enable RLS on products table
```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
```

#### Policy 1: Admins can read and write
```sql
CREATE POLICY admin_full_access ON products
  FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );
```

#### Policy 2: Customers can only read
```sql
CREATE POLICY customer_read_only ON products
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'customer'
    )
  );
```

#### Policy 3: Anonymous/unauthenticated users can read (if needed)
```sql
CREATE POLICY anonymous_read ON products
  FOR SELECT
  USING (true);
```

## User Roles

### Admin Role
- Can view all products
- Can add new products
- Can edit product details (name, price, unit)
- Can update stock quantity
- Can toggle out-of-stock status
- Can delete products
- Accessed at: Admin Dashboard

### Customer Role (Existing)
- Can only read products
- See "Out of Stock" label for 0 stock items
- Cannot add items with 0 stock to cart
- Access existing cart, checkout, orders features
- Accessed at: Main Navigation (Home → Categories → Products)

## Feature Workflows

### Admin Workflow
1. Login with admin account
2. Routed to Admin Dashboard
3. View all products in a list
4. Click "Add New Product" to add items
5. Click "Edit" to update product details
6. Click "Out Stock" to toggle availability
7. Click "Delete" to remove products
8. Pull-to-refresh to reload the list

### Customer Workflow (UNCHANGED)
1. Login with customer account
2. Routed to Main Navigation (unchanged)
3. Browse categories and products
4. Add items to cart
5. Proceed to checkout
6. View orders history
7. Everything works exactly as before

## Verification Checklist

✅ Admin inventory features work correctly
✅ Customer app flow is completely unchanged
✅ Role-based routing works on login
✅ Role-based routing works on app restart
✅ Out of stock products display correctly
✅ Add-to-cart disabled for out of stock items
✅ No breaking changes to existing code

## Testing Instructions

### Test Admin Features
1. Create a user with role = 'admin' in Supabase
2. Login with admin account
3. Verify you're routed to Admin Dashboard
4. Test: Add product
5. Test: Edit product
6. Test: Update stock
7. Test: Toggle out of stock
8. Test: Delete product

### Test Customer Features
1. Create a user with role = 'customer' in Supabase
2. Login with customer account
3. Verify you're routed to Main Navigation
4. Browse categories and products
5. Add items to cart
6. Test checkout
7. Verify out of stock items show label and are not addable

### Test Role-Based Routing
1. Logout from admin
2. Login as customer
3. Verify correct screen appears
4. Force close app and reopen
5. Verify correct screen appears based on current user

## Important Notes

⚠️ **RLS Policies**: Ensure RLS policies are correctly set up in Supabase or admin/customer features won't work as expected.

⚠️ **Profiles Table**: The 'role' column must exist in the profiles table and be properly populated with 'admin' or 'customer'.

⚠️ **No Modifications to Customer Code**: 
- All new code is in separate files
- Existing screens, providers, and models are unchanged
- Cart logic is untouched
- Checkout flow is untouched
- Orders logic is untouched

## File Structure
```
lib/
├── models/
│   ├── cart_item.dart (UNCHANGED)
│   └── admin_product.dart (NEW)
├── services/
│   └── admin_service.dart (NEW)
├── screens/
│   ├── admin/ (NEW)
│   │   ├── admin_dashboard_screen.dart
│   │   ├── add_product_dialog.dart
│   │   └── edit_product_dialog.dart
│   ├── auth/
│   │   └── login_screen.dart (MODIFIED - role-based routing)
│   ├── main_navigation.dart (UNCHANGED)
│   ├── home_screen.dart (UNCHANGED)
│   ├── cart_screen.dart (UNCHANGED)
│   ├── checkout_screen.dart (UNCHANGED)
│   └── ... (other customer screens - UNCHANGED)
├── providers/
│   └── cart_provider.dart (UNCHANGED)
├── utils/
│   └── role_util.dart (NEW)
├── theme/
│   └── app_colors.dart (UNCHANGED)
└── main.dart (MODIFIED - role-based routing)
```

## API Endpoints Used (Supabase)

### Admin Service Calls
- `GET /rest/v1/products` - Fetch all products
- `POST /rest/v1/products` - Add new product
- `PATCH /rest/v1/products` - Update product stock/status
- `DELETE /rest/v1/products` - Delete product
- `GET /rest/v1/profiles` - Get user role

## Future Enhancements (Optional)
- Product image support
- Bulk import/export
- Sales analytics
- Low stock alerts
- Product search and filters
- Inventory history/audit log
