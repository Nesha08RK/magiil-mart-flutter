-- ✅ SUPABASE SCHEMA UPDATE FOR MAGIIL MART
-- Run these SQL commands in your Supabase SQL Editor

-- 1️⃣ ADD NEW COLUMNS TO ORDERS TABLE
-- ✅ Add customer_name, phone_number, delivery_address columns
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- 2️⃣ UPDATE RLS POLICIES (if needed)
-- 2️⃣ UPDATE RLS POLICIES (if needed)
-- Ensure row-level security is enabled for the `orders` table
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

-- Safe approach: drop any existing policies with these names and (re)create
-- This avoids failures when policy names differ or don't exist yet.
DROP POLICY IF EXISTS "Users can read their own orders" ON public.orders;
CREATE POLICY "Users can read their own orders" ON public.orders
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders" ON public.orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own orders" ON public.orders;
CREATE POLICY "Users can update their own orders" ON public.orders
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- (Optional) If you want customers to be able to delete their own orders, add:
-- DROP POLICY IF EXISTS "Users can delete their own orders" ON public.orders;
-- CREATE POLICY "Users can delete their own orders" ON public.orders
--   FOR DELETE
--   USING (auth.uid() = user_id);

-- 3️⃣ CREATE INDEX FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ✅ Verify columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- ✅ Example: View all orders with customer details
SELECT 
  id,
  customer_name,
  phone_number,
  delivery_address,
  total_amount,
  status,
  created_at
FROM orders
ORDER BY created_at DESC
LIMIT 20;
