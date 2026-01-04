-- Migration: Ensure all groups have default expense categories
-- Date: 2026-01-03
--
-- Purpose: Create default categories for any groups that don't have them yet
-- This fixes issues where groups created after the initial seeding don't have categories

-- Insert default categories for all groups that don't have them
INSERT INTO public.expense_categories (group_id, name, is_default, created_by)
SELECT
  fg.id,
  category_name,
  true,
  NULL
FROM public.family_groups fg
CROSS JOIN (
  VALUES
    ('Food'),
    ('Utilities'),
    ('Transport'),
    ('Healthcare'),
    ('Entertainment'),
    ('Other')
) AS categories(category_name)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.expense_categories ec
  WHERE ec.group_id = fg.id
  AND ec.name = category_name
);

-- Verify all groups have categories
DO $$
DECLARE
  groups_without_categories INTEGER;
BEGIN
  SELECT COUNT(DISTINCT fg.id) INTO groups_without_categories
  FROM public.family_groups fg
  WHERE NOT EXISTS (
    SELECT 1 FROM public.expense_categories ec WHERE ec.group_id = fg.id
  );

  IF groups_without_categories > 0 THEN
    RAISE WARNING 'Found % groups without any categories!', groups_without_categories;
  ELSE
    RAISE NOTICE 'All groups have expense categories';
  END IF;
END $$;
