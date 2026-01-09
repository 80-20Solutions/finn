# Implementation Plan: Metodi di Pagamento per Spese

**Branch**: `011-payment-methods` | **Date**: 2026-01-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-payment-methods/spec.md`

## Summary

Add payment method tracking to expenses with predefined options (Contanti, Carta di Credito, Bonifico, Satispay) and support for user-defined custom payment methods. Follow the established category management pattern: default items are immutable, custom items can be created/edited/deleted through settings, with protection against deleting methods in use. Migrate existing expenses to default "Contanti" payment method.

## Technical Context

**Language/Version**: Dart 3.x with Flutter SDK
**Primary Dependencies**: Riverpod 2.4.0, GoRouter 12.0, Supabase client, Drift (SQLite offline cache)
**Storage**: Supabase (PostgreSQL) with Row-Level Security, local SQLite cache via Drift
**Testing**: Flutter test framework, widget tests, integration tests
**Target Platform**: iOS & Android (mobile app)
**Project Type**: Mobile (Flutter)
**Performance Goals**: <100ms UI response time, real-time sync across devices
**Constraints**: Offline-capable, must work with existing expense data, multi-user group support
**Scale/Scope**: 4 default payment methods, unlimited custom methods per user, ~20 files to modify/create

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ✅ PASS (Constitution file is empty template - no violations possible)

Since the constitution file contains only placeholder content, there are no specific principles to validate against. The implementation will follow established Flutter/Dart best practices and match existing codebase patterns:

- Clean Architecture (Domain/Data/Presentation layers)
- Repository Pattern for data access
- State management via Riverpod
- Offline-first with Supabase sync
- Test coverage for business logic

**Re-evaluation after Phase 1**: Will verify alignment with discovered patterns from category management implementation.

## Project Structure

### Documentation (this feature)

```text
specs/011-payment-methods/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (database design, patterns)
├── data-model.md        # Phase 1 output (entities, relationships)
├── quickstart.md        # Phase 1 output (dev guide)
├── contracts/           # Phase 1 output (API schema)
│   └── payment_methods_schema.yaml
├── checklists/          # Validation checklists
│   └── requirements.md  # Spec quality checklist (completed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── config/
│       └── default_payment_methods.dart         # NEW: Predefined methods list
│
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── expense_entity.dart          # MODIFY: Add paymentMethodId field
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── expense_model.dart           # MODIFY: Add paymentMethodId serialization
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── manual_expense_screen.dart   # MODIFY: Add payment method selector
│   │       │   ├── edit_expense_screen.dart     # MODIFY: Add payment method selector
│   │       │   └── expense_detail_screen.dart   # MODIFY: Display payment method
│   │       └── widgets/
│   │           ├── expense_list_item.dart       # MODIFY: Display payment method
│   │           └── payment_method_selector.dart # NEW: Dropdown/picker widget
│   │
│   └── payment_methods/                         # NEW FEATURE MODULE
│       ├── domain/
│       │   ├── entities/
│       │   │   └── payment_method_entity.dart   # NEW: Payment method entity
│       │   └── repositories/
│       │       └── payment_method_repository.dart # NEW: Repository interface
│       ├── data/
│       │   ├── models/
│       │   │   └── payment_method_model.dart    # NEW: JSON serialization model
│       │   ├── repositories/
│       │   │   └── payment_method_repository_impl.dart # NEW: Repository implementation
│       │   └── datasources/
│       │       ├── payment_method_remote_datasource.dart # NEW: Supabase queries
│       │       └── payment_method_cache_datasource.dart  # NEW: Drift offline cache
│       └── presentation/
│           ├── providers/
│           │   ├── payment_method_provider.dart        # NEW: State management
│           │   └── payment_method_actions_provider.dart # NEW: User actions
│           ├── screens/
│           │   └── payment_method_management_screen.dart # NEW: Settings screen
│           └── widgets/
│               ├── payment_method_list_item.dart      # NEW: List display
│               └── payment_method_form_dialog.dart    # NEW: Create/edit form
│
└── app/
    └── routes.dart                              # MODIFY: Add payment method management route

supabase/
└── migrations/
    ├── 0XX_create_payment_methods_table.sql     # NEW: Table schema
    └── 0XX_migrate_expenses_payment_method.sql  # NEW: Data migration to "Contanti"
```

**Structure Decision**: Mobile app following clean architecture with feature modules. New `payment_methods` feature follows the exact pattern established by `categories` feature. This ensures consistency and reuses proven patterns for custom item management.

## Complexity Tracking

> **No violations** - Implementation follows existing patterns without introducing new complexity.

The payment methods feature mirrors the categories implementation, which is already proven in the codebase:
- Same clean architecture layers (domain/data/presentation)
- Same Riverpod state management pattern
- Same custom item management UX (Settings → Payment Methods)
- Same validation rules (duplicate detection, usage prevention on delete)

## Phase 0: Research & Analysis

### Research Topics

1. **Database Schema Design**
   - Payment methods table structure
   - Relationship with expenses table
   - Migration strategy for existing data
   - Indexes for query performance

2. **State Management Pattern**
   - Review category provider implementation
   - Document provider dependencies
   - Real-time sync strategy
   - Offline cache invalidation

3. **Form Validation**
   - Name validation rules (1-50 chars, no duplicates)
   - Case-insensitive duplicate detection
   - User-scoped uniqueness (personal methods)

4. **Default Payment Methods**
   - Constant definition location
   - Seeding strategy on first use
   - Immutability enforcement

5. **Migration Strategy**
   - Adding payment_method_id to expenses
   - Backfilling existing expenses with "Contanti"
   - Handling concurrent updates during migration
   - Rollback plan if migration fails

### Dependencies Analysis

**Internal Dependencies:**
- Expense entity/model (must be modified)
- Settings navigation (add new route)
- Group context (for user_id filtering)
- Auth provider (for current user)

**External Dependencies:**
- Supabase migrations (database schema changes)
- Drift schema generator (for offline cache)

**Risk Areas:**
- Data migration must be atomic and reversible
- Expense forms must have backward compatibility during rollout
- Real-time sync must handle new payment_method_id field

## Phase 1: Design

### Data Model

**Entity**: `PaymentMethodEntity`

```dart
class PaymentMethodEntity {
  final String id;                 // UUID
  final String name;               // 1-50 chars, unique per user
  final String userId;             // Owner (null for default methods)
  final bool isDefault;            // true = predefined, false = custom
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? expenseCount;         // Optional, for UI display
}
```

**Modified Entity**: `ExpenseEntity`

```dart
class ExpenseEntity {
  // ... existing fields ...
  final String paymentMethodId;    // NEW: FK to payment_methods (required)
  final String? paymentMethodName; // NEW: Denormalized for display
}
```

### Database Schema

**New Table**: `payment_methods`

```sql
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL,
  user_id UUID,                          -- NULL for default methods
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_user_payment_method UNIQUE (user_id, name)
);

-- RLS policies
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view default payment methods"
  ON payment_methods FOR SELECT
  USING (is_default = true);

CREATE POLICY "Users can view their custom payment methods"
  ON payment_methods FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create their custom payment methods"
  ON payment_methods FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_default = false);

CREATE POLICY "Users can update their custom payment methods"
  ON payment_methods FOR UPDATE
  USING (user_id = auth.uid() AND is_default = false);

CREATE POLICY "Users can delete their custom payment methods"
  ON payment_methods FOR DELETE
  USING (user_id = auth.uid() AND is_default = false);

-- Indexes
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_is_default ON payment_methods(is_default);
```

**Modified Table**: `expenses`

```sql
ALTER TABLE expenses
  ADD COLUMN payment_method_id UUID,
  ADD COLUMN payment_method_name TEXT;

-- After migration:
ALTER TABLE expenses
  ALTER COLUMN payment_method_id SET NOT NULL;

-- Foreign key
ALTER TABLE expenses
  ADD CONSTRAINT fk_payment_method
  FOREIGN KEY (payment_method_id)
  REFERENCES payment_methods(id)
  ON DELETE RESTRICT;  -- Prevent deletion of methods in use

-- Index for queries
CREATE INDEX idx_expenses_payment_method ON expenses(payment_method_id);
```

**Seed Data**: Default payment methods

```sql
INSERT INTO payment_methods (id, name, user_id, is_default)
VALUES
  (uuid_generate_v4(), 'Contanti', NULL, true),
  (uuid_generate_v4(), 'Carta di Credito', NULL, true),
  (uuid_generate_v4(), 'Bonifico', NULL, true),
  (uuid_generate_v4(), 'Satispay', NULL, true);
```

**Migration**: Existing expenses

```sql
-- Step 1: Add default "Contanti" method if not exists
WITH contanti AS (
  SELECT id FROM payment_methods
  WHERE name = 'Contanti' AND is_default = true
  LIMIT 1
)
-- Step 2: Update all expenses without payment method
UPDATE expenses
SET
  payment_method_id = (SELECT id FROM contanti),
  payment_method_name = 'Contanti'
WHERE payment_method_id IS NULL;
```

### API Contracts

**Repository Interface**: `PaymentMethodRepository`

```dart
abstract class PaymentMethodRepository {
  /// Fetch all payment methods available to the current user
  /// (default methods + user's custom methods)
  Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods({
    required String userId,
  });

  /// Fetch a single payment method by ID
  Future<Either<Failure, PaymentMethodEntity>> getPaymentMethodById({
    required String id,
  });

  /// Create a new custom payment method
  Future<Either<Failure, PaymentMethodEntity>> createPaymentMethod({
    required String userId,
    required String name,
  });

  /// Update a custom payment method's name
  Future<Either<Failure, PaymentMethodEntity>> updatePaymentMethod({
    required String id,
    required String name,
  });

  /// Delete a custom payment method (fails if in use)
  Future<Either<Failure, bool>> deletePaymentMethod({
    required String id,
  });

  /// Count expenses using this payment method
  Future<Either<Failure, int>> getPaymentMethodExpenseCount({
    required String id,
  });

  /// Check if a payment method name already exists for this user
  Future<Either<Failure, bool>> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,  // For edit validation
  });

  /// Stream for real-time payment method updates
  Stream<List<PaymentMethodEntity>> watchPaymentMethods({
    required String userId,
  });
}
```

**Actions Provider**: `PaymentMethodActions`

```dart
class PaymentMethodActions {
  final PaymentMethodRepository _repository;

  /// Create a new custom payment method with validation
  Future<PaymentMethodEntity?> createPaymentMethod({
    required String userId,
    required String name,
  }) async {
    // Validate name
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw ValidationException('Name must be 1-50 characters');
    }

    // Check for duplicates
    final exists = await _repository.paymentMethodNameExists(
      userId: userId,
      name: trimmed,
    );
    if (exists.isRight() && exists.getOrElse(() => false)) {
      throw ValidationException('Payment method already exists');
    }

    // Create
    final result = await _repository.createPaymentMethod(
      userId: userId,
      name: trimmed,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (method) => method,
    );
  }

  /// Update custom payment method name with validation
  Future<PaymentMethodEntity?> updatePaymentMethod({
    required String id,
    required String userId,
    required String name,
  }) async {
    // Same validation as create
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw ValidationException('Name must be 1-50 characters');
    }

    // Check for duplicates (excluding current method)
    final exists = await _repository.paymentMethodNameExists(
      userId: userId,
      name: trimmed,
      excludeId: id,
    );
    if (exists.isRight() && exists.getOrElse(() => false)) {
      throw ValidationException('Payment method already exists');
    }

    // Update
    final result = await _repository.updatePaymentMethod(
      id: id,
      name: trimmed,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (method) => method,
    );
  }

  /// Delete custom payment method (with usage check)
  Future<bool> deletePaymentMethod({
    required String id,
  }) async {
    // Check if in use
    final countResult = await _repository.getPaymentMethodExpenseCount(id: id);
    final count = countResult.getOrElse(() => 0);

    if (count > 0) {
      throw ValidationException(
        'Cannot delete payment method used by $count expense(s)',
      );
    }

    // Delete
    final result = await _repository.deletePaymentMethod(id: id);
    return result.getOrElse(() => false);
  }

  /// Get expense count for a payment method
  Future<int?> getPaymentMethodExpenseCount({
    required String id,
  }) async {
    final result = await _repository.getPaymentMethodExpenseCount(id: id);
    return result.fold(
      (_) => null,
      (count) => count,
    );
  }
}
```

### State Management

**State Class**:

```dart
class PaymentMethodState {
  final List<PaymentMethodEntity> paymentMethods;
  final bool isLoading;
  final String? errorMessage;

  List<PaymentMethodEntity> get defaultMethods =>
      paymentMethods.where((m) => m.isDefault).toList();

  List<PaymentMethodEntity> get customMethods =>
      paymentMethods.where((m) => !m.isDefault).toList();

  PaymentMethodEntity? getById(String id) =>
      paymentMethods.firstWhereOrNull((m) => m.id == id);
}
```

**Provider Hierarchy**:

```dart
// Repository
final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final remoteDataSource = PaymentMethodRemoteDataSource(supabaseClient);
  final cacheDataSource = PaymentMethodCacheDataSource();
  return PaymentMethodRepositoryImpl(
    remoteDataSource: remoteDataSource,
    cacheDataSource: cacheDataSource,
  );
});

// State
final paymentMethodProvider = StateNotifierProvider.family<
    PaymentMethodNotifier,
    PaymentMethodState,
    String>((ref, userId) {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  return PaymentMethodNotifier(repository: repository, userId: userId);
});

// Actions
final paymentMethodActionsProvider = Provider<PaymentMethodActions>((ref) {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  return PaymentMethodActions(repository);
});
```

### UI Components

**Payment Method Selector** (for expense forms):

```dart
class PaymentMethodSelector extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String userId;

  // Displays dropdown with default + custom methods
  // Groups visually: "Default" section, "Custom" section
  // Default value: "Contanti" if selectedId is null
}
```

**Payment Method Management Screen** (Settings):

```dart
class PaymentMethodManagementScreen extends ConsumerStatefulWidget {
  // Lists default methods (non-editable, grayed out)
  // Lists custom methods (with edit/delete buttons)
  // FAB: "Add Payment Method"
  // Shows expense count per method
  // Confirms before delete (shows count if > 0)
}
```

**Payment Method Form Dialog**:

```dart
class PaymentMethodFormDialog extends StatefulWidget {
  final PaymentMethodEntity? method;  // null = create, non-null = edit
  final String userId;

  // Text field with validation
  // Duplicate name detection (case-insensitive)
  // Submit button with loading state
  // Error display
}
```

### Navigation

**Route Addition** (in `lib/app/routes.dart`):

```dart
GoRoute(
  path: '/payment-method-management',
  name: 'payment-method-management',
  builder: (context, state) => const PaymentMethodManagementScreen(),
),
```

**Settings Screen Integration** (in `lib/features/auth/presentation/screens/settings_screen.dart`):

Add list item after "Category Management":

```dart
ListTile(
  leading: Icon(Icons.payment),
  title: Text('Metodi di Pagamento'),
  subtitle: Text('Gestisci i metodi di pagamento'),
  onTap: () => context.push('/payment-method-management'),
),
```

## Phase 2: Tasks Generation

*Tasks will be generated in the next phase using `/speckit.tasks` command.*

Task generation will produce a dependency-ordered list covering:

1. **Database Layer** (T001-T005)
   - Create migration for payment_methods table
   - Create migration for expenses table modification
   - Create seed data for default methods
   - Create migration for existing expense backfill
   - Test migrations locally

2. **Domain Layer** (T006-T008)
   - Create PaymentMethodEntity
   - Create PaymentMethodRepository interface
   - Modify ExpenseEntity

3. **Data Layer** (T009-T015)
   - Create PaymentMethodModel
   - Create PaymentMethodRemoteDataSource
   - Create PaymentMethodCacheDataSource (Drift)
   - Create PaymentMethodRepositoryImpl
   - Modify ExpenseModel
   - Create default payment methods config file
   - Unit tests for data layer

4. **Presentation Layer - Payment Methods** (T016-T021)
   - Create PaymentMethodProvider
   - Create PaymentMethodActions
   - Create PaymentMethodManagementScreen
   - Create PaymentMethodFormDialog
   - Create PaymentMethodListItem widget
   - Widget tests

5. **Presentation Layer - Expense Integration** (T022-T027)
   - Create PaymentMethodSelector widget
   - Modify ManualExpenseScreen
   - Modify EditExpenseScreen
   - Modify ExpenseDetailScreen
   - Modify ExpenseListItem
   - Integration tests

6. **Navigation & Settings** (T028-T029)
   - Add route to routes.dart
   - Update SettingsScreen

7. **Testing & Validation** (T030-T033)
   - End-to-end test: create custom method
   - End-to-end test: assign method to expense
   - End-to-end test: delete protection
   - Verify migration on test database

8. **Documentation** (T034)
   - Update README/documentation

## Constitution Check (Post-Design)

**Re-evaluation Status**: ✅ PASS

The implementation design follows all established patterns from the codebase:

- ✅ Clean Architecture maintained (domain/data/presentation)
- ✅ Repository Pattern used consistently
- ✅ Riverpod state management as per existing features
- ✅ Offline support via Drift cache (matches categories)
- ✅ Real-time sync pattern reused from categories
- ✅ Form validation consistent with category forms
- ✅ Settings navigation follows existing structure
- ✅ Database migrations follow existing numbering/pattern
- ✅ RLS policies protect user data
- ✅ Error handling uses Either/Failure pattern

**No new complexity introduced** - This is a mirror implementation of the existing category management feature with domain-specific changes (payment methods instead of categories, user-scoped instead of group-scoped).

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data migration fails on large datasets | HIGH | Test migration on production copy first, add transaction rollback, monitor progress |
| Payment method deletion while expense is being created | MEDIUM | Database FK constraint (ON DELETE RESTRICT) prevents orphaned references |
| Real-time sync conflicts between devices | MEDIUM | Supabase handles conflict resolution, cache invalidation on sync errors |
| Default methods accidentally modified | LOW | RLS policies prevent updates to is_default=true records |
| User creates method with same name as default | LOW | Validation allows it (names are user-scoped), UI shows both clearly |

## Success Metrics

- ✅ All 18 functional requirements from spec.md implemented
- ✅ 100% of expenses have payment_method_id after migration
- ✅ Default methods cannot be edited/deleted
- ✅ Custom methods can be created/edited/deleted (with protection)
- ✅ Payment method visible in expense list and detail views
- ✅ Offline mode works for both viewing and creating with payment methods
- ✅ Real-time sync propagates custom method changes across devices
- ✅ Settings screen has "Payment Method Management" option
- ✅ No breaking changes to existing expense workflows

## Next Steps

1. Run `/speckit.tasks` to generate detailed implementation tasks
2. Review and approve task list
3. Execute tasks in dependency order
4. Test migration on staging environment before production
5. Deploy database migrations first, then app updates
