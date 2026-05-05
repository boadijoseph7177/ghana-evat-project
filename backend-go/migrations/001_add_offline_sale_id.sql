-- Migration: Add offline_sale_id to sales table
-- This column tracks sales made offline on the mobile app
-- When synced, the offline sale ID is stored to prevent duplicates

ALTER TABLE sales
ADD COLUMN IF NOT EXISTS offline_sale_id VARCHAR(255);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_offline_sale_id'
    ) THEN
        ALTER TABLE sales
        ADD CONSTRAINT unique_offline_sale_id UNIQUE (offline_sale_id);
    END IF;
END $$;

-- Additional index for better query performance
CREATE INDEX IF NOT EXISTS idx_sales_offline_sale_id ON sales(offline_sale_id);
