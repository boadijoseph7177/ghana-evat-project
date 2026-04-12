-- Migration: Add customer_tin to sales table
-- This column stores the customer's tax identification number

ALTER TABLE sales
ADD COLUMN IF NOT EXISTS customer_tin VARCHAR(255);
