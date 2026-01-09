# Research: Payment Methods Implementation

**Feature**: `011-payment-methods`
**Date**: 2026-01-07
**Purpose**: Document research findings and design decisions for payment method tracking

## Executive Summary

This feature adds payment method tracking to expenses by mirroring the proven category management pattern. Research confirms the existing architecture supports the new feature without modifications. All unknowns from Technical Context have been resolved through codebase analysis.

## Research Findings

### 1. Database Schema Design

**Question**: How should payment methods be structured in the database?

**Decision**: Create a dedicated `payment_methods` table with user-scoped custom methods and null-user default methods.

**Rationale**:
- Follows the same pattern as `expense_categories` table
- User-scoped uniqueness via composite unique constraint `(user_id, name)`
- Default methods have `user_id = NULL` and `is_default = true`
- RLS policies enforce isolation (users see defaults + their own custom methods)
- Foreign key constraint on expenses prevents orphaned references

**Alternatives Considered**:
1. **Enum in application code only** - Rejected: Not extensible for custom methods
2. **Single shared table for all users** - Rejected: Violates user privacy requirement from spec (methods are personal)
3. **Embedded JSON in user preferences** - Rejected: No referential integrity, complex querying

**Implementation Details**:
```sql
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  user_id UUID,  -- NULL for defaults
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  UNIQUE(user_id, name)
);
```

### 2. Migration Strategy for Existing Data

**Question**: How to safely backfill existing expenses with payment methods?

**Decision**: Two-phase migration with nullable-then-required pattern.

**Rationale**:
- Phase 1: Add nullable `payment_method_id` column to expenses
- Phase 2: Backfill all NULL values with "Contanti" default method
- Phase 3: Make column NOT NULL after backfill completes
- Ensures zero downtime and rollback capability
- Matches pattern from budget amount conversion migration (commits 42587b5, 40a9c8d)

**Alternatives Considered**:
1. **Direct NOT NULL addition** - Rejected: Breaks existing data immediately
2. **Application-level default** - Rejected: Doesn't fix historical data
3. **Lazy migration on read** - Rejected: Inconsistent state, complex logic

**Rollback Plan**:
```sql
-- If migration fails, rollback via:
ALTER TABLE expenses DROP COLUMN payment_method_id;
ALTER TABLE expenses DROP COLUMN payment_method_name;
DROP TABLE payment_methods;
```

**Testing Strategy**:
- Test on production database copy first
- Monitor migration progress with row counts
- Verify zero NULL payment_method_id after completion

### 3. State Management Pattern

**Question**: How should payment method state be managed in the Flutter app?

**Decision**: Use Riverpod StateNotifier with family parameter for userId, identical to category provider pattern.

**Rationale**:
- Existing `categoryProvider` implementation is well-tested and proven
- Family parameter allows per-user state isolation
- Real-time subscriptions via Supabase Realtime work seamlessly
- Offline cache via Drift provides resilience
- Pattern documented in `lib/features/categories/presentation/providers/category_provider.dart`

**Key Findings from Category Implementation**:
```dart
// State Notifier pattern
class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  final PaymentMethodRepository _repository;
  final String userId;

  Future<void> loadPaymentMethods() async {
    // Load from repository
    // Update state
    // Subscribe to real-time changes
  }
}

// Provider definition
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

**Alternatives Considered**:
1. **Single global provider** - Rejected: Doesn't support multi-user scenarios
2. **BLoC pattern** - Rejected: Project uses Riverpod exclusively
3. **Provider without family** - Rejected: Can't scope to user

### 4. Form Validation Rules

**Question**: What validation rules are needed for payment method names?

**Decision**: Match category validation: 1-50 characters, case-insensitive duplicate detection, user-scoped uniqueness.

**Rationale**:
- Consistency with existing category validation (see `category_form_dialog.dart`)
- Database constraint `VARCHAR(50)` enforces max length
- `UNIQUE(user_id, name)` constraint prevents duplicates at DB level
- Application validation provides immediate user feedback

**Implementation Pattern from Categories**:
```dart
// From lib/features/categories/presentation/widgets/category_form_dialog.dart
Future<void> _submit() async {
  final trimmed = _controller.text.trim();

  // Length validation
  if (trimmed.isEmpty || trimmed.length > 50) {
    setState(() => _error = 'Name must be 1-50 characters');
    return;
  }

  // Duplicate check
  final exists = await ref.read(categoryActionsProvider).categoryNameExists(
    groupId: widget.groupId,
    name: trimmed,
    excludeCategoryId: widget.category?.id,
  );

  if (exists) {
    setState(() => _error = 'Category already exists');
    return;
  }

  // Create/update
  await _createOrUpdate(trimmed);
}
```

**Validation Rules**:
1. Required: Name cannot be empty
2. Length: 1-50 characters
3. Trimming: Whitespace trimmed before validation
4. Uniqueness: Case-insensitive within user's methods
5. Excludes current: Edit mode excludes self from duplicate check

### 5. Default Payment Methods Configuration

**Question**: Where should default payment methods be defined and how are they seeded?

**Decision**: Define as Dart constants in `lib/core/config/default_payment_methods.dart`, seed via database migration.

**Rationale**:
- Matches pattern from `lib/core/config/default_italian_categories.dart`
- Database migration ensures all environments have consistent defaults
- Application constant provides compile-time reference
- No runtime dependency on migration state

**Pattern from Default Categories**:
```dart
// lib/core/config/default_italian_categories.dart
class DefaultItalianCategories {
  static const List<String> names = [
    'Spesa',
    'Benzina',
    'Ristoranti',
    // ...
  ];
}
```

**Proposed for Payment Methods**:
```dart
// lib/core/config/default_payment_methods.dart
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

**Seeding Strategy**:
- Migration file inserts defaults once on initial setup
- Idempotent: `INSERT ... ON CONFLICT DO NOTHING` pattern
- Seeded at database level, not application level
- Cannot be deleted due to FK constraint and RLS policies

**Alternatives Considered**:
1. **Application-level seeding** - Rejected: Race conditions, inconsistent timing
2. **Hard-coded UUIDs** - Rejected: Not portable across environments
3. **No constants file** - Rejected: Magic strings in code

### 6. Offline Cache Strategy

**Question**: How should payment methods be cached for offline use?

**Decision**: Use Drift (SQLite) local database with sync on network reconnection, matching category cache pattern.

**Rationale**:
- Category feature already implements offline caching successfully
- Drift provides encrypted local storage (SQLCipher)
- Automatic schema generation from table definitions
- Proven sync strategy: cache-first reads, remote-first writes
- Pattern documented in `lib/features/offline/data/datasources/category_cache_datasource.dart`

**Cache Invalidation Strategy**:
1. **On write operations**: Immediately update cache after successful remote write
2. **On network reconnect**: Fetch latest from remote and replace cache
3. **On real-time event**: Update cache when Supabase broadcasts changes
4. **On TTL expiry**: Optional, not implemented for categories (not needed for infrequent data)

**Drift Table Definition** (similar to categories):
```dart
class PaymentMethodsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get userId => text().nullable()();
  BoolColumn get isDefault => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Sync Logic**:
```dart
// Repository implementation
Future<List<PaymentMethodEntity>> getPaymentMethods(String userId) async {
  try {
    // Try remote first
    final remote = await _remoteDataSource.getPaymentMethods(userId);
    await _cacheDataSource.cachePaymentMethods(remote);
    return remote;
  } catch (e) {
    // Fallback to cache if network fails
    return await _cacheDataSource.getCachedPaymentMethods(userId);
  }
}
```

### 7. Real-Time Sync Architecture

**Question**: How should payment method changes sync across user devices?

**Decision**: Subscribe to Supabase Realtime channel for payment_methods table changes, reusing category sync pattern.

**Rationale**:
- Supabase Realtime provides PostgresChangeEvent for INSERT/UPDATE/DELETE
- Category provider already implements this successfully
- Zero additional infrastructure needed
- Automatic conflict resolution via Supabase's PostgreSQL replication

**Implementation Pattern from Categories**:
```dart
void _subscribeToRealtimeChanges() {
  final channel = _supabase
      .channel('payment_methods_$userId')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'payment_methods',
        ),
        (payload, [ref]) {
          if (payload['eventType'] == 'INSERT' ||
              payload['eventType'] == 'UPDATE' ||
              payload['eventType'] == 'DELETE') {
            // Reload payment methods
            loadPaymentMethods();
          }
        },
      )
      .subscribe();
}
```

**Conflict Resolution**:
- Last-write-wins (LWW) via `updated_at` timestamp
- Handled automatically by PostgreSQL replication
- No application-level conflict detection needed

**Performance Considerations**:
- Channel per user to reduce event noise
- Debounce reload calls (max 1 per second)
- Batch updates if multiple events in quick succession

### 8. Delete Protection Mechanism

**Question**: How to prevent deletion of payment methods currently in use?

**Decision**: Database-level foreign key constraint with `ON DELETE RESTRICT` + application-level validation for better UX.

**Rationale**:
- FK constraint is the ultimate safeguard (prevents data corruption)
- Application check provides user-friendly error message with count
- Two-layer protection follows defense-in-depth principle
- Pattern used successfully for category deletion

**Database Layer**:
```sql
ALTER TABLE expenses
  ADD CONSTRAINT fk_payment_method
  FOREIGN KEY (payment_method_id)
  REFERENCES payment_methods(id)
  ON DELETE RESTRICT;  -- Prevents deletion if FK exists
```

**Application Layer** (from `PaymentMethodActions`):
```dart
Future<bool> deletePaymentMethod(String id) async {
  // Check usage before attempting delete
  final count = await _repository.getPaymentMethodExpenseCount(id: id);

  if (count > 0) {
    throw ValidationException(
      'Cannot delete payment method used by $count expense(s)',
    );
  }

  // Proceed with delete
  return await _repository.deletePaymentMethod(id: id);
}
```

**User Experience**:
1. User clicks delete on payment method
2. Application checks expense count
3. If count > 0: Show alert with count, prevent delete
4. If count == 0: Confirm and delete
5. If FK constraint violation somehow occurs: Catch error, show generic message

**Alternatives Considered**:
1. **Application-only validation** - Rejected: Race condition between check and delete
2. **Soft delete** - Rejected: Spec doesn't require retention, adds complexity
3. **Reassignment wizard** - Rejected: Out of scope for V1

## Dependencies Analysis

### Internal Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Expense entity/model | Must modify | Add `paymentMethodId` and `paymentMethodName` fields |
| Settings navigation | Must extend | Add route to `/payment-method-management` |
| Auth provider | Exists | Use for `currentUserProvider` to get user ID |
| Supabase client | Exists | Shared service for remote queries |
| Drift database | Exists | Extend schema for payment_methods cache table |
| GoRouter | Exists | Add route definition |

### External Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Riverpod | 2.4.0 | State management |
| Supabase Flutter | Latest | Backend SDK |
| Drift | Latest | Local SQLite cache |
| GoRouter | 12.0 | Navigation |

**No new external dependencies required** - All necessary packages already in project.

### Risk Areas

1. **Data migration atomicity**
   - **Risk**: Migration fails midway, leaving partial state
   - **Mitigation**: Wrap in transaction, test on production copy first

2. **Concurrent expense creation during migration**
   - **Risk**: New expenses created with NULL payment_method_id during migration
   - **Mitigation**: Make column nullable initially, set NOT NULL after backfill completes

3. **Real-time sync latency**
   - **Risk**: User creates custom method, doesn't appear immediately in expense form
   - **Mitigation**: Optimistic updates in UI, fallback to polling

4. **Cache invalidation timing**
   - **Risk**: Stale cached methods shown after remote changes
   - **Mitigation**: Real-time subscriptions trigger immediate cache refresh

## Technical Decisions Summary

| Decision | Choice | Alternative Rejected |
|----------|--------|---------------------|
| Data Model | Dedicated table | Enum or JSON field |
| User Scope | Personal (user_id scoped) | Group-shared |
| Default Methods | Database-seeded | Application constants only |
| State Management | Riverpod StateNotifier.family | BLoC or global provider |
| Offline Cache | Drift SQLite | Hive or SharedPreferences |
| Real-Time Sync | Supabase Realtime | Polling or push notifications |
| Delete Protection | FK constraint + app validation | App-only or soft delete |
| Migration Strategy | Nullable→Backfill→NOT NULL | Direct NOT NULL |

## Open Questions (Resolved)

All questions from Phase 0 Research Topics have been resolved:

1. ✅ Database schema design - Documented above
2. ✅ State management pattern - Use Riverpod family provider
3. ✅ Form validation rules - 1-50 chars, case-insensitive unique
4. ✅ Default payment methods - Seeded via migration, constants file for reference
5. ✅ Migration strategy - Nullable→Backfill→NOT NULL pattern
6. ✅ Offline cache - Drift with cache-first reads
7. ✅ Real-time sync - Supabase Realtime channels
8. ✅ Delete protection - FK constraint + application check

No clarifications needed from stakeholders. All decisions based on existing codebase patterns and best practices.

## References

### Codebase Patterns

- Category management: `lib/features/categories/**`
- Expense entity: `lib/features/expenses/domain/entities/expense_entity.dart`
- Budget migration example: `supabase/migrations/008_standardize_budget_amounts.sql`
- Default config pattern: `lib/core/config/default_italian_categories.dart`
- Offline cache: `lib/features/offline/data/datasources/category_cache_datasource.dart`

### External Documentation

- [Riverpod Family Providers](https://riverpod.dev/docs/concepts/modifiers/family)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Drift Database](https://drift.simonbinder.eu/docs/getting-started/)
- [PostgreSQL FK Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK)

## Conclusion

Research confirms the feature is technically feasible using existing patterns and infrastructure. No unknowns remain. Ready to proceed with detailed design in Phase 1.

**Next**: Generate `data-model.md` with complete entity and schema definitions.
