# Tasks: Metodi di Pagamento per Spese

**Input**: Design documents from `/specs/011-payment-methods/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not requested in specification - test tasks are omitted

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- Mobile Flutter app structure: `lib/features/`, `supabase/migrations/`
- Paths reference Flutter project structure from plan.md

---

## Phase 1: Setup (Database & Configuration)

**Purpose**: Database schema creation and default constants setup

- [X] T001 Create payment_methods table migration in `supabase/migrations/0XX_create_payment_methods_table.sql`
- [X] T002 Create expenses table modification migration in `supabase/migrations/0XX_add_payment_method_to_expenses.sql`
- [X] T003 [P] Create default payment methods constants file in `lib/core/config/default_payment_methods.dart`
- [X] T004 Test migrations locally with `supabase db push` and verify table creation
- [X] T005 Verify seed data: Run SQL to confirm 4 default payment methods exist

---

## Phase 2: Foundational (Domain & Data Layer)

**Purpose**: Core entities, models, and repository infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Domain Layer

- [X] T006 [P] Create PaymentMethodEntity in `lib/features/payment_methods/domain/entities/payment_method_entity.dart`
- [X] T007 [P] Create PaymentMethodRepository interface in `lib/features/payment_methods/domain/repositories/payment_method_repository.dart`
- [X] T008 Modify ExpenseEntity to add paymentMethodId and paymentMethodName fields in `lib/features/expenses/domain/entities/expense_entity.dart`

### Data Layer

- [X] T009 [P] Create PaymentMethodModel in `lib/features/payment_methods/data/models/payment_method_model.dart`
- [X] T010 [P] Create PaymentMethodRemoteDataSource in `lib/features/payment_methods/data/datasources/payment_method_remote_datasource.dart`
- [X] T011 Create PaymentMethodRepositoryImpl in `lib/features/payment_methods/data/repositories/payment_method_repository_impl.dart`
- [X] T012 Modify ExpenseModel to add paymentMethodId and paymentMethodName serialization in `lib/features/expenses/data/models/expense_model.dart`

### Presentation Infrastructure

- [X] T013 [P] Create PaymentMethodState class in `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`
- [X] T014 Create PaymentMethodNotifier in `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`
- [X] T015 Create payment method repository provider and state provider in `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`
- [X] T016 [P] Create PaymentMethodActions class in `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Registrazione Spesa con Metodo di Pagamento (Priority: P1) 🎯 MVP

**Goal**: Users can create expenses with payment method selection, view payment method in expense list and details

**Independent Test**: Create new expense → Select "Carta di Credito" → Save → Verify payment method shows in list and detail screens

### Implementation for User Story 1

- [X] T017 [P] [US1] Create PaymentMethodSelector widget in `lib/features/expenses/presentation/widgets/payment_method_selector.dart`
- [X] T018 [US1] Modify ManualExpenseScreen to add payment method selector in `lib/features/expenses/presentation/screens/manual_expense_screen.dart`
- [X] T019 [US1] Update expense creation logic to include paymentMethodId (default to "Contanti") in `lib/features/expenses/presentation/screens/manual_expense_screen.dart`
- [X] T020 [US1] Modify ExpenseListItem to display payment method name in `lib/features/expenses/presentation/widgets/expense_list_item.dart`
- [X] T021 [US1] Modify ExpenseDetailScreen to display payment method in `lib/features/expenses/presentation/screens/expense_detail_screen.dart`
- [ ] T022 [US1] Verify payment method selector loads default and custom methods correctly
- [ ] T023 [US1] Test expense creation with different payment methods (Contanti, Carta di Credito, Bonifico, Satispay)

**Checkpoint**: At this point, User Story 1 should be fully functional - users can create expenses with payment methods and view them

---

## Phase 4: User Story 2 - Migrazione Spese Esistenti (Priority: P2)

**Goal**: All existing expenses automatically get "Contanti" as payment method, ensuring data consistency

**Independent Test**: Query database before and after migration → Verify all expenses have payment_method_id → Verify none are NULL

### Implementation for User Story 2

- [ ] T024 [US2] Verify migration script correctness in `supabase/migrations/0XX_add_payment_method_to_expenses.sql`
- [ ] T025 [US2] Create test migration on production database copy to validate backfill logic
- [ ] T026 [US2] Run migration on staging/test environment and verify results
- [ ] T027 [US2] Execute SQL query to count expenses with NULL payment_method_id (should be 0)
- [ ] T028 [US2] Verify existing expenses display "Contanti" in app UI
- [ ] T029 [US2] Test editing a migrated expense - verify payment method can be changed

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - new expenses use selected methods, old expenses show "Contanti"

---

## Phase 5: User Story 3 - Gestione Metodi di Pagamento Custom (Priority: P3)

**Goal**: Users can add, edit, and delete custom payment methods from settings that appear in expense forms

**Independent Test**: Go to Settings → Add custom method "PayPal" → Create expense → Verify "PayPal" appears in payment method selector

### Implementation for User Story 3

- [ ] T030 [P] [US3] Create PaymentMethodManagementScreen in `lib/features/payment_methods/presentation/screens/payment_method_management_screen.dart`
- [ ] T031 [P] [US3] Create PaymentMethodFormDialog widget in `lib/features/payment_methods/presentation/widgets/payment_method_form_dialog.dart`
- [ ] T032 [P] [US3] Create PaymentMethodListItem widget in `lib/features/payment_methods/presentation/widgets/payment_method_list_item.dart`
- [ ] T033 [US3] Implement createPaymentMethod action with validation in `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`
- [ ] T034 [US3] Implement updatePaymentMethod action with validation in `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`
- [ ] T035 [US3] Implement deletePaymentMethod action with usage check in `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`
- [ ] T036 [US3] Implement paymentMethodNameExists validation check in `lib/features/payment_methods/presentation/providers/payment_method_actions_provider.dart`
- [ ] T037 [US3] Add route to payment method management screen in `lib/app/routes.dart`
- [ ] T038 [US3] Add "Metodi di Pagamento" menu item to SettingsScreen in `lib/features/auth/presentation/screens/settings_screen.dart`
- [ ] T039 [US3] Test creating custom payment method and verify it appears in expense form selector
- [ ] T040 [US3] Test editing custom payment method name
- [ ] T041 [US3] Test deleting unused custom payment method
- [ ] T042 [US3] Test delete protection: Attempt to delete method in use → Verify error message with count

**Checkpoint**: All core user stories (US1, US2, US3) should now be independently functional

---

## Phase 6: User Story 4 - Modifica Metodo di Pagamento (Priority: P3)

**Goal**: Users can edit existing expenses and change their payment method

**Independent Test**: Open expense detail → Tap Edit → Change payment method → Save → Verify new method persists

### Implementation for User Story 4

- [ ] T043 [US4] Modify EditExpenseScreen to add payment method selector in `lib/features/expenses/presentation/screens/edit_expense_screen.dart`
- [ ] T044 [US4] Initialize payment method selector with expense's current payment method in `lib/features/expenses/presentation/screens/edit_expense_screen.dart`
- [ ] T045 [US4] Update expense update logic to include new paymentMethodId in `lib/features/expenses/presentation/screens/edit_expense_screen.dart`
- [ ] T046 [US4] Test editing expense without changing payment method → Verify method remains same
- [ ] T047 [US4] Test editing expense and changing payment method → Verify new method saves and displays

**Checkpoint**: All user stories (US1-US4) should now be complete and independently testable

---

## Phase 7: Offline Support & Real-Time Sync

**Purpose**: Enable offline functionality and real-time synchronization across devices

- [ ] T048 [P] Create Drift table definition for payment methods in `lib/features/offline/data/database/app_database.dart`
- [ ] T049 Run Drift code generator with `flutter pub run build_runner build`
- [ ] T050 [P] Create PaymentMethodCacheDataSource in `lib/features/payment_methods/data/datasources/payment_method_cache_datasource.dart`
- [ ] T051 Update PaymentMethodRepositoryImpl to integrate cache (remote-first writes, cache-first reads) in `lib/features/payment_methods/data/repositories/payment_method_repository_impl.dart`
- [ ] T052 Implement real-time subscription in PaymentMethodNotifier for Supabase Realtime changes in `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`
- [ ] T053 Test offline mode: Create expense offline → Go online → Verify sync
- [ ] T054 Test real-time sync: Add custom method on device A → Verify appears on device B

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T055 [P] Add error handling for all payment method operations (network errors, validation errors)
- [ ] T056 [P] Add loading states for payment method management screen
- [ ] T057 [P] Improve UI/UX for payment method selector (grouping default vs custom)
- [ ] T058 Verify payment method name denormalization in expenses table updates correctly
- [ ] T059 [P] Add expense count display to payment method list items in management screen
- [ ] T060 Code review and refactoring for consistency with category management pattern
- [ ] T061 [P] Update README/documentation with payment methods feature
- [ ] T062 Run all integration scenarios from quickstart.md
- [ ] T063 Performance test: Verify payment method queries scale with large datasets

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1 → US2 → US3 → US4)
- **Offline Support (Phase 7)**: Can start after US1 is complete (extends existing functionality)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (US1 - P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (US2 - P2)**: Can start after Foundational (Phase 2) - Independent of other stories (database-only)
- **User Story 3 (US3 - P3)**: Can start after Foundational (Phase 2) - Independent of other stories
- **User Story 4 (US4 - P3)**: Can start after Foundational (Phase 2) AND US1 (needs ExpenseEditScreen) - Minor dependency

### Within Each User Story

- Models before services
- Services before screens/widgets
- Core implementation before edge cases
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks (Phase 1) can run together
- Within Foundational (Phase 2):
  - T006, T007, T009, T010, T013, T016 can run in parallel (different files)
- Once Foundational completes:
  - US1, US2, US3 can start in parallel by different developers
  - US4 requires US1's EditExpenseScreen to exist first
- Within US1: T017 can run parallel with others (different file)
- Within US3: T030, T031, T032 can run in parallel (different files)
- Phase 7 (Offline): T048, T050 can run in parallel
- Phase 8 (Polish): T055, T056, T057, T061 can run in parallel (different concerns)

---

## Parallel Example: User Story 1

```bash
# Launch screen modifications together:
Task T017: "Create PaymentMethodSelector widget in lib/features/expenses/presentation/widgets/payment_method_selector.dart"
# While that's being built, can work on:
Task T020: "Modify ExpenseListItem to display payment method name in lib/features/expenses/presentation/widgets/expense_list_item.dart"
```

---

## Parallel Example: User Story 3

```bash
# Launch all widget files together:
Task T030: "Create PaymentMethodManagementScreen in lib/features/payment_methods/presentation/screens/payment_method_management_screen.dart"
Task T031: "Create PaymentMethodFormDialog widget in lib/features/payment_methods/presentation/widgets/payment_method_form_dialog.dart"
Task T032: "Create PaymentMethodListItem widget in lib/features/payment_methods/presentation/widgets/payment_method_list_item.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T016) - CRITICAL
3. Complete Phase 3: User Story 1 (T017-T023)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Create expense with each default payment method
   - Verify payment method shows in list and detail
   - Verify default "Contanti" is pre-selected
5. Deploy/demo if ready (MVP delivers core value: expense tracking with payment methods)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy (Data migration complete)
4. Add User Story 3 → Test independently → Deploy (Custom methods available)
5. Add User Story 4 → Test independently → Deploy (Edit functionality complete)
6. Add Offline Support (Phase 7) → Test → Deploy
7. Polish (Phase 8) → Test → Final release

Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (critical path)
2. Once Foundational is done:
   - Developer A: User Story 1 (T017-T023)
   - Developer B: User Story 2 (T024-T029) - Database migration
   - Developer C: User Story 3 (T030-T042) - Custom methods
3. After US1 completes:
   - Developer D: User Story 4 (T043-T047) - Edit functionality
4. Developers integrate and test together

---

## Task Count Summary

- **Total Tasks**: 63
- **Phase 1 (Setup)**: 5 tasks
- **Phase 2 (Foundational)**: 11 tasks (BLOCKS all stories)
- **Phase 3 (US1 - P1)**: 7 tasks - MVP
- **Phase 4 (US2 - P2)**: 6 tasks - Data migration
- **Phase 5 (US3 - P3)**: 13 tasks - Custom methods
- **Phase 6 (US4 - P3)**: 5 tasks - Edit functionality
- **Phase 7 (Offline)**: 7 tasks
- **Phase 8 (Polish)**: 9 tasks

**Parallelizable Tasks**: 15 tasks marked with [P]

**MVP Scope** (Recommended first delivery):
- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundational): 11 tasks
- Phase 3 (US1): 7 tasks
- **Total MVP**: 23 tasks

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label (US1, US2, US3, US4) maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests are NOT included (not requested in specification)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Migration tasks (US2) should be tested on database copy first
- Real-time sync (Phase 7) extends functionality but isn't blocking for MVP
- Follow category management pattern for consistency throughout implementation
