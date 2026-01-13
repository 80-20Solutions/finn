# Quickstart Guide: Personal and Group Budget Setup

**Feature**: 001-personal-group-budget
**Date**: 2026-01-12
**Target**: Developers implementing the personal/group budget feature

This guide provides step-by-step instructions for setting up the database schema, generating Drift tables, and running initial tests.

---

## Prerequisites

- Supabase project with existing `users` and `family_groups` tables
- Flutter project with `drift`, `supabase_flutter`, and `build_runner` dependencies
- PostgreSQL admin access for running migrations

---

## Step 1: Database Schema Migrations

### 1.1 Create Income Sources Table

```sql
-- Migration: 001_create_income_sources_table
CREATE TABLE income_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('salary', 'freelance', 'investment', 'other', 'custom')),
  custom_type_name VARCHAR(100),
  amount BIGINT NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_income_sources_user_id ON income_sources(user_id);
CREATE INDEX idx_income_sources_user_created ON income_sources(user_id, created_at DESC);

-- RLS Policies (Row-Level Security)
ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own income sources"
  ON income_sources FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own income sources"
  ON income_sources FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own income sources"
  ON income_sources FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own income sources"
  ON income_sources FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_income_sources_updated_at
  BEFORE UPDATE ON income_sources
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 1.2 Create Savings Goals Table

```sql
-- Migration: 002_create_savings_goals_table
CREATE TABLE savings_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL CHECK (amount >= 0),
  original_amount BIGINT CHECK (original_amount >= 0),
  adjusted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Index
CREATE INDEX idx_savings_goals_user_id ON savings_goals(user_id);

-- RLS Policies
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own savings goal"
  ON savings_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own savings goal"
  ON savings_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own savings goal"
  ON savings_goals FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own savings goal"
  ON savings_goals FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_savings_goals_updated_at
  BEFORE UPDATE ON savings_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 1.3 Create Group Expense Assignments Table

```sql
-- Migration: 003_create_group_expense_assignments_table
CREATE TABLE group_expense_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  spending_limit BIGINT NOT NULL CHECK (spending_limit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Indexes
CREATE INDEX idx_group_expense_assignments_user ON group_expense_assignments(user_id);
CREATE INDEX idx_group_expense_assignments_group ON group_expense_assignments(group_id);

-- RLS Policies
ALTER TABLE group_expense_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own assignments"
  ON group_expense_assignments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Group admins can manage assignments"
  ON group_expense_assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM family_groups
      WHERE family_groups.id = group_expense_assignments.group_id
      AND family_groups.admin_id = auth.uid()
    )
  );

-- Trigger for updated_at
CREATE TRIGGER update_group_expense_assignments_updated_at
  BEFORE UPDATE ON group_expense_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 1.4 Run Migrations

**In Supabase Dashboard**:
1. Navigate to SQL Editor
2. Create new query
3. Paste each migration script above
4. Execute in order (001 → 002 → 003)

**Via Supabase CLI** (if using migrations locally):
```bash
supabase migration new create_budget_tables
# Paste all three migrations into the generated file
supabase db push
```

---

## Step 2: Drift Local Database Setup

### 2.1 Define Drift Tables

Create files in `lib/core/database/drift/tables/`:

**`income_sources_table.dart`**:
```dart
import 'package:drift/drift.dart';

@DataClassName('IncomeSourceData')
class IncomeSources extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => textEnum<IncomeType>()();
  TextColumn get customTypeName => text().nullable()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

enum IncomeType {
  salary,
  freelance,
  investment,
  other,
  custom,
}
```

**`savings_goals_table.dart`**:
```dart
import 'package:drift/drift.dart';

@DataClassName('SavingsGoalData')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get amount => integer()();
  IntColumn get originalAmount => integer().nullable()();
  DateTimeColumn get adjustedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**`group_expense_assignments_table.dart`**:
```dart
import 'package:drift/drift.dart';

@DataClassName('GroupExpenseAssignmentData')
class GroupExpenseAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  IntColumn get spendingLimit => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 2.2 Update Drift Database Definition

Add tables to your main database file (e.g., `lib/core/database/app_database.dart`):

```dart
import 'package:drift/drift.dart';
import 'tables/income_sources_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/group_expense_assignments_table.dart';

@DriftDatabase(tables: [
  // ... existing tables
  IncomeSources,
  SavingsGoals,
  GroupExpenseAssignments,
])
class AppDatabase extends _$AppDatabase {
  // ... existing configuration
}
```

### 2.3 Generate Drift Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `app_database.g.dart` with table classes and DAOs
- Type-safe query builders

---

## Step 3: Create Data Access Objects (DAOs)

Create `lib/features/budgets/data/datasources/budget_local_datasource.dart`:

```dart
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [IncomeSources, SavingsGoals, GroupExpenseAssignments])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(AppDatabase db) : super(db);

  // Income Sources
  Future<List<IncomeSourceData>> getIncomeSources(String userId) =>
      (select(incomeSources)..where((t) => t.userId.equals(userId))).get();

  Future<int> insertIncomeSource(IncomeSourceData source) =>
      into(incomeSources).insert(source);

  Future<bool> updateIncomeSource(IncomeSourceData source) =>
      update(incomeSources).replace(source);

  Future<int> deleteIncomeSource(String id) =>
      (delete(incomeSources)..where((t) => t.id.equals(id))).go();

  // Savings Goals
  Future<SavingsGoalData?> getSavingsGoal(String userId) =>
      (select(savingsGoals)..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Future<int> upsertSavingsGoal(SavingsGoalData goal) =>
      into(savingsGoals).insertOnConflictUpdate(goal);

  // Group Expense Assignments
  Future<GroupExpenseAssignmentData?> getGroupExpenseAssignment(String userId) =>
      (select(groupExpenseAssignments)..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();
}
```

---

## Step 4: Run Initial Tests

### 4.1 Test Database Connectivity

```bash
flutter test test/core/database/drift_database_test.dart
```

### 4.2 Test Supabase Schema

Create `test/features/budgets/integration/supabase_schema_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient supabase;

  setUpAll(() async {
    await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
    supabase = Supabase.instance.client;
  });

  test('income_sources table exists and is accessible', () async {
    // Insert test data
    final response = await supabase.from('income_sources').insert({
      'user_id': supabase.auth.currentUser!.id,
      'type': 'salary',
      'amount': 100000,
    }).select();

    expect(response, isNotEmpty);
  });

  // Similar tests for savings_goals and group_expense_assignments
}
```

Run:
```bash
flutter test test/features/budgets/integration/supabase_schema_test.dart
```

---

## Step 5: Verify Setup

### Checklist:

- [ ] Supabase tables created (income_sources, savings_goals, group_expense_assignments)
- [ ] RLS policies enabled and tested
- [ ] Drift tables generated (`.g.dart` files exist)
- [ ] DAOs created and can query/insert data
- [ ] Integration tests pass
- [ ] Sample data can be inserted/retrieved from both Supabase and Drift

### Sample Data for Testing:

```sql
-- Insert test income source (replace USER_ID with actual UUID)
INSERT INTO income_sources (user_id, type, amount)
VALUES ('USER_ID', 'salary', 250000);

-- Insert test savings goal
INSERT INTO savings_goals (user_id, amount)
VALUES ('USER_ID', 50000);

-- Query budget summary
SELECT
  (SELECT COALESCE(SUM(amount), 0) FROM income_sources WHERE user_id = 'USER_ID') AS total_income,
  (SELECT COALESCE(amount, 0) FROM savings_goals WHERE user_id = 'USER_ID') AS savings_goal,
  (SELECT COALESCE(spending_limit, 0) FROM group_expense_assignments WHERE user_id = 'USER_ID') AS group_expenses;
```

---

## Step 6: Next Steps

After setup is complete:

1. **Run `/speckit.tasks`** to generate implementation tasks
2. **Implement use cases** (setup_personal_budget, add_income_source, etc.)
3. **Create Riverpod providers** for state management
4. **Build UI screens** (wizard flow, summary, management)
5. **Write tests** (unit for use cases, widget for UI, integration for flow)

---

## Troubleshooting

### Issue: RLS policies blocking access

**Solution**: Ensure user is authenticated before querying. Check `auth.uid()` matches `user_id`.

```dart
final user = supabase.auth.currentUser;
if (user == null) throw Exception('User not authenticated');
```

### Issue: Drift code generation fails

**Solution**: Run with `--delete-conflicting-outputs`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Issue: Foreign key constraint violation

**Solution**: Ensure referenced tables exist first. Check `users` and `family_groups` tables are populated.

---

## Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Riverpod Code Generation](https://riverpod.dev/docs/concepts/about_code_generation)
- Feature spec: `specs/001-personal-group-budget/spec.md`
- Data model: `specs/001-personal-group-budget/data-model.md`

---

**Setup Complete!** You're now ready to implement the personal and group budget management feature.
