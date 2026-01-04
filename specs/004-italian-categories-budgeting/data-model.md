# Data Model: Italian Categories and Budget Management

**Feature**: 004-italian-categories-budgeting
**Date**: 2026-01-04
**Status**: Phase 1 Complete

## Entity Relationship Diagram

```
┌──────────────────┐
│  FamilyGroup     │
│                  │
└────────┬─────────┘
         │ 1:N
         ▼
┌──────────────────┐       ┌──────────────────┐
│  ExpenseCategory │◄──────│  CategoryBudget  │
│  (Modified)      │  1:N  │  (New)           │
└────────┬─────────┘       └────────┬─────────┘
         │ 1:N                      │
         ├──────────────────────────┘
         │                          │
         │ N:N                      │ N:1
         ▼                          ▼
┌──────────────────┐       ┌──────────────────┐
│  User-Category   │       │     Profile      │
│  Usage (New)     │       │                  │
└──────────────────┘       └────────┬─────────┘
                                    │ 1:N
                                    ▼
                           ┌──────────────────┐
                           │     Expense      │
                           │   (Modified)     │
                           └──────────────────┘
```

## Entities

### ExpenseCategory (Modified)

**Existing table**: `expense_categories` (migration 013)

**Changes Required**:
- Update seed data to use Italian names
- Add migration to delete existing English categories
- Set existing expenses' `category_id` to NULL (orphan them)

**Modified Schema**:

| Field | Type | Constraints | Description | Change |
|-------|------|-------------|-------------|--------|
| id | UUID | PK | Category identifier | ✅ No change |
| name | VARCHAR(50) | NOT NULL, UNIQUE(group_id, name) | **Italian** category name | 🔄 Content change (English → Italian) |
| group_id | UUID | FK → family_groups, NOT NULL | Owning group | ✅ No change |
| is_default | BOOLEAN | DEFAULT false | System-provided category | ✅ No change |
| created_by | UUID | FK → profiles, NULL | Creator (NULL for defaults) | ✅ No change |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp | ✅ No change |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Last update timestamp | ✅ No change |

**Validation Rules**:
- Name: 2-50 characters, Italian text
- Unique within group
- Default categories (is_default=true) cannot be deleted
- At least one category must exist ("Varie" fallback)

**Italian Default Categories** (FR-028):

| Italian Name | English Translation | Description |
|--------------|---------------------|-------------|
| Spesa | Groceries | Food and household items |
| Benzina | Fuel | Gasoline/diesel |
| Ristoranti | Restaurants | Dining out |
| Bollette | Bills | Utilities (electric, water, gas) |
| Salute | Health | Medical, pharmacy |
| Trasporti | Transportation | Public transport, parking |
| Casa | Home | Rent, maintenance, furniture |
| Svago | Entertainment | Movies, games, hobbies |
| Abbigliamento | Clothing | Clothes, shoes |
| Varie | Miscellaneous | Fallback category |

---

### CategoryBudget (New)

**New table**: `category_budgets`

Stores monthly budget allocations per category per group.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Budget record identifier |
| category_id | UUID | FK → expense_categories, NOT NULL, ON DELETE CASCADE | Category being budgeted |
| group_id | UUID | FK → family_groups, NOT NULL, ON DELETE CASCADE | Owning group |
| amount | INTEGER | NOT NULL, CHECK (amount >= 0) | Monthly budget in cents (EUR) |
| month | INTEGER | NOT NULL, CHECK (month >= 1 AND month <= 12) | Budget month (1-12) |
| year | INTEGER | NOT NULL, CHECK (year >= 2000) | Budget year |
| created_by | UUID | FK → profiles, NOT NULL, ON DELETE CASCADE | User who set budget |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Last update timestamp |

**Constraints**:
- UNIQUE(category_id, group_id, year, month) - one budget per category per month
- amount stored in cents to avoid floating-point errors (e.g., €50.00 = 5000)

**Indexes**:
```sql
CREATE INDEX idx_category_budgets_lookup
  ON category_budgets(group_id, category_id, year, month);

CREATE INDEX idx_category_budgets_current_month
  ON category_budgets(group_id, year, month);
```

**Derived/Computed Fields** (calculated on-demand):
- `spent`: SUM of expenses.amount WHERE category_id = this.category_id AND date in month range
- `remaining`: amount - spent
- `percentage_used`: (spent / amount) * 100
- `is_over_budget`: spent > amount

**Lifecycle**:
- **Created**: When user sets budget for category (via settings or virgin prompt)
- **Updated**: When user modifies budget amount for existing month
- **Deleted**: When category is deleted (CASCADE) or manually removed
- **Queried**: Every dashboard load, expense detail view

---

### UserCategoryUsage (New)

**New table**: `user_category_usage`

Tracks which users have used which categories for virgin category detection (FR-006, FR-007).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Usage record identifier |
| user_id | UUID | FK → profiles, NOT NULL, ON DELETE CASCADE | User who used category |
| category_id | UUID | FK → expense_categories, NOT NULL, ON DELETE CASCADE | Category that was used |
| first_used_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Timestamp of first expense in category |

**Constraints**:
- UNIQUE(user_id, category_id) - one record per user-category pair

**Indexes**:
```sql
CREATE INDEX idx_user_category_usage_lookup
  ON user_category_usage(user_id, category_id);
```

**Lifecycle**:
- **Created**: Automatically when user creates first expense in a category
- **Checked**: Before showing budget prompt (virgin detection)
- **Deleted**: When category or user is deleted (CASCADE)

**Query Pattern**:
```sql
-- Virgin category check
SELECT EXISTS(
  SELECT 1 FROM user_category_usage
  WHERE user_id = ? AND category_id = ?
) AS has_used;
```

---

### Expense (Modified)

**Existing table**: `expenses`

**Changes Required**:
- Set `category_id` to NULL for all expenses (orphan migration)
- Add query patterns for orphaned expense detection

**Schema** (no structural changes):

| Field | Type | Constraints | Description | Change |
|-------|------|-------------|-------------|--------|
| id | UUID | PK | Expense identifier | ✅ No change |
| category_id | UUID | FK → expense_categories, **NULL** | Category (NULL = orphaned) | 🔄 Data change (set to NULL) |
| ... | ... | ... | (other fields unchanged) | ✅ No change |

**Orphaned Expense Identification** (FR-024, FR-026):
```sql
-- Get all orphaned expenses for group
SELECT * FROM expenses
WHERE group_id = ?
  AND category_id IS NULL
ORDER BY date DESC;
```

**Validation Rules** (modified):
- category_id is **optional** (NULL allowed for orphaned state)
- When creating new expense, category_id should be provided (but not enforced at DB level)
- UI should prevent creating expenses without category (except during migration period)

---

## Derived Entities (Application-Level)

### MonthlyBudgetStats

**Not stored in database** - calculated on-demand from `category_budgets` + `expenses`.

**Dart Model**:
```dart
class MonthlyBudgetStatsEntity {
  final String categoryId;
  final String categoryName;
  final int budgetAmount;      // cents
  final int spentAmount;       // cents
  final int remainingAmount;   // cents (can be negative)
  final double percentageUsed; // 0.0 - 100.0+
  final bool isOverBudget;
  final int month;
  final int year;
}
```

**Calculation Logic**:
1. Fetch `category_budgets` record for (group, category, year, month)
2. Query `expenses` SUM(amount) WHERE category_id = X AND date in month range
3. Compute derived fields: remaining, percentage, over_budget flag

---

### OverallGroupBudgetStats

**Not stored** - aggregation of all category budgets for dashboard display (FR-014).

**Dart Model**:
```dart
class OverallGroupBudgetStatsEntity {
  final int totalBudgeted;     // SUM of all category budgets (cents)
  final int totalSpent;        // SUM of all expenses in month (cents)
  final int totalRemaining;    // totalBudgeted - totalSpent
  final double percentageUsed; // (totalSpent / totalBudgeted) * 100
  final int categoriesOverBudget; // Count of categories with spent > budget
  final int month;
  final int year;
}
```

**Calculation Logic** (FR-014):
```dart
// Overall budget = SUM of all category budgets
totalBudgeted = SUM(category_budgets.amount)
  WHERE group_id = X AND year = Y AND month = M

// Total spent = SUM of all expenses with categories
totalSpent = SUM(expenses.amount)
  WHERE group_id = X AND date in month range AND category_id IS NOT NULL
```

---

## State Transitions

### Expense Categorization States

```
┌─────────────┐
│  Uncreated  │
└──────┬──────┘
       │ User creates expense
       ▼
┌─────────────┐
│  Orphaned   │ ◄── Migration sets existing expenses here
│ (NULL cat)  │
└──────┬──────┘
       │ User re-categorizes
       ▼
┌─────────────┐
│ Categorized │
│  (has ID)   │
└──────┬──────┘
       │ User changes category
       ▼
┌─────────────┐
│  Different  │
│  Category   │
└─────────────┘
```

### Virgin Category Workflow

```
┌──────────────────┐
│ User selects     │
│ category (first  │
│ time for user)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Check user_      │
│ category_usage   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Exists? │
    └────┬────┘
         │
    ┌────┴─────────┐
    │              │
    NO            YES
    │              │
    ▼              ▼
┌─────────┐   ┌─────────┐
│ Show    │   │ Silent  │
│ Budget  │   │ Save    │
│ Prompt  │   │ Expense │
└────┬────┘   └─────────┘
     │
 ┌───┴───┐
 │ User  │
 │Choice │
 └───┬───┘
     │
┌────┴───────┐
│            │
Set Budget  Decline
│            │
▼            ▼
Save       Use "Varie"
Budget     Budget
```

### Monthly Budget Cycle

```
Month N          Month N+1         Month N+2
┌─────────┐     ┌─────────┐      ┌─────────┐
│ Budget: │     │ Budget: │      │ Budget: │
│ €500    │     │ €500    │      │ €600    │
│ Spent:  │     │ Spent:  │      │ Spent:  │
│ €450    │     │ €520    │      │ €300    │
└─────────┘     └─────────┘      └─────────┘
     │               │                 │
     │ Automatic     │ Automatic       │
     │ "reset"       │ "reset"         │
     │ (new query)   │ (new query)     │
     ▼               ▼                 ▼
(Spent=0 at    (Spent=0 at      (Spent=0 at
month start)   month start)      month start)
```

**Note**: "Reset" is implicit - no data changes. Queries filter by new month range, so spending automatically starts at 0.

---

## Data Integrity Rules

### Cascading Deletes

| Parent | Child | Behavior |
|--------|-------|----------|
| expense_categories | category_budgets | CASCADE (delete budgets when category deleted) |
| expense_categories | user_category_usage | CASCADE (delete usage records) |
| expense_categories | expenses.category_id | SET NULL (orphan expenses) |
| family_groups | category_budgets | CASCADE |
| profiles | category_budgets.created_by | CASCADE |
| profiles | user_category_usage | CASCADE |

### Uniqueness Constraints

| Table | Constraint | Purpose |
|-------|-----------|---------|
| expense_categories | UNIQUE(group_id, name) | No duplicate category names per group |
| category_budgets | UNIQUE(category_id, group_id, year, month) | One budget per category per month |
| user_category_usage | UNIQUE(user_id, category_id) | Track first use only |

---

## Migration Strategy

### Phase 1: Schema Changes

1. **Create `category_budgets` table** (migration 026)
2. **Create `user_category_usage` table** (migration 027)
3. **Add index** `idx_expenses_category_month`
4. **Create RPC** `batch_reassign_orphaned_expenses`

### Phase 2: Data Migration

**Migration 029: Delete English Categories, Orphan Expenses**

```sql
-- Step 1: Set all expenses to orphaned state
UPDATE public.expenses
SET category_id = NULL
WHERE category_id IS NOT NULL;

-- Step 2: Delete all existing English categories
DELETE FROM public.expense_categories
WHERE is_default = true;

-- Step 3: Insert new Italian default categories
INSERT INTO public.expense_categories (group_id, name, is_default)
SELECT
  fg.id,
  category_name,
  true
FROM public.family_groups fg
CROSS JOIN (
  VALUES
    ('Spesa'),
    ('Benzina'),
    ('Ristoranti'),
    ('Bollette'),
    ('Salute'),
    ('Trasporti'),
    ('Casa'),
    ('Svago'),
    ('Abbigliamento'),
    ('Varie')
) AS categories(category_name)
ON CONFLICT (group_id, name) DO NOTHING;
```

### Phase 3: User Re-categorization

**Application-level workflow**:
1. On app launch, detect orphaned expenses
2. Show notification: "X spese necessitano di una categoria"
3. Navigate to `OrphanedExpensesScreen`
4. User bulk re-categorizes using new Italian categories
5. System creates `user_category_usage` records for assigned categories

---

## Performance Considerations

### Query Optimization

**Current Month Budget Stats** (most frequent query):
```sql
-- Optimized by idx_category_budgets_current_month
SELECT * FROM category_budgets
WHERE group_id = ? AND year = ? AND month = ?;

-- Optimized by idx_expenses_category_month
SELECT SUM(amount) FROM expenses
WHERE category_id = ?
  AND date >= ?::date
  AND date < ?::date;
```

**Expected Query Times** (target scale: 1000 expenses):
- Virgin category check: <10ms (indexed lookup)
- Monthly budget stats (single category): <50ms (indexed sum)
- Dashboard budget overview (all categories): <200ms (10 categories × ~20ms each)

### Caching Strategy

**Riverpod Providers** (existing pattern in codebase):
```dart
// Cache category budgets per month
final categoryBudgetsProvider = FutureProvider.family<
  List<CategoryBudgetEntity>,
  ({String groupId, int year, int month})
>((ref, params) async {
  // Fetches category_budgets for current month
  // Cached until month changes or budget updated
});

// Cache orphaned expense count
final orphanedExpensesCountProvider = FutureProvider<int>((ref) async {
  // SELECT COUNT(*) WHERE category_id IS NULL
  // Refreshed when expenses modified
});
```

---

## Summary

### New Tables
- ✅ `category_budgets` - Monthly budget allocations per category
- ✅ `user_category_usage` - Virgin category tracking

### Modified Tables
- 🔄 `expense_categories` - English → Italian names, existing rows deleted
- 🔄 `expenses` - category_id set to NULL (orphaned state)

### Derived Entities (Application-Level)
- `MonthlyBudgetStatsEntity` - Per-category budget status
- `OverallGroupBudgetStatsEntity` - Aggregated dashboard stats

### Key Design Decisions
- **Monthly budgets**: Separate records per month (year + month columns)
- **Orphaning strategy**: NULL category_id requires user re-categorization
- **Virgin tracking**: Junction table with compound unique constraint
- **Budget reset**: Implicit via date-range queries (no data changes)
