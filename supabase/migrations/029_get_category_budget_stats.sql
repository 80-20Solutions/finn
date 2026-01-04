-- Migration: Create RPC function for calculating category budget statistics
-- Feature: Italian Categories and Budget Management (004)
-- Task: T004

-- Create function to get category budget stats for a specific month
CREATE OR REPLACE FUNCTION get_category_budget_stats(
  p_group_id UUID,
  p_category_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE(
  category_id UUID,
  category_name TEXT,
  budget_amount INTEGER,
  spent_amount INTEGER,
  remaining_amount INTEGER,
  percentage_used NUMERIC,
  is_over_budget BOOLEAN,
  month INTEGER,
  year INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_budget_amount INTEGER;
  v_spent_amount INTEGER;
  v_category_name TEXT;
  v_month_start DATE;
  v_month_end DATE;
BEGIN
  -- Calculate month boundaries
  v_month_start := make_date(p_year, p_month, 1);

  -- Last day of month
  IF p_month = 12 THEN
    v_month_end := make_date(p_year + 1, 1, 1) - INTERVAL '1 day';
  ELSE
    v_month_end := make_date(p_year, p_month + 1, 1) - INTERVAL '1 day';
  END IF;

  -- Get budget allocation for this category and month
  SELECT amount
  INTO v_budget_amount
  FROM public.category_budgets
  WHERE category_budgets.group_id = p_group_id
    AND category_budgets.category_id = p_category_id
    AND category_budgets.year = p_year
    AND category_budgets.month = p_month;

  -- Default to 0 if no budget set
  v_budget_amount := COALESCE(v_budget_amount, 0);

  -- Get category name
  SELECT name
  INTO v_category_name
  FROM public.expense_categories
  WHERE id = p_category_id;

  -- Calculate total spending for this category in the month
  SELECT COALESCE(SUM(amount), 0)
  INTO v_spent_amount
  FROM public.expenses
  WHERE expenses.group_id = p_group_id
    AND expenses.category_id = p_category_id
    AND expenses.date >= v_month_start
    AND expenses.date <= v_month_end;

  -- Return calculated stats
  RETURN QUERY
  SELECT
    p_category_id,
    v_category_name,
    v_budget_amount,
    v_spent_amount,
    v_budget_amount - v_spent_amount AS remaining_amount,
    CASE
      WHEN v_budget_amount > 0 THEN (v_spent_amount::NUMERIC / v_budget_amount::NUMERIC) * 100
      ELSE 0
    END AS percentage_used,
    v_spent_amount > v_budget_amount AS is_over_budget,
    p_month,
    p_year;
END;
$$;

-- Add comment
COMMENT ON FUNCTION get_category_budget_stats IS 'Calculates budget statistics for a specific category and month including spent, remaining, and percentage';
