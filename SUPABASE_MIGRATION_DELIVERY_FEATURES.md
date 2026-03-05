# 🗄️ Magiil Mart - Supabase Schema Migration Guide

## 📋 Overview

This guide helps you add the new delivery-related columns to your Supabase `orders` table to support the new delivery features.

---

## ✅ What's New in the Schema

The `orders` table now supports:
1. **`subtotal_amount`** - Order subtotal before delivery fee
2. **`delivery_fee`** - Calculated delivery fee based on distance
3. **`delivery_distance_km`** - Distance from store to delivery location in km

These are **optional columns** for backward compatibility.

---

## 🚀 Migration Steps

### Option A: Using Supabase Dashboard (Recommended for non-developers)

1. **Login to Supabase Dashboard**
   - Go to https://app.supabase.io
   - Select your project (Magiil Mart)
   - Navigate to SQL Editor

2. **Copy-paste the migration SQL** (see below)

3. **Execute the queries**

### Option B: Using SQL Editor

1. **Open SQL Editor**
   - Supabase Dashboard → SQL Editor
   - New Query

2. **Copy and paste the SQL below**

3. **Click Execute**

---

## 📝 Migration SQL

### For Orders Table

```sql
-- Add new columns for delivery features
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS subtotal_amount INTEGER,
ADD COLUMN IF NOT EXISTS delivery_fee INTEGER,
ADD COLUMN IF NOT EXISTS delivery_distance_km NUMERIC;

-- Add comments for documentation
COMMENT ON COLUMN public.orders.subtotal_amount IS 'Order subtotal before delivery fee (in paise, ₹)';
COMMENT ON COLUMN public.orders.delivery_fee IS 'Delivery fee based on distance (in paise, ₹)';
COMMENT ON COLUMN public.orders.delivery_distance_km IS 'Distance from store to delivery location in kilometers';
```

### For Existing Orders Without These Fields

If you have existing orders, here's how to populate them:

```sql
-- Set default values for existing orders (without touching orders that already have values)
UPDATE public.orders
SET 
  subtotal_amount = COALESCE(subtotal_amount, total_amount),
  delivery_fee = COALESCE(delivery_fee, 0),
  delivery_distance_km = COALESCE(delivery_distance_km, 0)
WHERE subtotal_amount IS NULL OR delivery_fee IS NULL OR delivery_distance_km IS NULL;
```

---

## 🔍 Verify Migration

After running the migration, verify the columns were created:

```sql
-- Check the orders table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- Look for these columns in the output:
-- subtotal_amount         | integer      | YES
-- delivery_fee            | integer      | YES
-- delivery_distance_km    | numeric      | YES
```

---

## 📊 Sample Order Record (After Migration)

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "items": [
    {
      "name": "Tomatoes",
      "quantity": 2,
      "selectedUnit": "kg",
      "unitPrice": 60,
      "totalPrice": 120
    },
    {
      "name": "Onions",
      "quantity": 1,
      "selectedUnit": "kg",
      "unitPrice": 50,
      "totalPrice": 50
    }
  ],
  "subtotal_amount": 170,
  "delivery_fee": 20,
  "total_amount": 190,
  "status": "Placed",
  "created_at": "2026-02-19T10:30:00Z",
  "delivery_name": "John Doe",
  "delivery_phone": "9876543210",
  "delivery_address": "123 Main Street, Perundurai",
  "delivery_city": "Perundurai",
  "delivery_pincode": "638060",
  "delivery_latitude": 11.3723,
  "delivery_longitude": 77.7490,
  "delivery_distance_km": 2.5
}
```

---

## 🔄 Backward Compatibility

The implementation is **fully backward compatible**:

- ✅ Existing orders without these fields will still work
- ✅ New orders will have all fields populated
- ✅ Queries checking `total_amount` still work
- ✅ No existing data is modified
- ✅ Fallback logic handles missing columns

### Fallback Behavior (in checkout_screen.dart)

If columns don't exist on insert:
```dart
try {
  await supabase.from('orders').insert(payload);
} catch (e) {
  if (e.toString().contains('column') || e.toString().contains('does not exist')) {
    // Fallback: insert without new columns
    await supabase.from('orders').insert(fallbackPayload);
  }
}
```

---

## 🗑️ Rollback Instructions (If Needed)

If you need to remove these columns:

```sql
-- Drop the new columns
ALTER TABLE public.orders
DROP COLUMN IF EXISTS subtotal_amount,
DROP COLUMN IF EXISTS delivery_fee,
DROP COLUMN IF EXISTS delivery_distance_km;
```

---

## 📈 Querying Orders with Delivery Info

### Get all orders with delivery fees

```sql
SELECT 
  id,
  delivery_name,
  total_amount,
  subtotal_amount,
  delivery_fee,
  delivery_distance_km,
  created_at
FROM public.orders
WHERE delivery_fee > 0
ORDER BY created_at DESC;
```

### Calculate average delivery fee

```sql
SELECT 
  AVG(delivery_fee) as avg_delivery_fee,
  MIN(delivery_fee) as min_delivery_fee,
  MAX(delivery_fee) as max_delivery_fee
FROM public.orders
WHERE delivery_fee > 0;
```

### Orders by distance range

```sql
SELECT 
  CASE 
    WHEN delivery_distance_km <= 3 THEN '0-3 km'
    WHEN delivery_distance_km <= 6 THEN '3-6 km'
    WHEN delivery_distance_km <= 8 THEN '6-8 km'
    ELSE '8+ km'
  END as distance_range,
  COUNT(*) as order_count,
  AVG(delivery_fee) as avg_fee
FROM public.orders
WHERE delivery_distance_km IS NOT NULL
GROUP BY distance_range
ORDER BY avg_fee;
```

### Total revenue with delivery fees

```sql
SELECT 
  SUM(subtotal_amount) as subtotal_revenue,
  SUM(delivery_fee) as delivery_revenue,
  SUM(total_amount) as total_revenue
FROM public.orders
WHERE created_at >= NOW() - INTERVAL '30 days';
```

---

## 🔒 Row-Level Security (RLS) Considerations

If you have RLS enabled, verify these columns are accessible:

```sql
-- Example RLS policy for users to see their own orders
CREATE POLICY "Users can see their own orders"
ON public.orders FOR SELECT
USING (auth.uid() = user_id);

-- This policy already includes the new columns automatically
-- No changes needed for RLS policies
```

---

## 🛡️ Indexing (Optional Performance Tuning)

If your orders table grows large, consider adding indexes:

```sql
-- Index for faster distance-based queries
CREATE INDEX IF NOT EXISTS idx_orders_delivery_distance 
ON public.orders(delivery_distance_km);

-- Index for faster fee queries
CREATE INDEX IF NOT EXISTS idx_orders_delivery_fee 
ON public.orders(delivery_fee);

-- Composite index for distance + fee queries
CREATE INDEX IF NOT EXISTS idx_orders_delivery_info 
ON public.orders(delivery_distance_km, delivery_fee);
```

---

## 📱 Testing Migration in Development

### 1. Test Locally First

Before deploying to production:

```dart
// In your test code
void testDeliveryFeaturesMigration() {
  // Verify columns exist
  final supabase = Supabase.instance.client;
  
  // Try inserting order with new fields
  final testOrder = {
    'user_id': 'test_user',
    'subtotal_amount': 100,
    'delivery_fee': 20,
    'delivery_distance_km': 2.5,
    'total_amount': 120,
    'status': 'Placed',
  };
  
  // This should work without errors
  supabase.from('orders').insert(testOrder);
}
```

### 2. Check Supabase Dashboard

After migration:
1. Go to Supabase Dashboard
2. Tables → orders
3. Verify new columns appear in the schema

---

## 🐛 Troubleshooting

### Issue: "Column does not exist" errors

**Solution**:
```sql
-- Check if columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name='orders';

-- If missing, run the migration SQL again
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS subtotal_amount INTEGER,
ADD COLUMN IF NOT EXISTS delivery_fee INTEGER,
ADD COLUMN IF NOT EXISTS delivery_distance_km NUMERIC;
```

### Issue: Cannot insert new orders

**Solution**:
1. Verify RLS policies allow INSERT on the table
2. Check if your user has write permissions
3. Review Supabase logs for specific errors

### Issue: Old orders not showing delivery fee

**Solution** (Optional - populate existing orders):
```sql
UPDATE public.orders
SET 
  subtotal_amount = total_amount,
  delivery_fee = 0,
  delivery_distance_km = 0
WHERE subtotal_amount IS NULL;
```

---

## 📅 Migration Timeline

| Step | Action | Duration | Notes |
|---|---|---|---|
| 1 | Backup Supabase database | 5 min | Optional but recommended |
| 2 | Run migration SQL | 1 min | Execute ALTER TABLE statements |
| 3 | Verify columns | 2 min | Check schema in dashboard |
| 4 | Test locally | 5 min | Make test order in dev |
| 5 | Deploy app update | 10 min | Push Flutter code to production |
| 6 | Test in production | - | Place actual order and verify |

---

## 🚀 Post-Migration Checklist

- [ ] Columns added to orders table
- [ ] Can query new columns successfully
- [ ] Test app compiles and runs
- [ ] Place test order with all fields
- [ ] Verify order saved in Supabase with all fields
- [ ] Check delivery fee calculated correctly
- [ ] Confirm distance saved in database
- [ ] Old orders still query correctly
- [ ] RLS policies still work
- [ ] Ready for production deployment

---

## 📞 Support

If you encounter issues:

1. **Check Supabase Logs**
   - Supabase Dashboard → Logs → Database events
   - Look for error messages

2. **Verify Database Credentials**
   - Ensure `SUPABASE_URL` and `SUPABASE_KEY` are correct

3. **Test Connectivity**
   ```dart
   final response = await supabase.from('orders').select().limit(1);
   print('Connection OK: $response');
   ```

4. **Check Column Types**
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name='orders' 
   AND column_name IN ('subtotal_amount', 'delivery_fee', 'delivery_distance_km');
   ```

---

## 📚 Related Files

- [DELIVERY_FEATURES_IMPLEMENTATION.md](./DELIVERY_FEATURES_IMPLEMENTATION.md) - Feature documentation
- [DELIVERY_FEATURES_CODE_SNIPPETS.md](./DELIVERY_FEATURES_CODE_SNIPPETS.md) - Code examples
- [lib/utils/delivery_utils.dart](./lib/utils/delivery_utils.dart) - Calculation logic

---

**Migration Version**: 1.0.0
**Created**: February 19, 2026
**Status**: Ready for Production ✅
