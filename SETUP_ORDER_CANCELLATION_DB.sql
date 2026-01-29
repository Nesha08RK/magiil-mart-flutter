-- Order Cancellation Feature - Supabase SQL Setup

-- Add new columns to orders table
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS cancel_requested BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS cancel_requested_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;

-- Create index for quick lookup of pending cancellations
CREATE INDEX IF NOT EXISTS idx_orders_cancel_requested 
ON orders(cancel_requested) 
WHERE cancel_requested = true;

-- Create index for cancelled orders lookup
CREATE INDEX IF NOT EXISTS idx_orders_cancelled_at 
ON orders(cancelled_at) 
WHERE cancelled_at IS NOT NULL;

-- Optional: Add comment to document the columns
COMMENT ON COLUMN orders.cancel_requested IS 'Set to true when customer requests cancellation';
COMMENT ON COLUMN orders.cancel_requested_at IS 'Timestamp when cancellation was requested';
COMMENT ON COLUMN orders.cancelled_at IS 'Timestamp when cancellation was approved by admin';

-- RLS Policies (if RLS is enabled on orders table)

-- Policy 1: Users can view cancellation status of their own orders
-- (Usually already exists from base implementation)

-- Policy 2: Users can request cancellation on their own 'Placed' orders
CREATE POLICY "Users can request cancellation"
ON orders FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id AND
  status = 'Placed'
);

-- Policy 3: Admins can approve/reject cancellations
CREATE POLICY "Admins can process cancellations"
ON orders FOR UPDATE
USING (auth.jwt() ->> 'email' = 'admin@magiilmart.com')
WITH CHECK (
  auth.jwt() ->> 'email' = 'admin@magiilmart.com'
);

-- Verify the columns were added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY ordinal_position;
