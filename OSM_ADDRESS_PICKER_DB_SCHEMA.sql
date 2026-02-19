-- ============================================================================
-- Supabase Schema Update for OSM Address Picker Integration
-- ============================================================================
-- This migration adds latitude and longitude columns to the orders table
-- to store delivery location coordinates from the map picker.
--
-- IMPORTANT: This is OPTIONAL. The app works without these columns.
-- If columns don't exist, the app gracefully falls back.
-- ============================================================================

-- Add delivery coordinates columns to orders table
-- These store the exact latitude and longitude selected from the map
ALTER TABLE orders ADD COLUMN delivery_latitude DECIMAL(10, 7) DEFAULT NULL;
ALTER TABLE orders ADD COLUMN delivery_longitude DECIMAL(10, 7) DEFAULT NULL;

-- Optional: Create index for faster geo-queries (if you plan to query by location)
CREATE INDEX idx_orders_delivery_coords 
  ON orders(delivery_latitude, delivery_longitude);

-- Optional: Add comment to explain the columns
COMMENT ON COLUMN orders.delivery_latitude IS 'Latitude of delivery location from map picker';
COMMENT ON COLUMN orders.delivery_longitude IS 'Longitude of delivery location from map picker';

-- ============================================================================
-- Verification Query - Run after migration to verify
-- ============================================================================
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'orders' 
-- AND column_name LIKE 'delivery%';

-- ============================================================================
-- Rollback Script (if needed)
-- ============================================================================
-- ALTER TABLE orders DROP COLUMN delivery_latitude;
-- ALTER TABLE orders DROP COLUMN delivery_longitude;
-- DROP INDEX idx_orders_delivery_coords;
