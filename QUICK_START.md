# Quick Start Guide - Admin Feature

## 📋 Overview
The Admin Inventory Management feature has been successfully integrated into your Flutter + Supabase grocery app without modifying any existing customer functionality.

## 🚀 Quick Start (5 Minutes)

### 1. Database Setup (2 minutes)
```bash
# Copy all SQL from SUPABASE_SETUP.md into Supabase SQL Editor
# Step 1: Create products table
# Step 2: Ensure profiles has role column
# Step 3-5: Set up RLS policies
# Step 6: Create auth trigger
```

### 2. Create Test Users
```
Admin User:
- Email: admin@test.com
- Password: Test@123
- Role: admin

Customer User:
- Email: customer@test.com
- Password: Test@123
- Role: customer
```

### 3. Run the App
```bash
flutter pub get
flutter run
```

### 4. Test Both Flows
- Login as admin → See Admin Dashboard
- Login as customer → See Main Navigation

## 📁 File Structure

```
lib/
├── models/
│   ├── cart_item.dart              ✅ UNCHANGED
│   └── admin_product.dart          ✨ NEW
│
├── services/
│   └── admin_service.dart          ✨ NEW
│
├── screens/
│   ├── admin/                       📂 NEW FOLDER
│   │   ├── admin_dashboard_screen.dart
│   │   ├── add_product_dialog.dart
│   │   └── edit_product_dialog.dart
│   │
│   ├── auth/
│   │   ├── login_screen.dart       🔧 MODIFIED (role routing)
│   │   └── signup_screen.dart      ✅ UNCHANGED
│   │
│   ├── main_navigation.dart        ✅ UNCHANGED
│   ├── home_screen.dart            ✅ UNCHANGED
│   ├── product_list_screen.dart    ✅ UNCHANGED
│   ├── cart_screen.dart            ✅ UNCHANGED
│   ├── checkout_screen.dart        ✅ UNCHANGED
│   ├── orders_screen.dart          ✅ UNCHANGED
│   ├── order_details_screen.dart   ✅ UNCHANGED
│   ├── profile_screen.dart         ✅ UNCHANGED
│   └── splash_screen.dart          ✅ UNCHANGED
│
├── providers/
│   └── cart_provider.dart          ✅ UNCHANGED
│
├── utils/
│   └── role_util.dart              ✨ NEW
│
├── theme/
│   └── app_colors.dart             ✅ UNCHANGED
│
└── main.dart                        🔧 MODIFIED (role routing)
```

## 🔄 User Flow Diagram

```
┌─────────────────┐
│  App Startup    │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Logged  │
    │ In?     │
    └─┬──────┬┘
      │      │
  No  │      │ Yes
      │      │
      ▼      ┌──────────────────────┐
   Login     │  Check User Role     │
   Screen    │  (profiles table)    │
             └──┬───────────────────┘
                │
        ┌───────┴────────┐
        │                │
    role='admin'     role='customer'
        │                │
        ▼                ▼
   Admin Dashboard   Main Navigation
   (Inventory)       (Shopping)
```

## 🛠️ Admin Dashboard Features

| Feature | Capability | Database Action |
|---------|-----------|-----------------|
| View Products | List all products with stock | SELECT |
| Add Product | Create new product | INSERT |
| Edit Product | Update name, price, unit | UPDATE |
| Update Stock | Modify stock quantity | UPDATE |
| Toggle Status | Mark as out-of-stock | UPDATE |
| Delete Product | Remove product | DELETE |
| Logout | Return to login | Sign out |

## 🛍️ Customer Features (UNCHANGED)

| Feature | Capability | Database Action |
|---------|-----------|-----------------|
| Browse | View products by category | SELECT |
| Add to Cart | Add items (if stock > 0) | In-memory |
| Checkout | Place order | INSERT into orders |
| View Orders | See past orders | SELECT |
| Profile | View user info | SELECT |

## 🔐 Security Model

### Role-Based Access Control (RBAC)
```
Admin Role:
├── Read: All products ✅
├── Create: New products ✅
├── Update: Product details & stock ✅
└── Delete: Products ✅

Customer Role:
├── Read: Products with stock > 0 ✅
├── Create: New products ❌
├── Update: Product details ❌
└── Delete: Products ❌
```

### Row Level Security (RLS)
- Enforced at database level
- Policies prevent unauthorized access
- RLS is transparent to app code

## 📊 Database Schema

### Products Table
```
id (UUID)
name (TEXT)
base_price (INTEGER)           // in paise (e.g., 50 = ₹0.50)
base_unit (TEXT)               // kg, L, piece, g, ml
stock (INTEGER)                // current quantity
is_out_of_stock (BOOLEAN)      // true if stock = 0
category (TEXT, nullable)      // Vegetables, Fruits, etc.
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

### Profiles Table
```
id (UUID)                    // references auth.users(id)
role (TEXT)                  // 'admin' or 'customer'
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

## 🚦 Installation Checklist

- [ ] Copy Flutter code (all new files + modified files)
- [ ] Run `flutter pub get`
- [ ] Create products table in Supabase
- [ ] Add role column to profiles table
- [ ] Create RLS policies
- [ ] Create auth trigger
- [ ] Create test admin user
- [ ] Create test customer user
- [ ] Test app build: `flutter build apk`
- [ ] Test admin login → Admin Dashboard appears
- [ ] Test customer login → Main Navigation appears
- [ ] Test admin features (add, edit, delete products)
- [ ] Test customer features (browse, add to cart)
- [ ] Test out-of-stock behavior
- [ ] Deploy to production

## 🧪 Manual Testing

### Admin Test (5 minutes)
1. Login as admin
2. Click "Add New Product"
3. Enter: Name="Tomato", Price=50, Unit="kg", Stock=100
4. Click "Add Product"
5. Verify product appears in list
6. Click "Edit" → Change price to 60 → Update
7. Click "Out Stock" → Verify status changes
8. Click "Delete" → Confirm

### Customer Test (5 minutes)
1. Login as customer
2. Navigate to category (e.g., Vegetables)
3. Find a product with stock
4. Try to add to cart → Should work
5. Find product with 0 stock
6. Try to add to cart → Should show "Out of Stock" label
7. Proceed to checkout
8. Place order
9. View in orders screen

### Logout & Re-login Test (2 minutes)
1. Logout from admin
2. Login as customer → Verify routed to Main Navigation
3. Logout from customer
4. Login as admin → Verify routed to Admin Dashboard

## ⚠️ Important Notes

1. **Profiles Table**: Must have `role` column. Admins created before adding this column need to be updated:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE id = '[ADMIN_USER_ID]';
   ```

2. **Case Sensitivity**: Role values are case-sensitive ('admin', 'customer')

3. **RLS Policies**: Must be enabled before testing. Verify with:
   ```sql
   SELECT tablename, policyname FROM pg_policies WHERE tablename = 'products';
   ```

4. **No App Code Modifications**: Existing customer code is completely untouched

5. **Database-First Approach**: Role-based access is enforced by Supabase, not app code

## 📞 Troubleshooting

| Issue | Solution |
|-------|----------|
| Admin routed to customer screen | Check role in profiles table is 'admin' |
| Customer can see admin features | Check RLS policies are enabled |
| Can't add products | Check RLS policy for INSERT on products table |
| App crashes on login | Check profiles table exists and has role column |
| Products not loading | Check products table exists with all columns |

## 📚 Documentation Files

- **ADMIN_FEATURE_GUIDE.md** - Detailed feature documentation
- **IMPLEMENTATION_SUMMARY.md** - What was changed and why
- **SUPABASE_SETUP.md** - Database setup instructions
- **This file** - Quick start guide

## 🎯 Next Steps

1. **Immediate**: Set up database using SUPABASE_SETUP.md
2. **Short-term**: Test both admin and customer flows
3. **Medium-term**: Deploy to production
4. **Long-term**: Collect user feedback and iterate

## 💡 Pro Tips

- Use Supabase dashboard to quickly check products table
- Use SQL queries to verify RLS policies are working
- Monitor Supabase logs for any permission errors
- Test with multiple browsers/devices for role consistency
- Use Supabase's real-time feature to sync inventory across devices

## ✨ What's Different

### Before
- All users went to Main Navigation after login
- No inventory management interface
- Stock management only possible through database

### After
- Users routed based on role
- Admins have full inventory management interface
- Customers have unchanged shopping experience
- All changes at database level with RLS

## 🎉 Done!

Your app now has:
✅ Admin inventory management
✅ Role-based access control
✅ Database-level security (RLS)
✅ Unchanged customer experience
✅ Simple form-based admin interface

Enjoy your enhanced grocery app! 🛒
