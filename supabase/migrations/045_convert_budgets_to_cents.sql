-- Migration: Convert all budget amounts from euros to cents
-- This migration multiplies all existing budget amounts by 100 to convert them
-- from whole euros (old system) to cents (new standardized system)
--
-- Context: The codebase was refactored to use cents as the standard unit for
-- all monetary values (following CurrencyUtils standard). This migration ensures
-- database values match the new expectation.

-- Convert group_budgets from euros to cents
UPDATE public.group_budgets
SET amount = amount * 100
WHERE amount < 1000000; -- Safety check: only convert if amount seems reasonable (< 10k euros)

-- Convert personal_budgets from euros to cents
UPDATE public.personal_budgets
SET amount = amount * 100
WHERE amount < 1000000; -- Safety check: only convert if amount seems reasonable (< 10k euros)

-- Convert category_budgets from euros to cents
-- Note: category_budgets were already documented as cents in migration 026,
-- but may have been incorrectly saved as euros in practice
UPDATE public.category_budgets
SET amount = amount * 100
WHERE amount < 1000000; -- Safety check: only convert if amount seems reasonable (< 10k euros)

-- Add comment documenting the conversion
COMMENT ON COLUMN public.group_budgets.amount IS 'Budget amount in cents (e.g., 50000 = €500.00). Converted from euros to cents in migration 045.';
COMMENT ON COLUMN public.personal_budgets.amount IS 'Budget amount in cents (e.g., 50000 = €500.00). Converted from euros to cents in migration 045.';
COMMENT ON COLUMN public.category_budgets.amount IS 'Budget amount in cents (e.g., 50000 = €500.00). Originally documented as cents in migration 026, standardized in migration 045.';
