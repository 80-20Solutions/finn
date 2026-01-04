-- Migration: Add RLS policies for user_category_usage table
-- Feature: Italian Categories and Budget Management (004)
-- Task: T007

-- Enable RLS on user_category_usage table
ALTER TABLE public.user_category_usage ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own category usage" ON public.user_category_usage;
DROP POLICY IF EXISTS "Users can insert their own category usage" ON public.user_category_usage;

-- SELECT: Users can view their own category usage records
CREATE POLICY "Users can view their own category usage"
  ON public.user_category_usage
  FOR SELECT
  USING (
    user_id = auth.uid()
  );

-- INSERT: Users can create their own category usage records
CREATE POLICY "Users can insert their own category usage"
  ON public.user_category_usage
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
  );

-- Note: No UPDATE or DELETE policies - these records are immutable once created
