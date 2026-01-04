# Quickstart: Italian Categories and Budget Management

**Feature**: 004-italian-categories-budgeting
**Branch**: `004-italian-categories-budgeting`
**Date**: 2026-01-04

## Overview

This guide helps developers understand and implement the Italian Categories and Budget Management feature. Follow these steps to get oriented with the architecture and start implementing.

---

## Prerequisites

Before starting implementation, ensure you understand:

1. **Existing Architecture**: Review `specs/001-family-expense-tracker/` to understand:
   - Feature-first structure (`lib/features/`)
   - Supabase integration patterns
   - Riverpod state management
   - Existing budget implementation (`lib/features/budgets/`)

2. **Current State**: The app currently has:
   - ✅ English categories (Food, Utilities, etc.)
   - ✅ Group/personal budgets (no category-level budgets)
   - ✅ Expense tracking with category assignment
   - ❌ No Italian localization
   - ❌ No monthly budget cycles
   - ❌ No virgin category prompts

3. **Key Documents**:
   - [Specification](./spec.md) - User requirements and success criteria
   - [Research](./research.md) - Technical decisions
   - [Data Model](./data-model.md) - Database schema
   - [Plan](./plan.md) - Implementation structure

---

## Architecture Overview

### Data Flow

```
┌─────────────────────────────────────────────────────┐
│ Presentation Layer                                  │
│                                                     │
│  ┌───────────────┐  ┌────────────────┐            │
│  │  Dashboard    │  │  Add Expense   │            │
│  │  Screen       │  │  Screen        │            │
│  └───────┬───────┘  └────────┬───────┘            │
│          │                   │                     │
│          │ Watch Provider    │ Call Repository     │
│          ▼                   ▼                     │
│  ┌──────────────────────────────────┐             │
│  │  Budget Provider (Riverpod)      │             │
│  │  - Monthly budget stats          │             │
│  │  - Category budgets list         │             │
│  └──────────────┬───────────────────┘             │
└─────────────────┼───────────────────────────────────┘
                  │
┌─────────────────┼───────────────────────────────────┐
│ Domain Layer    │                                   │
│                 ▼                                   │
│  ┌──────────────────────────────┐                  │
│  │  Budget Repository Interface │                  │
│  └──────────────┬───────────────┘                  │
└─────────────────┼───────────────────────────────────┘
                  │
┌─────────────────┼───────────────────────────────────┐
│ Data Layer      ▼                                   │
│  ┌──────────────────────────────┐                  │
│  │  Budget Remote DataSource    │                  │
│  │  - Supabase queries          │                  │
│  │  - RPC function calls        │                  │
│  └──────────────┬───────────────┘                  │
└─────────────────┼───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Supabase Backend                                    │
│                                                     │
│  ┌────────────────┐  ┌────────────────┐           │
│  │ category_      │  │ user_category_ │           │
│  │ budgets        │  │ usage          │           │
│  └────────────────┘  └────────────────┘           │
│                                                     │
│  ┌────────────────────────────────────┐            │
│  │ RPC Functions                      │            │
│  │ - get_category_budget_stats        │            │
│  │ - get_overall_group_budget_stats   │            │
│  │ - batch_reassign_orphaned_expenses │            │
│  └────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

---

## Implementation Roadmap

### Phase 1: Database Schema ✅ (1 day)

**Goal**: Create new tables and migrations

**Tasks**:
1. Create migration `026_category_budgets_table.sql`
2. Create migration `027_user_category_usage_table.sql`
3. Create migration `028_batch_reassign_orphaned.sql` (RPC function)
4. Create migration `029_migrate_to_italian_categories.sql`

**Verification**:
```bash
# Run migrations
supabase db push

# Verify tables exist
psql -c "\d category_budgets"
psql -c "\d user_category_usage"

# Verify Italian categories seeded
psql -c "SELECT name FROM expense_categories WHERE is_default = true LIMIT 5;"
# Expected: Spesa, Benzina, Ristoranti, Bollette, Salute
```

**Reference**: See `research.md` sections 1-2 for schema details

---

### Phase 2: Domain Entities (1 day)

**Goal**: Create Dart models and entities

**Tasks**:
1. Create `lib/features/categories/domain/entities/`
   - `category_budget_entity.dart`
   - `monthly_budget_stats_entity.dart`
   - `user_category_usage_entity.dart`

**Example** (`category_budget_entity.dart`):
```dart
import 'package:equatable/equatable.dart';

class CategoryBudgetEntity extends Equatable {
  final String id;
  final String categoryId;
  final String groupId;
  final int amount; // cents
  final int month;
  final int year;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryBudgetEntity({
    required this.id,
    required this.categoryId,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        groupId,
        amount,
        month,
        year,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
```

**Reference**: See `data-model.md` for entity specifications

---

### Phase 3: Data Layer (2 days)

**Goal**: Implement Supabase data sources and repositories

**Tasks**:
1. Create `lib/features/categories/data/datasources/category_remote_datasource.dart`
2. Create `lib/features/categories/data/models/` (models extending entities)
3. Create `lib/features/categories/data/repositories/category_repository_impl.dart`
4. Modify `lib/features/budgets/data/` to add category budget methods

**Example** (`category_remote_datasource.dart`):
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRemoteDatasource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDatasource({required this.supabaseClient});

  /// Get all category budgets for current month
  Future<List<CategoryBudgetModel>> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient
          .from('category_budgets')
          .select('*, expense_categories(name)')
          .eq('group_id', groupId)
          .eq('year', year)
          .eq('month', month);

      return (response as List)
          .map((json) => CategoryBudgetModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    }
  }

  /// Check if user has used category (virgin detection)
  Future<bool> hasUserUsedCategory({
    required String userId,
    required String categoryId,
  }) async {
    try {
      final response = await supabaseClient
          .from('user_category_usage')
          .select('id')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    }
  }

  /// Get category budget stats (via RPC)
  Future<BudgetStatsModel> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_category_budget_stats',
        params: {
          'p_group_id': groupId,
          'p_category_id': categoryId,
          'p_year': year,
          'p_month': month,
        },
      );

      return BudgetStatsModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    }
  }
}
```

**Reference**: See `contracts/category_budgets_api.md` for API details

---

### Phase 4: Presentation Layer (3 days)

**Goal**: Build UI screens and widgets

**Tasks**:
1. Create `lib/features/categories/presentation/screens/`
   - `category_management_screen.dart` (settings)
   - `orphaned_expenses_screen.dart` (bulk re-categorization)
2. Create `lib/features/categories/presentation/widgets/`
   - `budget_prompt_dialog.dart` (virgin category)
   - `category_budget_card.dart` (budget display)
3. Modify `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
   - Add budget overview widgets
4. Modify `lib/features/expenses/presentation/screens/add_expense_screen.dart`
   - Add virgin category prompt trigger

**Example** (`budget_prompt_dialog.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetPromptDialog extends StatefulWidget {
  final String categoryName;
  final VoidCallback onDecline;
  final Function(int amount) onSetBudget;

  const BudgetPromptDialog({
    super.key,
    required this.categoryName,
    required this.onDecline,
    required this.onSetBudget,
  });

  @override
  State<BudgetPromptDialog> createState() => _BudgetPromptDialogState();
}

class _BudgetPromptDialogState extends State<BudgetPromptDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Budget per "${widget.categoryName}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questa è la prima spesa nella categoria "${widget.categoryName}". '
              'Vuoi impostare un budget mensile?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Budget mensile (€)',
                prefixText: '€',
                hintText: '100',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un importo';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Importo non valido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDecline();
          },
          child: const Text('Non ora'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final euros = int.parse(_controller.text);
              final cents = euros * 100;
              Navigator.pop(context);
              widget.onSetBudget(cents);
            }
          },
          child: const Text('Imposta budget'),
        ),
      ],
    );
  }
}
```

**Reference**: See `research.md` section 3 for UI patterns

---

### Phase 5: State Management (1 day)

**Goal**: Create Riverpod providers for budget state

**Tasks**:
1. Create `lib/features/categories/presentation/providers/category_provider.dart`
2. Modify `lib/features/budgets/presentation/providers/budget_provider.dart`

**Example** (`category_provider.dart`):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for category budgets (current month)
final categoryBudgetsProvider = FutureProvider.family<
  List<CategoryBudgetEntity>,
  ({String groupId, int year, int month})
>((ref, params) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryBudgets(
    groupId: params.groupId,
    year: params.year,
    month: params.month,
  );
});

// Provider for virgin category check
final virginCategoryCheckProvider = FutureProvider.family<
  bool,
  ({String userId, String categoryId})
>((ref, params) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.hasUserUsedCategory(
    userId: params.userId,
    categoryId: params.categoryId,
  );
});

// Provider for category budget stats
final categoryBudgetStatsProvider = FutureProvider.family<
  BudgetStatsEntity,
  ({String groupId, String categoryId, int year, int month})
>((ref, params) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryBudgetStats(
    groupId: params.groupId,
    categoryId: params.categoryId,
    year: params.year,
    month: params.month,
  );
});
```

---

### Phase 6: Integration & Testing (2 days)

**Goal**: Wire everything together and test end-to-end

**Tasks**:
1. Update routing in `lib/app/routes.dart`
2. Add navigation to orphaned expenses screen
3. Write unit tests for:
   - Budget calculations
   - Virgin category detection
   - Month boundary handling
4. Write widget tests for:
   - Budget prompt dialog
   - Category budget cards
5. Write integration test for:
   - Monthly budget cycle (create budget → add expenses → view stats)

**Example Test** (`budget_monthly_cycle_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Monthly budget cycle test', (tester) async {
    // 1. Create category budget for January
    // 2. Add expenses in January
    // 3. Verify budget stats show correct spent/remaining
    // 4. Simulate month change to February
    // 5. Verify stats "reset" (new month query returns 0 spent)
  });
}
```

---

## Key Code Patterns

### 1. Month Boundary Handling

**Always use `TimezoneHandler`** for month calculations:

```dart
import '../../../core/utils/timezone_handler.dart';

// Get current month
final now = DateTime.now();
final year = now.year;
final month = now.month;

// Get month boundaries
final monthStart = TimezoneHandler.getMonthStart(year, month);
final monthEnd = TimezoneHandler.getMonthEnd(year, month);

// Query expenses in date range
final expenses = await supabaseClient
    .from('expenses')
    .select('amount')
    .gte('date', monthStart.toIso8601String().split('T')[0])
    .lte('date', monthEnd.toIso8601String().split('T')[0]);
```

### 2. Virgin Category Detection

**Check before showing expense success**:

```dart
// After expense created successfully
final hasUsed = await ref.read(categoryRepositoryProvider)
    .hasUserUsedCategory(
      userId: currentUserId,
      categoryId: expense.categoryId,
    );

if (!hasUsed) {
  // Show budget prompt
  showDialog(
    context: context,
    builder: (_) => BudgetPromptDialog(
      categoryName: categoryName,
      onSetBudget: (amount) {
        // Create category budget
        // Mark category as used
      },
      onDecline: () {
        // Just mark as used (use "Varie" budget)
        ref.read(categoryRepositoryProvider).markCategoryAsUsed(
              userId: currentUserId,
              categoryId: expense.categoryId,
            );
      },
    ),
  );
}
```

### 3. Currency Display

**Always format amounts from cents**:

```dart
String formatCurrency(int cents) {
  final euros = cents / 100;
  return '€${euros.toStringAsFixed(2)}';
}

// Usage
final budget = CategoryBudgetEntity(..., amount: 5000); // €50.00
Text(formatCurrency(budget.amount)); // Display: "€50.00"
```

---

## Common Pitfalls

### ❌ DON'T: Query expenses without date filtering
```dart
// WRONG: Returns expenses from ALL months
final expenses = await supabaseClient
    .from('expenses')
    .select('amount')
    .eq('category_id', categoryId);
```

### ✅ DO: Always filter by month range
```dart
// CORRECT: Only current month expenses
final monthStart = TimezoneHandler.getMonthStart(year, month);
final monthEnd = TimezoneHandler.getMonthEnd(year, month);

final expenses = await supabaseClient
    .from('expenses')
    .select('amount')
    .eq('category_id', categoryId)
    .gte('date', monthStart.toIso8601String().split('T')[0])
    .lte('date', monthEnd.toIso8601String().split('T')[0]);
```

---

### ❌ DON'T: Store amounts as double
```dart
// WRONG: Floating-point errors
double amount = 50.10; // May become 50.099999...
```

### ✅ DO: Always use integers (cents)
```dart
// CORRECT: Integer arithmetic is exact
int amount = 5010; // €50.10
```

---

### ❌ DON'T: Forget virgin category check
```dart
// WRONG: Creates expense without checking first-time use
await repository.createExpense(expense);
Navigator.pop(context); // User never sees budget prompt!
```

### ✅ DO: Check after expense creation
```dart
// CORRECT: Check virgin status before closing screen
final expense = await repository.createExpense(expense);

final hasUsed = await repository.hasUserUsedCategory(...);
if (!hasUsed) {
  await showBudgetPrompt(); // Prompt user
  await repository.markCategoryAsUsed(...);
}

Navigator.pop(context);
```

---

## Debugging Tips

### Enable Supabase Logging

```dart
// In main.dart
Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
  debug: true, // Enable request/response logging
);
```

### Inspect Database State

```sql
-- Check Italian categories seeded
SELECT group_id, name, is_default
FROM expense_categories
WHERE is_default = true
ORDER BY name;

-- Check orphaned expenses
SELECT id, merchant, amount, category_id
FROM expenses
WHERE category_id IS NULL
LIMIT 10;

-- Check category budgets
SELECT
  cb.id,
  ec.name AS category_name,
  cb.amount / 100.0 AS budget_euros,
  cb.month,
  cb.year
FROM category_budgets cb
JOIN expense_categories ec ON ec.id = cb.category_id
WHERE cb.group_id = '<YOUR_GROUP_ID>';

-- Check virgin category usage
SELECT
  p.display_name,
  ec.name AS category_name,
  ucu.first_used_at
FROM user_category_usage ucu
JOIN profiles p ON p.id = ucu.user_id
JOIN expense_categories ec ON ec.id = ucu.category_id
ORDER BY ucu.first_used_at DESC;
```

### Test Monthly Reset

```dart
// Simulate month change by manually querying different months
final januaryStats = await repository.getCategoryBudgetStats(
  categoryId: categoryId,
  year: 2026,
  month: 1, // January
);

final februaryStats = await repository.getCategoryBudgetStats(
  categoryId: categoryId,
  year: 2026,
  month: 2, // February
);

// February spent should be 0 (new month, no expenses yet)
assert(februaryStats.spent == 0);
```

---

## Next Steps

1. **Start with Phase 1**: Create database migrations
2. **Review existing code**: Study `lib/features/budgets/` for patterns
3. **Read contracts**: Understand API in `contracts/category_budgets_api.md`
4. **Follow roadmap**: Complete phases 2-6 in order
5. **Test frequently**: Verify each phase before moving to next

**Questions?** Reference the detailed docs:
- [Specification](./spec.md)
- [Research](./research.md)
- [Data Model](./data-model.md)
- [API Contracts](./contracts/)
