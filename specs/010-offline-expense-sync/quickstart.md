# Quickstart: Offline Expense Sync Implementation

**Feature**: 010-offline-expense-sync
**Date**: 2026-01-07
**For**: Flutter developers implementing offline support
**Estimated Effort**: 3-5 days for core feature, +2 days for testing/polish

## Prerequisites

- ✅ Completed Phase 0 (research.md) and Phase 1 (data-model.md, contracts/*)
- ✅ Familiarity with Drift ORM, Riverpod state management, Supabase
- ✅ Access to Supabase project SQL Editor for creating RPC functions
- ✅ Understanding of Clean Architecture (data/domain/presentation layers)

---

## Implementation Roadmap

### Day 1: Setup & Data Layer (6-8 hours)

**Goal**: Configure encrypted Drift database with offline tables

#### Step 1.1: Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^6.1.0
  sqlcipher_flutter_libs: ^0.6.1
  workmanager: ^0.5.2

  # Already present:
  # drift: ^2.14.0
  # flutter_secure_storage: ^9.0.0
  # uuid: ^4.0.0
```

Run: `flutter pub get`

#### Step 1.2: Create Drift Tables
Create `lib/features/offline/data/local/offline_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

// Import table definitions (see data-model.md)
part 'offline_database.g.dart';

// Table: OfflineExpenses
class OfflineExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get categoryId => text()();
  TextColumn get merchant => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isGroupExpense => boolean().withDefault(const Constant(true))();
  TextColumn get localReceiptPath => text().nullable()();
  IntColumn get receiptImageSize => integer().nullable()();
  TextColumn get syncStatus => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttemptAt => dateTime().nullable()();
  TextColumn get syncErrorMessage => text().nullable()();
  BoolColumn get hasConflict => boolean().withDefault(const Constant(false))();
  TextColumn get serverVersionData => text().nullable()();
  DateTimeColumn get localCreatedAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: SyncQueueItems
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get operation => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  TextColumn get syncStatus => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: OfflineExpenseImages (similar pattern)
// Table: SyncConflicts (optional)

@DriftDatabase(tables: [OfflineExpenses, SyncQueueItems /*, ... */])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      // Get encryption key from secure storage
      final secureStorage = const FlutterSecureStorage();
      String? key = await secureStorage.read(key: 'drift_encryption_key');

      if (key == null) {
        // Generate new key
        key = base64.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
        await secureStorage.write(key: 'drift_encryption_key', value: key);
      }

      // Get database path
      final dbPath = await _getDatabasePath();
      final file = File(dbPath);

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          rawDb.execute('PRAGMA key = "$key"');
          rawDb.execute('PRAGMA cipher_page_size = 4096');
          rawDb.execute('PRAGMA kdf_iter = 64000');
        },
      );
    });
  }

  static Future<String> _getDatabasePath() async {
    // Platform-specific logic
    // Android: getApplicationDocumentsDirectory() / 'offline_expenses.db'
    // iOS: same
    // See research.md for details
  }
}
```

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

#### Step 1.3: Create Data Sources
Create `lib/features/offline/data/datasources/offline_expense_local_datasource.dart`:

```dart
abstract class OfflineExpenseLocalDataSource {
  Future<OfflineExpense> createOfflineExpense({...});
  Future<List<OfflineExpense>> getPendingExpenses();
  Future<void> updateSyncStatus(String id, String status);
  // ... other methods
}

class OfflineExpenseLocalDataSourceImpl implements OfflineExpenseLocalDataSource {
  final OfflineDatabase _db;
  final AuthService _authService;
  final Uuid _uuid;

  @override
  Future<OfflineExpense> createOfflineExpense({
    required double amount,
    required DateTime date,
    required String categoryId,
    String? merchant,
    String? notes,
    bool isGroupExpense = true,
  }) async {
    final userId = await _authService.getCurrentUserId();
    final expenseId = _uuid.v4();

    final companion = OfflineExpensesCompanion.insert(
      id: expenseId,
      userId: userId,
      amount: amount,
      date: date,
      categoryId: categoryId,
      merchant: Value(merchant),
      notes: Value(notes),
      isGroupExpense: isGroupExpense,
      syncStatus: 'pending',
      localCreatedAt: DateTime.now(),
      localUpdatedAt: DateTime.now(),
    );

    await _db.into(_db.offlineExpenses).insert(companion);

    // Add to sync queue
    await _addToSyncQueue('create', 'expense', expenseId, companion.toJson());

    return _db.offlineExpenses.select()
      .where((e) => e.id.equals(expenseId))
      .getSingle();
  }

  Future<void> _addToSyncQueue(String operation, String entityType, String entityId, Map<String, dynamic> payload) async {
    final userId = await _authService.getCurrentUserId();
    await _db.into(_db.syncQueueItems).insert(
      SyncQueueItemsCompanion.insert(
        userId: userId,
        operation: operation,
        entityType: entityType,
        entityId: entityId,
        payload: jsonEncode(payload),
        syncStatus: 'pending',
        createdAt: DateTime.now(),
      ),
    );
  }
}
```

---

### Day 2: Connectivity & Sync Service (6-8 hours)

**Goal**: Implement network monitoring and sync queue processor

#### Step 2.1: Connectivity Service
Create `lib/shared/services/connectivity_service.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

enum NetworkStatus { online, offline, unknown }

@riverpod
class ConnectivityService extends _$ConnectivityService {
  final _connectivity = Connectivity();
  StreamSubscription? _subscription;

  @override
  Stream<NetworkStatus> build() async* {
    // Initial check
    final result = await _connectivity.checkConnectivity();
    yield _mapResultToStatus(result);

    // Listen for changes with debouncing
    _subscription = _connectivity.onConnectivityChanged
      .asyncMap((result) async {
        // Debounce: wait 2 seconds for stable connection
        await Future.delayed(const Duration(seconds: 2));

        if (result != ConnectivityResult.none) {
          // Verify actual internet access
          final hasInternet = await _verifyInternetAccess();
          return hasInternet ? NetworkStatus.online : NetworkStatus.offline;
        }
        return NetworkStatus.offline;
      })
      .listen((status) => state = AsyncValue.data(status));
  }

  NetworkStatus _mapResultToStatus(ConnectivityResult result) {
    return result == ConnectivityResult.none
      ? NetworkStatus.offline
      : NetworkStatus.unknown; // Will verify in stream
  }

  Future<bool> _verifyInternetAccess() async {
    try {
      final response = await supabase.from('profiles').select('id').limit(1)
        .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### Step 2.2: Sync Queue Processor
Create `lib/features/offline/domain/services/sync_queue_processor.dart`:

```dart
class SyncQueueProcessor {
  final OfflineDatabase _db;
  final SupabaseClient _supabase;
  final AuthService _authService;
  final Logger _logger;

  Future<SyncBatchResult> processQueue() async {
    final userId = await _authService.getCurrentUserId();

    // Get pending items (max 10 per batch - FR-016)
    final pending = await (_db.select(_db.syncQueueItems)
      ..where((t) =>
        t.userId.equals(userId) &
        t.syncStatus.equals('pending') &
        (t.nextRetryAt.isNull() | t.nextRetryAt.isSmallerThanValue(DateTime.now())))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(10))
      .get();

    if (pending.isEmpty) {
      return SyncBatchResult.empty();
    }

    // Group by operation
    final creates = pending.where((i) => i.operation == 'create').toList();
    final updates = pending.where((i) => i.operation == 'update').toList();
    final deletes = pending.where((i) => i.operation == 'delete').toList();

    final results = <String, SyncItemResult>{};

    // Batch create
    if (creates.isNotEmpty) {
      results.addAll(await _batchCreate(creates));
    }

    // Batch update (with conflict detection)
    if (updates.isNotEmpty) {
      results.addAll(await _batchUpdate(updates));
    }

    // Batch delete
    if (deletes.isNotEmpty) {
      results.addAll(await _batchDelete(deletes));
    }

    // Update queue items based on results
    await _updateQueueItems(results);

    // Log sync events (FR-018: basic events with errors)
    _logger.info('Sync batch completed: ${results.length} items, '
      '${results.values.where((r) => r.success).length} successful');

    return SyncBatchResult(results);
  }

  Future<Map<String, SyncItemResult>> _batchCreate(List<SyncQueueItem> items) async {
    try {
      final response = await _supabase.rpc('batch_create_expenses', params: {
        'p_expenses': items.map((i) => jsonDecode(i.payload)).toList(),
      }) as List;

      return Map.fromEntries(
        response.map((r) => MapEntry(r['id'] as String, SyncItemResult.fromJson(r)))
      );
    } on PostgrestException catch (e) {
      _logger.error('Batch create failed', error: e);
      return {for (var item in items) item.entityId: SyncItemResult.error(e.message)};
    } catch (e) {
      _logger.error('Batch create unexpected error', error: e);
      return {for (var item in items) item.entityId: SyncItemResult.error('Network error')};
    }
  }

  Future<void> _updateQueueItems(Map<String, SyncItemResult> results) async {
    for (final entry in results.entries) {
      final item = await (_db.select(_db.syncQueueItems)
        ..where((t) => t.entityId.equals(entry.key)))
        .getSingleOrNull();

      if (item == null) continue;

      if (entry.value.success) {
        // Mark completed
        await (_db.delete(_db.syncQueueItems)
          ..where((t) => t.id.equals(item.id)))
          .go();
      } else {
        // Handle retry with exponential backoff
        await _handleRetry(item, entry.value.errorMessage);
      }
    }
  }

  Future<void> _handleRetry(SyncQueueItem item, String? errorMessage) async {
    final retryCount = item.retryCount + 1;
    final delays = [30, 120, 300]; // 30s, 2min, 5min (FR-008)

    DateTime? nextRetry;
    String syncStatus;

    if (retryCount <= 3) {
      nextRetry = DateTime.now().add(Duration(seconds: delays[min(retryCount - 1, 2)]));
      syncStatus = 'pending';
    } else {
      // Give up after 3 retries
      syncStatus = 'failed';
    }

    await (_db.update(_db.syncQueueItems)
      ..where((t) => t.id.equals(item.id)))
      .write(
        SyncQueueItemsCompanion(
          retryCount: Value(retryCount),
          nextRetryAt: Value(nextRetry),
          syncStatus: Value(syncStatus),
          errorMessage: Value(errorMessage),
        ),
      );
  }
}
```

---

### Day 3: Repository & UI Integration (6-8 hours)

**Goal**: Wire offline support into expense repository and update UI

#### Step 3.1: Update Expense Repository
Modify `lib/features/expenses/data/repositories/expense_repository_impl.dart`:

```dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  final OfflineExpenseLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense({
    required double amount,
    required DateTime date,
    required String categoryId,
    String? merchant,
    String? notes,
    Uint8List? receiptImage,
    bool isGroupExpense = true,
  }) async {
    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        // Online: Direct create to server (existing logic)
        return _createOnline(...);
      } else {
        // Offline: Save locally (FR-002)
        final offlineExpense = await _localDataSource.createOfflineExpense(
          amount: amount,
          date: date,
          categoryId: categoryId,
          merchant: merchant,
          notes: notes,
          isGroupExpense: isGroupExpense,
        );

        // Save receipt image locally if provided
        if (receiptImage != null) {
          await _localDataSource.saveOfflineReceiptImage(
            expenseId: offlineExpense.id,
            imageData: receiptImage,
          );
        }

        return Right(offlineExpense.toEntity());
      }
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({...}) async {
    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        // Fetch from server
        final serverExpenses = await _remoteDataSource.getExpenses(...);
        return Right(serverExpenses.map((e) => e.toEntity()).toList());
      } else {
        // Fetch from local (offline + cached synced)
        final localExpenses = await _localDataSource.getOfflineExpenses();
        return Right(localExpenses.map((e) => e.toEntity()).toList());
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

#### Step 3.2: Add Sync Status UI Indicators
Update `lib/features/expenses/presentation/widgets/expense_list_item.dart`:

```dart
class ExpenseListItem extends StatelessWidget {
  final ExpenseEntity expense;

  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildSyncStatusIndicator(),
      title: Text(expense.merchant ?? 'No merchant'),
      subtitle: Text('€${expense.amount.toStringAsFixed(2)}'),
      trailing: Text(_formatDate(expense.date)),
    );
  }

  Widget _buildSyncStatusIndicator() {
    // FR-006: Visual indicators for sync status
    if (expense.syncStatus == 'pending') {
      return const Icon(Icons.cloud_off, color: Colors.orange);
    } else if (expense.syncStatus == 'syncing') {
      // FR-025: "Syncing..." indicator (FR-024: locked for edits)
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (expense.syncStatus == 'failed') {
      return const Icon(Icons.error, color: Colors.red);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
```

#### Step 3.3: Add Offline Banner
Create `lib/shared/widgets/offline_banner.dart`:

```dart
@riverpod
class OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityServiceProvider);
    final pendingCount = ref.watch(pendingExpenseCountProvider);

    return connectivityStatus.when(
      data: (status) {
        if (status == NetworkStatus.offline) {
          return MaterialBanner(
            content: Text('Offline - ${pendingCount.value ?? 0} pending syncs'),
            backgroundColor: Colors.orange.shade100,
            actions: [
              TextButton(
                onPressed: () => ref.read(syncQueueProcessorProvider).processQueue(),
                child: const Text('Retry'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

---

### Day 4: Background Sync & Conflict Resolution (6-8 hours)

**Goal**: Setup WorkManager for background sync and implement conflict handling

#### Step 4.1: Android WorkManager Setup
Create `lib/features/offline/infrastructure/background_sync_manager.dart`:

```dart
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize app dependencies
      await _initializeAppForBackgroundTask();

      // Run sync
      final processor = SyncQueueProcessor(...);
      await processor.processQueue();

      return Future.value(true);
    } catch (e) {
      // Log error (FR-018)
      logger.error('Background sync failed', error: e);
      return Future.value(false);
    }
  });
}

class BackgroundSyncManager {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      "offline-expense-sync",
      "syncOfflineExpenses",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }
}
```

#### Step 4.2: iOS Background Fetch
Update `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
</array>
```

See research.md for iOS Background Fetch implementation.

#### Step 4.3: Conflict Resolution
Create `lib/features/offline/domain/services/conflict_resolver.dart`:

```dart
class ConflictResolver {
  Future<void> handleConflict({
    required OfflineExpense localVersion,
    required ExpenseModel serverVersion,
  }) async {
    // FR-009: Server wins, notify user
    await _notificationService.show(
      title: 'Expense Modified',
      body: 'Your offline changes to "${localVersion.merchant}" were overwritten. '
            'Server version was newer.',
      actions: ['View Details', 'Create New'],
    );

    // Log conflict (FR-018)
    _logger.info('Conflict resolved: expense ${localVersion.id}, server wins');

    // Record conflict for user review (User Story 4)
    await _db.into(_db.syncConflicts).insert(
      SyncConflictsCompanion.insert(
        userId: await _authService.getCurrentUserId(),
        expenseId: localVersion.id,
        localVersionData: jsonEncode(localVersion.toJson()),
        serverVersionData: jsonEncode(serverVersion.toJson()),
        conflictType: 'update_conflict',
        detectedAt: DateTime.now(),
      ),
    );

    // Delete local version (accept server)
    await _db.offlineExpenses.deleteWhere((e) => e.id.equals(localVersion.id));
  }

  Future<void> offerCreateFromLocalData(OfflineExpense localVersion) async {
    // User Story 4 Scenario 3: Create new expense with local data
    // Show dialog with option to create new expense
  }
}
```

---

### Day 5: Testing & Polish (6-8 hours)

**Goal**: Write tests, handle edge cases, and polish UX

#### Step 5.1: Unit Tests
Create `test/features/offline/domain/services/sync_queue_processor_test.dart`:

```dart
void main() {
  group('SyncQueueProcessor', () {
    late SyncQueueProcessor processor;
    late MockOfflineDatabase mockDb;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockDb = MockOfflineDatabase();
      mockSupabase = MockSupabaseClient();
      processor = SyncQueueProcessor(
        db: mockDb,
        supabase: mockSupabase,
        authService: MockAuthService(),
        logger: MockLogger(),
      );
    });

    test('processes batch of 10 expenses successfully', () async {
      // Arrange
      final queueItems = List.generate(10, (i) => _createMockQueueItem(i));
      when(mockDb.select(any)).thenReturn(FakeSelectStatement(queueItems));
      when(mockSupabase.rpc('batch_create_expenses', params: any))
        .thenAnswer((_) async => _createSuccessResponse(10));

      // Act
      final result = await processor.processQueue();

      // Assert
      expect(result.successCount, equals(10));
      expect(result.failureCount, equals(0));
      verify(mockDb.delete(any).go()).called(10); // All completed items deleted
    });

    test('retries failed items with exponential backoff', () async {
      // Test FR-008 exponential backoff logic
      // ...
    });

    test('gives up after 3 retry attempts', () async {
      // Test max retry limit
      // ...
    });
  });
}
```

#### Step 5.2: Integration Tests
Create `integration_test/offline_sync_test.dart`:

```dart
void main() {
  testWidgets('E2E: Create expense offline, sync when online', (tester) async {
    // 1. Disable network
    await tester.pumpWidget(MyApp());
    await _disableNetwork();

    // 2. Create expense offline
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await _fillExpenseForm(tester, amount: 42.50, merchant: 'Coffee Shop');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // 3. Verify saved locally with "pending" status
    expect(find.byIcon(Icons.cloud_off), findsOneWidget); // Offline indicator

    // 4. Re-enable network
    await _enableNetwork();
    await tester.pumpAndSettle(const Duration(seconds: 35)); // Wait for auto-sync (30s + buffer)

    // 5. Verify synced (SC-002: < 30 seconds)
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // Synced indicator

    // 6. Verify expense exists on server
    final serverExpenses = await supabase.from('expenses').select().eq('merchant', 'Coffee Shop');
    expect(serverExpenses, hasLength(1));
  });
}
```

#### Step 5.3: Edge Cases
- **500-expense limit** (FR-026, FR-027): Show dialog when limit reached
- **Sync during edit** (FR-024, FR-025): Lock expense with "Syncing..." indicator
- **Logout with pending** (FR-022): Preserve pending expenses for user
- **Storage warning** (FR-019): Show warning at < 10MB available

---

## Supabase Backend Setup

### Create RPC Functions
1. Open Supabase SQL Editor
2. Copy SQL from `contracts/batch-sync-api.md`
3. Execute migration
4. Test with sample data

---

## Testing Checklist

### Functional Tests
- [ ] Create expense offline saves locally
- [ ] Offline expenses sync automatically when network returns
- [ ] Batch sync completes in < 30s for 1 expense (SC-002)
- [ ] Batch sync completes in < 2min for 50 expenses (SC-003)
- [ ] 500-expense limit enforced (FR-026)
- [ ] Sync retry with exponential backoff (30s, 2min, 5min)
- [ ] Conflict resolution: server wins, user notified
- [ ] Logout preserves pending expenses for user
- [ ] Receipt images compressed and synced

### Performance Tests
- [ ] Database size < 50MB for 500 expenses (SC-012)
- [ ] App responsive with 500 pending expenses (SC-015)
- [ ] Encryption overhead < 100ms (C-009)
- [ ] Battery drain < 5%/hour offline (C-004)
- [ ] Sync lock duration < 2s (SC-014)

### Security Tests
- [ ] Offline data encrypted at rest (FR-021)
- [ ] Multi-user isolation works (FR-022)
- [ ] No sensitive data in logs (C-010)
- [ ] Encryption keys stored securely

---

## Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Encryption key lost** | Database can't be opened after app reinstall | Accept data loss; generate new key. Consider cloud backup in future. |
| **Sync stuck in "syncing"** | Expenses perpetually show spinner | Add timeout to sync operations; reset status to "pending" after 30s |
| **WorkManager not firing** | Background sync never runs on Android | Check battery optimization settings; test with `startWork()` |
| **iOS background fetch unreliable** | Sporadic sync on iOS | Expected behavior; foreground sync on app resume is primary |
| **Conflicts not detected** | Server version overwritten by client | Verify `client_updated_at` is sent correctly in batch update payload |
| **500-expense limit bypassed** | More than 500 expenses created | Enforce check in repository before inserting to Drift |

---

## Deployment Checklist

### Pre-Release
- [ ] All tests passing (unit, integration, E2E)
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Supabase RPC functions deployed to production
- [ ] iOS Background Modes capability enabled

### Release
- [ ] Monitor crash reports for encryption errors
- [ ] Track sync success rate (target: 99.5% - SC-005)
- [ ] Monitor battery usage (target: < 5%/hour - C-004)
- [ ] Gather user feedback on conflict resolution UX

### Post-Release
- [ ] Adjust background sync frequency based on battery impact
- [ ] Consider raising 500-expense limit if users request
- [ ] Plan Phase 2: Offline support for other features (OS-002)

---

## Next Phase: Tasks

After completing this quickstart, proceed to:
- `/speckit.tasks` - Generate dependency-ordered task breakdown
- `/speckit.implement` - Execute implementation with TDD approach

**Estimated Total Effort**: 3-5 days for experienced Flutter developer, +2 days for thorough testing

---

## Support Resources

- **Drift Docs**: https://drift.simonbinder.eu/docs/
- **connectivity_plus**: https://pub.dev/packages/connectivity_plus
- **workmanager**: https://pub.dev/packages/workmanager
- **SQLCipher**: https://www.zetetic.net/sqlcipher/

**Questions?** Refer to:
- `research.md` for technical decisions
- `data-model.md` for database schema
- `contracts/batch-sync-api.md` for Supabase integration
