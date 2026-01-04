-- Migration: Set all expenses to orphaned state and delete English categories
-- Feature: Italian Categories and Budget Management (004)
-- Task: T009
--
-- WARNING: This migration is destructive!
-- - Sets ALL expenses.category_id to NULL (orphaned state)
-- - Deletes ALL existing categories (English ones)
-- - Users will need to re-categorize expenses using new Italian categories

-- Step 1: Set all expenses to orphaned state (NULL category)
UPDATE public.expenses
SET category_id = NULL
WHERE category_id IS NOT NULL;

-- Step 2: Delete all existing categories (English categories)
-- This will cascade due to ON DELETE CASCADE in related tables
DELETE FROM public.expense_categories
WHERE is_default = true OR is_default = false;  -- Delete all categories (default and custom)

-- Note: Italian categories will be seeded in the next migration (035)
