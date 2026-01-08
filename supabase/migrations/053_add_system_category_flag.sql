-- Migration 053: Add System Category Flag
--
-- This migration adds support for system-managed categories that cannot be deleted.
-- The "Varie" (Other/Misc) category is marked as a system category and will serve
-- as the catch-all for uncategorized expenses.
--
-- Changes:
-- 1. Add is_system_category column to expense_categories
-- 2. Mark existing "Varie" category as system category
-- 3. Add constraint to prevent deletion of system categories

-- Add is_system_category flag to expense_categories
ALTER TABLE expense_categories
ADD COLUMN IF NOT EXISTS is_system_category BOOLEAN DEFAULT false;

-- Mark "Varie" as a system category
-- This is the catch-all category for uncategorized expenses
UPDATE expense_categories
SET is_system_category = true
WHERE name = 'Varie' AND is_default = true;

-- Note: If "Varie" doesn't exist in any group, it should be created by the app
-- We don't create it here because expense_categories requires group_id
-- The ensure_altro_category_budget function in migration 054 will handle creation per group

-- Add table comment
COMMENT ON COLUMN expense_categories.is_system_category IS
'Flag indicating this is a system-managed category (like "Varie"/"Other") that cannot be deleted. System categories are used for special purposes like catch-all for uncategorized expenses.';

-- Create index for efficient querying of system categories
CREATE INDEX IF NOT EXISTS idx_expense_categories_system
ON expense_categories(is_system_category)
WHERE is_system_category = true;

-- Add RLS policy to prevent deletion of system categories
-- First, check if the policy exists, if not create it
DO $$
BEGIN
    -- Drop existing delete policy if it exists
    DROP POLICY IF EXISTS "Users can delete their group's categories" ON expense_categories;

    -- Create new delete policy that prevents deletion of system categories
    CREATE POLICY "Users can delete non-system categories"
    ON expense_categories
    FOR DELETE
    TO authenticated
    USING (
        is_system_category = false
        AND group_id IN (
            SELECT group_id
            FROM group_members
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );
END $$;
