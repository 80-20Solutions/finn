# Research: Italian Categories and Budget Management

**Feature**: 004-italian-categories-budgeting
**Date**: 2026-01-04
**Status**: Phase 0 Complete

## Overview

This document captures technical research and decision-making for implementing monthly category budgets with Italian localization. All recommendations leverage existing architectural patterns from the codebase.

---

## 1. Database Schema for Monthly Budget Tracking

### Decision

**Separate budget tables with materialized monthly stats**

Create new `category_budgets` table following the existing pattern from `group_budgets` (migration 011) and `personal_budgets` (migration 012).

### Rationale

1. **Performance**: Existing pattern demonstrates ~1000 expenses can be efficiently aggregated on-demand using indexed date range queries
2. **Consistency**: Matches current architecture - budget allocations stored separately from spending calculations
3. **Scalability**: Month-based indexes optimize "current month spending" queries without denormalization complexity

### Implementation

**Table Schema** (migration `026_category_budgets_table.sql`):

```sql
CREATE TABLE IF NOT EXISTS public.category_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.expense_categories(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),  -- Stored in cents
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(category_id, group_id, year, month)
);

CREATE INDEX idx_category_budgets_lookup
  ON public.category_budgets(group_id, category_id, year, month);

CREATE INDEX idx_category_budgets_current_month
  ON public.category_budgets(group_id, year, month);
```

**Optimized Index for Category-Month Queries**:

```sql
CREATE INDEX idx_expenses_category_month
  ON public.expenses(category_id, group_id, date)
  WHERE category_id IS NOT NULL;
```

**Query Pattern** (Dart - following `budget_remote_datasource.dart:163-173`):

```dart
Future<int> getCurrentMonthSpending({
  required String categoryId,
  required String groupId,
  required int year,
  required int month,
}) async {
  final monthStart = TimezoneHandler.getMonthStart(year, month);
  final monthEnd = TimezoneHandler.getMonthEnd(year, month);

  final response = await supabaseClient
      .from('expenses')
      .select('amount')
      .eq('group_id', groupId)
      .eq('category_id', categoryId)
      .gte('date', monthStart.toIso8601String().split('T')[0])
      .lte('date', monthEnd.toIso8601String().split('T')[0]);

  final amounts = (response as List).map((e) => (e['amount'] as int)).toList();
  return amounts.fold(0, (sum, amount) => sum + amount);
}
```

### Alternatives Considered

- **Materialized View**: Rejected - adds refresh logic complexity, unnecessary for target scale
- **Denormalized "current_spent" column**: Rejected - requires triggers on every expense, increases write overhead
- **JSONB monthly history**: Rejected - harder to query, doesn't leverage PostgreSQL indexing

---

## 2. Per-User Category Usage Tracking (Virgin Category Detection)

### Decision

**Junction table with compound unique constraint**

Create `user_category_usage` table to track first-time category usage per user.

### Rationale

1. **Performance**: O(log n) lookup with compound index on (user_id, category_id)
2. **Data Integrity**: Foreign key constraints with `ON DELETE CASCADE` handle cleanup
3. **Simplicity**: Simple EXISTS query for virgin check, single INSERT to mark used
4. **Scale**: ~10 users × ~10 categories = ~100 rows per group (trivial for PostgreSQL)

### Implementation

**Table Schema** (migration `027_user_category_usage_table.sql`):

```sql
CREATE TABLE IF NOT EXISTS public.user_category_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.expense_categories(id) ON DELETE CASCADE,
  first_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(user_id, category_id)
);

CREATE INDEX idx_user_category_usage_lookup
  ON public.user_category_usage(user_id, category_id);
```

**Repository Methods** (Dart):

```dart
/// Check if user has used category before (virgin detection)
Future<bool> hasUserUsedCategory({
  required String userId,
  required String categoryId,
}) async {
  final response = await supabaseClient
      .from('user_category_usage')
      .select('id')
      .eq('user_id', userId)
      .eq('category_id', categoryId)
      .maybeSingle();

  return response != null;
}

/// Mark category as used (called after first expense in category)
Future<void> markCategoryAsUsed({
  required String userId,
  required String categoryId,
}) async {
  await supabaseClient
      .from('user_category_usage')
      .insert({
        'user_id': userId,
        'category_id': categoryId,
      })
      .onConflict('user_id,category_id')  // Ignore duplicates
      .select();
}
```

### Alternatives Considered

- **JSONB array in profiles table**: Rejected - no referential integrity, poor query performance
- **Check expense history on-demand**: Rejected - full table scan, doesn't scale beyond 1000s expenses
- **Bitmap in categories table**: Rejected - fixed user limit, complex bit operations

---

## 3. Orphaned Expense Handling: Bulk Re-categorization UI

### Decision

**Multi-select with bottom action sheet**

Long-press to enter selection mode, bottom sheet with category picker for batch updates.

### Rationale

1. **Familiar Pattern**: Standard Android/iOS multi-select UX (Gmail, Google Photos)
2. **Existing Infrastructure**: Reuses `batch_update_expense_category` RPC (migration 018)
3. **Transaction Safety**: Single RPC call = single database transaction (all-or-nothing)
4. **Scalability**: Handles 100+ orphaned expenses efficiently

### Implementation

**UI Flow**:

1. User long-presses expense → enters selection mode
2. Checkboxes appear, user taps to select multiple expenses
3. Bottom sheet shows "Assegna categoria" button
4. Tap button → category picker modal
5. Select category → batch RPC updates all selected expenses
6. Show progress indicator during update, SnackBar on completion

**New RPC Function** (`028_batch_reassign_orphaned.sql`):

```sql
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
  UPDATE public.expenses
  SET
    category_id = p_new_category_id,
    updated_at = NOW()
  WHERE id = ANY(p_expense_ids)
    AND category_id IS NULL;  -- Safety: only update orphaned

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN v_updated_count;
END;
$$;
```

**Key Widget State**:

```dart
class _OrphanedExpensesScreenState extends ConsumerState {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;

  // Long-press handler
  void _enterSelectionMode(String expenseId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(expenseId);
    });
  }

  // Batch update handler
  Future<void> _batchUpdateCategory(String categoryId) async {
    setState(() => _isProcessing = true);
    try {
      final count = await supabaseClient.rpc(
        'batch_reassign_orphaned_expenses',
        params: {
          'p_expense_ids': _selectedIds.toList(),
          'p_new_category_id': categoryId,
        },
      );
      // Show success SnackBar
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
```

### Alternatives Considered

- **Swipe gesture per item**: Rejected - tedious for 100+ items
- **Inline dropdown per row**: Rejected - cluttered UI, many network calls
- **Wizard flow**: Rejected - over-engineered

---

## 4. Monthly Budget Reset Strategy

### Decision

**Application-level query logic (no reset mechanism)**

Budget "reset" is implicit: each month is a separate record (year + month columns). Queries filter by current month.

### Rationale

1. **Existing Pattern**: Already implemented correctly in `budget_remote_datasource.dart` for group/personal budgets
2. **Simplicity**: No cron jobs, triggers, or background workers
3. **Timezone Safety**: Existing `TimezoneHandler` class handles month boundaries using `tz.local`
4. **Historical Data**: Keeping all months enables budget trend analysis

### Implementation

**How It Works**:

Budget amounts are stored per month. Spending is calculated by filtering expenses within month date range:

```dart
// Get current month stats (automatically "resets" when month changes)
Future<BudgetStatsModel> getCategoryBudgetStats({
  required String categoryId,
  required int year,
  required int month,
}) async {
  // 1. Get budget allocation for this month
  final budget = await supabaseClient
      .from('category_budgets')
      .select()
      .eq('category_id', categoryId)
      .eq('year', year)
      .eq('month', month)
      .maybeSingle();

  // 2. Get month boundaries (timezone-aware)
  final monthStart = TimezoneHandler.getMonthStart(year, month);
  final monthEnd = TimezoneHandler.getMonthEnd(year, month);

  // 3. Get spending for this month only
  final expenses = await supabaseClient
      .from('expenses')
      .select('amount')
      .eq('category_id', categoryId)
      .gte('date', monthStart.toIso8601String().split('T')[0])
      .lte('date', monthEnd.toIso8601String().split('T')[0]);

  // 4. Calculate stats
  final totalSpent = expenses.fold(0, (sum, e) => sum + e['amount']);
  return BudgetStatsModel(
    allocated: budget?['amount'] ?? 0,
    spent: totalSpent,
    remaining: (budget?['amount'] ?? 0) - totalSpent,
  );
}
```

**Timezone Handling** (existing in `timezone_handler.dart:38-59`):

```dart
static DateTime getMonthStart(int year, int month) {
  return tz.TZDateTime(
    tz.local,  // User's device timezone
    year,
    month,
    1,   // First day
    0,   // Midnight
  );
}

static DateTime getMonthEnd(int year, int month) {
  final nextMonth = tz.TZDateTime(tz.local, year, month + 1, 1);
  return nextMonth.subtract(const Duration(milliseconds: 1));
}
```

**Multi-Timezone Edge Case**:

Handled correctly: queries use date (YYYY-MM-DD) format, not timestamp. PostgreSQL date comparison is timezone-agnostic.

### Alternatives Considered

- **Database trigger on month boundary**: Rejected - requires background job, timezone complexity
- **Cloud Function/Cron**: Rejected - unnecessary infrastructure
- **App startup hook**: Rejected - unreliable (user may not open app)

---

## Summary

All four technical decisions leverage existing patterns from the codebase:

| Area | Decision | Existing Pattern Reused |
|------|----------|-------------------------|
| Monthly Budget Schema | Separate tables + indexed queries | `group_budgets` / `personal_budgets` (migrations 011/012) |
| Virgin Tracking | Junction table | `expense_categories` with foreign keys (migration 013) |
| Bulk Re-categorization | RPC + multi-select UI | `batch_update_expense_category` (migration 018) |
| Monthly Reset | Application logic | `TimezoneHandler` + date filtering (budget_remote_datasource.dart) |

**Next Phase**: Design detailed data model and API contracts based on these decisions.
