# User Story 3 Backend Integration

## Task T064: Backend RPC Function for Personal Budget Calculation

###T064: Modify get_personal_budget RPC Function

**Location**: Create new migration file `supabase/migrations/063_user_story_3_rpc_functions.sql`

```sql
-- RPC function to calculate personal budget including group allocation
CREATE OR REPLACE FUNCTION get_personal_budget(
  p_user_id UUID,
  p_group_id UUID,
  p_year INT,
  p_month INT
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
  v_member_percentage NUMERIC(5,2);
  v_personal_budget_cents INT;
  v_group_allocation_cents INT;
  v_personal_spent_cents INT;
  v_group_spent_cents INT;
BEGIN
  -- Get member's allocation percentage
  SELECT percentage_of_group INTO v_member_percentage
  FROM profiles
  WHERE id = p_user_id
    AND group_id = p_group_id;

  -- If no percentage found, default to 0 (member not in wizard)
  IF v_member_percentage IS NULL THEN
    v_member_percentage := 0;
  END IF;

  -- Calculate personal budget (sum of all personal category budgets)
  SELECT COALESCE(SUM(cb.amount), 0) INTO v_personal_budget_cents
  FROM category_budgets cb
  WHERE cb.user_id = p_user_id
    AND cb.group_id = p_group_id
    AND cb.year = p_year
    AND cb.month = p_month
    AND cb.is_group_budget = FALSE;

  -- Calculate group allocation (member's percentage of total group budget)
  SELECT COALESCE(SUM(
    ROUND((cb.amount * v_member_percentage / 100.0)::NUMERIC, 0)
  ), 0) INTO v_group_allocation_cents
  FROM category_budgets cb
  WHERE cb.group_id = p_group_id
    AND cb.year = p_year
    AND cb.month = p_month
    AND cb.is_group_budget = TRUE;

  -- Calculate personal spent
  SELECT COALESCE(SUM(e.amount_cents), 0) INTO v_personal_spent_cents
  FROM expenses e
  WHERE e.user_id = p_user_id
    AND e.group_id = p_group_id
    AND e.is_group_expense = FALSE
    AND EXTRACT(YEAR FROM e.expense_date) = p_year
    AND EXTRACT(MONTH FROM e.expense_date) = p_month;

  -- Calculate group spent
  SELECT COALESCE(SUM(e.amount_cents), 0) INTO v_group_spent_cents
  FROM expenses e
  WHERE e.user_id = p_user_id
    AND e.group_id = p_group_id
    AND e.is_group_expense = TRUE
    AND EXTRACT(YEAR FROM e.expense_date) = p_year
    AND EXTRACT(MONTH FROM e.expense_date) = p_month;

  -- Build result JSON
  SELECT json_build_object(
    'user_id', p_user_id,
    'group_id', p_group_id,
    'year', p_year,
    'month', p_month,
    'personal_budget_cents', v_personal_budget_cents,
    'group_allocation_cents', v_group_allocation_cents,
    'total_budget_cents', v_personal_budget_cents + v_group_allocation_cents,
    'personal_spent_cents', v_personal_spent_cents,
    'group_spent_cents', v_group_spent_cents,
    'total_spent_cents', v_personal_spent_cents + v_group_spent_cents
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_personal_budget(UUID, UUID, INT, INT) TO authenticated;
```

---

## Calculation Logic

### Budget Calculation

The total budget is the sum of:
1. **Personal Budget**: Sum of all category budgets where `is_group_budget = FALSE` and `user_id = p_user_id`
2. **Group Allocation**: Member's percentage of total group budget

Formula:
```
group_allocation_cents = SUM(group_category_budget * member_percentage / 100.0)
total_budget_cents = personal_budget_cents + group_allocation_cents
```

### Spent Calculation

The total spent is the sum of:
1. **Personal Spent**: Sum of expenses where `is_group_expense = FALSE`
2. **Group Spent**: Sum of expenses where `is_group_expense = TRUE`

Formula:
```
total_spent_cents = personal_spent_cents + group_spent_cents
```

### Accuracy Requirements (SC-003)

To ensure zero calculation errors:
- Use `ROUND((amount * percentage / 100.0)::NUMERIC, 0)` for integer cents precision
- Always use INTEGER cents (not DECIMAL euros) for storage and calculation
- Sum first, then format for display (never format intermediate values)

### Example

Given:
- Personal budget: €200 (20000 cents)
- Group budget total: €1000 (100000 cents)
- Member percentage: 35%
- Personal spent: €150 (15000 cents)
- Group spent: €250 (25000 cents)

Calculation:
```
group_allocation_cents = ROUND((100000 * 35 / 100.0), 0) = 35000
total_budget_cents = 20000 + 35000 = 55000 (€550)
total_spent_cents = 15000 + 25000 = 40000 (€400)
remaining_cents = 55000 - 40000 = 15000 (€150)
percentage_spent = 40000 / 55000 = 72.7%
```

---

## Testing Checklist

- [ ] Personal budget correctly sums all personal category budgets
- [ ] Group allocation correctly calculates member's percentage of group budget
- [ ] Total budget equals personal + group (exact, no rounding errors)
- [ ] Personal spent correctly sums non-group expenses
- [ ] Group spent correctly sums group expenses
- [ ] Total spent equals personal spent + group spent
- [ ] Zero rounding errors (SC-003) - test with various percentages (33.33%, 66.67%, etc.)
- [ ] Handles zero personal budget with group allocation
- [ ] Handles zero group allocation with personal budget
- [ ] Updates correctly when admin changes member percentage

---

## Implementation Status

- ✅ T057-T063: Frontend implementation complete (tests, entity, use case, provider, screen)
- [ ] T064: RPC function needs to be applied to Supabase

---

## Next Steps

1. **Apply Migration**: Create and run migration file `063_user_story_3_rpc_functions.sql`
2. **Test RPC Function**: Use Supabase SQL editor to test `get_personal_budget` with sample data
3. **Wire Up Repository**: Implement PersonalBudgetRepository with Supabase client
4. **Verify Calculation Accuracy**: Test with edge cases (zero budgets, unusual percentages)
5. **End-to-End Test**: Run integration test `budget_calculation_test.dart`
6. **Verify Budget Updates**: Test that budget updates when admin changes allocation percentage

---

## Notes

### Zero Budget Handling

If a member has:
- No personal budget + no group allocation → Total = €0
- Personal budget only → Total = Personal
- Group allocation only → Total = Group
- Both → Total = Personal + Group

### Member Not in Wizard

If `percentage_of_group` is NULL (member not yet allocated in wizard):
- Group allocation = €0
- Total = Personal budget only
- Member can still use personal budgets independently
