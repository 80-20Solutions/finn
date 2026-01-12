# Tasks: Group Budget Setup Wizard

**Input**: Design documents from `/specs/001-group-budget-wizard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Comprehensive test coverage following TDD approach (tests written first, failing, then implementation)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter/Dart Project**: `lib/`, `test/`, `integration_test/` at repository root
- **Supabase**: `supabase/migrations/` for database migrations
- **Feature Structure**: `lib/features/budgets/wizard/` (Clean Architecture layers: data/, domain/, presentation/)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database setup, Italian localization, and shared widgets

- [x] T001 Create database migration 060 for wizard completion tracking in supabase/migrations/060_add_wizard_completion_tracking.sql
- [x] T002 [P] Add Italian localization strings to lib/core/constants/strings_it.dart for wizard UI
- [x] T003 [P] Create PercentageInputField shared widget in lib/shared/widgets/percentage_input_field.dart
- [x] T004 Initialize Hive box for wizard state cache in lib/main.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core wizard infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create wizard feature directory structure lib/features/budgets/wizard/{data,domain,presentation}/
- [x] T006 [P] Create WizardConfiguration domain entity in lib/features/budgets/wizard/domain/entities/wizard_configuration.dart
- [x] T007 [P] Create BudgetAllocation domain entity in lib/features/budgets/wizard/domain/entities/budget_allocation.dart
- [x] T008 [P] Create CategorySelection domain entity in lib/features/budgets/wizard/domain/entities/category_selection.dart
- [x] T009 [P] Create WizardStateModel data model in lib/features/budgets/wizard/data/models/wizard_state_model.dart
- [x] T010 [P] Create MemberAllocationModel data model in lib/features/budgets/wizard/data/models/member_allocation_model.dart
- [x] T011 [P] Create CategorySelectionModel data model in lib/features/budgets/wizard/data/models/category_selection_model.dart
- [x] T012 Create WizardRepository abstract interface in lib/features/budgets/wizard/domain/repositories/wizard_repository.dart
- [x] T013 Create WizardRemoteDataSource in lib/features/budgets/wizard/data/datasources/wizard_remote_datasource.dart
- [x] T014 Create WizardLocalDataSource (Hive cache) in lib/features/budgets/wizard/data/datasources/wizard_local_datasource.dart
- [x] T015 Implement WizardRepositoryImpl in lib/features/budgets/wizard/data/repositories/wizard_repository_impl.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Administrator Configures Group Budget Categories (Priority: P1) 🎯 MVP

**Goal**: Enable group administrators to complete mandatory budget configuration wizard at first access, selecting categories, setting budgets, and distributing percentage allocations across members

**Independent Test**: Login as group administrator for first time → wizard automatically launches → select categories (e.g., Cibo, Utenze, Trasporto) → set budget amounts → distribute percentages (must total 100%) → submit → configuration saved and wizard marked complete

### Tests for User Story 1 (TDD Approach - Write First)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T016 [P] [US1] Unit test for WizardConfiguration entity validation in test/features/budgets/wizard/domain/entities/wizard_configuration_test.dart
- [x] T017 [P] [US1] Unit test for percentage validation (100% sum ±0.01% tolerance) in test/features/budgets/wizard/domain/entities/wizard_configuration_test.dart
- [x] T018 [P] [US1] Unit test for GetWizardInitialData use case in test/features/budgets/wizard/domain/usecases/get_wizard_initial_data_test.dart
- [x] T019 [P] [US1] Unit test for SaveWizardConfiguration use case in test/features/budgets/wizard/domain/usecases/save_wizard_configuration_test.dart
- [x] T020 [P] [US1] Unit test for MarkWizardCompleted use case in test/features/budgets/wizard/domain/usecases/mark_wizard_completed_test.dart
- [x] T021 [P] [US1] Widget test for CategorySelectionStep in test/features/budgets/wizard/presentation/widgets/category_selection_step_test.dart
- [x] T022 [P] [US1] Widget test for BudgetAmountStep validation in test/features/budgets/wizard/presentation/widgets/budget_amount_step_test.dart
- [x] T023 [P] [US1] Widget test for MemberAllocationStep with "Dividi Equamente" button in test/features/budgets/wizard/presentation/widgets/member_allocation_step_test.dart
- [x] T024 [P] [US1] Widget test for WizardStepper navigation in test/features/budgets/wizard/presentation/widgets/wizard_stepper_test.dart
- [x] T025 [US1] Integration test for complete wizard flow in integration_test/wizard_flow_test.dart

### Implementation for User Story 1

#### Use Cases
- [x] T026 [P] [US1] Create GetWizardInitialData use case in lib/features/budgets/wizard/domain/usecases/get_wizard_initial_data.dart
- [x] T027 [P] [US1] Create SaveWizardConfiguration use case in lib/features/budgets/wizard/domain/usecases/save_wizard_configuration.dart
- [x] T028 [P] [US1] Create MarkWizardCompleted use case in lib/features/budgets/wizard/domain/usecases/mark_wizard_completed.dart

#### Riverpod Providers
- [x] T029 [P] [US1] Create WizardStateProvider in lib/features/budgets/wizard/presentation/providers/wizard_state_provider.dart
- [x] T030 [P] [US1] Create CategorySelectionProvider in lib/features/budgets/wizard/presentation/providers/category_selection_provider.dart
- [x] T031 [P] [US1] Create AllocationProvider with percentage validation in lib/features/budgets/wizard/presentation/providers/allocation_provider.dart

#### Wizard Step Widgets
- [x] T032 [P] [US1] Create WizardStepper widget in lib/features/budgets/wizard/presentation/widgets/wizard_stepper.dart
- [x] T033 [P] [US1] Create CategorySelectionStep widget (Step 1) in lib/features/budgets/wizard/presentation/widgets/category_selection_step.dart
- [x] T034 [P] [US1] Create BudgetAmountStep widget (Step 2) in lib/features/budgets/wizard/presentation/widgets/budget_amount_step.dart
- [x] T035 [P] [US1] Create MemberAllocationStep widget (Step 3) in lib/features/budgets/wizard/presentation/widgets/member_allocation_step.dart
- [x] T036 [P] [US1] Create WizardSummaryStep widget (Step 4 - review) in lib/features/budgets/wizard/presentation/widgets/wizard_summary_step.dart

#### Screen & Router Integration
- [x] T037 [US1] Create BudgetWizardScreen container in lib/features/budgets/wizard/presentation/screens/budget_wizard_screen.dart
- [x] T038 [US1] Add wizard route to AppRouter in lib/app/router/app_router.dart
- [x] T039 [US1] Implement router guard logic (check budget_wizard_completed flag) in lib/app/router/app_router.dart
- [x] T040 [US1] Add wizard re-trigger functionality from group settings menu

#### Supabase RPC Functions (Backend)
- [x] T041 [US1] Create get_wizard_initial_data RPC function in Supabase dashboard or migration
- [x] T042 [US1] Create save_wizard_configuration RPC function (atomic transaction) in Supabase dashboard or migration
- [x] T043 [US1] Verify RLS policies allow admin-only wizard operations

**Checkpoint**: At this point, User Story 1 should be fully functional - admin can complete wizard and configuration is persisted

---

## Phase 4: User Story 2 - Member Views Group Budget in Personal Dashboard (Priority: P2)

**Goal**: Enable group members to view their allocated group spending in a hierarchical "Spesa Gruppo" parent category with expandable sub-categories showing per-category breakdowns

**Independent Test**: After admin completes wizard → login as group member → navigate to personal budget view → verify "Spesa Gruppo" parent category shows total allocated/spent → expand to see sub-categories (Cibo, Utenze, etc.) → verify read-only group status displayed

### Tests for User Story 2 (TDD Approach - Write First)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T044 [P] [US2] Unit test for GetGroupSpendingBreakdown use case in test/features/budgets/personal/domain/usecases/get_group_spending_breakdown_test.dart
- [x] T045 [P] [US2] Widget test for GroupSpendingCategory expandable widget in test/features/budgets/personal/presentation/widgets/group_spending_category_test.dart
- [x] T046 [P] [US2] Widget test for GroupSubCategoryItem read-only display in test/features/budgets/personal/presentation/widgets/group_sub_category_item_test.dart
- [x] T047 [US2] Integration test for member budget view with hierarchical categories in integration_test/member_budget_view_test.dart

### Implementation for User Story 2

#### Use Cases & Models
- [x] T048 [US2] Create GetGroupSpendingBreakdown use case in lib/features/budgets/personal/domain/usecases/get_group_spending_breakdown.dart
- [x] T049 [P] [US2] Create GroupSpendingBreakdown model in lib/features/budgets/personal/data/models/group_spending_breakdown_model.dart
- [x] T050 [P] [US2] Create SubCategorySpending model in lib/features/budgets/personal/data/models/sub_category_spending_model.dart

#### Widgets
- [x] T051 [P] [US2] Create GroupSpendingCategory widget (ExpansionTile parent) in lib/features/budgets/personal/presentation/widgets/group_spending_category.dart
- [x] T052 [P] [US2] Create GroupSubCategoryItem widget (subcategory row) in lib/features/budgets/personal/presentation/widgets/group_sub_category_item.dart

#### Screen Modification
- [x] T053 [US2] Modify PersonalBudgetScreen to include GroupSpendingCategory in lib/features/budgets/personal/presentation/screens/personal_budget_screen.dart
- [x] T054 [US2] Update PersonalBudgetProvider to fetch group spending breakdown in lib/features/budgets/personal/presentation/providers/personal_budget_provider.dart

#### Supabase RPC Functions (Backend)
- [x] T055 [US2] Create get_group_spending_breakdown RPC function in Supabase dashboard or migration
- [x] T056 [US2] Verify RLS policies allow member read-only access to group budget data

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - members can view their group allocations

---

## Phase 5: User Story 3 - Personal Budget Calculation Includes Group Allocation (Priority: P2)

**Goal**: Ensure personal budget totals automatically include the member's allocated group budget percentage for accurate financial tracking

**Independent Test**: Create personal budget → add personal expenses → verify total includes group allocation (e.g., €200 personal + €400 group = €600 total) → admin changes allocation percentage → verify personal budget total updates accordingly

### Tests for User Story 3 (TDD Approach - Write First)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T057 [P] [US3] Unit test for CalculatePersonalBudget use case with group allocation in test/features/budgets/personal/domain/usecases/calculate_personal_budget_test.dart
- [x] T058 [P] [US3] Unit test for budget calculation accuracy (zero errors per SC-003) in test/features/budgets/personal/domain/usecases/calculate_personal_budget_test.dart
- [x] T059 [US3] Integration test for budget recalculation when admin changes allocation in integration_test/budget_calculation_test.dart

### Implementation for User Story 3

#### Use Case Modification
- [x] T060 [US3] Modify CalculatePersonalBudget use case to sum group allocation in lib/features/budgets/personal/domain/usecases/calculate_personal_budget.dart
- [x] T061 [US3] Add group allocation field to PersonalBudget entity in lib/features/budgets/personal/domain/entities/personal_budget.dart

#### Provider & Screen Updates
- [x] T062 [US3] Update PersonalBudgetProvider calculation logic in lib/features/budgets/personal/presentation/providers/personal_budget_provider.dart
- [x] T063 [US3] Update PersonalBudgetScreen to display breakdown (personal + group = total) in lib/features/budgets/personal/presentation/screens/personal_budget_screen.dart

#### Supabase RPC Functions (Backend)
- [x] T064 [US3] Modify get_personal_budget RPC function to include group allocation calculation in Supabase dashboard or migration

**Checkpoint**: All user stories should now be independently functional - complete budget tracking system operational

---

## Phase 6: Monthly Reset Automation & Historical Data

**Purpose**: Implement monthly budget cycle automation and verify historical data preservation

- [x] T065 [P] Create MonthlyBudgetReset service in lib/core/services/monthly_budget_reset_service.dart
- [x] T066 Implement client-side month check on app launch in lib/main.dart
- [x] T067 [P] Create budget history query functions for reporting in lib/features/budgets/personal/domain/usecases/get_budget_history.dart
- [x] T068 Verify historical data preserved across month transitions (manual test with date mocking)

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, edge case handling, and performance optimization

- [x] T069 [P] Add error handling for network failures in wizard flow in lib/features/budgets/wizard/presentation/providers/wizard_state_provider.dart
- [x] T070 [P] Implement wizard draft save/restore from Hive cache in lib/features/budgets/wizard/data/datasources/wizard_local_datasource.dart
- [x] T071 [P] Add loading indicators and skeleton screens for wizard steps in lib/features/budgets/wizard/presentation/widgets/
- [x] T072 Handle edge case: admin cancels wizard mid-flow (save draft, allow resume)
- [x] T073 Handle edge case: category removed after expenses recorded (migrate to "Altro")
- [x] T074 Handle edge case: member leaves group mid-period (redistribute allocations or freeze)
- [x] T075 [P] Performance optimization: cache wizard initial data fetch in lib/features/budgets/wizard/data/datasources/wizard_local_datasource.dart
- [x] T076 [P] Add analytics events for wizard completion tracking
- [x] T077 Verify SC-001: Wizard completion under 5 minutes (manual timing test)
- [x] T078 Verify SC-006: Budget changes reflected within 5 seconds (manual latency test)
- [x] T079 Run quickstart.md validation (database setup, developer workflow, localization)
- [x] T080 [P] Update CLAUDE.md with wizard feature patterns and common pitfalls

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Phase 3) can start after Foundational
  - US2 (Phase 4) depends on US1 wizard configuration existing
  - US3 (Phase 5) depends on US2 personal budget view modifications
- **Monthly Reset (Phase 6)**: Depends on US1 configuration data structure
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Requires US1 wizard completion to have data to display - Soft dependency
- **User Story 3 (P2)**: Requires US2 personal budget view to modify calculations - Depends on US1 & US2

### Within Each User Story

- Tests (TDD) MUST be written and FAIL before implementation
- Domain entities before use cases
- Use cases before providers
- Providers before widgets/screens
- Widgets before screen assembly
- RPC functions can be created in parallel with frontend work
- Core implementation before integration

### Parallel Opportunities

- **Phase 1 (Setup)**: All 4 tasks [P] can run in parallel
- **Phase 2 (Foundational)**:
  - T006-T011 (all entity/model creation) can run in parallel
  - T013-T014 (datasources) can run in parallel after T012 (repository interface)
- **Phase 3 (US1)**:
  - T016-T024 (all tests) can run in parallel first
  - T026-T028 (use cases) can run in parallel after tests
  - T029-T031 (providers) can run in parallel after use cases
  - T032-T036 (widgets) can run in parallel after providers
  - T041-T042 (RPC functions) can run in parallel with frontend work
- **Phase 4 (US2)**:
  - T044-T046 (tests) in parallel
  - T049-T050 (models) in parallel
  - T051-T052 (widgets) in parallel
- **Phase 5 (US3)**:
  - T057-T058 (tests) in parallel
- **Phase 7 (Polish)**: T069-T071, T075-T076, T079-T080 can run in parallel

---

## Parallel Example: User Story 1 (Wizard Implementation)

### Step 1: Write All Tests First (Parallel)
```bash
Task T016: Unit test for WizardConfiguration entity validation
Task T017: Unit test for percentage validation (100% sum)
Task T018: Unit test for GetWizardInitialData use case
Task T019: Unit test for SaveWizardConfiguration use case
Task T020: Unit test for MarkWizardCompleted use case
Task T021: Widget test for CategorySelectionStep
Task T022: Widget test for BudgetAmountStep validation
Task T023: Widget test for MemberAllocationStep with button
Task T024: Widget test for WizardStepper navigation
# All should FAIL at this point
```

### Step 2: Create Use Cases (Parallel, after entities exist)
```bash
Task T026: Create GetWizardInitialData use case
Task T027: Create SaveWizardConfiguration use case
Task T028: Create MarkWizardCompleted use case
```

### Step 3: Create Providers (Parallel, after use cases)
```bash
Task T029: Create WizardStateProvider
Task T030: Create CategorySelectionProvider
Task T031: Create AllocationProvider with validation
```

### Step 4: Create Wizard Widgets (Parallel, after providers)
```bash
Task T032: Create WizardStepper widget
Task T033: Create CategorySelectionStep widget
Task T034: Create BudgetAmountStep widget
Task T035: Create MemberAllocationStep widget
Task T036: Create WizardSummaryStep widget
```

### Step 5: Backend Functions (Parallel with frontend work)
```bash
Task T041: Create get_wizard_initial_data RPC
Task T042: Create save_wizard_configuration RPC
# Can be developed by different team member simultaneously
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T015) - CRITICAL blocking phase
3. Complete Phase 3: User Story 1 (T016-T043)
4. **STOP and VALIDATE**: Test wizard end-to-end
   - Login as admin → wizard launches → select categories → set budgets → distribute percentages → submit
   - Verify configuration saved to database
   - Verify wizard_completed flag set
   - Verify router guard prevents re-trigger on subsequent logins
5. Deploy/demo if ready - admin can now configure group budgets

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Wizard) → Test independently → Deploy/Demo (MVP: admin configuration)
3. Add User Story 2 (Member View) → Test independently → Deploy/Demo (members can see allocations)
4. Add User Story 3 (Calculations) → Test independently → Deploy/Demo (accurate budget totals)
5. Add Phase 6 (Monthly Reset) → Test with date mocking → Deploy/Demo (full lifecycle)
6. Add Phase 7 (Polish) → Edge case handling → Deploy/Demo (production-ready)

Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. **Team completes Setup + Foundational together** (critical path)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Wizard frontend: T016-T040)
   - **Developer B**: User Story 1 (Supabase RPC functions: T041-T043)
   - **Developer C**: User Story 2 (Member view preparation: T044-T050)
3. After US1 complete:
   - **Developer A**: User Story 2 screen integration (T051-T056)
   - **Developer B**: User Story 3 calculations (T057-T064)
   - **Developer C**: Phase 6 monthly reset (T065-T068)
4. All converge on Phase 7 (Polish) for edge cases and performance

---

## Task Summary

| Phase | User Story | Tasks | Parallel Tasks | Description |
|-------|------------|-------|----------------|-------------|
| 1 | Setup | 4 | 3 | Database migration, localization, shared widgets |
| 2 | Foundational | 11 | 6 | Entities, models, datasources, repository |
| 3 | US1 (P1) 🎯 | 28 | 19 | Administrator wizard configuration (MVP) |
| 4 | US2 (P2) | 13 | 7 | Member hierarchical budget view |
| 5 | US3 (P2) | 8 | 4 | Personal budget calculation with group allocation |
| 6 | Monthly Reset | 4 | 2 | Monthly cycle automation and history |
| 7 | Polish | 12 | 6 | Error handling, edge cases, performance |
| **Total** | - | **80** | **47** | Complete feature with comprehensive testing |

### Test Coverage

- **Unit Tests**: 11 tests (entities, use cases, validation logic)
- **Widget Tests**: 8 tests (wizard steps, hierarchical categories)
- **Integration Tests**: 3 tests (wizard flow, member view, calculation accuracy)
- **Total Tests**: 22 test files (27.5% of total tasks)

### MVP Scope (Recommended First Delivery)

**Phases 1-3 only** (T001-T043):
- 43 tasks total
- 28 parallelizable
- Estimated: 5-6 days for 1 experienced Flutter developer
- Delivers: Fully functional admin wizard with database persistence and router guard

**Value**: Administrators can configure group budgets - foundational capability for entire feature

---

## Notes

- **[P] tasks**: Different files, no dependencies within phase - safe to parallelize
- **[Story] label**: Maps task to specific user story for traceability
- **TDD Approach**: All tests written before implementation (tests should fail initially)
- Each user story independently completable and testable
- Verify tests fail before implementing (red-green-refactor cycle)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **File Paths**: All paths relative to repository root (C:\Users\KreshOS\Documents\00-Progetti\Fin\)
- **Italian Context**: All UI strings in Italian (percentageAllocation, splitEqually, totalMustBe100, etc.)
- **Performance Targets**: Wizard <500ms load, <2s submission, router guard <50ms
- **Validation**: Percentage sum = 100% ±0.01% tolerance, budget amounts >€0

**Avoid**:
- Vague tasks without file paths
- Same file conflicts (multiple tasks editing one file simultaneously)
- Cross-story dependencies that break independence
- Implementation before tests (violates TDD)
