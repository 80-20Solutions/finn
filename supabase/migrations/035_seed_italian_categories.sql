-- Migration: Seed default Italian categories for all family groups
-- Feature: Italian Categories and Budget Management (004)
-- Task: T010

-- Insert default Italian categories for ALL existing family groups
-- Each group gets the same set of 10 Italian categories

INSERT INTO public.expense_categories (group_id, name, is_default, created_by)
SELECT
  fg.id AS group_id,
  category_name,
  true AS is_default,
  NULL AS created_by  -- NULL indicates system-provided default
FROM public.family_groups fg
CROSS JOIN (
  VALUES
    ('Spesa'),           -- Groceries
    ('Benzina'),         -- Fuel
    ('Ristoranti'),      -- Restaurants
    ('Bollette'),        -- Bills/Utilities
    ('Salute'),          -- Health
    ('Trasporti'),       -- Transportation
    ('Casa'),            -- Home
    ('Svago'),           -- Entertainment
    ('Abbigliamento'),   -- Clothing
    ('Varie')            -- Miscellaneous (fallback category)
) AS categories(category_name)
ON CONFLICT (group_id, name) DO NOTHING;  -- Avoid duplicates if migration is re-run

-- Add comment
COMMENT ON TABLE public.expense_categories IS 'Expense categories - now using Italian names (Spesa, Benzina, etc.)';
