-- Migration: Populate category_id from legacy category field
-- Date: 2026-01-03
--
-- Purpose: Migrate existing expenses to use category_id (UUID) instead of category (text)
-- This migration maps the old category string values to the new expense_categories table

-- Step 1: Update existing expenses to set category_id based on category string
-- This uses a subquery to find the matching category ID for each expense
UPDATE public.expenses e
SET category_id = (
  SELECT ec.id
  FROM public.expense_categories ec
  WHERE ec.group_id = e.group_id
    AND LOWER(ec.name) = CASE
      WHEN e.category = 'food' THEN 'food'
      WHEN e.category = 'utilities' THEN 'utilities'
      WHEN e.category = 'transport' THEN 'transport'
      WHEN e.category = 'healthcare' THEN 'healthcare'
      WHEN e.category = 'entertainment' THEN 'entertainment'
      WHEN e.category = 'household' THEN 'household'
      WHEN e.category = 'other' THEN 'other'
      ELSE 'other'  -- Fallback for any unknown values
    END
  LIMIT 1
)
WHERE e.category_id IS NULL AND e.category IS NOT NULL;

-- Step 2: For any expenses that still have no category_id, assign them to "Other"
UPDATE public.expenses e
SET category_id = (
  SELECT ec.id
  FROM public.expense_categories ec
  WHERE ec.group_id = e.group_id
    AND LOWER(ec.name) = 'other'
  LIMIT 1
)
WHERE e.category_id IS NULL;

-- Step 3: Make category_id NOT NULL since all expenses should now have a category
ALTER TABLE public.expenses
  ALTER COLUMN category_id SET NOT NULL;

-- Step 4: Drop the old category column (after verifying migration succeeded)
-- IMPORTANT: Only uncomment this after verifying the migration worked correctly
-- ALTER TABLE public.expenses DROP COLUMN IF EXISTS category;

-- Verification query (run this manually to check migration success):
-- SELECT
--   COUNT(*) as total_expenses,
--   COUNT(category_id) as expenses_with_category_id,
--   COUNT(category) as expenses_with_old_category
-- FROM public.expenses;

-- Add comment for documentation
COMMENT ON COLUMN public.expenses.category_id IS
  'Foreign key to expense_categories table. Replaces the legacy category text field.';
