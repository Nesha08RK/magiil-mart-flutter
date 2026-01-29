-- ============================================================
-- MAGIIL MART: Database Schema Update for Realtime Fixes
-- ============================================================
-- Execute these commands in Supabase SQL Editor
-- ============================================================

-- STEP 1: Check current column names
-- (Run this first to see what columns exist)
-- ============================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- ============================================================
-- STEP 2: RENAME columns if they exist as 'name', 'phone', 'address'
-- (Run only if Step 1 shows these column names)
-- ============================================================
-- These renames align Supabase schema with Dart code field names

ALTER TABLE orders RENAME COLUMN "name" TO customer_name;
ALTER TABLE orders RENAME COLUMN "phone" TO phone_number;
ALTER TABLE orders RENAME COLUMN "address" TO delivery_address;

-- ============================================================
-- STEP 3: VERIFY the new column names exist
-- (Run this to confirm the renames worked)
-- ============================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- ============================================================
-- STEP 4 (ALTERNATIVE): If columns don't exist, ADD them
-- (Run only if Step 1 shows columns don't exist)
-- ============================================================
-- Skip this if you ran Step 2 (RENAME)

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS delivery_address TEXT;

-- ============================================================
-- STEP 5: Verify orders table has realtime enabled
-- (Check this in Supabase dashboard)
-- ============================================================
-- Navigate to: Database → orders table → RLS & Realtime
-- Ensure "Realtime" toggle is ON

-- ============================================================
-- STEP 6: Ensure necessary columns exist for cancellation
-- ============================================================
-- These should already exist, but verify:

-- cancelled_at - timestamp of cancellation
-- status - order status (Placed, Packed, Out for Delivery, Delivered, Cancelled)

-- If missing, add them:
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP,
ALTER COLUMN status SET DEFAULT 'Placed';

-- ============================================================
-- DONE! 
-- ============================================================
-- Next: Deploy the Flutter app (flutter run)
-- Test: Cancel an order and verify stock is restored
-- ============================================================
