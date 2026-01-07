-- Migration: Fix euro-to-cents conversion bug in budget calculation functions
-- Bug: Expense amounts (DECIMAL euros) were summed without converting to cents,
--      causing budget calculations to show 1/100th of actual spending
-- Fix: Multiply expense amounts by 100 to convert from euros to cents

-- Fix 1: Update get_category_budget_stats function
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
  -- FIX: Convert euros to cents (multiply by 100)
  SELECT COALESCE(SUM(amount * 100), 0)::INTEGER
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

COMMENT ON FUNCTION get_category_budget_stats IS 'Calculates budget statistics for a specific category and month including spent, remaining, and percentage';

-- Fix 2: Update get_overall_group_budget_stats function
CREATE OR REPLACE FUNCTION get_overall_group_budget_stats(
  p_group_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE(
  total_budgeted INTEGER,
  total_spent INTEGER,
  total_remaining INTEGER,
  percentage_used NUMERIC,
  categories_over_budget INTEGER,
  month INTEGER,
  year INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_budgeted INTEGER;
  v_total_spent INTEGER;
  v_categories_over_budget INTEGER;
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

  -- Calculate total budgeted (sum of all category budgets)
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total_budgeted
  FROM public.category_budgets
  WHERE category_budgets.group_id = p_group_id
    AND category_budgets.year = p_year
    AND category_budgets.month = p_month;

  -- Calculate total spent (sum of all expenses with categories in month)
  -- FIX: Convert euros to cents (multiply by 100)
  SELECT COALESCE(SUM(amount * 100), 0)::INTEGER
  INTO v_total_spent
  FROM public.expenses
  WHERE expenses.group_id = p_group_id
    AND expenses.category_id IS NOT NULL
    AND expenses.date >= v_month_start
    AND expenses.date <= v_month_end;

  -- Count categories over budget
  WITH category_spending AS (
    SELECT
      cb.category_id,
      cb.amount AS budget,
      -- FIX: Convert euros to cents (multiply by 100)
      COALESCE(SUM(e.amount * 100), 0)::INTEGER AS spent
    FROM public.category_budgets cb
    LEFT JOIN public.expenses e
      ON e.category_id = cb.category_id
      AND e.group_id = cb.group_id
      AND e.date >= v_month_start
      AND e.date <= v_month_end
    WHERE cb.group_id = p_group_id
      AND cb.year = p_year
      AND cb.month = p_month
    GROUP BY cb.category_id, cb.amount
  )
  SELECT COUNT(*)
  INTO v_categories_over_budget
  FROM category_spending
  WHERE spent > budget;

  -- Return overall stats
  RETURN QUERY
  SELECT
    v_total_budgeted,
    v_total_spent,
    v_total_budgeted - v_total_spent AS total_remaining,
    CASE
      WHEN v_total_budgeted > 0 THEN (v_total_spent::NUMERIC / v_total_budgeted::NUMERIC) * 100
      ELSE 0
    END AS percentage_used,
    v_categories_over_budget,
    p_month,
    p_year;
END;
$$;

COMMENT ON FUNCTION get_overall_group_budget_stats IS 'Calculates overall group budget statistics for dashboard including totals and over-budget category count';
