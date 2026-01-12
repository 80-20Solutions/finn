# User Story 2 Backend Integration

## Tasks T055-T056: Backend RPC Functions and RLS Policies

### T055: Create get_group_spending_breakdown RPC Function

**Location**: Create new migration file `supabase/migrations/062_user_story_2_rpc_functions.sql`

```sql
-- RPC function to get group spending breakdown for a member
CREATE OR REPLACE FUNCTION get_group_spending_breakdown(
  p_user_id UUID,
  p_group_id UUID,
  p_year INT,
  p_month INT
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
  v_member_percentage NUMERIC(5,2);
BEGIN
  -- Get member's allocation percentage
  SELECT percentage_of_group INTO v_member_percentage
  FROM profiles
  WHERE id = p_user_id
    AND group_id = p_group_id;

  -- If no percentage found, return error
  IF v_member_percentage IS NULL THEN
    RAISE EXCEPTION 'Member allocation not found for user % in group %', p_user_id, p_group_id;
  END IF;

  -- Build result JSON with subcategories
  SELECT json_build_object(
    'total_allocated_cents', (
      SELECT COALESCE(SUM(
        ROUND((cb.amount * v_member_percentage / 100.0)::NUMERIC, 0)
      ), 0)
      FROM category_budgets cb
      WHERE cb.group_id = p_group_id
        AND cb.year = p_year
        AND cb.month = p_month
        AND cb.is_group_budget = TRUE
    ),
    'total_spent_cents', (
      SELECT COALESCE(SUM(e.amount_cents), 0)
      FROM expenses e
      WHERE e.group_id = p_group_id
        AND e.user_id = p_user_id
        AND e.is_group_expense = TRUE
        AND EXTRACT(YEAR FROM e.expense_date) = p_year
        AND EXTRACT(MONTH FROM e.expense_date) = p_month
    ),
    'sub_categories', (
      SELECT COALESCE(json_agg(json_build_object(
        'category_id', cb.category_id,
        'category_name', ec.name_it,
        'allocated_cents', ROUND((cb.amount * v_member_percentage / 100.0)::NUMERIC, 0),
        'spent_cents', COALESCE((
          SELECT SUM(e.amount_cents)
          FROM expenses e
          WHERE e.group_id = p_group_id
            AND e.user_id = p_user_id
            AND e.category_id = cb.category_id
            AND e.is_group_expense = TRUE
            AND EXTRACT(YEAR FROM e.expense_date) = p_year
            AND EXTRACT(MONTH FROM e.expense_date) = p_month
        ), 0),
        'icon', ec.icon,
        'color', ec.color
      ) ORDER BY ec.name_it ASC), '[]'::json)
      FROM category_budgets cb
      JOIN expense_categories ec ON ec.id = cb.category_id
      WHERE cb.group_id = p_group_id
        AND cb.year = p_year
        AND cb.month = p_month
        AND cb.is_group_budget = TRUE
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_group_spending_breakdown(UUID, UUID, INT, INT) TO authenticated;
```

---

### T056: Verify RLS Policies for Member Read-Only Access

**Location**: Same migration file `supabase/migrations/062_user_story_2_rpc_functions.sql`

```sql
-- RLS Policy: Allow group members to read group category budgets
CREATE POLICY "Members can read group category budgets"
ON category_budgets
FOR SELECT
USING (
  is_group_budget = TRUE
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.group_id = category_budgets.group_id
  )
);

-- RLS Policy: Allow group members to read their own group expenses
CREATE POLICY "Members can read their group expenses"
ON expenses
FOR SELECT
USING (
  is_group_expense = TRUE
  AND user_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.group_id = expenses.group_id
  )
);

-- RLS Policy: Allow group members to read expense categories
-- (This should already exist, but verify it allows all members)
CREATE POLICY IF NOT EXISTS "Members can read expense categories"
ON expense_categories
FOR SELECT
USING (
  is_system = TRUE
  OR EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.group_id = expense_categories.group_id
  )
);
```

---

## Implementation Notes

### Member Percentage Calculation

The member's allocated budget for each category is calculated as:
```
allocated_cents = ROUND((group_budget_amount * member_percentage / 100.0), 0)
```

For example:
- Group budget for "Cibo": €200 (20000 cents)
- Member percentage: 35%
- Member allocated: €70 (7000 cents)

### Spent Amount Calculation

The member's spent amount is the sum of all their expenses marked as `is_group_expense = TRUE` for the specified category, year, and month.

### Zero Spent Handling

If no expenses exist for a category, `COALESCE` ensures the spent amount returns 0 instead of NULL.

### RLS Security

- Members can only read group-level category budgets (not personal budgets of other members)
- Members can only read their own group expenses
- The RPC function uses `SECURITY DEFINER` to query across tables with proper authorization

---

## Testing Checklist

- [ ] Member can see "Spesa Gruppo" category in personal budget view
- [ ] Member can expand to see subcategories
- [ ] Member's allocated amounts correctly reflect their percentage
- [ ] Member's spent amounts correctly sum their group expenses
- [ ] Progress indicators show correct percentages
- [ ] Read-only lock icon is displayed
- [ ] Member cannot edit group budget allocations
- [ ] RLS policies prevent unauthorized access
- [ ] Zero spending shows as 0,00 € (not NULL or error)
- [ ] Category icons and colors display correctly

---

## Implementation Status

- ✅ T044-T054: Frontend implementation complete (tests, entities, widgets, screens)
- [ ] T055: RPC function needs to be applied to Supabase
- [ ] T056: RLS policies need to be verified/created

---

## Next Steps

1. **Apply Migration**: Create and run migration file `062_user_story_2_rpc_functions.sql`
2. **Test RPC Function**: Use Supabase SQL editor to test `get_group_spending_breakdown` with sample data
3. **Verify RLS Policies**: Check policy coverage for category_budgets, expenses, and expense_categories tables
4. **Wire Up Repository**: Implement PersonalBudgetRepository with Supabase client
5. **End-to-End Test**: Run integration test `member_budget_view_test.dart`
