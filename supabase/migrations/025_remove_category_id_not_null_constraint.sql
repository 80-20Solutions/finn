-- Migration: Remove NOT NULL constraint from category_id column
-- Feature: Italian Categories and Budget Management (004)
-- Date: 2026-01-04
--
-- Issue: We need to set category_id to NULL (orphaned state) for migration
-- to Italian categories, but the column has NOT NULL constraint
--
-- Solution: Make category_id nullable to allow orphaned expenses during
-- re-categorization period

-- Remove NOT NULL constraint from category_id column
ALTER TABLE public.expenses
ALTER COLUMN category_id DROP NOT NULL;

-- Add comment explaining the change
COMMENT ON COLUMN public.expenses.category_id IS
  'Category UUID reference. Made nullable 2026-01-04 to allow orphaned expenses during Italian category migration. NULL = orphaned expense requiring user re-categorization.';
