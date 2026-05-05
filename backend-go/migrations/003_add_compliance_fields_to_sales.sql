-- Migration: Add compliance fields to sales table
-- These columns store GRA response data for receipt and sync status display.

ALTER TABLE sales
ADD COLUMN IF NOT EXISTS sdc_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS qr_code TEXT;
