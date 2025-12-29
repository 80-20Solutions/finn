-- Fix expense table columns to match app expectations
-- Migration: 007_fix_expense_columns.sql

-- Rename user_id to created_by
ALTER TABLE public.expenses
  RENAME COLUMN user_id TO created_by;

-- Rename user_display_name to created_by_name
ALTER TABLE public.expenses
  RENAME COLUMN user_display_name TO created_by_name;

-- Add paid_by column (who paid for the expense, defaults to created_by)
ALTER TABLE public.expenses
  ADD COLUMN paid_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Set paid_by to created_by for existing rows
UPDATE public.expenses
SET paid_by = created_by
WHERE paid_by IS NULL;

-- Add paid_by_name column
ALTER TABLE public.expenses
  ADD COLUMN paid_by_name TEXT;

-- Set paid_by_name to created_by_name for existing rows
UPDATE public.expenses
SET paid_by_name = created_by_name
WHERE paid_by_name IS NULL;

-- Update index on user_id to use created_by
DROP INDEX IF EXISTS idx_expenses_user_id;
CREATE INDEX idx_expenses_created_by ON public.expenses(created_by);
CREATE INDEX idx_expenses_paid_by ON public.expenses(paid_by);

-- Add receipt_url as alias for receipt_image_url if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'receipt_url'
  ) THEN
    ALTER TABLE public.expenses
      RENAME COLUMN receipt_image_url TO receipt_url;
  END IF;
END $$;
