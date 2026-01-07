-- Migration: Batch Sync RPC Functions for Offline Expense Sync
-- Feature: 010-offline-expense-sync
-- Date: 2026-01-07
-- Purpose: Create Supabase RPC functions for efficient batch synchronization

-- =============================================================================
-- 1. Batch Create Expenses
-- =============================================================================
-- Creates multiple expenses in a single transaction with individual error handling
CREATE OR REPLACE FUNCTION batch_create_expenses(
  p_expenses JSONB -- Array of expense objects
)
RETURNS JSONB -- Array of created expense IDs and any errors
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_expense JSONB;
  v_created_expense RECORD;
  v_user_id UUID;
  v_group_id UUID;
BEGIN
  -- Get current user and group
  v_user_id := auth.uid();
  SELECT group_id INTO v_group_id FROM profiles WHERE id = v_user_id;

  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'User not in a group';
  END IF;

  -- Process each expense in batch
  FOR v_expense IN SELECT * FROM jsonb_array_elements(p_expenses)
  LOOP
    BEGIN
      INSERT INTO expenses (
        id, user_id, group_id, amount, date, category_id, merchant, notes, is_group_expense, created_at, updated_at
      )
      VALUES (
        (v_expense->>'id')::UUID,
        v_user_id,
        v_group_id,
        (v_expense->>'amount')::DECIMAL,
        (v_expense->>'date')::TIMESTAMP,
        (v_expense->>'category_id')::UUID,
        v_expense->>'merchant',
        v_expense->>'notes',
        (v_expense->>'is_group_expense')::BOOLEAN,
        (v_expense->>'created_at')::TIMESTAMP,
        NOW()
      )
      RETURNING * INTO v_created_expense;

      v_result := v_result || jsonb_build_object(
        'id', v_created_expense.id,
        'status', 'success',
        'server_updated_at', v_created_expense.updated_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense->>'id',
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;

-- =============================================================================
-- 2. Batch Update Expenses (with conflict detection)
-- =============================================================================
-- Updates multiple expenses with server-wins conflict resolution
CREATE OR REPLACE FUNCTION batch_update_expenses(
  p_updates JSONB -- Array of {id, fields_to_update, client_updated_at}
)
RETURNS JSONB -- Array of update results with conflict detection
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_update JSONB;
  v_existing RECORD;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
  LOOP
    BEGIN
      -- Check for conflicts (server version newer than client)
      SELECT * INTO v_existing
      FROM expenses
      WHERE id = (v_update->>'id')::UUID;

      IF NOT FOUND THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'error',
          'error_code', 'NOT_FOUND',
          'error_message', 'Expense not found (may have been deleted)'
        );
        CONTINUE;
      END IF;

      -- Conflict detection (FR-009: server wins)
      IF v_existing.updated_at > (v_update->>'client_updated_at')::TIMESTAMP THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'conflict',
          'server_version', row_to_json(v_existing),
          'server_updated_at', v_existing.updated_at,
          'client_updated_at', v_update->>'client_updated_at'
        );
        CONTINUE;
      END IF;

      -- No conflict - proceed with update
      UPDATE expenses
      SET
        amount = COALESCE((v_update->'fields'->>'amount')::DECIMAL, amount),
        date = COALESCE((v_update->'fields'->>'date')::TIMESTAMP, date),
        category_id = COALESCE((v_update->'fields'->>'category_id')::UUID, category_id),
        merchant = COALESCE(v_update->'fields'->>'merchant', merchant),
        notes = COALESCE(v_update->'fields'->>'notes', notes),
        is_group_expense = COALESCE((v_update->'fields'->>'is_group_expense')::BOOLEAN, is_group_expense),
        updated_at = NOW()
      WHERE id = (v_update->>'id')::UUID
      RETURNING updated_at INTO v_existing.updated_at;

      v_result := v_result || jsonb_build_object(
        'id', v_update->>'id',
        'status', 'success',
        'server_updated_at', v_existing.updated_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;

-- =============================================================================
-- 3. Batch Delete Expenses
-- =============================================================================
-- Deletes multiple expenses with user ownership validation
CREATE OR REPLACE FUNCTION batch_delete_expenses(
  p_expense_ids UUID[] -- Array of expense IDs to delete
)
RETURNS JSONB -- Array of deletion results
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_expense_id UUID;
  v_deleted BOOLEAN;
BEGIN
  FOREACH v_expense_id IN ARRAY p_expense_ids
  LOOP
    BEGIN
      DELETE FROM expenses
      WHERE id = v_expense_id
      AND user_id = auth.uid(); -- Security: user can only delete their own expenses

      GET DIAGNOSTICS v_deleted = ROW_COUNT;

      IF v_deleted > 0 THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'success'
        );
      ELSE
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'error',
          'error_code', 'NOT_FOUND',
          'error_message', 'Expense not found or not owned by user'
        );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;

-- =============================================================================
-- 4. Get Expenses by IDs (for conflict resolution)
-- =============================================================================
-- Fetches server versions of expenses for conflict resolution
CREATE OR REPLACE FUNCTION get_expenses_by_ids(
  p_expense_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(row_to_json(e.*))
  INTO v_result
  FROM expenses e
  WHERE e.id = ANY(p_expense_ids)
  AND e.group_id = (SELECT group_id FROM profiles WHERE id = auth.uid());

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- =============================================================================
-- Grant Permissions
-- =============================================================================
-- Allow authenticated users to execute batch sync functions
GRANT EXECUTE ON FUNCTION batch_create_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION batch_update_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION batch_delete_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION get_expenses_by_ids TO authenticated;

-- =============================================================================
-- Migration Complete
-- =============================================================================
-- Created 4 RPC functions for batch sync operations:
-- 1. batch_create_expenses - Batch create with individual error handling
-- 2. batch_update_expenses - Batch update with conflict detection
-- 3. batch_delete_expenses - Batch delete with ownership validation
-- 4. get_expenses_by_ids - Fetch for conflict resolution
