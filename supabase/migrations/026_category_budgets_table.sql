-- Migration: Create category_budgets table for monthly budget allocations
-- Feature: Italian Categories and Budget Management (004)
-- Task: T001

-- Create category_budgets table
CREATE TABLE IF NOT EXISTS public.category_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.expense_categories(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),  -- Stored in cents to avoid floating-point errors
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Ensure one budget per category per month
  UNIQUE(category_id, group_id, year, month)
);

-- Create indexes for optimized queries
CREATE INDEX idx_category_budgets_lookup
  ON public.category_budgets(group_id, category_id, year, month);

CREATE INDEX idx_category_budgets_current_month
  ON public.category_budgets(group_id, year, month);

-- Add trigger for updated_at
CREATE TRIGGER set_updated_at_category_budgets
  BEFORE UPDATE ON public.category_budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comment
COMMENT ON TABLE public.category_budgets IS 'Monthly budget allocations per category per group';
