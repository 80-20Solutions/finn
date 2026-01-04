-- Migration: Create optimized index for category-month expense queries
-- Feature: Italian Categories and Budget Management (004)
-- Task: T008

-- Create composite index for optimized category budget calculations
-- This index speeds up queries that filter by category_id and date range (monthly spending)
CREATE INDEX IF NOT EXISTS idx_expenses_category_month
  ON public.expenses(category_id, group_id, date)
  WHERE category_id IS NOT NULL;

-- Add comment
COMMENT ON INDEX idx_expenses_category_month IS 'Optimizes monthly spending queries by category for budget calculations';
