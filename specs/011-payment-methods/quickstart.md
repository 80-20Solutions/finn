# Payment Methods - Developer Quickstart

**Feature**: `011-payment-methods`
**Branch**: `011-payment-methods`
**Last Updated**: 2026-01-07

## Overview

This guide helps developers implement the payment methods feature by following the established category management pattern. The feature adds payment method tracking to expenses with predefined options (Contanti, Carta di Credito, Bonifico, Satispay) and user-defined custom methods.

---

## Prerequisites

Before starting implementation:

1. **Read these docs** (in order):
   - [ ] [spec.md](./spec.md) - Feature requirements
   - [ ] [research.md](./research.md) - Technical decisions
   - [ ] [data-model.md](./data-model.md) - Data structures
   - [ ] [plan.md](./plan.md) - Implementation strategy

2. **Understand the category pattern**:
   - [ ] Review `lib/features/categories/` structure
   - [ ] Read `lib/features/categories/presentation/providers/category_provider.dart`
   - [ ] Examine `lib/features/categories/presentation/screens/category_management_screen.dart`

3. **Set up local environment**:
   - [ ] Flutter SDK installed (Dart 3.x)
   - [ ] Supabase CLI installed
   - [ ] Local Supabase instance running
   - [ ] Project dependencies installed (`flutter pub get`)

---

## Implementation Phases

### Phase 1: Database Setup (1-2 hours)

#### 1.1 Create Migrations

**File**: `supabase/migrations/0XX_create_payment_methods_table.sql`

```sql
-- Create payment_methods table
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL,
  user_id UUID,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_name_length CHECK (LENGTH(TRIM(name)) BETWEEN 1 AND 50),
  CONSTRAINT chk_default_no_user CHECK (
    (is_default = true AND user_id IS NULL) OR
    (is_default = false AND user_id IS NOT NULL)
  ),
  CONSTRAINT unique_user_payment_method UNIQUE (user_id, LOWER(name))
);

-- Indexes
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id)
  WHERE user_id IS NOT NULL;
CREATE INDEX idx_payment_methods_is_default ON payment_methods(is_default)
  WHERE is_default = true;

-- RLS
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

-- Seed defaults
INSERT INTO payment_methods (id, name, user_id, is_default)
VALUES
  (gen_random_uuid(), 'Contanti', NULL, true),
  (gen_random_uuid(), 'Carta di Credito', NULL, true),
  (gen_random_uuid(), 'Bonifico', NULL, true),
  (gen_random_uuid(), 'Satispay', NULL, true)
ON CONFLICT DO NOTHING;
```

**File**: `supabase/migrations/0XX_add_payment_method_to_expenses.sql`

```sql
-- Add payment method columns to expenses
ALTER TABLE expenses
  ADD COLUMN payment_method_id UUID,
  ADD COLUMN payment_method_name TEXT;

-- Backfill existing expenses with "Contanti"
DO $$
DECLARE
  contanti_id UUID;
BEGIN
  SELECT id INTO contanti_id
  FROM payment_methods
  WHERE name = 'Contanti' AND is_default = true
  LIMIT 1;

  UPDATE expenses
  SET
    payment_method_id = contanti_id,
    payment_method_name = 'Contanti'
  WHERE payment_method_id IS NULL;
END $$;

-- Make NOT NULL
ALTER TABLE expenses
  ALTER COLUMN payment_method_id SET NOT NULL;

-- Foreign key with delete protection
ALTER TABLE expenses
  ADD CONSTRAINT fk_payment_method
  FOREIGN KEY (payment_method_id)
  REFERENCES payment_methods(id)
  ON DELETE RESTRICT;

-- Index
CREATE INDEX idx_expenses_payment_method ON expenses(payment_method_id);
```

#### 1.2 Run Migrations

```bash
# Apply migrations locally
supabase db push

# Verify tables created
supabase db execute --sql "SELECT * FROM payment_methods;"

# Verify expenses updated
supabase db execute --sql "
  SELECT COUNT(*) as total,
         COUNT(payment_method_id) as with_method
  FROM expenses;
"
```

**Checkpoint**: All expenses should have `payment_method_id` set.

---

### Phase 2: Domain Layer (2-3 hours)

#### 2.1 Create Entity

**File**: `lib/features/payment_methods/domain/entities/payment_method_entity.dart`

See [data-model.md](./data-model.md#paymentmethodentity-new) for complete implementation.

**Key Points**:
- Extend `Equatable` for value equality
- Include all fields from database schema
- Add factory constructors (`empty()`, `copyWith()`)

#### 2.2 Create Repository Interface

**File**: `lib/features/payment_methods/domain/repositories/payment_method_repository.dart`

Copy from [contracts/payment_methods_repository.dart](./contracts/payment_methods_repository.dart)

#### 2.3 Update Expense Entity

**File**: `lib/features/expenses/domain/entities/expense_entity.dart`

Add fields:
```dart
final String paymentMethodId;
final String? paymentMethodName;
```

Update `copyWith()` and `props` getter.

**Testing**:
```bash
flutter test test/features/payment_methods/domain/entities/
```

---

### Phase 3: Data Layer (4-5 hours)

#### 3.1 Create Model

**File**: `lib/features/payment_methods/data/models/payment_method_model.dart`

```dart
class PaymentMethodModel extends PaymentMethodEntity {
  // fromJson, toJson, fromEntity
}
```

See [data-model.md](./data-model.md#paymentmethodmodel) for full code.

#### 3.2 Create Remote Data Source

**File**: `lib/features/payment_methods/data/datasources/payment_method_remote_datasource.dart`

**Pattern**: Follow `lib/features/categories/data/datasources/category_remote_datasource.dart`

**Key Methods**:
- `getPaymentMethods(String userId)`: Query with RLS filter
- `createPaymentMethod(...)`: Insert with user_id
- `updatePaymentMethod(...)`: Update by ID
- `deletePaymentMethod(...)`: Delete by ID
- `getExpenseCount(...)`: JOIN count query
- `watchPaymentMethods(...)`: Realtime subscription

**Example Query**:
```dart
Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
  final response = await _supabase
      .from('payment_methods')
      .select()
      .or('is_default.eq.true,user_id.eq.$userId')
      .order('is_default', ascending: false)
      .order('name', ascending: true);

  return (response as List)
      .map((json) => PaymentMethodModel.fromJson(json))
      .toList();
}
```

#### 3.3 Create Cache Data Source (Drift)

**File**: `lib/features/payment_methods/data/datasources/payment_method_cache_datasource.dart`

**Pattern**: Follow `lib/features/offline/data/datasources/category_cache_datasource.dart`

**Steps**:
1. Define Drift table in `lib/features/offline/data/database/app_database.dart`
2. Run code generator: `flutter pub run build_runner build`
3. Implement cache operations (get, insert, update, delete)

#### 3.4 Create Repository Implementation

**File**: `lib/features/payment_methods/data/repositories/payment_method_repository_impl.dart`

**Pattern**: Follow `lib/features/categories/data/repositories/category_repository_impl.dart`

**Strategy**:
- Remote-first for writes
- Cache-first for reads (fallback to remote)
- Update cache on successful remote operations

**Example**:
```dart
@override
Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods({
  required String userId,
}) async {
  try {
    final remote = await _remoteDataSource.getPaymentMethods(userId);
    await _cacheDataSource.cachePaymentMethods(remote);
    return Right(remote);
  } on ServerException catch (e) {
    try {
      final cached = await _cacheDataSource.getCachedPaymentMethods(userId);
      return Right(cached);
    } catch (_) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

#### 3.5 Create Default Constants

**File**: `lib/core/config/default_payment_methods.dart`

```dart
class DefaultPaymentMethods {
  static const List<String> names = [
    'Contanti',
    'Carta di Credito',
    'Bonifico',
    'Satispay',
  ];

  static const String defaultMethod = 'Contanti';
}
```

#### 3.6 Update Expense Model

**File**: `lib/features/expenses/data/models/expense_model.dart`

Add to `fromJson()`:
```dart
paymentMethodId: json['payment_method_id'] as String,
paymentMethodName: json['payment_method_name'] as String?,
```

Add to `toJson()`:
```dart
'payment_method_id': paymentMethodId,
'payment_method_name': paymentMethodName,
```

**Testing**:
```bash
flutter test test/features/payment_methods/data/
```

---

### Phase 4: Presentation Layer - Payment Methods (5-6 hours)

#### 4.1 Create State Class

**File**: `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`

```dart
class PaymentMethodState extends Equatable {
  final List<PaymentMethodEntity> paymentMethods;
  final bool isLoading;
  final String? errorMessage;

  // Getters: defaultMethods, customMethods, getById, defaultContanti
}
```

#### 4.2 Create State Notifier

**Same file as above**:

```dart
class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  final PaymentMethodRepository _repository;
  final String userId;

  Future<void> loadPaymentMethods() async { ... }
  void _subscribeToRealtimeChanges() { ... }
}
```

**Pattern**: Follow `lib/features/categories/presentation/providers/category_provider.dart`

#### 4.3 Create Provider

```dart
final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  // Wire dependencies
});

final paymentMethodProvider = StateNotifierProvider.family<
    PaymentMethodNotifier,
    PaymentMethodState,
    String>((ref, userId) {
  return PaymentMethodNotifier(
    repository: ref.watch(paymentMethodRepositoryProvider),
    userId: userId,
  );
});
```

#### 4.4 Create Actions Provider

**File**: `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`

```dart
class PaymentMethodActions {
  Future<PaymentMethodEntity?> createPaymentMethod({...}) async { ... }
  Future<PaymentMethodEntity?> updatePaymentMethod({...}) async { ... }
  Future<bool> deletePaymentMethod({...}) async { ... }
  Future<int?> getPaymentMethodExpenseCount({...}) async { ... }
}

final paymentMethodActionsProvider = Provider<PaymentMethodActions>((ref) {
  return PaymentMethodActions(ref.watch(paymentMethodRepositoryProvider));
});
```

#### 4.5 Create Management Screen

**File**: `lib/features/payment_methods/presentation/screens/payment_method_management_screen.dart`

**Pattern**: Follow `lib/features/categories/presentation/screens/category_management_screen.dart`

**UI Structure**:
```
Scaffold
├── AppBar (title: "Metodi di Pagamento")
├── Body
│   ├── Section: Default Methods (grayed out, no actions)
│   └── Section: Custom Methods (with edit/delete buttons)
└── FloatingActionButton (label: "Aggiungi Metodo")
```

**Key Features**:
- Load payment methods on init
- Listen to state changes (Riverpod `ref.watch`)
- Show loading indicator while fetching
- Show error message if load fails
- Confirm before delete (with expense count)

#### 4.6 Create Form Dialog

**File**: `lib/features/payment_methods/presentation/widgets/payment_method_form_dialog.dart`

**Pattern**: Follow `lib/features/categories/presentation/widgets/category_form_dialog.dart`

**Validations**:
- Required: Name not empty
- Length: 1-50 characters
- Duplicate: Check if name exists (case-insensitive)

**Modes**:
- Create: `method` parameter is null
- Edit: `method` parameter is non-null

#### 4.7 Create List Item Widget

**File**: `lib/features/payment_methods/presentation/widgets/payment_method_list_item.dart`

**UI**:
```
ListTile
├── Leading: Icon(Icons.payment)
├── Title: method.name
├── Subtitle: "Used by X expenses" (if expenseCount > 0)
└── Trailing: Edit/Delete buttons (only for custom methods)
```

**Testing**:
```bash
flutter test test/features/payment_methods/presentation/
```

---

### Phase 5: Expense Integration (4-5 hours)

#### 5.1 Create Selector Widget

**File**: `lib/features/expenses/presentation/widgets/payment_method_selector.dart`

**UI**: Dropdown or bottom sheet picker

**Features**:
- Load payment methods for current user
- Group visually: "Default" section, "Custom" section
- Default selection: "Contanti" if `selectedId` is null
- Callback on selection: `onChanged(String methodId)`

**Example**:
```dart
class PaymentMethodSelector extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentMethodProvider(userId));

    return DropdownButtonFormField<String>(
      value: selectedId ?? state.defaultContanti?.id,
      decoration: InputDecoration(labelText: 'Metodo di Pagamento'),
      items: [
        // Default methods
        ...state.defaultMethods.map((m) => DropdownMenuItem(
          value: m.id,
          child: Text(m.name),
        )),
        if (state.customMethods.isNotEmpty) DropdownMenuItem(
          enabled: false,
          child: Text('--- Custom ---', style: TextStyle(color: Colors.grey)),
        ),
        // Custom methods
        ...state.customMethods.map((m) => DropdownMenuItem(
          value: m.id,
          child: Text(m.name),
        )),
      ],
      onChanged: (id) => onChanged(id!),
    );
  }
}
```

#### 5.2 Update Manual Expense Screen

**File**: `lib/features/expenses/presentation/screens/manual_expense_screen.dart`

**Changes**:
1. Add state variable: `String? _selectedPaymentMethodId`
2. Add selector widget to form
3. Set default on init: `_selectedPaymentMethodId = defaultContantiId`
4. Pass to repository on save

**Example**:
```dart
// In build()
PaymentMethodSelector(
  selectedId: _selectedPaymentMethodId,
  onChanged: (id) => setState(() => _selectedPaymentMethodId = id),
  userId: currentUser.id,
),

// In _submit()
await expenseRepository.createExpense(
  // ... other fields ...
  paymentMethodId: _selectedPaymentMethodId!,
);
```

#### 5.3 Update Edit Expense Screen

**File**: `lib/features/expenses/presentation/screens/edit_expense_screen.dart`

Same pattern as manual expense screen, but initialize with existing expense's payment method:

```dart
@override
void initState() {
  super.initState();
  _selectedPaymentMethodId = widget.expense.paymentMethodId;
}
```

#### 5.4 Update Expense Detail Screen

**File**: `lib/features/expenses/presentation/screens/expense_detail_screen.dart`

**Changes**:
- Add row to display payment method name
- Use denormalized `expense.paymentMethodName` (no fetch needed)

**Example**:
```dart
_DetailRow(
  label: 'Metodo di Pagamento',
  value: expense.paymentMethodName ?? 'N/A',
  icon: Icons.payment,
),
```

#### 5.5 Update Expense List Item

**File**: `lib/features/expenses/presentation/widgets/expense_list_item.dart`

**Changes**:
- Add payment method icon/label to list tile
- Keep it subtle (secondary info, not primary)

**Example**:
```dart
// In subtitle
Row(
  children: [
    Text(expense.categoryName ?? 'Uncategorized'),
    SizedBox(width: 8),
    Icon(Icons.payment, size: 14, color: Colors.grey),
    SizedBox(width: 4),
    Text(expense.paymentMethodName ?? 'N/A', style: TextStyle(color: Colors.grey)),
  ],
)
```

**Testing**:
```bash
flutter test test/features/expenses/presentation/
```

---

### Phase 6: Navigation & Settings (1 hour)

#### 6.1 Add Route

**File**: `lib/app/routes.dart`

```dart
GoRoute(
  path: '/payment-method-management',
  name: 'payment-method-management',
  builder: (context, state) => const PaymentMethodManagementScreen(),
),
```

#### 6.2 Update Settings Screen

**File**: `lib/features/auth/presentation/screens/settings_screen.dart`

Add after "Category Management":

```dart
ListTile(
  leading: Icon(Icons.payment),
  title: Text('Metodi di Pagamento'),
  subtitle: Text('Gestisci i metodi di pagamento'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => context.push('/payment-method-management'),
),
```

---

### Phase 7: Testing & Validation (3-4 hours)

#### 7.1 Unit Tests

**Test Files**:
- `test/features/payment_methods/domain/entities/payment_method_entity_test.dart`
- `test/features/payment_methods/data/models/payment_method_model_test.dart`
- `test/features/payment_methods/data/repositories/payment_method_repository_impl_test.dart`

**Pattern**: Follow existing test files in `test/features/categories/`

#### 7.2 Widget Tests

**Test Files**:
- `test/features/payment_methods/presentation/widgets/payment_method_form_dialog_test.dart`
- `test/features/payment_methods/presentation/screens/payment_method_management_screen_test.dart`

#### 7.3 Integration Tests

**Test Scenarios**:
1. Create custom payment method → See it in selector
2. Create expense with custom method → View in detail screen
3. Delete payment method in use → See error message
4. Edit payment method name → See updated name in expense form

**Test File**: `integration_test/payment_methods_flow_test.dart`

#### 7.4 Manual Testing Checklist

- [ ] Default methods visible to all users
- [ ] Create custom method
- [ ] Edit custom method name
- [ ] Delete unused custom method
- [ ] Attempt to delete method in use (should fail)
- [ ] Create expense with custom method
- [ ] View expense with payment method in list
- [ ] View expense with payment method in detail
- [ ] Edit expense and change payment method
- [ ] Real-time sync: Add method on device A, see on device B
- [ ] Offline mode: Create expense offline, sync when online

---

## Common Patterns

### Error Handling

```dart
result.fold(
  (failure) {
    if (failure is ValidationFailure) {
      showSnackBar('Validation error: ${failure.message}');
    } else if (failure is ServerFailure) {
      showSnackBar('Server error: ${failure.message}');
    } else {
      showSnackBar('Unknown error');
    }
  },
  (success) {
    // Handle success
  },
);
```

### Loading States

```dart
if (state.isLoading) {
  return LoadingIndicator(message: 'Loading payment methods...');
}
```

### Real-Time Sync

```dart
void _subscribeToRealtimeChanges() {
  final channel = _supabase
      .channel('payment_methods_$userId')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'payment_methods'),
        (payload, [ref]) => loadPaymentMethods(),
      )
      .subscribe();
}
```

---

## Debugging Tips

### Check Database State

```bash
# Count payment methods
supabase db execute --sql "SELECT COUNT(*) FROM payment_methods;"

# View all payment methods
supabase db execute --sql "SELECT * FROM payment_methods ORDER BY is_default DESC, name;"

# Check expenses with payment methods
supabase db execute --sql "
  SELECT e.id, e.payment_method_name, pm.name
  FROM expenses e
  LEFT JOIN payment_methods pm ON pm.id = e.payment_method_id
  LIMIT 10;
"
```

### Check RLS Policies

```bash
# Test as authenticated user
supabase db execute --sql "
  SET ROLE authenticated;
  SET request.jwt.claim.sub = '<user-uuid>';
  SELECT * FROM payment_methods;
"
```

### Check Cache

```dart
// In Drift database class
Future<void> debugPrintCachedPaymentMethods() async {
  final cached = await select(paymentMethods).get();
  print('Cached: ${cached.length} payment methods');
  for (var pm in cached) {
    print('- ${pm.name} (${pm.isDefault ? "default" : "custom"})');
  }
}
```

---

## Rollback Plan

If deployment fails:

1. **Database Rollback**:
   ```sql
   ALTER TABLE expenses DROP CONSTRAINT fk_payment_method;
   ALTER TABLE expenses DROP COLUMN payment_method_id;
   ALTER TABLE expenses DROP COLUMN payment_method_name;
   DROP TABLE payment_methods;
   ```

2. **Code Rollback**:
   ```bash
   git revert <commit-hash>
   ```

3. **Re-deploy Previous Version**:
   ```bash
   flutter build apk
   # Upload to app stores
   ```

---

## Performance Optimization

### Caching

- Payment methods cached locally via Drift
- Cache invalidated on real-time events
- TTL: No expiry (methods rarely change)

### Indexing

- `idx_payment_methods_user_id`: Speeds up user-specific queries
- `idx_expenses_payment_method`: Speeds up expense count queries

### Denormalization

- `payment_method_name` stored in expenses for display
- Avoids JOIN on every expense list query
- Trade-off: Slightly stale data if method renamed (acceptable)

---

## Deployment Checklist

- [ ] All tests passing (`flutter test`)
- [ ] Migrations tested on production copy
- [ ] RLS policies verified
- [ ] Offline mode tested
- [ ] Real-time sync tested
- [ ] Performance tested (large datasets)
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Rollback plan prepared
- [ ] Monitoring alerts configured

---

## Next Steps

1. Run `/speckit.tasks` to generate detailed task list
2. Start with Phase 1 (Database Setup)
3. Proceed sequentially through phases
4. Test each phase before moving to next
5. Deploy to staging first, then production

---

## Support

**Questions?** Refer to:
- [spec.md](./spec.md) - Requirements
- [data-model.md](./data-model.md) - Data structures
- [research.md](./research.md) - Design decisions
- [plan.md](./plan.md) - Implementation plan

**Need help?** Contact the development team.
