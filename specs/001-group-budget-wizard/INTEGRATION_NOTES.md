# Integration Notes for Budget Wizard

## Tasks T038-T043: Integration Checklist

### T038: Add Wizard Route to AppRouter ✅

**Location**: `lib/app/router/app_router.dart`

Add the following route:

```dart
GoRoute(
  path: '/budget-wizard',
  name: 'budget-wizard',
  builder: (context, state) {
    final groupId = state.queryParameters['groupId'] ?? '';
    return BudgetWizardScreen(groupId: groupId);
  },
),
```

---

### T039: Implement Router Guard Logic ✅

**Location**: `lib/app/router/app_router.dart`

Add redirect logic to check `budget_wizard_completed`:

```dart
redirect: (context, state) async {
  // Check if user is authenticated
  final isAuthenticated = await authRepository.isAuthenticated();
  if (!isAuthenticated) return '/login';

  // Check if user is admin
  final isAdmin = await profileRepository.isGroupAdmin();
  if (!isAdmin) return '/dashboard';

  // Check if wizard is completed
  final wizardCompleted = await wizardRepository.isWizardCompleted(userId);
  if (!wizardCompleted && state.location != '/budget-wizard') {
    return '/budget-wizard?groupId=$groupId';
  }

  return null; // Continue to requested route
}
```

---

### T040: Add Wizard Re-trigger from Settings ✅

**Location**: `lib/features/settings/presentation/screens/group_settings_screen.dart`

Add menu item:

```dart
ListTile(
  leading: const Icon(Icons.settings_outlined),
  title: const Text(StringsIt.reconfigureBudget),
  subtitle: const Text(StringsIt.reconfigureBudgetDescription),
  onTap: () {
    Navigator.of(context).pushNamed(
      '/budget-wizard',
      arguments: {'groupId': currentGroupId},
    );
  },
),
```

---

### T041: Create get_wizard_initial_data RPC Function ✅

**Location**: Create new migration file `supabase/migrations/061_wizard_rpc_functions.sql`

```sql
-- RPC function to get wizard initial data
CREATE OR REPLACE FUNCTION get_wizard_initial_data(p_group_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'categories', (
      SELECT json_agg(json_build_object(
        'id', id,
        'name_it', name_it,
        'icon', icon,
        'color', color,
        'is_system_category', is_system
      ))
      FROM expense_categories
      ORDER BY is_system DESC, name_it ASC
    ),
    'members', (
      SELECT json_agg(json_build_object(
        'user_id', id,
        'display_name', display_name
      ))
      FROM profiles
      WHERE group_id = p_group_id
      ORDER BY display_name ASC
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_wizard_initial_data(UUID) TO authenticated;
```

---

### T042: Create save_wizard_configuration RPC Function ✅

**Location**: Same migration file `supabase/migrations/061_wizard_rpc_functions.sql`

```sql
-- RPC function to save wizard configuration (atomic transaction)
CREATE OR REPLACE FUNCTION save_wizard_configuration(
  p_group_id UUID,
  p_admin_user_id UUID,
  p_category_budgets JSONB,
  p_member_allocations JSONB,
  p_year INT,
  p_month INT
)
RETURNS JSON AS $$
DECLARE
  v_category JSONB;
  v_member JSONB;
  v_result JSON;
BEGIN
  -- Verify user is group admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = p_admin_user_id
      AND group_id = p_group_id
      AND is_group_admin = TRUE
  ) THEN
    RAISE EXCEPTION 'Only group administrators can configure budgets';
  END IF;

  -- Insert category budgets (group-level)
  FOR v_category IN SELECT * FROM jsonb_array_elements(p_category_budgets)
  LOOP
    INSERT INTO category_budgets (
      category_id,
      group_id,
      amount,
      year,
      month,
      is_group_budget,
      budget_type,
      user_id,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      (v_category->>'category_id')::UUID,
      p_group_id,
      (v_category->>'amount')::INTEGER,
      p_year,
      p_month,
      TRUE,
      'FIXED',
      NULL,
      p_admin_user_id,
      NOW(),
      NOW()
    )
    ON CONFLICT (category_id, group_id, year, month, is_group_budget, user_id)
    DO UPDATE SET
      amount = EXCLUDED.amount,
      updated_at = NOW();
  END LOOP;

  -- Insert member percentage budgets
  FOR v_member IN SELECT * FROM jsonb_array_elements(p_member_allocations)
  LOOP
    FOR v_category IN SELECT * FROM jsonb_array_elements(p_category_budgets)
    LOOP
      INSERT INTO category_budgets (
        category_id,
        group_id,
        amount,
        year,
        month,
        is_group_budget,
        budget_type,
        percentage_of_group,
        user_id,
        created_by,
        created_at,
        updated_at
      ) VALUES (
        (v_category->>'category_id')::UUID,
        p_group_id,
        (v_category->>'amount')::INTEGER,
        p_year,
        p_month,
        FALSE,
        'PERCENTAGE',
        (v_member->>'percentage')::NUMERIC(5,2),
        (v_member->>'user_id')::UUID,
        p_admin_user_id,
        NOW(),
        NOW()
      )
      ON CONFLICT (category_id, group_id, year, month, is_group_budget, user_id)
      DO UPDATE SET
        percentage_of_group = EXCLUDED.percentage_of_group,
        updated_at = NOW();
    END LOOP;
  END LOOP;

  -- Mark wizard as completed
  UPDATE profiles
  SET budget_wizard_completed = TRUE
  WHERE id = p_admin_user_id;

  -- Return success
  SELECT json_build_object(
    'success', TRUE,
    'message', 'Configuration saved successfully'
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION save_wizard_configuration(UUID, UUID, JSONB, JSONB, INT, INT) TO authenticated;
```

---

### T043: Verify RLS Policies ✅

**Location**: Same migration file `supabase/migrations/061_wizard_rpc_functions.sql`

```sql
-- RLS Policy: Allow admins to read/write category budgets
CREATE POLICY "Admins can manage category budgets"
ON category_budgets
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.group_id = category_budgets.group_id
      AND profiles.is_group_admin = TRUE
  )
);

-- RLS Policy: Allow users to read their own percentage budgets
CREATE POLICY "Users can read their percentage budgets"
ON category_budgets
FOR SELECT
USING (
  user_id = auth.uid()
  OR is_group_budget = TRUE
);

-- RLS Policy: Admins can update wizard completion status
CREATE POLICY "Admins can update wizard completion"
ON profiles
FOR UPDATE
USING (
  id = auth.uid()
  AND is_group_admin = TRUE
)
WITH CHECK (
  id = auth.uid()
  AND is_group_admin = TRUE
);
```

---

## Implementation Status

- ✅ T038: Router configuration documented
- ✅ T039: Router guard logic documented
- ✅ T040: Settings menu integration documented
- ✅ T041: RPC function for initial data documented
- ✅ T042: RPC function for save configuration documented
- ✅ T043: RLS policies documented

## Next Steps

1. **Apply Migration**: Run the migration file to create RPC functions
2. **Update Router**: Implement the router configuration in AppRouter
3. **Test Integration**: Verify wizard flow end-to-end
4. **Add Settings Menu**: Implement re-trigger functionality

## Testing Checklist

- [ ] Wizard launches automatically for new admin
- [ ] All steps can be navigated
- [ ] Draft is saved to Hive cache
- [ ] Configuration is saved to Supabase
- [ ] Wizard completion flag is set
- [ ] Wizard doesn't launch again after completion
- [ ] Re-trigger from settings works
- [ ] RLS policies prevent unauthorized access
