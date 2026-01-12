# Monthly Reset Testing Guide

## Task T068: Verify Historical Data Preservation

### Purpose

Verify that historical budget data is preserved across month transitions and that monthly reset works correctly.

---

## Test Scenarios

### Scenario 1: First Month Budget Creation

**Steps:**
1. Admin completes wizard for January 2026
2. Verify budget configuration is saved for January 2026
3. Check database has records in `category_budgets` table with year=2026, month=1

**Expected Results:**
- Budget data exists for January 2026
- Member allocations are set correctly
- Spent amounts are 0

---

### Scenario 2: Month Transition (Manual Date Mocking)

**Setup:**
- Budget configured for January 2026
- Some expenses recorded in January
- Manually advance system date to February 1, 2026

**Steps:**
1. Close and reopen app on February 1, 2026
2. Verify monthly reset check triggers
3. Check that:
   - January 2026 data is preserved (historical)
   - February 2026 budget is created (copy of January config)
   - February 2026 spent amounts are reset to 0
   - January 2026 spent amounts remain unchanged

**Expected Results:**
```sql
-- January 2026 (historical - preserved)
SELECT * FROM category_budgets WHERE year=2026 AND month=1;
-- Should show original budgets with spent amounts

-- February 2026 (new month - reset)
SELECT * FROM category_budgets WHERE year=2026 AND month=2;
-- Should show same budget amounts but spent=0
```

---

### Scenario 3: Multiple Month History

**Setup:**
- Budget configured for January 2026
- Expenses recorded in January, February, March

**Steps:**
1. Query budget history from January to March
2. Verify each month has independent data
3. Check that spent amounts differ across months
4. Verify budget configurations remain consistent (unless admin modified)

**Expected Results:**
- 3 distinct months of data
- Each month has its own spent amounts
- Historical data is queryable
- No data loss during transitions

---

### Scenario 4: Admin Modifies Allocation Mid-Year

**Setup:**
- Budget configured for January 2026 with Member A: 40%, Member B: 60%
- February starts with same allocation
- Admin changes allocation in March to Member A: 50%, Member B: 50%

**Steps:**
1. Verify January-February have original allocation (40/60)
2. Admin re-triggers wizard in March and changes allocation
3. Verify March-onwards have new allocation (50/50)
4. Check historical data (Jan-Feb) is unchanged

**Expected Results:**
```sql
-- January-February (preserved with old allocation)
SELECT * FROM category_budgets
WHERE year=2026 AND month IN (1, 2) AND is_group_budget=FALSE;
-- Should show 40/60 split

-- March onwards (new allocation)
SELECT * FROM category_budgets
WHERE year=2026 AND month >= 3 AND is_group_budget=FALSE;
-- Should show 50/50 split
```

---

### Scenario 5: Year Transition

**Setup:**
- Budget configured for December 2025
- Date advances to January 2026

**Steps:**
1. Close app on December 31, 2025
2. Reopen app on January 1, 2026
3. Verify budget copies from December 2025 to January 2026
4. Check year correctly increments in database

**Expected Results:**
- December 2025 data preserved
- January 2026 budget created
- Year field correctly set to 2026
- No data corruption during year transition

---

## Manual Testing Procedure

### Prerequisites

1. **Date Mocking Setup**:
   - Use device/emulator date settings to manually advance time
   - OR use database triggers to simulate month changes
   - OR modify app code temporarily to use fixed test dates

2. **Database Access**:
   - Supabase dashboard for SQL queries
   - Table editor to inspect `category_budgets` table

3. **Test Data**:
   - At least 2 members in a group
   - Admin with wizard completed
   - Some expenses recorded

### Testing Steps

1. **Baseline Setup** (Month 1):
   ```dart
   // January 2026
   - Admin completes wizard
   - Set Category "Cibo": €200
   - Set Category "Utenze": €150
   - Member A: 40%, Member B: 60%
   - Add expense: €50 to "Cibo"
   ```

2. **Month Transition** (Month 1 → Month 2):
   ```dart
   // Advance date to February 1, 2026
   - Restart app
   - Verify monthly reset triggered
   - Check February budget created
   - Verify January data preserved
   ```

3. **Historical Query**:
   ```sql
   -- Query all months
   SELECT year, month, category_id, amount, spent_cents
   FROM category_budgets
   WHERE group_id = 'test-group-id'
   ORDER BY year, month, category_id;
   ```

4. **Verify Data Integrity**:
   - No duplicate entries for same month
   - Budget amounts consistent across months (unless modified)
   - Spent amounts correctly reset each month
   - Historical spent amounts unchanged

---

## Expected Database Structure

### category_budgets Table (Historical Data)

```
| year | month | category_id | amount | spent_cents | user_id  | percentage |
|------|-------|-------------|--------|-------------|----------|------------|
| 2026 | 1     | cibo-id     | 20000  | 5000        | NULL     | NULL       |
| 2026 | 1     | cibo-id     | 20000  | 2000        | userA-id | 40.00      |
| 2026 | 1     | cibo-id     | 20000  | 3000        | userB-id | 60.00      |
| 2026 | 2     | cibo-id     | 20000  | 0           | NULL     | NULL       |
| 2026 | 2     | cibo-id     | 20000  | 0           | userA-id | 40.00      |
| 2026 | 2     | cibo-id     | 20000  | 0           | userB-id | 60.00      |
```

---

## Success Criteria

✅ **Pass** if:
- Historical data is preserved across month transitions
- Budget configurations copy correctly to new months
- Spent amounts reset to 0 each month
- No data loss or corruption
- Budget history is queryable for reporting
- Year transitions work correctly

❌ **Fail** if:
- Historical data is overwritten
- Budget configurations lost during transition
- Spent amounts don't reset
- Data corruption or missing records
- Year/month calculations incorrect

---

## Automation Opportunities

For future automation:

1. **Integration Test with Date Mocking**:
   ```dart
   testWidgets('Monthly reset preserves historical data', (tester) async {
     // Mock clock to return February 1, 2026
     // Trigger monthly reset
     // Query database for both months
     // Verify data integrity
   });
   ```

2. **Database Trigger Test**:
   ```sql
   -- Test SQL function
   SELECT perform_monthly_reset('user-id', 'group-id', 2026, 2);
   ```

3. **Scheduled Job Testing**:
   - Run monthly reset job on test data
   - Verify output matches expected structure

---

## Notes

- **Manual Testing Required**: T068 is flagged as manual test due to date/time dependency
- **Data Safety**: Always test on development/staging environment first
- **Backup**: Create database backup before month transition tests
- **Restore**: Keep SQL scripts to restore test data between test runs
