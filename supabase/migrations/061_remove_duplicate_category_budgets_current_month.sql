-- Migration 061: Remove duplicate category budgets for current month
--
-- This migration removes duplicate category_budgets entries that may exist
-- for the same category in the same month, keeping only the most recent one.
-- This is a cleanup migration to fix existing data issues.

-- Step 1: Log duplicate entries before deletion (for debugging)
DO $$
DECLARE
    duplicate_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO duplicate_count
    FROM (
        SELECT category_id, group_id, year, month, COUNT(*) as cnt
        FROM category_budgets
        GROUP BY category_id, group_id, year, month
        HAVING COUNT(*) > 1
    ) duplicates;

    RAISE NOTICE 'Found % duplicate category budget entries', duplicate_count;
END $$;

-- Step 2: Remove duplicates, keeping only the most recent entry per category/group/month/year
-- This uses a CTE to identify records to keep, then deletes everything else
WITH records_to_keep AS (
    SELECT DISTINCT ON (category_id, group_id, year, month)
        id
    FROM category_budgets
    ORDER BY category_id, group_id, year, month, created_at DESC
)
DELETE FROM category_budgets
WHERE id NOT IN (SELECT id FROM records_to_keep);

-- Step 3: Verify the UNIQUE constraint exists to prevent future duplicates
-- This constraint should have been added in migration 046, but we verify it here
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'category_budgets_category_id_group_id_year_month_key'
    ) THEN
        -- Add unique constraint if it doesn't exist
        ALTER TABLE category_budgets
        ADD CONSTRAINT category_budgets_category_id_group_id_year_month_key
        UNIQUE (category_id, group_id, year, month);

        RAISE NOTICE 'Added UNIQUE constraint to prevent future duplicates';
    ELSE
        RAISE NOTICE 'UNIQUE constraint already exists';
    END IF;
END $$;

-- Step 4: Also check for duplicate member_category_budgets and clean those up
WITH member_records_to_keep AS (
    SELECT DISTINCT ON (category_budget_id, user_id)
        id
    FROM member_category_budgets
    ORDER BY category_budget_id, user_id, created_at DESC
)
DELETE FROM member_category_budgets
WHERE id NOT IN (SELECT id FROM member_records_to_keep);

-- Add comment
COMMENT ON TABLE category_budgets IS 'Monthly budget allocations per category per group. Duplicates cleaned up in migration 061.';
