# Data Model: Offline Expense Sync

**Feature**: 010-offline-expense-sync
**Date**: 2026-01-07
**Purpose**: Define Drift database schema for offline expense management

## Overview

This data model extends the existing expense system with offline support, adding three new tables for local data persistence, sync queue management, and conflict tracking.

**Design Principles**:
- User isolation: All tables scoped by `user_id` for multi-user device support
- Encryption: All tables stored in SQLCipher-encrypted Drift database
- Persistence: Data survives app restarts, device reboots, and user logout/login cycles
- Sync metadata: Track sync status, retry attempts, and conflicts

---

## Table Definitions

### 1. OfflineExpenses

Stores expenses created or modified while offline, with full expense data plus sync metadata.

```dart
@TableIndex(name: 'offline_expenses_user_status_idx', columns: {#userId, #syncStatus})
@TableIndex(name: 'offline_expenses_user_created_idx', columns: {#userId, #localCreatedAt})
class OfflineExpenses extends Table {
  // Primary Key
  TextColumn get id => text()(); // UUID v4 generated client-side

  // User Isolation (FR-022)
  TextColumn get userId => text()(); // References auth.users(id)

  // Expense Fields (same as server expense model)
  RealColumn get amount => real()(); // Decimal amount
  DateTimeColumn get date => dateTime()(); // Transaction date
  TextColumn get categoryId => text()(); // References expense_categories(id)
  TextColumn get merchant => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isGroupExpense => boolean().withDefault(const Constant(true))();

  // Receipt Image Reference (if uploaded offline)
  TextColumn get localReceiptPath => text().nullable()(); // Local file path
  IntColumn get receiptImageSize => integer().nullable()(); // Bytes, for SC-012 tracking

  // Sync Metadata
  TextColumn get syncStatus => text()(); // 'pending', 'syncing', 'completed', 'failed', 'conflict'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttemptAt => dateTime().nullable()();
  TextColumn get syncErrorMessage => text().nullable()();

  // Conflict Resolution
  BoolColumn get hasConflict => boolean().withDefault(const Constant(false))();
  TextColumn get serverVersionData => text().nullable()(); // JSON of server version if conflict

  // Timestamps
  DateTimeColumn get localCreatedAt => dateTime()(); // Client-side creation time
  DateTimeColumn get localUpdatedAt => dateTime()(); // Client-side last modification

  @override
  Set<Column> get primaryKey => {id};
}
```

**Lifecycle**:
1. **Create Offline**: Insert with `syncStatus='pending'`, UUID v4 `id`
2. **Edit Offline**: Update fields, increment `localUpdatedAt`, keep `syncStatus='pending'`
3. **Sync**: Set `syncStatus='syncing'`, attempt upload
4. **Success**: Set `syncStatus='completed'`, optionally delete row (implementation choice)
5. **Failure**: Set `syncStatus='failed'`, increment `retryCount`, log `syncErrorMessage`
6. **Conflict**: Set `syncStatus='conflict'`, `hasConflict=true`, store `serverVersionData`

**Storage Estimate**: ~500 bytes per expense (without image) = 250KB for 500 expenses (within SC-012)

---

### 2. SyncQueueItems

Manages ordered queue of sync operations (create, update, delete) for expenses and images.

```dart
@TableIndex(name: 'sync_queue_user_status_idx', columns: {#userId, #syncStatus, #nextRetryAt})
@TableIndex(name: 'sync_queue_created_idx', columns: {#createdAt})
class SyncQueueItems extends Table {
  // Primary Key
  IntColumn get id => integer().autoIncrement()();

  // User Isolation
  TextColumn get userId => text()();

  // Operation Details
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get entityType => text()(); // 'expense', 'expense_image'
  TextColumn get entityId => text()(); // UUID of offline expense or server expense ID
  TextColumn get payload => text()(); // JSON serialized data for the operation

  // Sync Metadata
  TextColumn get syncStatus => text()(); // 'pending', 'syncing', 'completed', 'failed'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()(); // For exponential backoff
  TextColumn get errorMessage => text().nullable()();

  // Priority & Ordering
  IntColumn get priority => integer().withDefault(const Constant(0))(); // Higher = more urgent
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Operation Types**:
- `create`: Sync new offline expense to server
- `update`: Sync modified expense fields to server
- `delete`: Delete expense from server (user deleted offline)
- `upload_image`: Upload receipt image to storage bucket

**Queue Processing**:
1. Query: `WHERE userId = ? AND syncStatus = 'pending' AND (nextRetryAt IS NULL OR nextRetryAt <= NOW()) ORDER BY createdAt LIMIT 10`
2. Batch process up to 10 items (FR-016)
3. For each item:
   - Set `syncStatus='syncing'`
   - Execute operation (API call)
   - On success: `syncStatus='completed'`
   - On failure: Increment `retryCount`, calculate `nextRetryAt` (30s, 2min, 5min), `syncStatus='pending'` or `'failed'` if retries exhausted

**Exponential Backoff** (FR-008):
```dart
final delays = [30, 120, 300]; // seconds: 30s, 2min, 5min
final retryDelay = retryCount <= 3 ? delays[min(retryCount - 1, 2)] : null;
nextRetryAt = retryDelay != null ? DateTime.now().add(Duration(seconds: retryDelay)) : null;
```

**Storage Estimate**: ~300 bytes per item = 150KB for 500 items

---

### 3. OfflineExpenseImages

Stores compressed receipt images for offline expenses until synced to Supabase Storage.

```dart
@TableIndex(name: 'offline_images_expense_idx', columns: {#expenseId})
@TableIndex(name: 'offline_images_user_idx', columns: {#userId, #uploadStatus})
class OfflineExpenseImages extends Table {
  // Primary Key
  IntColumn get id => integer().autoIncrement()();

  // Relationships
  TextColumn get expenseId => text()(); // References offline_expenses(id) or synced server expense ID
  TextColumn get userId => text()();

  // Image Data
  BlobColumn get compressedImageData => blob()(); // Compressed JPEG bytes
  IntColumn get originalSizeBytes => integer()();
  IntColumn get compressedSizeBytes => integer()();
  RealColumn get compressionRatio => real()(); // originalSize / compressedSize

  // Upload Metadata
  TextColumn get uploadStatus => text()(); // 'pending', 'uploading', 'completed', 'failed'
  TextColumn get storagePath => text().nullable()(); // Supabase storage path after upload
  IntColumn get uploadRetryCount => integer().withDefault(const Constant(0))();
  TextColumn get uploadErrorMessage => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Image Processing Flow**:
1. **Capture**: User takes photo or selects from gallery
2. **Compress**: Use `flutter_image_compress` to target 80% quality, max 10MB (FR-013)
3. **Store**: Insert compressed bytes into this table
4. **Sync**: When expense syncs successfully, queue image upload operation
5. **Upload**: Stream image to Supabase Storage with progress (FR-014)
6. **Complete**: Update `uploadStatus='completed'`, store `storagePath`, delete blob data (optional)

**Compression Strategy** (C-006: min 80% visual similarity):
```dart
final compressed = await FlutterImageCompress.compressWithList(
  imageBytes,
  quality: 85, // JPEG quality 0-100
  format: CompressFormat.jpeg,
);

// Enforce 10MB limit (FR-013)
if (compressed.length > 10 * 1024 * 1024) {
  throw ImageTooLargeException('Compressed image exceeds 10MB limit');
}
```

**Storage Estimate**: Average 1MB per compressed image = 500MB for 500 images (exceeds SC-012, but images are deleted post-upload)

---

### 4. SyncConflicts (Optional - for User Story 4 P4)

Tracks conflicts detected during sync for user review and resolution.

```dart
@TableIndex(name: 'sync_conflicts_user_idx', columns: {#userId, #resolvedAt})
class SyncConflicts extends Table {
  // Primary Key
  IntColumn get id => integer().autoIncrement()();

  // Relationships
  TextColumn get userId => text()();
  TextColumn get expenseId => text()(); // The conflicted expense ID

  // Conflict Data
  TextColumn get localVersionData => text()(); // JSON of local version
  TextColumn get serverVersionData => text()(); // JSON of server version
  TextColumn get conflictType => text()(); // 'update_conflict', 'delete_conflict'

  // Resolution
  TextColumn get resolutionAction => text().nullable()(); // 'accepted_server', 'created_new', 'discarded'
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  // Timestamps
  DateTimeColumn get detectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Conflict Resolution Flow** (FR-009):
1. **Detect**: During sync, compare `localUpdatedAt` vs server `updated_at`
2. **Log**: Insert conflict record with both versions
3. **Notify**: Show user notification with conflict details
4. **Resolve**: User chooses action (accept server, create new expense, discard)
5. **Record**: Update `resolutionAction` and `resolvedAt`

---

## Relationships

```
Users (Supabase auth.users)
  ├─1:N─> OfflineExpenses (userId)
  ├─1:N─> SyncQueueItems (userId)
  ├─1:N─> OfflineExpenseImages (userId)
  └─1:N─> SyncConflicts (userId)

OfflineExpenses
  ├─1:1─> OfflineExpenseImages (expenseId) [optional]
  ├─1:N─> SyncQueueItems (entityId where entityType='expense')
  └─1:N─> SyncConflicts (expenseId) [optional]

ExpenseCategories (existing server table)
  └─1:N─> OfflineExpenses (categoryId)
```

---

## Validation Rules

Enforced at application layer (Drift doesn't support CHECK constraints):

### OfflineExpenses
- `amount > 0` (positive non-zero)
- `date <= NOW()` (no future expenses)
- `syncStatus IN ('pending', 'syncing', 'completed', 'failed', 'conflict')`
- `retryCount >= 0 AND retryCount <= 3`
- `receiptImageSize <= 10MB` if present (FR-013)
- `userId` must match current authenticated user when querying

### SyncQueueItems
- `operation IN ('create', 'update', 'delete', 'upload_image')`
- `entityType IN ('expense', 'expense_image')`
- `syncStatus IN ('pending', 'syncing', 'completed', 'failed')`
- `retryCount >= 0 AND retryCount <= 3`
- `nextRetryAt > NOW()` if present
- `payload` must be valid JSON

### OfflineExpenseImages
- `compressedSizeBytes <= 10MB` (FR-013)
- `originalSizeBytes >= compressedSizeBytes`
- `compressionRatio >= 1.0`
- `uploadStatus IN ('pending', 'uploading', 'completed', 'failed')`
- `uploadRetryCount >= 0`

---

## State Transitions

### Offline Expense Lifecycle

```
[Created Offline]
   ↓
syncStatus='pending' ────> [User Edits] ──> localUpdatedAt updated, syncStatus remains 'pending'
   ↓
[Network Restored]
   ↓
syncStatus='syncing' (locked for edits - FR-024)
   ↓
[Sync Result]
   ├─ Success ──> syncStatus='completed' ──> [Delete or Archive]
   ├─ Failure ──> syncStatus='failed', retryCount++, nextRetryAt set ──> [Retry or Manual Fix]
   └─ Conflict ─> syncStatus='conflict', hasConflict=true ──> [User Resolution]
```

### Sync Queue Item Lifecycle

```
[Operation Queued]
   ↓
syncStatus='pending'
   ↓
[Queue Processor]
   ↓
syncStatus='syncing'
   ↓
[API Call Result]
   ├─ Success ──> syncStatus='completed' ──> [Delete from queue]
   ├─ Retriable Error ──> retryCount++, nextRetryAt calculated, syncStatus='pending'
   └─ Permanent Error ──> syncStatus='failed', nextRetryAt=null ──> [User Intervention]
```

---

## Indexes & Performance

### Critical Indexes
1. `offline_expenses_user_status_idx`: Fast filtering by user + sync status
2. `sync_queue_user_status_idx`: Efficient queue queries for batch processing
3. `offline_images_expense_idx`: Quick lookup of images by expense

### Query Performance Targets (SC-015)
- Fetch pending expenses for user: < 50ms (indexed user_id + syncStatus)
- Batch queue query (10 items): < 30ms
- Insert new offline expense: < 20ms
- Update sync status: < 10ms

### Database Size Monitoring (SC-012)
```dart
// Monitor total size
final dbFile = File(dbPath);
final sizeBytes = await dbFile.length();
final sizeMB = sizeBytes / (1024 * 1024);

if (sizeMB > 50) {
  // Warn user or force sync (approaching SC-012 limit)
  await _warnUserToSync();
}
```

---

## Migration Strategy

### Phase 1: Add Tables
```dart
@DriftDatabase(
  tables: [
    OfflineExpenses,
    SyncQueueItems,
    OfflineExpenseImages,
    SyncConflicts, // Optional
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2; // Increment from existing version

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll(); // Create all tables
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add offline tables
        await m.createTable(offlineExpenses);
        await m.createTable(syncQueueItems);
        await m.createTable(offlineExpenseImages);
        await m.createTable(syncConflicts);

        // Create indexes
        await m.createIndex(Index(
          'offline_expenses_user_status_idx',
          'CREATE INDEX offline_expenses_user_status_idx ON offline_expenses (user_id, sync_status)',
        ));
        // ... other indexes ...
      }
    },
  );
}
```

### Phase 2: Seed Initial Data (if needed)
- No seeding required; tables start empty
- Existing server expenses remain on server
- Offline expenses created only when network unavailable

---

## Security Considerations

### Encryption (FR-021, C-009)
- All tables encrypted at rest with SQLCipher AES-256
- Encryption key stored in `flutter_secure_storage` (iOS Keychain, Android Keystore)
- Performance overhead: < 15% (well under < 100ms requirement)

### Data Sanitization
- No sensitive data in logs (C-010)
- Sync error messages: generic ("Network error") not full exception traces
- Conflict notifications: show merchant name, not full amount/notes

### User Isolation
- All queries automatically filter by `userId`
- No cross-user data access possible
- Logout clears current user context, not data (FR-022)

---

## Testing Strategy

### Unit Tests
- Validate all state transitions
- Test retry logic with mock time
- Verify user isolation (multi-user scenarios)
- Test 500-expense limit enforcement (FR-026)

### Integration Tests
- End-to-end offline create → online sync flow
- Conflict detection and resolution
- Image compression and upload
- Background sync with WorkManager

### Performance Tests
- 500 pending expenses: query time < 500ms (SC-015)
- Database size with 500 expenses + images: < 50MB (SC-012)
- Encryption overhead: < 100ms per operation (C-009)

---

## Next Steps

1. ✅ **Phase 0 Complete**: Research.md created
2. ✅ **Phase 1 In Progress**: Data-model.md created
3. ⏭️ **Next**: Create API contracts (if backend needs batch endpoints)
4. ⏭️ **Next**: Create quickstart.md for developers
5. ⏭️ **Next**: Update agent context with new technologies
