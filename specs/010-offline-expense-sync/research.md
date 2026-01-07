# Offline Expense Sync Implementation Research

## Overview

This document provides comprehensive research findings for implementing offline expense sync in a Flutter app with Supabase backend. The research covers encryption, connectivity monitoring, sync queue architecture, conflict resolution, user session isolation, background sync, and UUID generation.

---

## 1. Drift Database Encryption

### Decision
Use **Drift** with **sqlcipher_flutter_libs** package for database encryption, combined with **flutter_secure_storage** for secure key management.

### Rationale
- **Native SQLCipher Integration**: The `sqlcipher_flutter_libs` package provides transparent 256-bit AES encryption across Android, iOS, macOS, Linux, and Windows platforms
- **Official Drift Support**: Drift's official documentation recommends this approach for new apps over the older `encrypted_drift` package
- **Secure Key Management**: `flutter_secure_storage` provides platform-specific secure storage (iOS Keychain, Android Keystore) for encryption keys
- **Production Ready**: This combination is actively maintained and used in production Flutter apps as of 2025

### Alternatives Considered
- **encrypted_drift**: Older package, now deprecated in favor of sqlcipher_flutter_libs
- **sqflite_sqlcipher**: Works with sqflite but doesn't provide Drift's type-safe, reactive query capabilities
- **Hive with encryption**: Simpler but lacks SQL query capabilities and relational data management

### Implementation Notes
```dart
// 1. Add dependencies to pubspec.yaml
dependencies:
  drift: ^2.x.x
  drift_flutter: ^0.x.x
  sqlcipher_flutter_libs: ^0.x.x
  flutter_secure_storage: ^9.x.x
  path_provider: ^2.x.x

dev_dependencies:
  drift_dev: ^2.x.x
  build_runner: ^2.x.x

// 2. Generate and store encryption key
final storage = FlutterSecureStorage();
String? key = await storage.read(key: 'db_encryption_key');
if (key == null) {
  key = base64.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
  await storage.write(key: 'db_encryption_key', value: key);
}

// 3. Initialize encrypted database
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'encrypted_db.sqlite'));

    final key = await _getEncryptionKey(); // From flutter_secure_storage

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
  });
}

@DriftDatabase(tables: [Expenses, Categories, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

**Platform-Specific Configuration:**
- **Android**: No special setup required, native libraries included automatically
- **iOS/macOS**: May need to handle code signing and entitlements for keychain access
- **Key Rotation**: Consider implementing key rotation strategy for enhanced security

**Best Practices:**
- Generate 32-byte random keys using `Random.secure()`
- Never hardcode encryption keys in source code
- Store keys only in platform secure storage
- Test database migration scenarios with encrypted databases
- Handle key loss scenarios (e.g., user must re-authenticate)

### References
- [Drift Encryption Documentation](https://drift.simonbinder.eu/platforms/encryption/)
- [sqlcipher_flutter_libs Package](https://pub.dev/packages/sqlcipher_flutter_libs)
- [Securing Local Storage in Flutter - LogRocket](https://blog.logrocket.com/securing-local-storage-flutter/)
- [Flutter Secure Storage Best Practices - Medium](https://medium.com/flutter-community/flutter-secure-your-sensitive-data-2869239e6f9a)

---

## 2. Connectivity Monitoring

### Decision
Use **connectivity_plus** for network type detection, combined with **internet_connection_checker_plus** for actual internet connectivity verification. Implement a reactive stream-based pattern with **BLoC/Cubit** for state management.

### Rationale
- **Dual-Layer Approach**: `connectivity_plus` detects network interface status (WiFi/mobile), while `internet_connection_checker_plus` verifies actual internet connectivity
- **Official Flutter Plus Plugin**: `connectivity_plus` is the official Flutter Community plugin with support for all major platforms
- **Stream-Based Architecture**: Provides reactive connectivity updates that integrate seamlessly with Flutter's reactive framework
- **Production Reliability**: The dual approach prevents false positives (connected to WiFi but no internet)

### Alternatives Considered
- **connectivity_plus alone**: Can report "connected" when WiFi has no internet access
- **auto_sync_plus**: New package (2025) but less mature, combines connectivity with sync logic (less modular)
- **Manual polling**: Less efficient, drains battery, doesn't provide real-time updates
- **Network callbacks only**: Platform-specific, harder to maintain cross-platform

### Implementation Notes
```dart
// 1. Dependencies
dependencies:
  connectivity_plus: ^6.x.x
  internet_connection_checker_plus: ^2.x.x
  flutter_bloc: ^8.x.x
  rxdart: ^0.27.x  # For debouncing

// 2. Connectivity Service (with debouncing to avoid rapid state changes)
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  // Debounced stream to avoid rapid sync triggers
  Stream<bool> get isConnectedStream {
    return Rx.combineLatest2(
      _connectivity.onConnectivityChanged,
      _internetChecker.onStatusChange,
      (List<ConnectivityResult> connectivityResults, InternetStatus internetStatus) {
        final hasNetworkInterface = connectivityResults.any(
          (result) => result != ConnectivityResult.none
        );
        final hasInternet = internetStatus == InternetStatus.connected;
        return hasNetworkInterface && hasInternet;
      },
    ).debounceTime(Duration(seconds: 2)); // Avoid rapid state changes
  }

  Future<bool> isConnected() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return false;
    }
    return await _internetChecker.hasInternetAccess;
  }
}

// 3. BLoC Implementation for State Management
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _service;
  StreamSubscription? _subscription;

  ConnectivityCubit(this._service) : super(ConnectivityInitial()) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _subscription = _service.isConnectedStream.listen((isConnected) {
      if (isConnected) {
        emit(ConnectivityOnline());
        // Trigger sync when coming online
        _triggerSync();
      } else {
        emit(ConnectivityOffline());
      }
    });
  }

  void _triggerSync() {
    // Inject sync service and trigger synchronization
    getIt<SyncService>().startSync();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

// 4. UI Integration (Optional: show connectivity banner)
BlocBuilder<ConnectivityCubit, ConnectivityState>(
  builder: (context, state) {
    if (state is ConnectivityOffline) {
      return OfflineBanner();
    }
    return SizedBox.shrink();
  },
)
```

**Important Notes:**
- **Don't Block UI**: Never block operations based solely on connectivity status. Always handle network timeouts and errors gracefully
- **Debouncing**: Implement 1-2 second debounce to avoid triggering sync on rapid network fluctuations
- **Battery Optimization**: Use passive listening; don't actively poll connectivity
- **Auto-Sync Trigger**: Listen to connectivity stream and trigger sync service when connection is established

**Platform Considerations:**
- **Android**: Requires `ACCESS_NETWORK_STATE` permission
- **iOS**: Works without special permissions
- **Background**: Connectivity streams may be suspended in background; use WorkManager for background sync

### References
- [connectivity_plus Package](https://pub.dev/packages/connectivity_plus)
- [internet_connection_checker_plus Package](https://pub.dev/packages/internet_connection_checker_plus)
- [Flutter Connectivity Plus Guide - DHiWise](https://www.dhiwise.com/post/the-ultimate-guide-to-flutter-connectivity-plus-package)
- [Building an Always Listening Internet Connection Checker with BLoC](https://atuoha.hashnode.dev/building-an-always-listening-internet-connection-checker-in-flutter-using-bloc)

---

## 3. Sync Queue Architecture

### Decision
Implement a **custom sync queue** using Drift database tables with a state machine pattern. Consider **Brick** package for more complex offline-first scenarios requiring less custom code.

### Rationale
- **Drift-Based Queue**: Stores pending operations persistently in encrypted database, survives app restarts
- **State Machine**: Clear operation lifecycle (pending → syncing → completed/failed)
- **Batching Support**: Group operations by entity type and batch size (10 items as per spec)
- **Exponential Backoff**: Implement retry logic with increasing delays (30s, 2min, 5min)
- **Atomicity**: Use Drift transactions to ensure all-or-nothing batch updates
- **Ordering**: Maintain creation timestamp for sequential operation processing

### Alternatives Considered
- **Brick Package**: Full offline-first solution with built-in sync queue, but adds complexity and learning curve
- **Synquill**: Newer package (2025) with intelligent sync queues, but less mature than Brick
- **offline_sync_kit**: Comprehensive but may be overkill for simpler use cases
- **PowerSync**: Commercial solution with excellent offline-first support, but requires subscription
- **Custom in-memory queue**: Lost on app restart, not suitable for critical financial data

### Implementation Notes

```dart
// 1. Sync Queue Schema
@DataClassName('SyncOperation')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text().unique()(); // UUID
  TextColumn get entityType => text()(); // 'expense', 'category', etc.
  TextColumn get entityId => text()(); // UUID of the entity
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text().nullable()(); // JSON serialized data
  IntColumn get retryCount => integer().withDefault(Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get status => text()(); // 'pending', 'syncing', 'completed', 'failed'
  TextColumn get errorMessage => text().nullable()();
}

// 2. Sync Service with Batching and Exponential Backoff
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final ConnectivityService _connectivity;

  static const int BATCH_SIZE = 10;
  static const List<int> RETRY_DELAYS = [30, 120, 300]; // seconds: 30s, 2min, 5min

  bool _isSyncing = false;

  Future<void> startSync() async {
    if (_isSyncing) return;
    if (!await _connectivity.isConnected()) return;

    _isSyncing = true;
    try {
      await _processSyncQueue();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncQueue() async {
    // Get pending operations that are ready to retry
    final operations = await (_db.select(_db.syncQueue)
          ..where((tbl) => tbl.status.equals('pending') | tbl.status.equals('failed'))
          ..where((tbl) => tbl.retryCount.isSmallerThanValue(RETRY_DELAYS.length))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
          ..limit(BATCH_SIZE))
        .get();

    if (operations.isEmpty) return;

    // Filter operations ready for retry (after backoff delay)
    final readyOps = operations.where((op) {
      if (op.lastAttemptAt == null) return true;

      final delay = RETRY_DELAYS[min(op.retryCount, RETRY_DELAYS.length - 1)];
      final nextAttempt = op.lastAttemptAt!.add(Duration(seconds: delay));
      return DateTime.now().isAfter(nextAttempt);
    }).toList();

    // Group by entity type for batch processing
    final grouped = <String, List<SyncOperation>>{};
    for (final op in readyOps) {
      grouped.putIfAbsent(op.entityType, () => []).add(op);
    }

    // Process each entity type batch
    for (final entry in grouped.entries) {
      await _processBatch(entry.key, entry.value);
    }

    // Continue processing if there are more items
    if (operations.length == BATCH_SIZE) {
      await _processSyncQueue();
    }
  }

  Future<void> _processBatch(String entityType, List<SyncOperation> operations) async {
    try {
      // Mark as syncing
      await _db.batch((batch) {
        for (final op in operations) {
          batch.update(
            _db.syncQueue,
            SyncQueueCompanion(
              status: Value('syncing'),
              lastAttemptAt: Value(DateTime.now()),
              retryCount: Value(op.retryCount + 1),
            ),
            where: (tbl) => tbl.id.equals(op.id),
          );
        }
      });

      // Execute batch operation based on entity type
      switch (entityType) {
        case 'expense':
          await _syncExpenses(operations);
          break;
        case 'category':
          await _syncCategories(operations);
          break;
        // Add other entity types...
      }

      // Mark as completed
      await _db.batch((batch) {
        for (final op in operations) {
          batch.update(
            _db.syncQueue,
            SyncQueueCompanion(status: Value('completed')),
            where: (tbl) => tbl.id.equals(op.id),
          );
        }
      });

      // Clean up old completed operations (keep last 100 for audit)
      await _cleanupCompletedOperations();

    } catch (e) {
      // Mark as failed
      await _db.batch((batch) {
        for (final op in operations) {
          final shouldFail = op.retryCount + 1 >= RETRY_DELAYS.length;
          batch.update(
            _db.syncQueue,
            SyncQueueCompanion(
              status: Value(shouldFail ? 'failed' : 'pending'),
              errorMessage: Value(e.toString()),
            ),
            where: (tbl) => tbl.id.equals(op.id),
          );
        }
      });

      rethrow;
    }
  }

  Future<void> _syncExpenses(List<SyncOperation> operations) async {
    final creates = operations.where((op) => op.operation == 'create');
    final updates = operations.where((op) => op.operation == 'update');
    final deletes = operations.where((op) => op.operation == 'delete');

    // Batch creates
    if (creates.isNotEmpty) {
      final data = creates.map((op) => jsonDecode(op.payload!)).toList();
      await _supabase.from('expenses').insert(data);
    }

    // Batch updates (using RPC or individual updates)
    for (final op in updates) {
      final data = jsonDecode(op.payload!);
      await _supabase.from('expenses')
          .update(data)
          .eq('id', op.entityId);
    }

    // Batch deletes
    if (deletes.isNotEmpty) {
      final ids = deletes.map((op) => op.entityId).toList();
      await _supabase.from('expenses').delete().inFilter('id', ids);
    }
  }

  Future<void> _cleanupCompletedOperations() async {
    final completed = await (_db.select(_db.syncQueue)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    if (completed.length > 100) {
      final toDelete = completed.skip(100).map((op) => op.id).toList();
      await (_db.delete(_db.syncQueue)
            ..where((tbl) => tbl.id.isIn(toDelete)))
          .go();
    }
  }

  // Helper to add operations to queue
  Future<void> queueOperation({
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        operationId: Uuid().v4(),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: Value(payload != null ? jsonEncode(payload) : null),
        createdAt: DateTime.now(),
        status: 'pending',
      ),
    );
  }
}

// 3. Integration with Repository Pattern
class ExpenseRepository {
  final AppDatabase _db;
  final SyncService _sync;

  Future<void> createExpense(Expense expense) async {
    // 1. Save locally first (offline-first)
    await _db.into(_db.expenses).insert(expense);

    // 2. Queue for sync
    await _sync.queueOperation(
      entityType: 'expense',
      entityId: expense.id,
      operation: 'create',
      payload: expense.toJson(),
    );

    // 3. Trigger sync if online
    unawaited(_sync.startSync());
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.update(_db.expenses).replace(expense);

    await _sync.queueOperation(
      entityType: 'expense',
      entityId: expense.id,
      operation: 'update',
      payload: expense.toJson(),
    );

    unawaited(_sync.startSync());
  }

  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenses)..where((tbl) => tbl.id.equals(id))).go();

    await _sync.queueOperation(
      entityType: 'expense',
      entityId: id,
      operation: 'delete',
    );

    unawaited(_sync.startSync());
  }
}
```

**Key Design Decisions:**
- **Operation Ordering**: Use `createdAt` timestamp to process operations in order
- **Idempotency**: Ensure operations can be retried safely (use UUIDs, upserts where possible)
- **Transaction Safety**: Use Drift transactions for atomic batch updates
- **Failure Handling**: After 3 retries (30s, 2min, 5min), mark as permanently failed
- **Audit Trail**: Keep last 100 completed operations for debugging

### References
- [Creating Flutter Apps With Offline-First Architecture - Vibe Studio](https://vibe-studio.ai/insights/creating-flutter-apps-with-offline-first-architecture)
- [Flutter Offline-First with Supabase - Dev Adnani](https://www.devadnani.com/blog/flutter-offline-first-supabase)
- [Building Offline-First Apps with Conflict Resolution - Vibe Studio](https://vibe-studio.ai/insights/building-offline-first-apps-with-conflict-resolution-logic)
- [Building Offline-First Flutter Apps with Drift - Medium](https://777genius.medium.com/building-offline-first-flutter-apps-a-complete-sync-solution-with-drift-d287da021ab0)

---

## 4. Conflict Resolution

### Decision
Implement **"Server Wins"** strategy with user notification for conflicts. Provide conflict details and option to create a new expense with the offline data.

### Rationale
- **Financial Data Integrity**: For expense tracking, server is the authoritative source to prevent budget calculation errors
- **Simplicity**: Server wins is straightforward to implement and reason about
- **User Transparency**: Notify users when their offline changes are overridden
- **Data Preservation**: Offer to save offline changes as a new expense rather than losing data
- **Timestamp-Based Detection**: Use `updated_at` fields to detect conflicts

### Alternatives Considered
- **Last Write Wins (LWW)**: Relies on device clock accuracy, risky with multiple users/devices
- **Client Wins**: Could cause data loss if server has more recent updates from other devices
- **Manual Resolution**: Complex UI/UX for financial data, slows down user workflow
- **Merge Strategy**: Too complex for expense data structure, prone to errors
- **Custom per-field**: Overkill for expense tracking use case

### Implementation Notes

```dart
// 1. Add conflict tracking columns
@DataClassName('Expense')
class Expenses extends Table {
  TextColumn get id => text()(); // UUID
  // ... other expense fields
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()(); // Last successful sync
  BoolColumn get isDirty => boolean().withDefault(Constant(false))(); // Has local changes
}

// 2. Conflict Detection and Resolution Service
class ConflictResolutionService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  Future<void> syncExpenseWithConflictCheck(String expenseId) async {
    final localExpense = await (_db.select(_db.expenses)
          ..where((tbl) => tbl.id.equals(expenseId)))
        .getSingle();

    // Fetch server version
    final serverData = await _supabase
        .from('expenses')
        .select()
        .eq('id', expenseId)
        .maybeSingle();

    if (serverData == null) {
      // Expense deleted on server
      await _handleServerDeleteConflict(localExpense);
      return;
    }

    final serverExpense = Expense.fromJson(serverData);

    // Check for conflict
    if (localExpense.isDirty && _hasConflict(localExpense, serverExpense)) {
      await _handleConflict(localExpense, serverExpense);
    } else {
      // No conflict, apply server version
      await _applyServerVersion(serverExpense);
    }
  }

  bool _hasConflict(Expense local, Expense server) {
    // Conflict if:
    // 1. Local has unsync'd changes (isDirty = true)
    // 2. Server was updated after last sync
    if (!local.isDirty) return false;
    if (local.syncedAt == null) return false;

    return server.updatedAt.isAfter(local.syncedAt!);
  }

  Future<void> _handleConflict(Expense local, Expense server) async {
    // Server wins: apply server version
    await _applyServerVersion(server);

    // Notify user about conflict
    await _notifyUserOfConflict(
      conflictType: ConflictType.modified,
      localExpense: local,
      serverExpense: server,
    );
  }

  Future<void> _handleServerDeleteConflict(Expense local) async {
    // Server deleted, local modified
    await (_db.delete(_db.expenses)
          ..where((tbl) => tbl.id.equals(local.id)))
        .go();

    await _notifyUserOfConflict(
      conflictType: ConflictType.deleted,
      localExpense: local,
      serverExpense: null,
    );
  }

  Future<void> _applyServerVersion(Expense server) async {
    await _db.update(_db.expenses).replace(
      server.copyWith(
        syncedAt: DateTime.now(),
        isDirty: false,
      ),
    );
  }

  Future<void> _notifyUserOfConflict({
    required ConflictType conflictType,
    required Expense localExpense,
    Expense? serverExpense,
  }) async {
    // Store conflict notification
    await _db.into(_db.conflictNotifications).insert(
      ConflictNotification(
        id: Uuid().v4(),
        conflictType: conflictType.name,
        entityType: 'expense',
        entityId: localExpense.id,
        localData: jsonEncode(localExpense.toJson()),
        serverData: serverExpense != null ? jsonEncode(serverExpense.toJson()) : null,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    // Show in-app notification or dialog
    _showConflictDialog(conflictType, localExpense, serverExpense);
  }

  void _showConflictDialog(ConflictType type, Expense local, Expense? server) {
    // UI Implementation - show dialog with options:
    // - View changes (show diff)
    // - Discard local changes (already done - server wins)
    // - Save as new expense (create new with local data)
    // - Don't show again (dismiss)
  }
}

// 3. Conflict Notification Schema
enum ConflictType { modified, deleted }

@DataClassName('ConflictNotification')
class ConflictNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get conflictType => text()(); // 'modified', 'deleted'
  TextColumn get entityType => text()(); // 'expense', 'category'
  TextColumn get entityId => text()();
  TextColumn get localData => text()(); // JSON
  TextColumn get serverData => text().nullable()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(Constant(false))();
}

// 4. User Action Handlers
class ConflictActionService {
  final AppDatabase _db;
  final ExpenseRepository _expenseRepo;

  Future<void> saveLocalAsNew(String conflictId) async {
    final conflict = await (_db.select(_db.conflictNotifications)
          ..where((tbl) => tbl.id.equals(conflictId)))
        .getSingle();

    final localExpense = Expense.fromJson(jsonDecode(conflict.localData));

    // Create new expense with local data
    final newExpense = localExpense.copyWith(
      id: Uuid().v4(), // New UUID
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _expenseRepo.createExpense(newExpense);

    // Mark conflict as read
    await _markConflictAsRead(conflictId);
  }

  Future<void> discardLocal(String conflictId) async {
    await _markConflictAsRead(conflictId);
  }

  Future<void> _markConflictAsRead(String conflictId) async {
    await (_db.update(_db.conflictNotifications)
          ..where((tbl) => tbl.id.equals(conflictId)))
        .write(ConflictNotificationsCompanion(isRead: Value(true)));
  }
}

// 5. Conflict Badge in UI
class ConflictBadgeProvider {
  final AppDatabase _db;

  Stream<int> get unreadConflictCount {
    return (_db.select(_db.conflictNotifications)
          ..where((tbl) => tbl.isRead.equals(false)))
        .watch()
        .map((conflicts) => conflicts.length);
  }
}
```

**Conflict Detection Strategy:**
- Mark local records as "dirty" when modified offline
- Store `syncedAt` timestamp on successful sync
- On sync, compare server `updated_at` with local `syncedAt`
- If server is newer and local is dirty → conflict detected

**User Notification Approach:**
- Non-blocking: Don't prevent sync, apply server version immediately
- Informative: Show what changed (diff view)
- Actionable: Option to save local data as new expense
- Persistent: Store conflict notifications in database for later review
- Badge counter: Show unread conflicts in app navigation

**Edge Cases:**
- Deleted on server, modified locally: Notify user, offer to re-create
- Created offline with same UUID (unlikely): Use UUID v4 to minimize risk
- Multiple conflicts: Batch notifications, allow bulk actions

### References
- [Building Offline-First Apps with Conflict Resolution - Vibe Studio](https://vibe-studio.ai/insights/building-offline-first-apps-with-conflict-resolution-logic)
- [offline_sync_kit Package](https://pub.dev/packages/offline_sync_kit)
- [Implementing Data Sync & Conflict Resolution Offline - Vibe Studio](https://vibe-studio.ai/insights/implementing-data-sync-conflict-resolution-offline-in-flutter)
- [Building a Flutter Offline-First Sync Engine - Medium](https://medium.com/@pravinkunnure9/building-a-flutter-offline-first-sync-engine-flutter-sync-engine-with-conflict-resolution-5a087f695104)

---

## 5. User Session Isolation

### Decision
Implement **user-scoped database filtering** at the application level using Row Level Security (RLS) on Supabase and user ID filtering in local Drift queries.

### Rationale
- **Single Database, Filtered Queries**: More efficient than separate databases per user
- **Supabase RLS Integration**: Server-side security ensures only user's data is synced
- **Automatic Filtering**: Drift custom queries can automatically inject user ID filters
- **Multi-Device Support**: User can switch devices without data duplication
- **Simpler Backup/Restore**: Single database file per device

### Alternatives Considered
- **Separate Database Files per User**: Complex file management, slow user switching
- **SQLite User Schema**: Limited support in SQLite, complex migrations
- **Partition Tables**: Overkill for mobile app, complicates queries
- **No Isolation (Single User)**: Doesn't meet spec requirement for multi-user devices

### Implementation Notes

```dart
// 1. User Session Management
class UserSessionService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final _currentUserController = BehaviorSubject<String?>();

  Stream<String?> get currentUserIdStream => _currentUserController.stream;
  String? get currentUserId => _currentUserController.valueOrNull;

  Future<void> init() async {
    final userId = await _storage.read(key: 'current_user_id');
    _currentUserController.add(userId);
  }

  Future<void> setCurrentUser(String userId) async {
    await _storage.write(key: 'current_user_id', value: userId);
    _currentUserController.add(userId);
  }

  Future<void> clearCurrentUser() async {
    await _storage.delete(key: 'current_user_id');
    _currentUserController.add(null);
  }
}

// 2. Update Schema to Include User ID
@DataClassName('Expense')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // Add user_id to all tables
  // ... other fields

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get indexes => [
    Index('idx_user_expenses', [userId, createdAt]),
  ];
}

// 3. Custom Drift Queries with Automatic User Filtering
@DriftDatabase(tables: [Expenses, Categories, Budgets, SyncQueue])
class AppDatabase extends _$AppDatabase {
  final UserSessionService _userSession;

  AppDatabase(this._userSession) : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // User-scoped query builder
  SimpleSelectStatement<Expenses, Expense> _userExpenses() {
    final userId = _userSession.currentUserId;
    if (userId == null) {
      throw StateError('No user logged in');
    }
    return select(expenses)..where((tbl) => tbl.userId.equals(userId));
  }

  // Public methods automatically filter by user
  Future<List<Expense>> getAllExpenses() => _userExpenses().get();

  Stream<List<Expense>> watchAllExpenses() => _userExpenses().watch();

  Future<Expense?> getExpenseById(String id) {
    return (_userExpenses()..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertExpense(ExpensesCompanion expense) async {
    final userId = _userSession.currentUserId;
    if (userId == null) throw StateError('No user logged in');

    await into(expenses).insert(
      expense.copyWith(userId: Value(userId)),
    );
  }

  // Similar patterns for update, delete, etc.
}

// 4. Supabase Row Level Security (RLS) Setup
/*
-- On Supabase Dashboard, enable RLS for all tables:

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Create policies for user isolation
CREATE POLICY "Users can only access their own expenses"
  ON expenses
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own categories"
  ON categories
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own budgets"
  ON budgets
  FOR ALL
  USING (auth.uid() = user_id);
*/

// 5. Sync Service with User Filtering
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final UserSessionService _userSession;

  Future<void> syncExpenses() async {
    final userId = _userSession.currentUserId;
    if (userId == null) return;

    // Fetch only current user's data from Supabase (RLS enforced)
    final serverExpenses = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId); // Explicit filter + RLS double protection

    // Update local database (automatically filtered by user in insertExpense)
    await _db.transaction(() async {
      for (final data in serverExpenses) {
        final expense = Expense.fromJson(data);
        await _db.into(_db.expenses).insertOnConflictUpdate(expense);
      }
    });
  }

  // When pushing local changes, user_id is already in the record
  Future<void> pushLocalChanges() async {
    final operations = await _db.select(_db.syncQueue).get();

    for (final op in operations) {
      final payload = jsonDecode(op.payload!);
      // payload already contains user_id from local record
      await _supabase.from(op.entityType).insert(payload);
    }
  }
}

// 6. User Switching Handler
class UserSwitchService {
  final AppDatabase _db;
  final UserSessionService _userSession;
  final SyncService _sync;

  Future<void> switchUser(String newUserId) async {
    // 1. Sync current user's data before switching
    await _sync.startSync();

    // 2. Switch user session
    await _userSession.setCurrentUser(newUserId);

    // 3. Fetch new user's data
    await _sync.pullFromServer();

    // 4. UI will automatically update via streams watching user-filtered queries
  }

  Future<void> logout() async {
    await _sync.startSync(); // Final sync before logout
    await _userSession.clearCurrentUser();
  }
}

// 7. Data Cleanup on User Deletion
class UserDataCleanupService {
  final AppDatabase _db;

  Future<void> deleteUserData(String userId) async {
    // Only call after user confirms account deletion
    await _db.transaction(() async {
      // Delete all user data from local database
      await (_db.delete(_db.expenses)
            ..where((tbl) => tbl.userId.equals(userId)))
          .go();
      await (_db.delete(_db.categories)
            ..where((tbl) => tbl.userId.equals(userId)))
          .go();
      await (_db.delete(_db.budgets)
            ..where((tbl) => tbl.userId.equals(userId)))
          .go();
      // Delete from sync queue
      await (_db.delete(_db.syncQueue)
            ..where((tbl) => tbl.entityId.isIn(
                _db.selectOnly(_db.expenses)
                  ..where(_db.expenses.userId.equals(userId))
                  ..addColumns([_db.expenses.id])
              )))
          .go();
    });
  }
}
```

**Key Implementation Points:**
- **Automatic Filtering**: All database queries automatically filter by current user ID
- **Fail-Safe**: Throw error if query executed without active user session
- **Index Optimization**: Create composite indexes on (user_id, created_at) for performance
- **Supabase RLS**: Server-side enforcement prevents unauthorized data access during sync
- **User Switching**: Gracefully handle user switching with sync before/after
- **Memory Efficiency**: Single database, filtered views rather than multiple database files

**Security Considerations:**
- Always validate user session before database operations
- Use Supabase RLS as defense-in-depth (client filtering + server enforcement)
- Clear sensitive data from memory on logout
- Implement session timeout and re-authentication

**Multi-User UX:**
- Fast user switching (< 1 second)
- User avatar/name in app header
- "Switch User" option in settings
- Automatic sync on user switch

### References
- [Drift Database Documentation](https://drift.simonbinder.eu/)
- [Supabase Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Building Offline-First Flutter Apps with Drift - Medium](https://777genius.medium.com/building-offline-first-flutter-apps-a-complete-sync-solution-with-drift-d287da021ab0)

---

## 6. Background Sync

### Decision
Use **workmanager** package for both Android and iOS background sync. Accept iOS limitations and implement best-effort background sync with proper user expectations.

### Rationale
- **Cross-Platform**: Single API for both Android and iOS background tasks
- **Production Ready**: Widely used in production Flutter apps as of 2025
- **WorkManager Integration**: Leverages Android WorkManager (reliable) and iOS BGTaskScheduler
- **Constraint Support**: Can specify network connectivity, charging state requirements
- **Persistent**: Tasks survive app restarts and device reboots

### Alternatives Considered
- **background_fetch**: iOS-focused, less reliable on Android
- **flutter_background_service**: Requires foreground service notification on Android (poor UX for sync)
- **alarm_manager**: Android only, no iOS support
- **Manual implementation**: Platform-specific code, harder to maintain
- **PowerSync**: Commercial solution with excellent background sync, but requires subscription

### Implementation Notes

```dart
// 1. Dependencies
dependencies:
  workmanager: ^0.5.x

// 2. Platform Configuration

// Android: AndroidManifest.xml (automatic with workmanager)
// No additional configuration needed

// iOS: Enable Background Modes in Xcode
// 1. Open ios/Runner.xcworkspace in Xcode
// 2. Select Runner target → Signing & Capabilities
// 3. Add "Background Modes" capability
// 4. Check "Background fetch" and "Background processing"

// iOS: Info.plist
/*
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.yourapp.expense.sync</string>
</array>
*/

// 3. Initialize WorkManager
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  runApp(MyApp());
}

// 4. Background Callback (Top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'expense-sync':
          await _performBackgroundSync();
          break;
        default:
          print('Unknown task: $task');
      }
      return Future.value(true); // Task completed successfully
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false); // Task failed, will retry
    }
  });
}

// 5. Background Sync Logic
Future<void> _performBackgroundSync() async {
  // Initialize minimal dependencies (no UI context)
  final db = AppDatabase(await _getUserSession());
  final supabase = await _getSupabaseClient();
  final sync = SyncService(db, supabase, ConnectivityService());

  // Check connectivity
  if (!await sync.isConnected()) {
    print('Background sync skipped: no connectivity');
    return;
  }

  // Perform sync
  await sync.startSync();

  print('Background sync completed at ${DateTime.now()}');
}

// 6. Register Periodic Background Sync
class BackgroundSyncScheduler {
  static const String syncTaskName = 'expense-sync';

  static Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(hours: 1),
  }) async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when online
        requiresBatteryNotLow: true,        // Don't drain battery
        requiresCharging: false,            // Can run on battery
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep, // Don't duplicate
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: Duration(minutes: 5),
    );
  }

  static Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
  }

  // One-time sync (e.g., after user makes changes offline)
  static Future<void> scheduleImmediateSync() async {
    await Workmanager().registerOneOffTask(
      'sync-${DateTime.now().millisecondsSinceEpoch}',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: Duration(seconds: 5), // Small delay to batch changes
      backoffPolicy: BackoffPolicy.exponential,
    );
  }
}

// 7. User Preference for Background Sync
class BackgroundSyncSettings {
  static const String _key = 'background_sync_enabled';
  final SharedPreferences _prefs;

  Future<bool> isEnabled() async {
    return _prefs.getBool(_key) ?? true; // Default enabled
  }

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_key, enabled);

    if (enabled) {
      await BackgroundSyncScheduler.schedulePeriodicSync();
    } else {
      await BackgroundSyncScheduler.cancelPeriodicSync();
    }
  }
}

// 8. Battery Optimization Warning (Android)
class BatteryOptimizationHelper {
  // Optional: Guide user to disable battery optimization for reliable background sync
  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    // Use permission_handler or battery_optimization package
    // Show dialog explaining why battery optimization should be disabled
    // Link to system settings
  }
}
```

**Platform-Specific Behavior:**

**Android:**
- Uses WorkManager (very reliable)
- Periodic tasks: minimum 15 minutes interval
- Respects Doze mode and App Standby
- Can run even if app is force-stopped (unless battery optimization is aggressive)

**iOS:**
- Uses BGTaskScheduler (less predictable)
- System decides when to run background tasks
- **Not guaranteed**: iOS may not run task if battery is low or app is rarely used
- Recommended: Set user expectation that background sync is "best effort"
- Foreground sync is more reliable

**Best Practices:**
- **Frequency**: 1-4 hours for periodic sync (not too aggressive)
- **Constraints**: Always require network connectivity
- **Timeout**: Keep background task under 30 seconds (iOS limitation)
- **Fallback**: Always sync when app comes to foreground
- **User Control**: Allow users to disable background sync in settings
- **Battery**: Respect battery optimization settings
- **Testing**: Test on real devices (emulators don't reflect real background behavior)

**iOS Testing Note:**
As of January 2024, some developers reported partial iOS functionality issues with workmanager. Test thoroughly on real iOS devices. Consider implementing foreground-only sync as fallback.

**User Communication:**
- Android: "Background sync will run approximately every [X] hours"
- iOS: "Background sync may run periodically when conditions allow"
- Both: "Your data will always sync when you open the app"

### References
- [workmanager Package](https://pub.dev/packages/workmanager)
- [Handling Background Tasks with WorkManager - Vibe Studio](https://vibe-studio.ai/insights/handling-background-tasks-with-workmanager)
- [Building Offline Auto-Sync with Background Services - Medium](https://medium.com/@dhruvmanavadaria/building-offline-auto-sync-in-flutter-with-background-services-using-workmanager-13f5bc94023d)
- [Flutter Background Processes Documentation](https://docs.flutter.dev/packages-and-plugins/background-processes)

---

## 7. UUID Generation

### Decision
Use the **uuid** package with **v4 (random)** UUIDs for all client-generated identifiers.

### Rationale
- **Collision Resistance**: UUID v4 has extremely low collision probability (1 in 2^122)
- **Offline-Safe**: Doesn't require network, timestamp sync, or MAC address
- **Privacy**: No device information embedded (unlike v1)
- **Standard**: RFC4122 compliant, widely supported
- **Simple**: No configuration or state management required

### Alternatives Considered
- **UUID v1**: Includes MAC address and timestamp (privacy concern, not suitable for mobile)
- **UUID v7**: Timestamp-based with random component (newer standard, good for sorting, but less mature library support)
- **ULID**: Sortable, compact, but less standardized than UUID
- **Sequential IDs**: Can't generate offline, require server coordination
- **Compound keys**: Complex, poor database performance

### Implementation Notes

```dart
// 1. Dependency
dependencies:
  uuid: ^4.x.x

// 2. Create UUID Service (Singleton)
class UuidService {
  static final UuidService _instance = UuidService._internal();
  factory UuidService() => _instance;
  UuidService._internal();

  final Uuid _uuid = Uuid();

  String generateId() {
    return _uuid.v4(); // e.g., "550e8400-e29b-41d4-a716-446655440000"
  }

  // For cases where you need to validate UUID format
  bool isValidUuid(String id) {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(id);
  }
}

// 3. Register as Singleton (with get_it or similar)
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<UuidService>(() => UuidService());
  // ... other dependencies
}

// 4. Usage in Models
@DataClassName('Expense')
class Expenses extends Table {
  TextColumn get id => text().clientDefault(() => UuidService().generateId())();
  // ... other fields

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Usage in Repositories
class ExpenseRepository {
  final AppDatabase _db;
  final UuidService _uuid;

  Future<Expense> createExpense({
    required String userId,
    required double amount,
    required String categoryId,
    // ... other fields
  }) async {
    final expense = ExpensesCompanion.insert(
      id: Value(_uuid.generateId()), // Explicit UUID generation
      userId: userId,
      amount: amount,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // ... other fields
    );

    await _db.into(_db.expenses).insert(expense);
    return (await _db.select(_db.expenses)
          ..where((tbl) => tbl.id.equals(expense.id.value)))
        .getSingle();
  }
}

// 6. Supabase Database Schema
/*
-- On Supabase, use UUID type for ID columns

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  amount DECIMAL(10, 2) NOT NULL,
  -- ... other columns
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index on UUID for faster lookups
CREATE INDEX idx_expenses_user_id ON expenses(user_id);

-- Note: When inserting from Flutter, client provides the UUID
-- So the DEFAULT gen_random_uuid() is only used for server-side inserts
*/

// 7. Sync Queue with UUID Operations
class SyncService {
  final UuidService _uuid;

  Future<void> queueOperation({
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    final operationId = _uuid.generateId(); // Unique operation ID

    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        operationId: operationId,
        entityType: entityType,
        entityId: entityId, // This is also a UUID
        operation: operation,
        payload: Value(payload != null ? jsonEncode(payload) : null),
        createdAt: DateTime.now(),
        status: 'pending',
      ),
    );
  }
}

// 8. UUID vs ULID Consideration
/*
If you need sortable IDs (e.g., for pagination, chronological ordering),
consider using ULID instead:

dependencies:
  ulid: ^2.x.x

final ulid = Ulid();
final id = ulid.nextULID(); // Sortable by creation time

However, UUID v4 is more standard and has better tooling support.
For sorting, use separate created_at timestamp column instead.
*/

// 9. Testing UUID Generation
void main() {
  test('UUID service generates valid v4 UUIDs', () {
    final uuidService = UuidService();
    final id1 = uuidService.generateId();
    final id2 = uuidService.generateId();

    expect(uuidService.isValidUuid(id1), true);
    expect(uuidService.isValidUuid(id2), true);
    expect(id1, isNot(equals(id2))); // Collision check
  });

  test('UUID collision probability is negligible', () {
    final uuidService = UuidService();
    final ids = <String>{};

    // Generate 10,000 UUIDs
    for (int i = 0; i < 10000; i++) {
      ids.add(uuidService.generateId());
    }

    // All should be unique
    expect(ids.length, 10000);
  });
}
```

**UUID Format:**
- Version 4 (random): `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
- Where `4` indicates version 4
- `y` is one of `8`, `9`, `a`, or `b`
- All other `x` are random hex digits

**Database Considerations:**
- **Storage**: UUID is 16 bytes (vs 4 bytes for INT), but mobile DB size is rarely an issue
- **Indexing**: Modern databases (PostgreSQL, SQLite) index UUIDs efficiently
- **String vs Binary**: Use string representation for simplicity in Flutter/Dart

**Best Practices:**
- Generate UUID as early as possible (at creation time, not on insert)
- Use UUID for all entities that may be created offline
- Avoid UUID for truly sequential data (use auto-increment on server for logs, etc.)
- Always validate UUID format when receiving from external sources

**Conflict Prevention:**
- UUID v4 collision probability: ~1 in 2^122 (quintillions)
- For a billion users creating a million records each: probability of collision is ~0.00000000000000001%
- No need for additional uniqueness checks in practice

**Migration from Auto-Increment:**
If migrating from auto-increment IDs:
1. Create new UUID column
2. Generate UUIDs for existing records
3. Update foreign keys
4. Switch primary key to UUID
5. Drop old auto-increment column

### References
- [UUID in Flutter: A Comprehensive Guide - Medium](https://medium.com/@desiappdev24/uuid-in-flutter-a-comprehensive-guide-75f1a8acbcb1)
- [How to use UUIDs in Flutter using Drift](https://chikomukwenha.co/programming/how-to-use-uuids-in-flutter-using-drift/)
- [Flutter UUID Package](https://pub.dev/packages/uuid)
- [Introducing dart-uuid: Comprehensive Guide - Medium](https://medium.com/@flutternewshub/introducing-dart-uuid-a-comprehensive-guide-to-uuid-generation-19afff411f25)

---

## Summary of Technology Decisions

| Component | Technology | Version | Primary Reason |
|-----------|-----------|---------|----------------|
| Local Database | Drift + SQLCipher | Drift 2.x | Type-safe, reactive, encrypted |
| Encryption | sqlcipher_flutter_libs | 0.x | Cross-platform, AES-256 |
| Key Storage | flutter_secure_storage | 9.x | Platform secure storage |
| Connectivity | connectivity_plus + internet_connection_checker_plus | 6.x + 2.x | Reliable online detection |
| Sync Queue | Custom (Drift-based) | N/A | Tailored to requirements |
| Background Sync | workmanager | 0.5.x | Cross-platform, reliable |
| UUID Generation | uuid | 4.x | Standard, collision-resistant |
| Conflict Resolution | Custom (Server Wins) | N/A | Financial data integrity |
| State Management | flutter_bloc | 8.x | Reactive, testable |

## Implementation Sequence

1. **Phase 1 - Foundation**
   - Set up Drift database with encryption
   - Implement UUID service
   - Add user session management

2. **Phase 2 - Offline Storage**
   - Create database schema with user_id columns
   - Implement user-scoped queries
   - Add local CRUD operations

3. **Phase 3 - Sync Infrastructure**
   - Build sync queue system
   - Implement connectivity monitoring
   - Create sync service with batching and retry logic

4. **Phase 4 - Conflict Resolution**
   - Add server wins conflict detection
   - Implement conflict notification system
   - Build conflict resolution UI

5. **Phase 5 - Background Sync**
   - Configure workmanager
   - Implement background sync logic
   - Add user preferences for background sync

6. **Phase 6 - Testing & Polish**
   - Integration testing (offline → online scenarios)
   - Performance optimization
   - User experience refinements

## Additional Considerations

### Testing Strategy
- **Unit Tests**: UUID generation, sync queue logic, conflict detection
- **Integration Tests**: Full offline → online sync flow
- **Manual Testing**: Real device testing with airplane mode
- **Edge Cases**: Battery optimization, app force-stop, concurrent edits

### Performance Optimization
- **Batch Operations**: Group sync operations (max 10 items per batch)
- **Incremental Sync**: Only sync changed records (use `updated_at` timestamps)
- **Compression**: Consider compressing large payloads in sync queue
- **Pagination**: Fetch data in pages during initial sync (1000 records max per page)

### Error Handling
- **Network Errors**: Retry with exponential backoff
- **Supabase Errors**: Log errors, notify user of critical failures
- **Database Errors**: Handle encryption key errors, disk full scenarios
- **Sync Failures**: Mark operations as failed after 3 retries, allow manual retry

### Security Considerations
- **Encryption at Rest**: All local data encrypted with SQLCipher
- **Encryption in Transit**: Supabase uses HTTPS
- **Key Management**: Keys stored in platform secure storage only
- **Row Level Security**: Enforce user isolation on server
- **Authentication**: Re-authenticate on sensitive operations

### User Experience
- **Offline Indicator**: Show banner when offline
- **Sync Status**: Display sync progress (e.g., "Syncing 5 of 12 expenses")
- **Conflict Notifications**: Badge with unread conflict count
- **Background Sync**: Clear user expectations (best effort on iOS)
- **Error Recovery**: Actionable error messages with retry options

---

**Document Version**: 1.0
**Last Updated**: 2026-01-07
**Status**: Complete
