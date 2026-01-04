-- Migration: Add RLS policies for category_budgets table
-- Feature: Italian Categories and Budget Management (004)
-- Task: T006

-- Enable RLS on category_budgets table
ALTER TABLE public.category_budgets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view category budgets for their groups" ON public.category_budgets;
DROP POLICY IF EXISTS "Group admins can insert category budgets" ON public.category_budgets;
DROP POLICY IF EXISTS "Group admins can update category budgets" ON public.category_budgets;
DROP POLICY IF EXISTS "Group admins can delete category budgets" ON public.category_budgets;

-- SELECT: Users can view category budgets for groups they belong to
CREATE POLICY "Users can view category budgets for their groups"
  ON public.category_budgets
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id
      FROM public.profiles
      WHERE id = auth.uid()
    )
  );

-- INSERT: Group admins can create category budgets
CREATE POLICY "Group admins can insert category budgets"
  ON public.category_budgets
  FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id
      FROM public.profiles
      WHERE id = auth.uid()
        AND is_group_admin = true
    )
  );

-- UPDATE: Group admins can update category budgets
CREATE POLICY "Group admins can update category budgets"
  ON public.category_budgets
  FOR UPDATE
  USING (
    group_id IN (
      SELECT group_id
      FROM public.profiles
      WHERE id = auth.uid()
        AND is_group_admin = true
    )
  )
  WITH CHECK (
    group_id IN (
      SELECT group_id
      FROM public.profiles
      WHERE id = auth.uid()
        AND is_group_admin = true
    )
  );

-- DELETE: Group admins can delete category budgets
CREATE POLICY "Group admins can delete category budgets"
  ON public.category_budgets
  FOR DELETE
  USING (
    group_id IN (
      SELECT group_id
      FROM public.profiles
      WHERE id = auth.uid()
        AND is_group_admin = true
    )
  );
