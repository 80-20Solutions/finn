# Migration Testing Guide - Category-Only Budget System

## Overview

This guide provides step-by-step instructions for testing the database migrations (052-057) that implement the category-only budget system.

## Prerequisites

- Access to development Supabase project
- Backup of current database
- Supabase CLI installed
- Database credentials configured

---

## Pre-Migration Checks

### 1. Create Database Backup

```bash
# Using Supabase CLI
supabase db dump -f backup_pre_migration_$(date +%Y%m%d_%H%M%S).sql

# Or via Supabase Dashboard
# Navigate to: Database → Backups → Create Manual Backup
```

### 2. Document Current State

Run these queries to capture current data:

```sql
-- Count existing budgets
SELECT
  (SELECT COUNT(*) FROM group_budgets) as group_budgets_count,
  (SELECT COUNT(*) FROM personal_budgets) as personal_budgets_count,
  (SELECT COUNT(*) FROM category_budgets) as category_budgets_count;

-- List all group budgets
SELECT id, group_id, amount, month, year, created_at
FROM group_budgets
ORDER BY created_at DESC
LIMIT 10;

-- List all personal budgets
SELECT id, user_id, amount, month, year, created_at
FROM personal_budgets
ORDER BY created_at DESC
LIMIT 10;

-- Check for uncategorized expenses
SELECT COUNT(*) as uncategorized_expenses
FROM expenses
WHERE category_id IS NULL;

-- Check "Varie" category existence
SELECT id, name, is_default, group_id
FROM expense_categories
WHERE name = 'Varie' OR name = 'Altro';
```

Save the results for comparison after migration.

---

## Migration Execution

### 1. Run Migrations in Order

Execute each migration file in sequence:

```bash
# Migration 052: Deprecate manual budgets
supabase db push --file supabase/migrations/052_deprecate_manual_budgets.sql

# Migration 053: Add system category flag
supabase db push --file supabase/migrations/053_add_system_category_flag.sql

# Migration 054: Create ensure_altro RPC function
supabase db push --file supabase/migrations/054_ensure_altro_budget_function.sql

# Migration 055: Create budget total views
supabase db push --file supabase/migrations/055_create_budget_total_views.sql

# Migration 056: Migrate manual to category budgets
supabase db push --file supabase/migrations/056_migrate_manual_to_category_budgets.sql

# Migration 057: Auto-assign uncategorized expenses
supabase db push --file supabase/migrations/057_assign_uncategorized_to_altro.sql
```

### 2. Verify Each Migration

After each migration, run verification queries:

**After 052 (Deprecate):**
```sql
-- Check columns added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name IN ('group_budgets', 'personal_budgets')
  AND column_name = 'is_deprecated';

-- Check all existing budgets marked deprecated
SELECT
  (SELECT COUNT(*) FROM group_budgets WHERE is_deprecated = true) as deprecated_group_budgets,
  (SELECT COUNT(*) FROM personal_budgets WHERE is_deprecated = true) as deprecated_personal_budgets;
```

**After 053 (System Category):**
```sql
-- Check system category flag added
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'expense_categories'
  AND column_name = 'is_system_category';

-- Check "Varie" marked as system
SELECT id, name, is_system_category, group_id
FROM expense_categories
WHERE is_system_category = true;
```

**After 054 (RPC Function):**
```sql
-- Check function exists
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'ensure_altro_category_budget';

-- Test function call (replace with real IDs)
SELECT * FROM ensure_altro_category_budget(
  'your-group-id'::uuid,
  2026,
  1
);
```

**After 055 (Views):**
```sql
-- Check views created
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('v_group_budget_totals', 'v_personal_budget_totals');

-- Test group budget totals view
SELECT * FROM v_group_budget_totals
WHERE year = 2026 AND month = 1;

-- Test personal budget totals view
SELECT * FROM v_personal_budget_totals
WHERE year = 2026 AND month = 1;

-- Test helper functions
SELECT get_group_budget_total('your-group-id'::uuid, 2026, 1);
SELECT get_personal_budget_total('your-user-id'::uuid, 2026, 1);
```

**After 056 (Data Migration):**
```sql
-- Check category budgets created from manual budgets
SELECT
  cb.id,
  cb.category_id,
  cb.amount,
  cb.month,
  cb.year,
  ec.name as category_name
FROM category_budgets cb
JOIN expense_categories ec ON ec.id = cb.category_id
WHERE ec.name IN ('Varie', 'Altro')
ORDER BY cb.created_at DESC;

-- Verify amounts match original manual budgets
-- (Manual verification against pre-migration data)
```

**After 057 (Auto-Assign):**
```sql
-- Check trigger created
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_assign_altro_category';

-- Check function created
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'auto_assign_altro_category';

-- Verify no uncategorized expenses remain
SELECT COUNT(*) as uncategorized_count
FROM expenses
WHERE category_id IS NULL;

-- Check expenses assigned to Altro
SELECT COUNT(*) as assigned_to_altro
FROM expenses e
JOIN expense_categories ec ON ec.id = e.category_id
WHERE ec.name IN ('Varie', 'Altro');
```

---

## Post-Migration Validation

### 1. Data Integrity Checks

```sql
-- Compare budget totals before and after
-- Group budget totals should match
SELECT
  gb.group_id,
  gb.month,
  gb.year,
  gb.amount as old_manual_amount,
  (SELECT SUM(amount) FROM category_budgets WHERE group_id = gb.group_id AND month = gb.month AND year = gb.year AND is_group_budget = true) as new_calculated_amount
FROM group_budgets gb
WHERE gb.is_deprecated = true;

-- Personal budget totals should match (approximately)
SELECT
  pb.user_id,
  pb.month,
  pb.year,
  pb.amount as old_manual_amount,
  (SELECT SUM(cmc.contribution_amount_cents)
   FROM category_member_contributions cmc
   JOIN category_budgets cb ON cb.id = cmc.budget_id
   WHERE cmc.user_id = pb.user_id AND cb.month = pb.month AND cb.year = pb.year) as new_calculated_amount
FROM personal_budgets pb
WHERE pb.is_deprecated = true;
```

### 2. View Functionality

```sql
-- Test group budget totals view with real data
SELECT * FROM v_group_budget_totals
ORDER BY year DESC, month DESC
LIMIT 10;

-- Test personal budget totals view with real data
SELECT * FROM v_personal_budget_totals
ORDER BY year DESC, month DESC
LIMIT 10;
```

### 3. RPC Function Testing

```sql
-- Test ensure_altro_category_budget with various scenarios

-- Scenario 1: Group without any budgets
SELECT * FROM ensure_altro_category_budget('new-group-id'::uuid, 2026, 2);

-- Scenario 2: Group with existing budgets but no Altro
SELECT * FROM ensure_altro_category_budget('existing-group-id'::uuid, 2026, 2);

-- Scenario 3: Group with Altro already (should be idempotent)
SELECT * FROM ensure_altro_category_budget('group-with-altro'::uuid, 2026, 1);
```

### 4. Trigger Testing

```sql
-- Test auto-assign trigger by inserting expense without category
BEGIN;

-- Insert expense without category_id
INSERT INTO expenses (user_id, group_id, amount, description, expense_date, is_group_expense, created_by)
VALUES ('test-user-id'::uuid, 'test-group-id'::uuid, 1000, 'Test uncategorized expense', CURRENT_DATE, false, 'test-user-id'::uuid);

-- Check if it got assigned to Altro
SELECT e.id, e.description, e.category_id, ec.name
FROM expenses e
JOIN expense_categories ec ON ec.id = e.category_id
WHERE e.description = 'Test uncategorized expense';

ROLLBACK; -- Or COMMIT if satisfied
```

---

## Edge Case Testing

### 1. Empty Group (No Budgets)

```sql
-- Create test group with no budgets
-- Call ensure_altro function
-- Verify Altro category created with €0 budget
```

### 2. Manual Budget Without Varie Category

```sql
-- Simulate scenario where group has manual budget but no Varie category
-- Run migration
-- Verify Varie category created and budget assigned
```

### 3. Multiple Groups Same User

```sql
-- Verify views correctly aggregate across multiple groups
SELECT * FROM v_personal_budget_totals
WHERE user_id = 'test-user-id'::uuid
ORDER BY year DESC, month DESC;
```

### 4. System Category Deletion Attempt

```sql
-- Try to delete system category (should fail)
DELETE FROM expense_categories
WHERE is_system_category = true;
-- Should return error or 0 rows deleted
```

---

## Rollback Procedure

If migration fails or issues are found:

### 1. Restore from Backup

```bash
# Restore full database
supabase db restore backup_pre_migration_YYYYMMDD_HHMMSS.sql
```

### 2. Or Use Rollback Script

```sql
-- Run rollback script (if created)
-- supabase/migrations/058_rollback_category_only_budgets.sql

-- Manual rollback steps:
-- 1. Drop trigger
DROP TRIGGER IF EXISTS trigger_auto_assign_altro_category ON expenses;

-- 2. Drop functions
DROP FUNCTION IF EXISTS auto_assign_altro_category();
DROP FUNCTION IF EXISTS ensure_altro_category_budget(uuid, integer, integer);
DROP FUNCTION IF EXISTS get_group_budget_total(uuid, integer, integer);
DROP FUNCTION IF EXISTS get_personal_budget_total(uuid, integer, integer);

-- 3. Drop views
DROP VIEW IF EXISTS v_personal_budget_totals;
DROP VIEW IF EXISTS v_group_budget_totals;

-- 4. Remove system category flags
ALTER TABLE expense_categories DROP COLUMN IF EXISTS is_system_category;

-- 5. Remove deprecated flags
ALTER TABLE group_budgets DROP COLUMN IF EXISTS is_deprecated;
ALTER TABLE personal_budgets DROP COLUMN IF EXISTS is_deprecated;

-- 6. Delete migrated category budgets (if needed)
-- BE CAREFUL - This deletes data!
-- DELETE FROM category_budgets WHERE created_at >= 'migration-timestamp';
```

---

## Performance Testing

### 1. View Query Performance

```sql
-- Test view query speed
EXPLAIN ANALYZE
SELECT * FROM v_group_budget_totals
WHERE year = 2026 AND month = 1;

EXPLAIN ANALYZE
SELECT * FROM v_personal_budget_totals
WHERE year = 2026 AND month = 1;
```

### 2. RPC Function Performance

```sql
-- Test RPC function speed
EXPLAIN ANALYZE
SELECT * FROM ensure_altro_category_budget('group-id'::uuid, 2026, 1);
```

### 3. Trigger Performance

```sql
-- Test trigger overhead on insert
EXPLAIN ANALYZE
INSERT INTO expenses (...) VALUES (...);
```

---

## Success Criteria

Migration is successful if ALL of the following are true:

- [ ] All 6 migrations executed without errors
- [ ] All existing manual budgets marked as deprecated
- [ ] "Varie"/"Altro" categories marked as system categories
- [ ] All uncategorized expenses assigned to Altro
- [ ] Database views return correct totals
- [ ] RPC functions work correctly
- [ ] Triggers function properly
- [ ] No data loss (budget amounts preserved)
- [ ] Performance acceptable (<100ms for views)
- [ ] All edge cases handled correctly

---

## Troubleshooting

### Issue: Migration fails with foreign key error

**Solution:** Check if referenced tables/columns exist. May need to adjust migration order.

### Issue: Views return NULL or incorrect totals

**Solution:** Verify category_budgets table has data. Check join conditions in view definition.

### Issue: Trigger doesn't fire

**Solution:** Check trigger definition. Verify function exists and has correct signature.

### Issue: RPC function returns error

**Solution:** Check function parameters. Verify UUID format. Check permissions.

### Issue: Performance degradation

**Solution:** Add indexes on commonly queried columns:
```sql
CREATE INDEX IF NOT EXISTS idx_category_budgets_group_month_year
ON category_budgets(group_id, year, month);

CREATE INDEX IF NOT EXISTS idx_expenses_category_date
ON expenses(category_id, expense_date);
```

---

## Report Template

After testing, document results:

```
Migration Testing Report - Category-Only Budget System
Date: YYYY-MM-DD
Tester: [Name]
Environment: [Dev/Staging/Prod]

Pre-Migration State:
- Group Budgets: [count]
- Personal Budgets: [count]
- Category Budgets: [count]
- Uncategorized Expenses: [count]

Migration Execution:
- 052: [✓ Success / ✗ Failed] - [Notes]
- 053: [✓ Success / ✗ Failed] - [Notes]
- 054: [✓ Success / ✗ Failed] - [Notes]
- 055: [✓ Success / ✗ Failed] - [Notes]
- 056: [✓ Success / ✗ Failed] - [Notes]
- 057: [✓ Success / ✗ Failed] - [Notes]

Post-Migration State:
- Deprecated Group Budgets: [count]
- Deprecated Personal Budgets: [count]
- System Categories: [count]
- Category Budgets (total): [count]
- Uncategorized Expenses: [should be 0]

Data Integrity: [✓ Pass / ✗ Fail]
- Budget totals match: [Yes/No]
- No data loss: [Yes/No]
- Views accurate: [Yes/No]

Performance:
- View queries: [avg time]
- RPC functions: [avg time]
- Trigger overhead: [avg time]

Issues Found:
1. [Issue description]
2. [Issue description]

Recommendation: [Proceed to Production / Rollback / Fix Issues]
```

---

## Next Steps After Successful Migration

1. Deploy application code updates (Phases 1-5)
2. Monitor error logs for 24 hours
3. Verify UI displays correctly
4. Test user workflows end-to-end
5. Gradual rollout (10% → 50% → 100%)
6. Remove deprecated code after 30 days

---

**Document Version:** 1.0
**Last Updated:** 2026-01-08
**Author:** Claude Sonnet 4.5
