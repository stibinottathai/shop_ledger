-- Add low_stock_threshold column to items table
-- This allows each item to have its own low stock alert threshold

ALTER TABLE items 
ADD COLUMN IF NOT EXISTS low_stock_threshold DOUBLE PRECISION;

-- Add comment explaining the column
COMMENT ON COLUMN items.low_stock_threshold IS 'Custom low stock threshold for this item. If NULL, uses global default threshold.';

-- Optional: Set a default threshold for existing items (e.g., 10 units)
-- Uncomment the following line if you want to set a default for existing items:
-- UPDATE items SET low_stock_threshold = 10.0 WHERE low_stock_threshold IS NULL;
