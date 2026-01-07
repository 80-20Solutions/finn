# Implementation Plan: Offline Expense Management with Auto-Sync

**Branch**: `010-offline-expense-sync` | **Date**: 2026-01-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-offline-expense-sync/spec.md`

## Summary

Implement offline-first expense management for the family expense tracker app, allowing users to create, edit, and delete expenses without internet connectivity. Expenses are stored in an encrypted local Drift database and automatically synced to Supabase when network returns. The system supports batch synchronization (10 items per batch), exponential backoff retry (30s, 2min, 5min), conflict resolution (server wins strategy), and multi-user device isolation. Maximum 500 pending expenses per user with background sync on Android (WorkManager) and iOS (Background Fetch).

**Primary Technical Approach**:
- **Local Storage**: Drift ORM with SQLCipher encryption (AES-256)
- **Connectivity**: connectivity_plus for real-time network monitoring
- **Sync Queue**: Drift-based persistent queue with retry logic
- **Batch API**: Supabase RPC functions for efficient batch operations
- **Background Sync**: WorkManager (Android) + Background Fetch (iOS)
- **Conflict Resolution**: Timestamp comparison with server wins policy

---

## Technical Context

**Language/Version**: Dart 3.0+ / Flutter 3.0+
**Primary Dependencies**:
- Drift ^2.14.0 (SQLite ORM with encryption)
- Riverpod ^2.4.0 (state management)
- Supabase Flutter ^2.0.0 (backend)
- connectivity_plus ^6.1.0 (network monitoring)
- workmanager ^0.5.2 (background sync Android)
- SQLCipher ^0.6.1 (database encryption)

**Storage**:
- Local: Drift (SQLite) with SQLCipher encryption
- Remote: Supabase (Postgres) for synced expenses
- Images: Supabase Storage for receipt images

**Testing**:
- flutter_test (unit tests)
- integration_test (E2E tests)
- mockito ^5.4.0 (mocking)

**Target Platform**:
- iOS 13.0+
- Android API 24+ (Android 7.0+)
- Mobile-only (no web/desktop)

**Project Type**: Mobile (Flutter) with existing Clean Architecture (feature-based structure)

**Performance Goals**:
- Single expense sync: < 30 seconds (SC-002)
- Batch 50 expenses sync: < 2 minutes (SC-003)
- App responsiveness with 500 pending expenses: < 500ms operations (SC-015)
- Database queries: < 50ms for user+status filtered queries
- Encryption overhead: < 100ms per operation (C-009)

**Constraints**:
- Battery usage: < 5% drain per hour of offline use (C-004)
- Storage: < 50MB for 500 expenses with compressed images (SC-012)
- Sync lock duration: < 2 seconds per expense (SC-014)
- No sensitive data in logs (C-010)
- Must work on devices with minimum 50MB available storage (C-005)

**Scale/Scope**:
- Max 500 pending offline expenses per user (FR-026)
- Batch size: 10 expenses per sync batch (FR-016)
- Retry attempts: 3 max with exponential backoff (FR-008)
- Expected user base: Family groups (2-6 members per family)
- Image size limit: 10MB per receipt image (FR-013)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: No project constitution file found (`.specify/memory/constitution.md` is template-only). Proceeding with Flutter/Supabase best practices.

### Assumed Development Principles

#### Clean Architecture Adherence
✅ **PASS**: Feature follows existing Clean Architecture pattern:
- **Data Layer**: Drift tables, datasources, repositories
- **Domain Layer**: Entities, sync queue processor, conflict resolver
- **Presentation Layer**: Riverpod providers, UI widgets

#### Security-First Approach
✅ **PASS**: Security requirements met:
- AES-256 encryption for offline data (FR-021)
- Encryption keys in secure storage (iOS Keychain, Android Keystore)
- User isolation via user_id scoping (FR-022)
- No sensitive data in logs (C-010)
- RLS policies on Supabase enforced

#### Test Coverage
⚠️ **WARNING**: TDD enforcement unclear without constitution. Recommend:
- Unit tests for all sync logic
- Integration tests for E2E offline→online flows
- Performance tests for SC-* criteria
- Security audit for encryption

#### Simplicity & YAGNI
✅ **PASS**: Minimal complexity justified:
- No over-engineering: Uses existing Drift (already in dependencies)
- Server wins conflict resolution: Simplest strategy
- Background sync: Platform best practices, not custom solutions
- No premature abstractions: Direct repository pattern

### Re-evaluation After Phase 1

✅ **PASS**: Design artifacts validated:
- **research.md**: All technology choices justified with alternatives
- **data-model.md**: Four tables, normalized schema, no redundancy
- **contracts/*.md**: Minimal backend changes (RPC functions only)
- **quickstart.md**: 3-5 day implementation estimate realistic

**Proceed to Phase 2 (tasks generation)**: ✅ Approved

---

## Project Structure

### Documentation (this feature)

```text
specs/010-offline-expense-sync/
├── spec.md                        # Feature specification (created by /speckit.specify)
├── plan.md                        # This file (created by /speckit.plan)
├── research.md                    # Phase 0 research output
├── data-model.md                  # Drift database schema
├── quickstart.md                  # Developer implementation guide
├── contracts/
│   └── batch-sync-api.md          # Supabase RPC function contracts
├── checklists/
│   └── requirements.md            # Spec quality checklist
└── tasks.md                       # NOT YET CREATED (use /speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── app/                           # Existing: App initialization
├── core/                          # Existing: Shared utilities
│   ├── config/
│   ├── errors/                    # ✅ Already has Failure/Exception classes
│   └── utils/
├── shared/                        # Existing: Cross-feature services
│   ├── services/
│   │   ├── secure_storage_service.dart      # ✅ Existing
│   │   ├── supabase_client.dart             # ✅ Existing
│   │   └── connectivity_service.dart        # ➕ NEW (to be created)
│   └── widgets/
│       └── offline_banner.dart              # ➕ NEW
├── features/
│   ├── expenses/                  # ✅ Existing feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── expense_remote_datasource.dart  # ✅ Existing
│   │   │   │   └── expense_local_datasource.dart   # ➕ MODIFY (add offline fallback)
│   │   │   ├── models/
│   │   │   │   └── expense_model.dart              # ✅ Existing
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart    # ➕ MODIFY (add offline logic)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── expense_entity.dart             # ✅ Existing
│   │   │   └── repositories/
│   │   │       └── expense_repository.dart         # ✅ Existing interface
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── expense_provider.dart           # ➕ MODIFY (watch connectivity)
│   │       └── widgets/
│   │           └── expense_list_item.dart          # ➕ MODIFY (sync status indicator)
│   └── offline/                   # ➕ NEW FEATURE
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── offline_expense_local_datasource.dart
│       │   │   └── offline_image_local_datasource.dart
│       │   ├── models/
│       │   │   ├── offline_expense_model.dart
│       │   │   ├── sync_queue_item_model.dart
│       │   │   └── sync_conflict_model.dart
│       │   └── local/
│       │       ├── offline_database.dart          # Drift database
│       │       └── offline_database.g.dart        # Generated
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── offline_expense_entity.dart
│       │   │   └── sync_result_entity.dart
│       │   └── services/
│       │       ├── sync_queue_processor.dart      # Core sync logic
│       │       ├── conflict_resolver.dart         # Conflict handling
│       │       └── batch_sync_service.dart        # Batch API calls
│       ├── presentation/
│       │   ├── providers/
│       │   │   ├── offline_status_provider.dart
│       │   │   ├── sync_queue_provider.dart
│       │   │   └── pending_count_provider.dart
│       │   └── widgets/
│       │       ├── sync_status_indicator.dart
│       │       └── conflict_resolution_dialog.dart
│       └── infrastructure/
│           └── background_sync_manager.dart       # WorkManager setup
└── test/
    ├── features/
    │   ├── expenses/
    │   │   └── data/repositories/
    │   │       └── expense_repository_impl_test.dart  # ➕ ADD offline tests
    │   └── offline/
    │       ├── data/datasources/
    │       │   └── offline_expense_local_datasource_test.dart
    │       └── domain/services/
    │           └── sync_queue_processor_test.dart
    └── integration_test/
        └── offline_sync_test.dart                 # ➕ NEW E2E test

supabase/migrations/
└── 004_batch_sync_rpc.sql                         # ➕ NEW (Supabase RPC functions)

android/app/build.gradle                           # ➕ MODIFY (add WorkManager)
ios/Runner/Info.plist                              # ➕ MODIFY (add Background Modes)
```

**Structure Decision**:
The project follows Flutter's feature-first Clean Architecture with existing features (auth, expenses, dashboard, etc.). The offline sync functionality is implemented as:

1. **New `offline/` feature** for sync-specific logic (queue, conflicts, background tasks)
2. **Modifications to `expenses/` feature** to add offline fallback in repository layer
3. **New shared services** (`connectivity_service`) for cross-feature network monitoring
4. **Supabase migration** for batch RPC functions (minimal backend changes)

This structure maintains separation of concerns while integrating seamlessly with existing expense management flow.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. Complexity is justified and minimal:
- Background sync uses platform best practices (WorkManager/Background Fetch)
- Batch API reduces network calls (performance optimization)
- Encryption is mandatory security requirement (FR-021)
- Sync queue persistence prevents data loss (FR-003)

---

## Phase 0: Research & Technical Decisions

**Status**: ✅ Complete

**Artifacts**: [research.md](./research.md)

### Key Decisions Summary

| Area | Technology | Rationale |
|------|------------|-----------|
| **Encrypted Storage** | Drift + SQLCipher + flutter_secure_storage | Industry-standard AES-256, minimal overhead (< 15%), cross-platform |
| **Connectivity** | connectivity_plus | Real-time stream, battery-efficient, 5000+ pub points |
| **Sync Queue** | Drift-based persistent queue | ACID transactions, ordering, retry logic, user isolation |
| **Conflict Resolution** | Server wins with timestamp comparison | Data integrity, simplicity, explicit user notification |
| **Background Sync** | workmanager (Android) + Background Fetch (iOS) | Platform best practices, respects battery optimization |
| **UUID Generation** | uuid v4 | Collision-free (2^122 space), Postgres compatible |

### Research Deliverables

1. ✅ **Drift Encryption Pattern**: SQLCipher integration with secure key management
2. ✅ **Connectivity Monitoring**: Debounced stream with actual internet verification
3. ✅ **Sync Queue Architecture**: Drift table schema with exponential backoff logic
4. ✅ **Conflict Detection**: Timestamp comparison strategy with user notification
5. ✅ **User Session Isolation**: user_id foreign key scoping pattern
6. ✅ **Background Sync Configuration**: WorkManager Android setup, iOS Background Modes
7. ✅ **UUID Best Practices**: Client-side v4 generation for offline ID assignment

**All Technical Unknowns Resolved**: ✅ No "NEEDS CLARIFICATION" items remaining

---

## Phase 1: Design & Contracts

**Status**: ✅ Complete

**Artifacts**:
- [data-model.md](./data-model.md)
- [contracts/batch-sync-api.md](./contracts/batch-sync-api.md)
- [quickstart.md](./quickstart.md)

### Data Model Summary

**New Drift Tables**:
1. **OfflineExpenses**: Stores expenses created/modified offline (20 columns, user-isolated)
2. **SyncQueueItems**: Manages ordered sync operations (12 columns, FIFO queue)
3. **OfflineExpenseImages**: Stores compressed receipt images (11 columns, blob storage)
4. **SyncConflicts** (Optional): Tracks conflicts for user review (9 columns)

**Indexes Created**:
- `offline_expenses_user_status_idx` (userId, syncStatus)
- `offline_expenses_user_created_idx` (userId, localCreatedAt)
- `sync_queue_user_status_idx` (userId, syncStatus, nextRetryAt)
- `sync_queue_created_idx` (createdAt)

**Storage Estimate**:
- Offline expenses: ~250KB for 500 expenses (without images)
- Sync queue: ~150KB for 500 items
- Images: ~500MB (but deleted post-sync) → **Total: ~50MB within SC-012 target**

### API Contracts Summary

**New Supabase RPC Functions**:
1. `batch_create_expenses(p_expenses JSONB)` → Batch create up to 10 expenses
2. `batch_update_expenses(p_updates JSONB)` → Batch update with conflict detection
3. `batch_delete_expenses(p_expense_ids UUID[])` → Batch delete
4. `get_expenses_by_ids(p_expense_ids UUID[])` → Fetch for conflict resolution

**Performance Benefits**:
- Reduces 500 single-item requests → 50 batch requests (10x fewer network calls)
- Single sync batch: ~30s for 10 expenses (meets SC-002)
- Within Supabase rate limits: 60 req/min → 50 batches = safe

### Quickstart Guide Summary

**5-Day Implementation Plan**:
- Day 1: Setup & Data Layer (Drift tables, encryption, datasources)
- Day 2: Connectivity & Sync Service (network monitoring, queue processor)
- Day 3: Repository & UI Integration (offline fallback, sync indicators)
- Day 4: Background Sync & Conflicts (WorkManager, conflict resolution)
- Day 5: Testing & Polish (unit tests, integration tests, edge cases)

**Testing Checklist**: 21 functional tests, 8 performance tests, 4 security tests

---

## Phase 2: Task Decomposition

**Status**: ⏭️ Next (use `/speckit.tasks` command)

**Prerequisites Met**:
- ✅ Research complete (all technology choices validated)
- ✅ Data model finalized (Drift schema defined)
- ✅ API contracts defined (Supabase RPC functions specified)
- ✅ Quickstart guide created (implementation roadmap documented)
- ✅ Agent context updated (new dependencies added to CLAUDE.md)

**Expected Output**: `tasks.md` with dependency-ordered task list

**Estimated Task Count**: 35-45 tasks across:
- Setup (dependencies, database migration)
- Data layer (Drift tables, datasources, repositories)
- Domain layer (sync queue processor, conflict resolver)
- Presentation layer (UI indicators, providers)
- Infrastructure (background sync, WorkManager)
- Backend (Supabase RPC functions)
- Testing (unit, integration, E2E)

---

## Risk Assessment & Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| **Battery drain exceeds 5%/hour** | Medium | High | Profile early on low-end devices; reduce background sync frequency if needed; add user setting for sync frequency |
| **Encryption overhead > 100ms** | Low | Medium | Benchmark on low-end Android devices (e.g., Samsung A10); optimize Drift queries with indexes |
| **Sync queue deadlock** | Low | High | Use Drift transactions correctly; add 30s timeout on sync operations; implement deadlock detection |
| **iOS background fetch unreliable** | High | Low | Expected behavior; foreground sync on app resume is primary mechanism; background is bonus |
| **500-expense limit too restrictive** | Low | Low | Monitor user behavior via analytics; can increase limit to 1000 if storage allows |
| **Conflict resolution UX confusion** | Medium | Medium | User testing before release; clear messaging in notifications; consider conflict log screen |
| **Supabase rate limit hit** | Low | Medium | Batch API reduces calls 10x; monitor usage; implement client-side throttling if needed |
| **SQLCipher compatibility issues** | Low | High | Test on wide range of devices (Android 7-14, iOS 13-17); have fallback migration plan |

---

## Success Metrics (Post-Release Monitoring)

### Performance Metrics (From Success Criteria)
- **SC-002**: Sync time for single expense < 30 seconds
- **SC-003**: Sync time for 50 expenses < 2 minutes
- **SC-005**: Sync success rate ≥ 99.5%
- **SC-006**: No UI freezing (< 500ms responsiveness)
- **SC-011**: Battery drain < 3% for syncing 50 expenses
- **SC-012**: Database size < 50MB for 500 expenses
- **SC-014**: Sync lock duration < 2 seconds (95th percentile)
- **SC-015**: App responsive with 500 pending expenses

### User Experience Metrics
- % of users creating expenses offline
- Average pending expense count per user
- Conflict resolution rate
- User satisfaction with offline feature (survey)

### Technical Health Metrics
- Sync failure reasons (breakdown by error type)
- Background sync success rate (Android vs iOS)
- Encryption key recovery failures
- Storage warnings triggered

---

## Dependencies & Blockers

### External Dependencies
- ✅ Supabase access for RPC function creation (available)
- ✅ Google Play Services (WorkManager) - included in Android SDK
- ✅ iOS Background Modes entitlement - standard capability

### Internal Dependencies
- ✅ Existing expense repository pattern (already implemented)
- ✅ Auth service with getCurrentUserId() (already implemented)
- ✅ Supabase client singleton (already implemented)
- ✅ Image compression service (flutter_image_compress already in pubspec)

### No Blockers Identified

---

## Rollout Strategy

### Phase 1: Internal Testing (Week 1-2)
- Deploy to internal test group (2-3 family groups)
- Monitor crash reports for encryption errors
- Validate battery usage metrics
- Test conflict resolution UX

### Phase 2: Beta Release (Week 3-4)
- Deploy to beta testers via TestFlight/Play Internal Testing
- Monitor sync success rate
- Gather user feedback on offline banner UX
- A/B test: 500 vs 1000 expense limit

### Phase 3: Production Rollout (Week 5+)
- Staged rollout: 10% → 50% → 100% over 1 week
- Monitor Supabase API quotas
- Track adoption rate of offline feature
- Prepare hotfix plan for critical issues

---

## Future Enhancements (Out of Scope for 010)

From spec.md "Out of Scope" section:
- **OS-002**: Offline support for dashboard, reports, budget management
- **OS-004**: Wifi-only sync preferences
- **OS-005**: Manual export/import of offline expenses
- **OS-006**: Enhanced offline analytics caching
- **OS-007**: Versioning/history tracking of offline edits
- **OS-008**: Custom conflict resolution strategies (e.g., manual merge UI)

**Recommendation**: Evaluate OS-002 (dashboard offline support) in Q2 2026 based on user demand.

---

## References

- **Spec**: [spec.md](./spec.md) - Feature requirements and user stories
- **Research**: [research.md](./research.md) - Technical decisions and alternatives
- **Data Model**: [data-model.md](./data-model.md) - Drift database schema
- **API Contracts**: [contracts/batch-sync-api.md](./contracts/batch-sync-api.md) - Supabase RPC functions
- **Quickstart**: [quickstart.md](./quickstart.md) - Developer implementation guide

---

## Approval & Next Steps

**Plan Status**: ✅ Approved for task generation

**Next Command**: `/speckit.tasks` - Generate dependency-ordered task list

**Estimated Implementation Time**:
- Core feature: 3-5 days (experienced Flutter developer)
- Testing & polish: 2 days
- Total: 5-7 days (1 sprint)

**Ready for**:
1. Task decomposition (`/speckit.tasks`)
2. Implementation (`/speckit.implement`)

---

**Plan Version**: 1.0
**Last Updated**: 2026-01-07
**Author**: Spec workflow automation
**Reviewed By**: Pending review after `/speckit.tasks`
