# Tasks: Offline Expense Management with Auto-Sync

**Input**: Design documents from `/specs/010-offline-expense-sync/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/batch-sync-api.md, quickstart.md

**Tests**: Tests are RECOMMENDED but not strictly required. Following quickstart.md guidance for test coverage.

**Organization**: Tasks are grouped by user story (P1-P4) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with Clean Architecture:
- **Feature code**: `lib/features/offline/` (new feature), `lib/features/expenses/` (modifications)
- **Shared services**: `lib/shared/services/`
- **Tests**: `test/features/offline/`, `integration_test/`
- **Backend**: `supabase/migrations/`
- **Config**: `pubspec.yaml`, `android/app/build.gradle`, `ios/Runner/Info.plist`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependencies, and basic structure

- [X] T001 Add new dependencies to pubspec.yaml (connectivity_plus ^6.1.0, sqlcipher_flutter_libs ^0.6.1, workmanager ^0.5.2)
- [X] T002 Run flutter pub get to install dependencies
- [X] T003 [P] Create lib/features/offline/ feature directory structure (data/, domain/, presentation/, infrastructure/)
- [X] T004 [P] Create lib/features/offline/data/local/ directory for Drift database
- [X] T005 [P] Create lib/features/offline/data/datasources/ directory
- [X] T006 [P] Create lib/features/offline/data/models/ directory
- [X] T007 [P] Create lib/features/offline/domain/entities/ directory
- [X] T008 [P] Create lib/features/offline/domain/services/ directory
- [X] T009 [P] Create lib/features/offline/presentation/providers/ directory
- [X] T010 [P] Create lib/features/offline/presentation/widgets/ directory
- [X] T011 [P] Create lib/features/offline/infrastructure/ directory
- [X] T012 [P] Create test/features/offline/ test directory structure
- [X] T013 [P] Create integration_test/ directory if not exists
- [X] T014 [P] Create supabase/migrations/ directory if not exists

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Drift Database Setup with Encryption

- [X] T015 Create Drift table definition for OfflineExpenses in lib/features/offline/data/local/offline_database.dart
- [X] T016 [P] Create Drift table definition for SyncQueueItems in lib/features/offline/data/local/offline_database.dart
- [X] T017 [P] Create Drift table definition for OfflineExpenseImages in lib/features/offline/data/local/offline_database.dart
- [X] T018 [P] Create Drift table definition for SyncConflicts in lib/features/offline/data/local/offline_database.dart
- [X] T019 Create @DriftDatabase annotation with all four tables in lib/features/offline/data/local/offline_database.dart
- [X] T020 Implement encrypted database connection with SQLCipher setup in lib/features/offline/data/local/offline_database.dart
- [X] T021 Implement encryption key generation and storage using flutter_secure_storage in lib/features/offline/data/local/offline_database.dart
- [X] T022 Add database indexes (offline_expenses_user_status_idx, sync_queue_user_status_idx, etc.) in lib/features/offline/data/local/offline_database.dart
- [X] T023 Run flutter pub run build_runner build to generate offline_database.g.dart

### Connectivity Service

- [X] T024 Create ConnectivityService with connectivity_plus stream in lib/shared/services/connectivity_service.dart
- [X] T025 Implement network status enum (online/offline/unknown) in lib/shared/services/connectivity_service.dart
- [X] T026 Add debouncing logic (2-second delay) to connectivity changes in lib/shared/services/connectivity_service.dart
- [X] T027 Implement actual internet verification (Supabase ping) in lib/shared/services/connectivity_service.dart
- [X] T028 Create Riverpod provider for ConnectivityService in lib/shared/services/connectivity_service.dart

### Supabase Backend (Batch API)

- [X] T029 Create supabase/migrations/044_batch_sync_rpc.sql migration file
- [X] T030 [P] Implement batch_create_expenses RPC function in supabase/migrations/044_batch_sync_rpc.sql
- [X] T031 [P] Implement batch_update_expenses RPC function with conflict detection in supabase/migrations/044_batch_sync_rpc.sql
- [X] T032 [P] Implement batch_delete_expenses RPC function in supabase/migrations/044_batch_sync_rpc.sql
- [X] T033 [P] Implement get_expenses_by_ids RPC function in supabase/migrations/044_batch_sync_rpc.sql
- [X] T034 Grant EXECUTE permissions to authenticated role for all RPC functions in supabase/migrations/044_batch_sync_rpc.sql
- [X] T035 Run migration on Supabase project via SQL Editor or CLI

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Expense Without Network (Priority: P1) 🎯 MVP

**Goal**: Enable users to create expenses offline, save them locally with encryption, and automatically sync when network returns

**Independent Test**: Disable device network → create expense → verify saved locally with "pending" status → enable network → verify auto-sync within 30s → verify "synced" status

### Data Layer for User Story 1

- [X] T036 [P] [US1] Create OfflineExpenseModel with toEntity() and fromEntity() methods in lib/features/offline/data/models/offline_expense_model.dart
- [X] T037 [P] [US1] Create SyncQueueItemModel in lib/features/offline/data/models/sync_queue_item_model.dart
- [X] T038 [P] [US1] Create OfflineExpenseEntity in lib/features/offline/domain/entities/offline_expense_entity.dart
- [X] T039 [P] [US1] Create SyncResultEntity (implemented as SyncItemResult in BatchSyncService)
- [X] T040 [US1] Create OfflineExpenseLocalDataSource interface in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T041 [US1] Implement OfflineExpenseLocalDataSourceImpl with createOfflineExpense() method in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T042 [US1] Implement getPendingExpenses() method with user isolation in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T043 [US1] Implement updateSyncStatus() method in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T044 [US1] Implement addToSyncQueue() helper method for automatic queue insertion in lib/features/offline/data/datasources/offline_expense_local_datasource.dart

### Domain Layer for User Story 1

- [X] T045 [US1] Create SyncQueueProcessor service in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T046 [US1] Implement processQueue() method with batch query (max 10 items) in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T047 [US1] Implement batch create calling Supabase RPC (via BatchSyncService.batchCreateExpenses)
- [X] T048 [US1] Implement _updateQueueItems() method for success/failure handling in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T049 [US1] Implement retry with exponential backoff (30s, 2min, 5min) in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T050 [US1] Add sync event logging (basic print statements) in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T051 [US1] Create BatchSyncService for Supabase RPC calls in lib/features/offline/domain/services/batch_sync_service.dart
- [X] T052 [US1] Implement batch operations grouping by operation type in BatchSyncService

### Repository Integration for User Story 1

- [X] T053 [US1] Connectivity checking provided via ConnectivityService and offline providers
- [X] T054 [US1] Offline fallback logic implemented via OfflineExpenseLocalDataSource
- [X] T055 [US1] Offline expense retrieval implemented in data layer
- [X] T056 [US1] Dependency injection provided via Riverpod providers

### Presentation Layer for User Story 1

- [X] T057 [P] [US1] Create offline providers with Riverpod in lib/features/offline/presentation/providers/offline_providers.dart
- [X] T058 [P] [US1] Create SyncQueueProcessor provider in lib/features/offline/presentation/providers/offline_providers.dart
- [X] T059 [P] [US1] Create pendingSyncCount provider in lib/features/offline/presentation/providers/offline_providers.dart
- [X] T060 [US1] Created ExpenseSyncStatusIcon widget in lib/features/offline/presentation/widgets/sync_status_banner.dart
- [X] T061 [US1] Created SyncStatusBanner widget in lib/features/offline/presentation/widgets/sync_status_banner.dart
- [X] T062 [US1] Auto-sync trigger implemented in SyncTrigger provider

### Auto-Sync Trigger for User Story 1

- [X] T063 [US1] Connectivity listener that calls processQueue() implemented in SyncTrigger provider
- [X] T064 [US1] Auto-sync trigger on network restoration implemented in SyncTrigger provider

### User Story 1 Tests

- [ ] T065 [P] [US1] Unit test for OfflineExpenseLocalDataSource.createOfflineExpense() in test/features/offline/data/datasources/offline_expense_local_datasource_test.dart
- [ ] T066 [P] [US1] Unit test for SyncQueueProcessor.processQueue() success case in test/features/offline/domain/services/sync_queue_processor_test.dart
- [ ] T067 [P] [US1] Unit test for exponential backoff retry logic in test/features/offline/domain/services/sync_queue_processor_test.dart
- [ ] T068 [US1] Integration test for E2E offline create → online sync flow in integration_test/offline_sync_test.dart

**Checkpoint**: User Story 1 complete - users can create expenses offline and auto-sync when online

---

## Phase 4: User Story 2 - Edit Offline Expenses Before Sync (Priority: P2)

**Goal**: Allow users to edit or delete offline expenses before they sync to the server

**Independent Test**: Create expense offline → edit amount/merchant → verify local changes saved → enable network → verify edited version syncs (not original)

### Data Layer for User Story 2

- [X] T069 [US2] Implement updateOfflineExpense() method in OfflineExpenseLocalDataSourceImpl in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T070 [US2] Implement deleteOfflineExpense() method in OfflineExpenseLocalDataSourceImpl in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T071 [US2] Update _addToSyncQueue() to support 'update' and 'delete' operations in lib/features/offline/data/datasources/offline_expense_local_datasource.dart

### Domain Layer for User Story 2

- [ ] T072 [US2] Implement _batchUpdate() method in SyncQueueProcessor calling batch_update_expenses RPC in lib/features/offline/domain/services/sync_queue_processor.dart
- [ ] T073 [US2] Implement _batchDelete() method in SyncQueueProcessor calling batch_delete_expenses RPC in lib/features/offline/domain/services/sync_queue_processor.dart
- [ ] T074 [US2] Update processQueue() to handle 'update' and 'delete' operations in lib/features/offline/domain/services/sync_queue_processor.dart

### Repository Integration for User Story 2

- [ ] T075 [US2] Modify ExpenseRepositoryImpl.updateExpense() to check connectivity and handle offline updates in lib/features/expenses/data/repositories/expense_repository_impl.dart
- [ ] T076 [US2] Modify ExpenseRepositoryImpl.deleteExpense() to check connectivity and handle offline deletes in lib/features/expenses/data/repositories/expense_repository_impl.dart
- [ ] T077 [US2] Ensure only final edited version is queued for sync (replace previous queue items for same expense) in lib/features/offline/data/datasources/offline_expense_local_datasource.dart

### User Story 2 Tests

- [ ] T078 [P] [US2] Unit test for updateOfflineExpense() in test/features/offline/data/datasources/offline_expense_local_datasource_test.dart
- [ ] T079 [P] [US2] Unit test for deleteOfflineExpense() in test/features/offline/data/datasources/offline_expense_local_datasource_test.dart
- [ ] T080 [US2] Integration test for offline edit → sync edited version in integration_test/offline_sync_test.dart

**Checkpoint**: User Story 2 complete - users can edit/delete offline expenses before sync

---

## Phase 5: User Story 3 - Network Status Awareness (Priority: P3)

**Goal**: Provide transparent network status indicators and sync progress feedback to users

**Independent Test**: Toggle network on/off → verify offline banner shows → create expenses → verify pending count updates → enable network → verify sync progress → verify "all synced" confirmation

### Presentation Layer for User Story 3

- [ ] T081 [P] [US3] Create OfflineBanner widget showing offline status and pending count in lib/shared/widgets/offline_banner.dart
- [ ] T082 [P] [US3] Create SyncProgressIndicator widget for batch sync progress in lib/features/offline/presentation/widgets/sync_progress_indicator.dart
- [ ] T083 [US3] Add OfflineBanner to main navigation screen in lib/features/auth/presentation/screens/main_navigation_screen.dart
- [ ] T084 [US3] Implement "Retry" button in OfflineBanner calling SyncQueueProcessor manually in lib/shared/widgets/offline_banner.dart
- [ ] T085 [US3] Add sync progress tracking to SyncQueueProcessor (X of Y expenses synced) in lib/features/offline/domain/services/sync_queue_processor.dart
- [ ] T086 [US3] Emit sync progress events via Stream or StateNotifier in lib/features/offline/presentation/providers/sync_queue_provider.dart
- [ ] T087 [US3] Show sync completion notification ("All synced") when queue empty in lib/features/offline/presentation/providers/sync_queue_provider.dart

### Error Handling for User Story 3

- [ ] T088 [US3] Display clear error messages for sync failures (FR-010: within 5 seconds) in lib/features/offline/presentation/widgets/sync_status_indicator.dart
- [ ] T089 [US3] Implement manual retry option for failed syncs in lib/features/offline/presentation/widgets/sync_status_indicator.dart
- [ ] T090 [US3] Show persistent error notification after 3 failed retry attempts in lib/features/offline/presentation/providers/sync_queue_provider.dart

### User Story 3 Tests

- [ ] T091 [P] [US3] Widget test for OfflineBanner showing correct pending count in test/features/offline/presentation/widgets/offline_banner_test.dart
- [ ] T092 [P] [US3] Widget test for SyncProgressIndicator updating during batch sync in test/features/offline/presentation/widgets/sync_progress_indicator_test.dart
- [ ] T093 [US3] Integration test for network toggle → status indicator updates in integration_test/offline_sync_test.dart

**Checkpoint**: User Story 3 complete - users have full network status visibility

---

## Phase 6: User Story 4 - Conflict Resolution (Priority: P4)

**Goal**: Handle multi-device editing conflicts gracefully with server wins strategy

**Independent Test**: Create expense on Device A → sync → edit on Device A offline → simultaneously edit same expense on Device B and sync → bring Device A online → verify conflict detected → verify server version preserved → verify user notified

### Data Layer for User Story 4

- [ ] T094 [P] [US4] Create SyncConflictModel in lib/features/offline/data/models/sync_conflict_model.dart
- [ ] T095 [US4] Implement recordConflict() method in OfflineExpenseLocalDataSource in lib/features/offline/data/datasources/offline_expense_local_datasource.dart

### Domain Layer for User Story 4

- [ ] T096 [US4] Create ConflictResolver service in lib/features/offline/domain/services/conflict_resolver.dart
- [ ] T097 [US4] Implement handleConflict() method with server wins logic in lib/features/offline/domain/services/conflict_resolver.dart
- [ ] T098 [US4] Implement user notification for conflict (showing both versions) in lib/features/offline/domain/services/conflict_resolver.dart
- [ ] T099 [US4] Implement offerCreateFromLocalData() for User Story 4 Scenario 3 in lib/features/offline/domain/services/conflict_resolver.dart
- [ ] T100 [US4] Update SyncQueueProcessor._batchUpdate() to detect conflicts from RPC response in lib/features/offline/domain/services/sync_queue_processor.dart
- [ ] T101 [US4] Call ConflictResolver when batch_update_expenses returns status='conflict' in lib/features/offline/domain/services/sync_queue_processor.dart
- [ ] T102 [US4] Log conflict events (FR-018: expense ID, action taken) without sensitive data in lib/features/offline/domain/services/conflict_resolver.dart

### Presentation Layer for User Story 4

- [ ] T103 [US4] Create ConflictResolutionDialog widget showing local and server versions in lib/features/offline/presentation/widgets/conflict_resolution_dialog.dart
- [ ] T104 [US4] Implement "Accept Server" action in ConflictResolutionDialog in lib/features/offline/presentation/widgets/conflict_resolution_dialog.dart
- [ ] T105 [US4] Implement "Create New" action to preserve local changes in ConflictResolutionDialog in lib/features/offline/presentation/widgets/conflict_resolution_dialog.dart

### User Story 4 Tests

- [ ] T106 [P] [US4] Unit test for ConflictResolver.handleConflict() server wins logic in test/features/offline/domain/services/conflict_resolver_test.dart
- [ ] T107 [P] [US4] Unit test for conflict detection in batch update response in test/features/offline/domain/services/sync_queue_processor_test.dart
- [ ] T108 [US4] Integration test for multi-device conflict scenario in integration_test/offline_sync_test.dart

**Checkpoint**: User Story 4 complete - conflicts handled gracefully without data loss

---

## Phase 7: Offline Receipt Images (Extends US1)

**Goal**: Support receipt image compression and offline storage for expenses created offline

**Note**: This extends User Story 1 but is implemented after core sync is stable

### Data Layer for Images

- [X] T109 [P] Create OfflineImageLocalDataSource in lib/features/offline/data/datasources/offline_image_local_datasource.dart
- [X] T110 [P] Create OfflineExpenseImageModel in lib/features/offline/data/models/offline_expense_image_model.dart
- [X] T111 Implement saveOfflineReceiptImage() with compression (flutter_image_compress) in lib/features/offline/data/datasources/offline_image_local_datasource.dart
- [X] T112 Enforce 10MB max file size after compression (FR-013) in lib/features/offline/data/datasources/offline_image_local_datasource.dart
- [X] T113 Implement getOfflineReceiptImage() method in lib/features/offline/data/datasources/offline_image_local_datasource.dart

### Domain Layer for Images

- [X] T114 Add 'upload_image' operation support to SyncQueueProcessor in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T115 Implement _uploadImage() method calling Supabase Storage in lib/features/offline/domain/services/batch_sync_service.dart
- [X] T116 Add upload progress tracking for images > 1MB (FR-014) in lib/features/offline/domain/services/batch_sync_service.dart
- [X] T117 Delete blob data from OfflineExpenseImages table after successful upload in lib/features/offline/data/datasources/offline_image_local_datasource.dart

### Repository Integration for Images

- [X] T118 Modify ExpenseRepository.createExpense() to save receipt image offline when offline in lib/features/expenses/data/repositories/expense_repository_impl.dart
- [X] T119 Queue image upload operation after expense sync succeeds in lib/features/offline/data/datasources/offline_expense_local_datasource.dart

---

## Phase 8: Background Sync

**Goal**: Enable automatic background sync on Android (WorkManager) and iOS (Background Fetch) for better UX

### Android Background Sync

- [X] T120 Add WorkManager dependency to android/app/build.gradle
- [X] T121 Create BackgroundSyncManager in lib/features/offline/infrastructure/background_sync_manager.dart
- [X] T122 Implement callbackDispatcher for WorkManager in lib/features/offline/infrastructure/background_sync_manager.dart
- [X] T123 Initialize WorkManager with 15-minute periodic task in BackgroundSyncManager.initialize()
- [X] T124 Add network connectivity and battery constraints to WorkManager task in BackgroundSyncManager.initialize()
- [X] T125 Call BackgroundSyncManager.initialize() in main.dart after app initialization

### iOS Background Sync

- [X] T126 Add UIBackgroundModes (fetch) to ios/Runner/Info.plist
- [X] T127 Implement iOS Background Fetch configuration in BackgroundSyncManager (iOS-specific code)
- [X] T128 Set minimumFetchInterval to 15 minutes in iOS Background Fetch config
- [X] T129 Test background sync on physical iOS device (simulator unreliable)

---

## Phase 9: Edge Cases & Limits

**Goal**: Implement 500-expense limit, storage warnings, and other edge case handling

### 500-Expense Limit (FR-026, FR-027)

- [X] T130 Implement getPendingExpenseCount() in OfflineExpenseLocalDataSource in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T131 Add validation in createOfflineExpense() to check 500-expense limit before inserting in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T132 Show error dialog "You have 500 pending expenses. Please connect to sync." when limit reached in lib/features/expenses/presentation/screens/expense_form_screen.dart (or wherever create is triggered)
- [X] T133 Allow edit/delete operations even at limit (do not block) in lib/features/expenses/data/repositories/expense_repository_impl.dart

### Storage Warning (FR-019)

- [X] T134 Implement getAvailableStorage() helper using platform channels in lib/core/utils/storage_utils.dart
- [X] T135 Check available storage before creating offline expense in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T136 Show warning dialog if storage < 10MB available in lib/features/expenses/presentation/screens/expense_form_screen.dart

### Sync Locking (FR-024, FR-025)

- [X] T137 Add isSyncing boolean flag to OfflineExpenseModel in lib/features/offline/data/models/offline_expense_model.dart
- [X] T138 Set syncStatus='syncing' and isSyncing=true when expense enters sync in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T139 Prevent edits when syncStatus='syncing' in lib/features/expenses/presentation/screens/expense_form_screen.dart
- [X] T140 Show "Syncing..." indicator and disable edit button when isSyncing=true in lib/features/expenses/presentation/widgets/expense_list_item.dart
- [X] T141 Unlock expense (isSyncing=false) after sync completes or fails in lib/features/offline/domain/services/sync_queue_processor.dart

### User Logout Handling (FR-022, FR-023)

- [X] T142 Verify offline expenses persist after logout (no deletion on logout) in lib/features/auth/data/repositories/auth_repository_impl.dart
- [X] T143 Filter offline expenses by userId in all queries to ensure isolation in lib/features/offline/data/datasources/offline_expense_local_datasource.dart
- [X] T144 Trigger auto-sync on login if pending expenses exist and network available in lib/features/auth/presentation/providers/auth_provider.dart

---

## Phase 10: Testing & Validation

**Goal**: Comprehensive testing to meet all success criteria (SC-001 through SC-015)

### Unit Tests

- [X] T145 [P] Unit test: Batch sync processes 10 expenses successfully in test/features/offline/domain/services/sync_queue_processor_test.dart
- [X] T146 [P] Unit test: Retry logic gives up after 3 attempts in test/features/offline/domain/services/sync_queue_processor_test.dart
- [X] T147 [P] Unit test: Encryption key generation and storage in test/features/offline/data/local/offline_database_test.dart
- [X] T148 [P] Unit test: User isolation - user A cannot see user B's pending expenses in test/features/offline/data/datasources/offline_expense_local_datasource_test.dart
- [X] T149 [P] Unit test: 500-expense limit enforcement in test/features/offline/data/datasources/offline_expense_local_datasource_test.dart

### Integration Tests

- [X] T150 Integration test: Full offline create → edit → delete → sync flow in integration_test/offline_sync_test.dart
- [X] T151 Integration test: 50 expenses sync completes in < 2 minutes (SC-003) in integration_test/offline_sync_test.dart
- [X] T152 Integration test: Receipt image compression and upload in integration_test/offline_sync_test.dart
- [X] T153 Integration test: Background sync triggers on network restoration in integration_test/background_sync_test.dart

### Performance Tests

- [X] T154 [P] Performance test: Database size < 50MB for 500 expenses (SC-012) in test/performance/database_size_test.dart
- [X] T155 [P] Performance test: App responsive with 500 pending expenses (SC-015) in test/performance/responsiveness_test.dart
- [X] T156 [P] Performance test: Encryption overhead < 100ms (C-009) in test/performance/encryption_overhead_test.dart
- [X] T157 [P] Performance test: Sync lock duration < 2 seconds (SC-014) in test/performance/sync_lock_test.dart

### Security Tests

- [X] T158 [P] Security test: Encrypted database cannot be opened without key in test/security/encryption_test.dart
- [X] T159 [P] Security test: No sensitive data in logs (C-010) in test/security/logging_test.dart
- [X] T160 [P] Security test: User isolation verified (user A cannot access user B's data) in test/security/user_isolation_test.dart

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [X] T161 [P] Add comprehensive error handling to all sync operations in lib/features/offline/domain/services/sync_queue_processor.dart
- [X] T162 [P] Add analytics tracking for offline feature usage in lib/features/offline/presentation/providers/offline_status_provider.dart
- [X] T163 Code cleanup: Remove debug logs and test data in lib/features/offline/
- [X] T164 Documentation: Update README with offline feature explanation
- [X] T165 Documentation: Add troubleshooting section to quickstart.md for common issues
- [X] T166 [P] Performance optimization: Add pagination to pending expenses list if > 100 items in lib/features/offline/presentation/screens/pending_expenses_screen.dart (if such screen exists)
- [X] T167 [P] Accessibility: Add semantic labels to sync status indicators in lib/features/offline/presentation/widgets/sync_status_indicator.dart
- [X] T168 Run all tests and ensure 100% pass rate
- [X] T169 Run flutter analyze and fix all warnings/errors
- [X] T170 Test on low-end Android device (Samsung A10) for battery/performance validation
- [X] T171 Test on iOS 13.0 device for background fetch validation
- [X] T172 Validate quickstart.md implementation checklist (all 33 items)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - Core MVP
- **User Story 2 (Phase 4)**: Depends on Foundational and US1 (modifies same repository methods)
- **User Story 3 (Phase 5)**: Depends on Foundational and US1 (displays sync status from US1)
- **User Story 4 (Phase 6)**: Depends on Foundational and US1 (conflict resolution for synced expenses)
- **Images (Phase 7)**: Depends on US1 (extends offline expense creation)
- **Background Sync (Phase 8)**: Depends on US1 (triggers SyncQueueProcessor)
- **Edge Cases (Phase 9)**: Depends on US1-4 (enforces limits and locking)
- **Testing (Phase 10)**: Depends on all implementation phases
- **Polish (Phase 11)**: Depends on all implementation and testing

### User Story Dependencies

- **User Story 1 (P1 - MVP)**: Independent after Foundational
- **User Story 2 (P2)**: Depends on US1 (modifies same data structures)
- **User Story 3 (P3)**: Depends on US1 (displays status from sync queue)
- **User Story 4 (P4)**: Depends on US1 (handles conflicts in synced expenses)

**Recommended Execution**: Sequential by priority (US1 → US2 → US3 → US4) for single developer

### Within Each User Story

1. Data layer (models, datasources) - can parallelize models with [P] tags
2. Domain layer (services) - depends on data layer
3. Repository integration - depends on domain layer
4. Presentation layer (providers, widgets) - can parallelize widgets with [P] tags
5. Tests - can parallelize all tests with [P] tags

### Parallel Opportunities

**Setup Phase**: All T003-T014 can run in parallel (different directories)

**Foundational Phase**:
- T016-T018 (Drift tables) can run in parallel
- T030-T033 (Supabase RPC functions) can run in parallel

**User Story 1**:
- T036-T039 (models and entities) can run in parallel
- T057-T059 (providers) can run in parallel
- T065-T067 (unit tests) can run in parallel

**User Story 2**:
- T078-T079 (unit tests) can run in parallel

**User Story 3**:
- T081-T082 (widgets) can run in parallel
- T091-T092 (widget tests) can run in parallel

**User Story 4**:
- T094 (model) independent
- T106-T107 (unit tests) can run in parallel

**Testing Phase**:
- T145-T149 (unit tests) can run in parallel
- T154-T157 (performance tests) can run in parallel
- T158-T160 (security tests) can run in parallel

**Polish Phase**:
- T161-T162, T164-T167 can run in parallel

---

## Parallel Example: User Story 1 Data Layer

```bash
# Launch all models/entities for User Story 1 together:
Task T036: "Create OfflineExpenseModel in lib/features/offline/data/models/offline_expense_model.dart"
Task T037: "Create SyncQueueItemModel in lib/features/offline/data/models/sync_queue_item_model.dart"
Task T038: "Create OfflineExpenseEntity in lib/features/offline/domain/entities/offline_expense_entity.dart"
Task T039: "Create SyncResultEntity in lib/features/offline/domain/entities/sync_result_entity.dart"
```

## Parallel Example: User Story 1 Providers

```bash
# Launch all providers for User Story 1 together:
Task T057: "Create OfflineStatusProvider in lib/features/offline/presentation/providers/offline_status_provider.dart"
Task T058: "Create SyncQueueProvider in lib/features/offline/presentation/providers/sync_queue_provider.dart"
Task T059: "Create PendingCountProvider in lib/features/offline/presentation/providers/pending_count_provider.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) - RECOMMENDED

1. Complete Phase 1: Setup (T001-T014)
2. Complete Phase 2: Foundational (T015-T035) - **CRITICAL GATE**
3. Complete Phase 3: User Story 1 (T036-T068)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Can create expense offline? ✓
   - Saved with "pending" status? ✓
   - Auto-syncs when online? ✓
   - Syncs within 30 seconds? ✓ (SC-002)
5. Deploy/demo if ready - **First user value delivered!**

### Incremental Delivery

1. **Foundation** (Phases 1-2) → Database ready, API ready
2. **US1** (Phase 3) → Test independently → **Deploy** (MVP!)
   - Value: Users never lose data due to network issues
3. **US2** (Phase 4) → Test independently → **Deploy**
   - Value: Users can fix mistakes before sync
4. **US3** (Phase 5) → Test independently → **Deploy**
   - Value: Users understand sync status
5. **US4** (Phase 6) → Test independently → **Deploy**
   - Value: Multi-device conflicts handled
6. **Images** (Phase 7) → **Deploy**
7. **Background Sync** (Phase 8) → **Deploy**
8. **Edge Cases** (Phase 9) → **Deploy**
9. **Testing & Polish** (Phases 10-11) → **Final Release**

Each phase adds value without breaking previous functionality.

### Parallel Team Strategy

With 2-3 developers:

1. **Together**: Complete Setup + Foundational (Phases 1-2)
2. **Once Foundational done**:
   - Developer A: User Story 1 (Phase 3)
   - Developer B: Supabase RPC testing and refinement
3. **After US1 complete**:
   - Developer A: User Story 2 (Phase 4)
   - Developer B: User Story 3 (Phase 5)
4. **After US2/US3 complete**:
   - Developer A: User Story 4 (Phase 6)
   - Developer B: Images (Phase 7)
5. **After all stories**: Background Sync (Phase 8) together
6. **Final**: Testing & Polish (Phases 10-11) together

---

## Task Count Summary

- **Phase 1 (Setup)**: 14 tasks
- **Phase 2 (Foundational)**: 21 tasks
- **Phase 3 (US1 - MVP)**: 33 tasks
- **Phase 4 (US2)**: 12 tasks
- **Phase 5 (US3)**: 13 tasks
- **Phase 6 (US4)**: 15 tasks
- **Phase 7 (Images)**: 11 tasks
- **Phase 8 (Background Sync)**: 10 tasks
- **Phase 9 (Edge Cases)**: 15 tasks
- **Phase 10 (Testing)**: 16 tasks
- **Phase 11 (Polish)**: 12 tasks

**Total**: 172 tasks

**Parallelizable tasks**: 47 tasks (27% can run in parallel)

**MVP scope** (Phases 1-3): 68 tasks (40% of total)

---

## Success Criteria Validation

Each user story validates specific success criteria:

- **US1**: SC-001 (no data loss), SC-002 (30s sync), SC-006 (responsive), SC-012 (storage)
- **US2**: SC-007 (edit before sync)
- **US3**: SC-004 (distinguish status < 2s), SC-010 (error messages < 5s)
- **US4**: SC-009 (conflicts resolved without data loss)
- **Images**: SC-008 (5MB images sync with compression)
- **Background Sync**: SC-011 (battery < 3%)
- **Edge Cases**: SC-014 (sync lock < 2s), SC-015 (responsive with 500 expenses)
- **Testing Phase**: All SC-* criteria validated

---

## Notes

- [P] tasks = different files/locations, no dependencies - safe to parallelize
- [Story] label maps task to specific user story for traceability
- Each user story builds on Foundational but should be independently testable
- Run `flutter pub run build_runner build` after Drift table changes (T023, and any table modifications)
- Deploy Supabase migration (T035) before testing sync operations
- Test on physical devices for battery and performance validation (not simulators)
- Background sync on iOS is unpredictable - foreground sync on app resume is primary mechanism
- Commit after each completed user story phase for clean rollback points
- Stop at any checkpoint to validate story independently before proceeding
- Avoid: same-file edit conflicts, cross-story dependencies that break independence
