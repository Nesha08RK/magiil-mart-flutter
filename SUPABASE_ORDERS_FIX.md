# 🔧 Supabase Orders Table Fix

## Issue
Error: `Could not find the 'user_email' column of 'orders' in the schema cache`

## Solution

Your orders table is **missing** the `user_email` column that the checkout screen is trying to insert.

### Fix for Supabase

Go to **Supabase Console** → **SQL Editor** and run this:

```sql
-- Add user_email column to orders table if it doesn't exist
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS user_email TEXT NOT NULL DEFAULT 'unknown@email.com';

-- Create index on user_email for faster lookups
CREATE INDEX IF NOT EXISTS idx_orders_user_email ON orders(user_email);
```

### Or Add Column via UI

1. Go to **Supabase Console**
2. Click **Database** → **Tables** → **orders**
3. Click **+ Add Column**
4. Set:
   - **Column name:** `user_email`
   - **Type:** `text`
   - **Default value:** `'unknown@email.com'`
   - **Is nullable:** ✓ No (required)

---

## Complete Orders Table Schema

Your `orders` table should have these columns:

```
id              | uuid          | Primary Key
user_id         | uuid          | Foreign Key → auth.users(id)
user_email      | text          | ← ADD THIS
total_amount    | numeric       | 
status          | text          | Default: 'Placed'
items           | jsonb         | Order items array
created_at      | timestamp     | Default: now()
updated_at      | timestamp     | Default: now()
```

### Expected Orders Table Structure (SQL)

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,
  total_amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'Placed',
  items JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_user_email ON orders(user_email);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
```

---

## RLS Policies (Row Level Security)

After adding the column, ensure you have these RLS policies:

### 1. Users can view their own orders
```sql
CREATE POLICY "Users can view their own orders"
ON orders FOR SELECT
USING (auth.uid() = user_id);
```

### 2. Admins can view all orders
```sql
CREATE POLICY "Admins can view all orders"
ON orders FOR SELECT
USING (auth.jwt() ->> 'email' = 'admin@magiilmart.com');
```

### 3. Users can create orders
```sql
CREATE POLICY "Users can create orders"
ON orders FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

### 4. Admins can update orders
```sql
CREATE POLICY "Admins can update order status"
ON orders FOR UPDATE
USING (auth.jwt() ->> 'email' = 'admin@magiilmart.com');
```

---

## Testing

After adding the column:

1. **Restart Flutter app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test checkout:**
   - Login as customer
   - Add products to cart
   - Click checkout
   - Order should now place successfully ✅

3. **Check admin panel:**
   - Login as admin@magiilmart.com
   - Go to Orders
   - See newly placed orders with customer email ✅

---

## What Changed in Code

**Fixed:** AdminService now uses `fromMap()` instead of undefined `fromJson()`

- File: `lib/services/admin_service.dart`
- Changes: Updated 3 methods to use `AdminProduct.fromMap()` instead of `AdminProduct.fromJson()`
- Status: ✅ Error fixed

---

## Quick Checklist

- [ ] Add `user_email` column to orders table
- [ ] Set column type to `text`
- [ ] Set as required (not nullable)
- [ ] Save changes
- [ ] Restart Flutter app
- [ ] Test placing an order
- [ ] Verify order appears in admin panel with customer email

Once you add the column, orders will place successfully! ✅
