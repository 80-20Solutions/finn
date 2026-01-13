# Tasks: Personal and Group Budget Management

**Input**: Design documents from `/specs/001-personal-group-budget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in specification - focusing on implementation tasks only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (Flutter)**: `lib/features/budgets/`, `lib/core/`, `lib/shared/`
- Follows Clean Architecture: data/domain/presentation layers
- Tests in `test/features/budgets/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database schema and Drift table setup

- [X] T001 Create Supabase migration for income_sources table as specified in quickstart.md
- [X] T002 Create Supabase migration for savings_goals table as specified in quickstart.md
- [X] T003 Create Supabase migration for group_expense_assignments table as specified in quickstart.md
- [X] T004 [P] Create Drift table definition for IncomeSources in lib/core/database/drift/tables/income_sources_table.dart
- [X] T005 [P] Create Drift table definition for SavingsGoals in lib/core/database/drift/tables/savings_goals_table.dart
- [X] T006 [P] Create Drift table definition for GroupExpenseAssignments in lib/core/database/drift/tables/group_expense_assignments_table.dart
- [X] T007 Update AppDatabase class to include new tables and run build_runner to generate Drift code

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, repositories, and datasources that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 [P] Create IncomeSourceEntity in lib/features/budgets/domain/entities/income_source_entity.dart with all fields from data model
- [X] T009 [P] Create SavingsGoalEntity in lib/features/budgets/domain/entities/savings_goal_entity.dart with all fields from data model
- [X] T010 [P] Create GroupExpenseAssignmentEntity in lib/features/budgets/domain/entities/group_expense_assignment_entity.dart with all fields from data model
- [X] T011 [P] Create BudgetSummaryEntity in lib/features/budgets/domain/entities/budget_summary_entity.dart as computed entity per data model
- [X] T012 [P] Create IncomeSourceModel in lib/features/budgets/data/models/income_source_model.dart with fromJson/toJson/toEntity methods
- [X] T013 [P] Create SavingsGoalModel in lib/features/budgets/data/models/savings_goal_model.dart with fromJson/toJson/toEntity methods
- [X] T014 [P] Create GroupExpenseAssignmentModel in lib/features/budgets/data/models/group_expense_assignment_model.dart with fromJson/toJson/toEntity methods
- [X] T015 Create BudgetRepository abstract interface in lib/features/budgets/domain/repositories/budget_repository.dart with all CRUD methods
- [X] T016 Create BudgetLocalDataSource in lib/features/budgets/data/datasources/budget_local_datasource.dart implementing Drift DAO for all three tables
- [X] T017 Create BudgetRemoteDataSource in lib/features/budgets/data/datasources/budget_remote_datasource.dart implementing Supabase operations for all three tables
- [X] T018 Create BudgetRepositoryImpl in lib/features/budgets/data/repositories/budget_repository_impl.dart implementing repository with optimistic updates
- [X] T019 Create BudgetRepositoryProvider in lib/features/budgets/presentation/providers/budget_repository_provider.dart as Riverpod provider

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Personal Budget Initial Setup (Priority: P1) 🎯 MVP

**Goal**: Enable users to complete guided setup flow capturing income sources and savings goals, showing available budget

**Independent Test**: Complete the wizard flow by adding at least one income source and a savings goal, verify budget summary displays correctly with totalIncome - savingsGoal = availableBudget

### Domain Layer for User Story 1

- [X] T020 [P] [US1] Create SetupPersonalBudgetUseCase in lib/features/budgets/domain/usecases/setup_personal_budget_usecase.dart orchestrating wizard completion
- [X] T021 [P] [US1] Create AddIncomeSourceUseCase in lib/features/budgets/domain/usecases/add_income_source_usecase.dart with FR-003 validation (amount >= 0)
- [X] T022 [P] [US1] Create UpdateSavingsGoalUseCase in lib/features/budgets/domain/usecases/update_savings_goal_usecase.dart with FR-007 validation (goal < totalIncome)
- [X] T023 [P] [US1] Create CalculateAvailableBudgetUseCase in lib/features/budgets/domain/usecases/calculate_available_budget_usecase.dart implementing FR-008 formula

### Presentation Layer for User Story 1

- [X] T024 [US1] Create BudgetSetupProvider in lib/features/budgets/presentation/providers/budget_setup_provider.dart managing wizard state with PageController
- [X] T025 [P] [US1] Create IncomeSources Provider in lib/features/budgets/presentation/providers/income_sources_provider.dart watching repository for income list
- [X] T026 [P] [US1] Create BudgetSummaryProvider in lib/features/budgets/presentation/providers/budget_summary_provider.dart computing budget from income + savings
- [X] T027 [US1] Create shared CurrencyInputField widget in lib/shared/widgets/currency_input_field.dart for reusable currency entry with validation
- [X] T028 [P] [US1] Create IncomeTypeSelector widget in lib/features/budgets/presentation/widgets/income_type_selector.dart with predefined types dropdown per FR-004
- [X] T029 [P] [US1] Create GuidedStepIndicator widget in lib/features/budgets/presentation/widgets/guided_step_indicator.dart showing 3-step progress
- [X] T030 [US1] Create BudgetSetupWizardScreen in lib/features/budgets/presentation/screens/budget_setup_wizard_screen.dart with PageView containing all steps
- [X] T031 [US1] Create IncomeEntryScreen in lib/features/budgets/presentation/screens/income_entry_screen.dart as step 1 with income type selector and amount input
- [X] T032 [US1] Create SavingsGoalScreen in lib/features/budgets/presentation/screens/savings_goal_screen.dart as step 2 with savings input and validation
- [X] T033 [US1] Create BudgetSummaryScreen in lib/features/budgets/presentation/screens/budget_summary_screen.dart as step 3 displaying total income, savings, and available budget
- [X] T034 [US1] Create BudgetBreakdownCard widget in lib/features/budgets/presentation/widgets/budget_breakdown_card.dart showing income/savings/available with visual formatting
- [X] T035 [US1] Add navigation route for BudgetSetupWizardScreen in go_router configuration
- [X] T036 [US1] Implement edge case handling for zero income sources per FR-022 allowing wizard completion with totalIncome = 0

**Checkpoint**: At this point, User Story 1 should be fully functional - users can complete guided setup and see their budget summary

---

## Phase 4: User Story 2 - Multiple Income Source Management (Priority: P2)

**Goal**: Enable users to add multiple income sources with different types, view them separately, and edit/remove sources after initial setup

**Independent Test**: Add 2-3 income sources with different types (Salary, Freelance, Custom), verify each displays separately, total calculates correctly, and edit/delete operations work

### Domain Layer for User Story 2

- [X] T037 [P] [US2] Create UpdateIncomeSourceUseCase in lib/features/budgets/domain/usecases/update_income_source_usecase.dart with validation
- [X] T038 [P] [US2] Create DeleteIncomeSourceUseCase in lib/features/budgets/domain/usecases/delete_income_source_usecase.dart handling cascade to budget recalculation

### Presentation Layer for User Story 2

- [X] T039 [P] [US2] Create IncomeSourceListItem widget in lib/features/budgets/presentation/widgets/income_source_list_item.dart displaying type, custom name, amount with edit/delete actions
- [X] T040 [US2] Create IncomeManagementScreen in lib/features/budgets/presentation/screens/income_management_screen.dart showing list of all sources with add button
- [X] T041 [US2] Add "Add Another Income Source" button to IncomeEntryScreen enabling multiple entries in wizard step 1
- [X] T042 [US2] Update BudgetSummaryScreen to display each income source separately using IncomeSourceListItem widgets
- [X] T043 [US2] Implement custom income type input field in IncomeTypeSelector showing text input when "Custom" selected per FR-004
- [X] T044 [US2] Add navigation route for IncomeManagementScreen accessible from budget summary
- [X] T045 [US2] Implement real-time total income recalculation in BudgetSummaryProvider when sources added/removed meeting SC-003 (< 1 second display update)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - users can manage multiple income sources and see accurate totals

---

## Phase 5: User Story 3 - Group Membership and Expense Assignment (Priority: P3)

**Goal**: When users join a group and receive expense assignments, create "Group Expenses" category in personal budget, auto-adjust savings if needed, and show notification

**Independent Test**: Have user join group, assign expenses exceeding available budget, verify savings auto-reduces, notification displays new amount, and group expenses category appears in budget

### Domain Layer for User Story 3

- [X] T046 [P] [US3] Create AssignGroupExpensesUseCase in lib/features/budgets/domain/usecases/assign_group_expenses_usecase.dart implementing FR-011, FR-012, FR-013 (create/update assignment, deduct from available budget)
- [X] T047 [US3] Create AdjustSavingsForGroupUseCase in lib/features/budgets/domain/usecases/adjust_savings_for_group_usecase.dart implementing FR-015 (auto-reduce savings when group expenses > available)

### Presentation Layer for User Story 3

- [X] T048 [P] [US3] Create SavingsAdjustmentNotification widget in lib/features/budgets/presentation/widgets/savings_adjustment_notification.dart as dismissible banner per research.md (SnackBar + persistent banner pattern)
- [X] T049 [US3] Update BudgetSummaryProvider to include group expense assignment query and recalculate availableBudget as (totalIncome - savings - groupExpenseLimit)
- [X] T050 [US3] Update BudgetSummaryScreen to display "Group Expenses" category section when assignment exists showing spending limit
- [X] T051 [US3] Update BudgetBreakdownCard to show three-way breakdown: Total Income → Savings → Group Expenses → Available when group assignment present
- [X] T052 [US3] Implement savings adjustment notification trigger in AssignGroupExpensesUseCase showing old and new savings amounts per FR-016
- [X] T053 [US3] Add handling for edge case when group expenses exceed available budget triggering auto-adjustment per clarification decision
- [X] T054 [US3] Implement real-time update of group expense limit when assignments change meeting SC-005 (< 5 seconds delay)
- [X] T055 [US3] Handle user removal from group scenario per FR-020/FR-021: retain group expenses category, remove group views/features access

**Checkpoint**: All user stories should now be independently functional - complete personal budget setup, multiple income management, and group expense integration all work

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories, validation, and documentation

- [X] T056 [P] Add input validation error messages for all forms (income amount, savings goal, custom type name) with user-friendly text
- [X] T057 [P] Implement loading states in all providers during async operations (budget fetching, income adding, savings updating)
- [X] T058 [P] Add error handling with proper Failure types for all use cases following existing codebase pattern (dartz Either<Failure, Success>)
- [X] T059 [P] Implement offline-first behavior: optimistic Drift updates with background Supabase sync and rollback on failure
- [X] T060 [P] Add localization keys for all user-facing strings to lib/l10n/intl_*.arb files (income types, wizard labels, error messages)
- [X] T061 [P] Update existing PersonalBudgetModel and GroupBudgetModel to add relationships to new entities per data model
- [X] T062 Verify all monetary values stored as integers (cents) throughout models and entities
- [X] T063 Test budget calculation performance meets SC-008 requirement (< 100ms for all scenarios)
- [X] T064 Validate guided setup completion time meets SC-001 (< 3 minutes end-to-end)
- [X] T065 [P] Add widget tests for key UI components: IncomeTypeSelector, GuidedStepIndicator, BudgetBreakdownCard
- [X] T066 Run integration test for complete wizard flow per quickstart.md validation scenarios
- [X] T067 [P] Add README section documenting new budget setup feature and user flows
- [X] T068 Ensure RLS policies are correctly applied to all three Supabase tables per quickstart.md migration scripts

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Enhances US1 but independently testable (adds management UI)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Integrates with US1 budget calculations but independently testable

### Within Each User Story

- Domain layer (use cases) before presentation layer
- Entities and models before use cases
- Providers before screens/widgets
- Shared widgets before screens that use them
- Core implementation before edge case handling

### Parallel Opportunities

**Phase 1 (Setup)**:
- T001, T002, T003 can run in parallel (different Supabase migrations)
- T004, T005, T006 can run in parallel (different Drift tables)

**Phase 2 (Foundational)**:
- T008, T009, T010, T011 can run in parallel (different entities)
- T012, T013, T014 can run in parallel (different models)
- After T015 complete: T016, T017 can run in parallel (different datasources)

**Phase 3 (User Story 1)**:
- T020, T021, T022, T023 can run in parallel (independent use cases)
- T025, T026 can run in parallel after T024 (different providers)
- T028, T029 can run in parallel (different widgets)

**Phase 4 (User Story 2)**:
- T037, T038 can run in parallel (independent use cases)
- T039, T043 can run in parallel (different widgets)

**Phase 5 (User Story 3)**:
- T046, T048 can run in parallel after foundational (different concerns)

**Phase 6 (Polish)**:
- T056, T057, T058, T059, T060, T061, T065, T067 can all run in parallel (different files/concerns)

---

## Parallel Example: User Story 1

```bash
# Launch all domain use cases for User Story 1 together:
Task: "Create SetupPersonalBudgetUseCase in lib/features/budgets/domain/usecases/setup_personal_budget_usecase.dart"
Task: "Create AddIncomeSourceUseCase in lib/features/budgets/domain/usecases/add_income_source_usecase.dart"
Task: "Create UpdateSavingsGoalUseCase in lib/features/budgets/domain/usecases/update_savings_goal_usecase.dart"
Task: "Create CalculateAvailableBudgetUseCase in lib/features/budgets/domain/usecases/calculate_available_budget_usecase.dart"

# After wizard provider (T024) completes, launch providers together:
Task: "Create IncomeSourcesProvider in lib/features/budgets/presentation/providers/income_sources_provider.dart"
Task: "Create BudgetSummaryProvider in lib/features/budgets/presentation/providers/budget_summary_provider.dart"

# Launch widget components together:
Task: "Create IncomeTypeSelector widget in lib/features/budgets/presentation/widgets/income_type_selector.dart"
Task: "Create GuidedStepIndicator widget in lib/features/budgets/presentation/widgets/guided_step_indicator.dart"
```

---

## Parallel Example: Foundational Phase

```bash
# Launch all entities together:
Task: "Create IncomeSourceEntity in lib/features/budgets/domain/entities/income_source_entity.dart"
Task: "Create SavingsGoalEntity in lib/features/budgets/domain/entities/savings_goal_entity.dart"
Task: "Create GroupExpenseAssignmentEntity in lib/features/budgets/domain/entities/group_expense_assignment_entity.dart"
Task: "Create BudgetSummaryEntity in lib/features/budgets/domain/entities/budget_summary_entity.dart"

# Then launch all models together:
Task: "Create IncomeSourceModel in lib/features/budgets/data/models/income_source_model.dart"
Task: "Create SavingsGoalModel in lib/features/budgets/data/models/savings_goal_model.dart"
Task: "Create GroupExpenseAssignmentModel in lib/features/budgets/data/models/group_expense_assignment_model.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T007) → Database ready
2. Complete Phase 2: Foundational (T008-T019) → Core architecture ready
3. Complete Phase 3: User Story 1 (T020-T036) → Guided setup wizard functional
4. **STOP and VALIDATE**: Test complete wizard flow independently
5. Deploy/demo MVP - users can set up personal budgets and see available spending

**MVP Delivers**: Core value of guided budget setup with income tracking and savings goals

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (19 tasks)
2. Add User Story 1 → Test independently → Deploy/Demo (17 tasks) - **MVP!**
3. Add User Story 2 → Test independently → Deploy/Demo (9 tasks) - Enhances income management
4. Add User Story 3 → Test independently → Deploy/Demo (10 tasks) - Adds group collaboration
5. Add Polish phase → Final production-ready release (13 tasks)

Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (Phases 1-2)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (T020-T036) - Wizard flow
   - **Developer B**: User Story 2 (T037-T045) - Income management
   - **Developer C**: User Story 3 (T046-T055) - Group expenses
3. Stories complete and integrate independently
4. Team reconvenes for Polish phase

---

## Summary Statistics

**Total Tasks**: 68
- Phase 1 (Setup): 7 tasks
- Phase 2 (Foundational): 12 tasks
- Phase 3 (User Story 1): 17 tasks 🎯 MVP
- Phase 4 (User Story 2): 9 tasks
- Phase 5 (User Story 3): 10 tasks
- Phase 6 (Polish): 13 tasks

**Parallelizable Tasks**: 31 marked with [P]

**User Story Breakdown**:
- US1 (P1 - MVP): 17 tasks
- US2 (P2): 9 tasks
- US3 (P3): 10 tasks

**MVP Scope**: Phases 1 + 2 + 3 = 36 tasks for fully functional personal budget setup

---

## Notes

- [P] tasks = different files, no dependencies between them
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All paths follow Flutter Clean Architecture convention: lib/features/{feature}/data|domain|presentation
- Monetary values MUST be stored as integers (cents) per technical constraints
- Budget calculations MUST complete in < 100ms per performance goals
- Wizard completion MUST take < 3 minutes per success criteria
