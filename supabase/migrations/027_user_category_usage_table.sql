-- Migration: Create user_category_usage table for virgin category tracking
-- Feature: Italian Categories and Budget Management (004)
-- Task: T002

-- Create user_category_usage table
CREATE TABLE IF NOT EXISTS public.user_category_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.expense_categories(id) ON DELETE CASCADE,
  first_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Ensure one record per user-category pair (virgin tracking)
  UNIQUE(user_id, category_id)
);

-- Create index for optimized virgin category checks
CREATE INDEX idx_user_category_usage_lookup
  ON public.user_category_usage(user_id, category_id);

-- Add comment
COMMENT ON TABLE public.user_category_usage IS 'Tracks first-time category usage per user for virgin category detection';
