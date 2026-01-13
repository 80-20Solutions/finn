# Data Model: Personal and Group Budget Management

**Feature**: 001-personal-group-budget
**Date**: 2026-01-12
**Status**: Complete

This document defines all entities, relationships, and validation rules for the budget management feature.

---

## Entity Definitions

### 1. IncomeSource (NEW)

**Purpose**: Represents a single source of monthly income for a user

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary key, auto-generated | Unique identifier |
| `userId` | UUID | Foreign key (users.id), NOT NULL | Owner of income source |
| `type` | Enum | NOT NULL, one of: salary, freelance, investment, other, custom | Income category |
| `customTypeName` | String? | Max 100 chars, NULL unless type=custom | User-defined type label |
| `amount` | Int | >= 0, NOT NULL | Monthly income in smallest currency unit (cents) |
| `createdAt` | DateTime | Auto-set, NOT NULL | Creation timestamp |
| `updatedAt` | DateTime | Auto-updated, NOT NULL | Last modification timestamp |

**Relationships**:
- Belongs to one `User` (userId)
- One user can have multiple income sources (0..*)

**Validation Rules**:
- FR-003: amount >= 0 (prevent negative income)
- If type = 'custom', customTypeName MUST be provided
- If type != 'custom', customTypeName MUST be NULL

**State/Lifecycle**:
- Created → Active → (optionally) Deleted
- No state field needed, existence = active

---

### 2. SavingsGoal (NEW)

**Purpose**: Represents a user's monthly savings target with adjustment tracking

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary key, auto-generated | Unique identifier |
| `userId` | UUID | Foreign key (users.id), UNIQUE, NOT NULL | Owner (one goal per user) |
| `amount` | Int | >= 0, NOT NULL | Current savings goal in smallest currency unit |
| `originalAmount` | Int? | >= 0, NULL if never adjusted | Initial goal before auto-adjustments |
| `adjustedAt` | DateTime? | NULL if never adjusted | Timestamp of last auto-adjustment |
| `createdAt` | DateTime | Auto-set, NOT NULL | Creation timestamp |
| `updatedAt` | DateTime | Auto-updated, NOT NULL | Last modification timestamp |

**Relationships**:
- Belongs to one `User` (userId), one-to-one relationship
- One user has at most one savings goal

**Validation Rules**:
- FR-007: amount < totalIncome (calculated validation in use case)
- FR-015: Auto-reduced when groupExpenseLimit > (totalIncome - amount)
- If adjustedAt is set, originalAmount MUST also be set

**State Transitions**:
```
Initial (originalAmount=NULL) → Adjusted (originalAmount=initial, adjustedAt=now)
                               → Manual Update (resets originalAmount=NULL if user explicitly changes)
```

---

### 3. GroupExpenseAssignment (NEW)

**Purpose**: Links a user to group-assigned expenses with a spending limit

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary key, auto-generated | Unique identifier |
| `groupId` | UUID | Foreign key (family_groups.id), NOT NULL | Associated family group |
| `userId` | UUID | Foreign key (users.id), NOT NULL | Assigned member |
| `spendingLimit` | Int | >= 0, NOT NULL | Monthly spending limit for group expenses |
| `createdAt` | DateTime | Auto-set, NOT NULL | Creation timestamp |
| `updatedAt` | DateTime | Auto-updated, NOT NULL | Last modification timestamp |

**Relationships**:
- Belongs to one `User` (userId)
- Belongs to one `FamilyGroup` (groupId)
- Unique constraint on (groupId, userId) - one assignment per user per group

**Validation Rules**:
- FR-015: Triggers savings goal adjustment if spendingLimit > (totalIncome - savingsGoal)
- FR-020: Retained when user removed from group (only group views disabled)

**Lifecycle**:
- Created when user joins group + expenses assigned
- Updated when group expense assignments change (FR-014)
- Persisted even when user leaves group (FR-020/FR-021)

---

### 4. PersonalBudget (MODIFIED - existing entity)

**Purpose**: Monthly budget for an individual user (existing table, add relationships)

**New/Modified Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| ... | ... | (existing fields unchanged) | ... |
| *(calculated)* `totalIncome` | Int | Read-only, sum of income sources | Total monthly income |
| *(calculated)* `availableBudget` | Int | Read-only, totalIncome - savingsGoal - groupExpenseLimit | Spendable amount |

**New Relationships**:
- Has many `IncomeSources` (userId = PersonalBudget.userId)
- Has one `SavingsGoal` (userId = PersonalBudget.userId)
- Has zero or one `GroupExpenseAssignment` (userId = PersonalBudget.userId)

**Calculated Properties** (computed in application layer, NOT stored):
```dart
totalIncome = sum(incomeSources.map((s) => s.amount))
availableBudget = totalIncome - savingsGoal.amount - (groupExpenseAssignment?.spendingLimit ?? 0)
```

**Validation Rules**:
- FR-008: availableBudget calculation formula enforced
- FR-022: Can exist with zero income sources (totalIncome = 0)

---

### 5. GroupBudget (MODIFIED - existing entity)

**Purpose**: Monthly budget for a family group (existing table, add relationships)

**New Relationships**:
- Has many `GroupExpenseAssignments` (groupId = GroupBudget.groupId)

**No schema changes required** - assignments linked via groupId

---

### 6. BudgetSummary (NEW - computed entity, not stored)

**Purpose**: Aggregated view of user's complete budget state

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `userId` | UUID | User identifier |
| `totalIncome` | Int | Sum of all income sources |
| `savingsGoal` | Int | Current savings goal amount |
| `savingsOriginal` | Int? | Original goal before adjustments (if adjusted) |
| `groupExpenseLimit` | Int | Group-assigned spending limit (0 if no group) |
| `availableBudget` | Int | totalIncome - savingsGoal - groupExpenseLimit |
| `incomeSources` | List<IncomeSource> | All income sources |
| `hasGroupExpenses` | Bool | Whether user has group assignment |
| `savingsWasAdjusted` | Bool | Whether savings was auto-reduced |

**Computed in Use Case**:
```dart
class GetBudgetSummaryUseCase {
  Future<BudgetSummary> execute(String userId) {
    // 1. Fetch all income sources
    // 2. Fetch savings goal
    // 3. Fetch group expense assignment (if any)
    // 4. Calculate totals
    // 5. Return BudgetSummary entity
  }
}
```

---

## Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ INCOME_SOURCE : "has"
    USER ||--o| SAVINGS_GOAL : "has"
    USER ||--o| GROUP_EXPENSE_ASSIGNMENT : "assigned"
    FAMILY_GROUP ||--o{ GROUP_EXPENSE_ASSIGNMENT : "assigns"

    USER ||--|| PERSONAL_BUDGET : "owns"
    FAMILY_GROUP ||--|| GROUP_BUDGET : "owns"

    INCOME_SOURCE {
        uuid id PK
        uuid userId FK
        enum type
        string customTypeName
        int amount
        datetime createdAt
        datetime updatedAt
    }

    SAVINGS_GOAL {
        uuid id PK
        uuid userId FK_UNIQUE
        int amount
        int originalAmount
        datetime adjustedAt
        datetime createdAt
        datetime updatedAt
    }

    GROUP_EXPENSE_ASSIGNMENT {
        uuid id PK
        uuid groupId FK
        uuid userId FK
        int spendingLimit
        datetime createdAt
        datetime updatedAt
    }

    PERSONAL_BUDGET {
        uuid id PK
        uuid userId FK
        int totalIncome_CALC
        int availableBudget_CALC
    }

    GROUP_BUDGET {
        uuid id PK
        uuid groupId FK
    }
```

---

## Validation Rules Summary

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| **FR-003** | Income amount >= 0 | Database CHECK constraint + app validation |
| **FR-007** | Savings goal < total income | Application-layer validation before save |
| **FR-015** | Auto-adjust savings when group expenses > available | Triggered in `AssignGroupExpensesUseCase` |
| **FR-016** | Show notification when savings adjusted | UI layer, triggered by adjustment event |
| **FR-022** | Allow zero income sources | No validation, totalIncome defaults to 0 |

---

## Data Access Patterns

### Query Patterns:

1. **Get Budget Summary** (most frequent):
   ```sql
   SELECT * FROM income_sources WHERE user_id = :userId;
   SELECT * FROM savings_goals WHERE user_id = :userId;
   SELECT * FROM group_expense_assignments WHERE user_id = :userId;
   ```
   **Index**: `idx_income_sources_user_id`, `idx_savings_goals_user_id`, `idx_group_expense_assignments_user`

2. **Update Income Source**:
   ```sql
   UPDATE income_sources SET amount = :amount, updated_at = NOW() WHERE id = :id;
   ```

3. **Adjust Savings Goal**:
   ```sql
   UPDATE savings_goals
   SET amount = :newAmount,
       original_amount = COALESCE(original_amount, amount),
       adjusted_at = NOW(),
       updated_at = NOW()
   WHERE user_id = :userId;
   ```

4. **Assign Group Expenses**:
   ```sql
   INSERT INTO group_expense_assignments (group_id, user_id, spending_limit)
   VALUES (:groupId, :userId, :limit)
   ON CONFLICT (group_id, user_id) DO UPDATE SET spending_limit = :limit;
   ```

### Performance Considerations:

- **Caching**: Budget summary computed in Riverpod provider, cached until dependencies change
- **Batch Queries**: Fetch all 3 tables (income, savings, assignments) in parallel when loading summary
- **Optimistic Updates**: Drift local cache updated immediately, Supabase synced in background

---

## Migration Strategy

### Database Migrations:

1. **Migration 001**: Create `income_sources` table
2. **Migration 002**: Create `savings_goals` table
3. **Migration 003**: Create `group_expense_assignments` table
4. **Migration 004**: Add RLS policies for user-owned data
5. **Migration 005**: Add triggers for `updated_at` auto-update

### Drift Schema Sync:

- Generate Drift tables matching Supabase schema
- Run `dart run build_runner build` to generate database code
- Add DAO (Data Access Object) classes for each table

### Data Seeding:

- No default data required (user creates income sources via wizard)
- Optional: Seed predefined income type labels for i18n

---

## Appendix: Code Generation Templates

### Drift Table Example:

```dart
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
```

### Riverpod Provider Example:

```dart
@riverpod
Future<BudgetSummary> budgetSummary(BudgetSummaryRef ref, String userId) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return await GetBudgetSummaryUseCase(repository).execute(userId);
}
```

---

**Status**: Data model complete and validated against all functional requirements.
**Next**: Generate API contracts in `contracts/` directory.
