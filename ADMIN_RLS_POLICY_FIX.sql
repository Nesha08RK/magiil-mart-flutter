-- ✅ ADMIN RLS POLICY FIX FOR MAGIIL MART
-- Run this SQL in Supabase SQL Editor to allow admin@magiilmart.com to see all orders
-- This fixes the issue where orders are placed but not visible to admin

-- 1️⃣ ENSURE RLS IS ENABLED ON ORDERS TABLE
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

-- 2️⃣ ADD ADMIN POLICY - Allow admin@magiilmart.com to read ALL orders
DROP POLICY IF EXISTS "Admin can read all orders" ON public.orders;
CREATE POLICY "Admin can read all orders" ON public.orders
  FOR SELECT
  USING (
    auth.jwt() ->> 'email' = 'admin@magiilmart.com'
  );

-- 3️⃣ ADD ADMIN POLICY - Allow admin@magiilmart.com to UPDATE order status
DROP POLICY IF EXISTS "Admin can update all orders" ON public.orders;
CREATE POLICY "Admin can update all orders" ON public.orders
  FOR UPDATE
  USING (
    auth.jwt() ->> 'email' = 'admin@magiilmart.com'
  )
  WITH CHECK (
    auth.jwt() ->> 'email' = 'admin@magiilmart.com'
  );

-- 4️⃣ KEEP EXISTING CUSTOMER POLICIES (unchanged)
-- Users can read their own orders
DROP POLICY IF EXISTS "Users can read their own orders" ON public.orders;
CREATE POLICY "Users can read their own orders" ON public.orders
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create own orders
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders" ON public.orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders (for cancellation requests, etc)
DROP POLICY IF EXISTS "Users can update their own orders" ON public.orders;
CREATE POLICY "Users can update their own orders" ON public.orders
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ✅ VERIFY POLICIES
SELECT tablename, policyname, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY policyname;

-- ✅ VERIFY COLUMN STRUCTURE
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;
