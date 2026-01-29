-- Add timestamp columns for order lifecycle events
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS packed_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS out_for_delivery_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE;

-- Optional: create indexes for quick queries
CREATE INDEX IF NOT EXISTS idx_orders_packed_at ON orders(packed_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);

-- Verify
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'orders' AND column_name IN ('packed_at','out_for_delivery_at','delivered_at','updated_at');
