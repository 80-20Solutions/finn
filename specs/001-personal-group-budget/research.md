# Research & Technology Decisions

**Feature**: Personal and Group Budget Management
**Date**: 2026-01-12
**Status**: Complete

This document captures all technology decisions made during Phase 0 research.

---

## 1. Guided Wizard Flow Pattern

**Decision**: Use `PageView` with custom step indicators and `go_router` for navigation

**Rationale**:
- `PageView` provides smooth horizontal swipe navigation between steps
- Maintains state across steps without complex navigation logic
- Custom `guided_step_indicator.dart` widget for visual progress
- `go_router` handles deep linking and back navigation naturally
- WoltModalSheet is better suited for bottom sheets, not multi-step wizards

**Alternatives Considered**:
- **WoltModalSheet**: Good for modal dialogs, but overkill for a full-screen wizard flow. Doesn't provide horizontal swipe gestures naturally.
- **Nested go_router routes**: Creates complexity with state management across routes. PageView keeps all steps in one widget tree.
- **Stepper widget**: Too rigid, doesn't match Finn's design language, limited customization

**Implementation Notes**:
- Use `PageController` for programmatic page changes
- Allow swipe gestures only when current step is valid
- Persist wizard state in Riverpod provider to survive navigation away/back
- 3 steps: Income Entry → Savings Goal → Summary/Confirmation

---

## 2. Budget Calculation Strategy

**Decision**: Use Riverpod computed providers with selective invalidation

**Rationale**:
- Riverpod's `ref.watch()` automatically recomputes when dependencies change
- Calculations are fast (<100ms per spec) so no need for debouncing
- Computed providers cache results until dependencies change
- Follows existing pattern in dashboard_provider.dart

**Alternatives Considered**:
- **Manual memoization**: Unnecessary complexity when Riverpod handles it
- **Computed package**: Extra dependency not needed with Riverpod 2.4+
- **Stream-based reactive**: Overkill for simple arithmetic calculations

**Implementation Formula**:
```dart
availableBudget = totalIncome - savingsGoal - groupExpenseLimit
totalIncome = sum(all income sources)
```

**Performance Notes**:
- Budget calculations triggered only on:
  - Income source add/update/delete
  - Savings goal change
  - Group expense assignment change
- Use `@riverpod` code generation for clean provider definitions

---

## 3. Supabase Schema Design

**Decision**: Three new tables with foreign keys to existing `users` and `family_groups` tables

**Rationale**:
- Normalized design prevents data duplication
- Foreign keys ensure referential integrity
- Indexes on userId for fast user-specific queries
- Matches existing schema patterns (personal_budgets, group_budgets tables already exist)

**Tables**:

### `income_sources`
```sql
CREATE TABLE income_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('salary', 'freelance', 'investment', 'other', 'custom')),
  custom_type_name VARCHAR(100), -- NULL unless type = 'custom'
  amount BIGINT NOT NULL CHECK (amount >= 0), -- Stored as cents/smallest unit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_income_sources_user_id ON income_sources(user_id);
CREATE INDEX idx_income_sources_user_created ON income_sources(user_id, created_at DESC);
```

### `savings_goals`
```sql
CREATE TABLE savings_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL CHECK (amount >= 0),
  original_amount BIGINT, -- Tracks amount before auto-adjustment
  adjusted_at TIMESTAMPTZ, -- NULL if never adjusted
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id) -- One savings goal per user
);

CREATE INDEX idx_savings_goals_user_id ON savings_goals(user_id);
```

### `group_expense_assignments`
```sql
CREATE TABLE group_expense_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  spending_limit BIGINT NOT NULL CHECK (spending_limit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id) -- One assignment per user per group
);

CREATE INDEX idx_group_expense_assignments_user ON group_expense_assignments(user_id);
CREATE INDEX idx_group_expense_assignments_group ON group_expense_assignments(group_id);
```

**Alternatives Considered**:
- **Embedding income sources in personal_budgets JSON**: Poor queryability, no validation
- **Separate monthly snapshots**: Would require complex historical queries
- **Single savings_amount column in users table**: Doesn't track adjustment history

**Migration Notes**:
- Add RLS policies for user-owned data
- Create triggers for `updated_at` auto-update
- Consider soft deletes for audit trail (can add `deleted_at` later)

---

## 4. Notification System Integration

**Decision**: Use in-app SnackBar for transient notifications + persistent banner for savings adjustments

**Rationale**:
- Savings adjustment is critical info that shouldn't disappear quickly
- SnackBar for success/error feedback (< 5 seconds)
- Persistent banner (dismissible) at top of budget summary for savings changes
- No need for push notifications (in-app action only)

**Implementation**:
```dart
// For savings adjustment
showBanner(context,
  message: 'Your savings goal was adjusted from €500 to €350 to accommodate group expenses.',
  type: BannerType.warning,
  dismissible: true
);

// For success/error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Income source added successfully'))
);
```

**Alternatives Considered**:
- **Dialog**: Too intrusive, blocks user interaction
- **Push notifications**: Overkill for in-app state changes
- **notification_service.dart**: Currently for system-level notifications, not in-app messages

**UI Pattern**:
- Banner: Yellow/orange background, info icon, dismiss X button
- Auto-dismiss after 10 seconds or manual dismiss
- Only one banner visible at a time (queue if multiple)

---

## 5. Drift Local Cache Strategy

**Decision**: Optimistic updates with background sync, no conflict resolution (last-write-wins)

**Rationale**:
- Budget data is user-specific, no concurrent editing conflicts
- Optimistic UI updates provide instant feedback (matches SC-003: < 1 second)
- Background sync when connectivity restored
- Follows existing pattern in groups/categories features

**Sync Strategy**:
1. User makes change → Update Drift immediately → Show success
2. Attempt Supabase update in background
3. On success: No action (Drift already updated)
4. On failure: Rollback Drift + show error SnackBar
5. On app start: Fetch latest from Supabase, merge with Drift

**Drift Tables** (mirror Supabase schema):
```dart
class IncomeSources extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get customTypeName => text().nullable()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Similar for SavingsGoals, GroupExpenseAssignments
```

**Alternatives Considered**:
- **Server-only (no Drift)**: Poor offline experience, violates offline-first principle
- **Conflict resolution with timestamps**: Unnecessary for single-user data
- **Two-way sync with CRDTs**: Massive overkill for budget data

**Performance Notes**:
- Index on userId in Drift for fast queries
- Batch sync on app start (single query per table)
- Use Drift's query caching for computed budget summaries

---

## 6. Localization for Income Types

**Decision**: Store income type as enum key, display localized labels from `intl` package

**Rationale**:
- Database stores `'salary'` (lowercase English key)
- UI displays localized string: `AppLocalizations.of(context).incomeTypeSalary`
- Custom types stored as-is in `custom_type_name` column (user's language)
- Matches existing i18n patterns in auth/groups features

**Enum Definition**:
```dart
enum IncomeType {
  salary,
  freelance,
  investment,
  other,
  custom,
}
```

**Localization Keys** (add to `lib/l10n/intl_*.arb`):
```json
{
  "incomeTypeSalary": "Stipendio",
  "incomeTypeFreelance": "Freelance",
  "incomeTypeInvestment": "Investimenti",
  "incomeTypeOther": "Altro",
  "incomeTypeCustom": "Personalizzato"
}
```

**Currency Handling** (from edge case):
- **Decision**: Single currency per user (per A-002), stored as ISO code in user profile
- All amounts in database are integers (smallest currency unit: cents, centesimi, etc.)
- Display formatting via `intl.NumberFormat.currency(locale: userLocale, symbol: userCurrencySymbol)`
- Currency selection during user registration (out of scope for this feature)

**Alternatives Considered**:
- **Store translated labels in DB**: Requires migration for new languages, data duplication
- **Multiple currency support**: Explicitly out of scope per spec, deferred to future
- **Hardcoded labels**: Not scalable for internationalization

**Implementation Notes**:
- Use `Intl.message()` for all user-facing strings
- Income type dropdown populated from enum + localizations
- Custom type input shown only when "Custom" selected

---

## Summary Table

| Decision Area | Chosen Solution | Key Benefit |
|---------------|----------------|-------------|
| Wizard Flow | PageView + go_router | Smooth UX, state preservation |
| Budget Calc | Riverpod computed providers | Auto-reactive, performant |
| Schema | 3 normalized tables | Data integrity, fast queries |
| Notifications | SnackBar + persistent banner | Appropriate urgency levels |
| Local Cache | Optimistic Drift sync | Offline-first, instant feedback |
| Localization | Enum keys + intl labels | Scalable i18n, clean DB |

**All NEEDS CLARIFICATION items resolved**. Ready for Phase 1 data modeling.
