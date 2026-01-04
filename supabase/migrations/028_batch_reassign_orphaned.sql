-- Migration: Create RPC function for batch re-categorization of orphaned expenses
-- Feature: Italian Categories and Budget Management (004)
-- Task: T003

-- Create function to batch reassign orphaned expenses
CREATE OR REPLACE FUNCTION batch_reassign_orphaned_expenses(
  p_expense_ids UUID[],
  p_new_category_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  -- Update all specified expenses to new category
  -- Only update expenses that are currently orphaned (category_id IS NULL)
  UPDATE public.expenses
  SET
    category_id = p_new_category_id,
    updated_at = NOW()
  WHERE id = ANY(p_expense_ids)
    AND category_id IS NULL;  -- Safety: only update orphaned expenses

  -- Get count of updated rows
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN v_updated_count;
END;
$$;

-- Add comment
COMMENT ON FUNCTION batch_reassign_orphaned_expenses IS 'Batch re-categorizes orphaned expenses (NULL category_id) to specified category';
