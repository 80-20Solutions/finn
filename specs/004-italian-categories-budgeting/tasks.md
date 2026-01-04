---

description: "Task list for Italian Categories and Budget Management System"
---

# Tasks: Italian Categories and Budget Management System

**Input**: Design documents from `/specs/004-italian-categories-budgeting/`
**Prerequisites**: plan.md (✅), spec.md (✅), research.md (✅), data-model.md (✅), contracts/ (✅)

**Tests**: Not explicitly requested in spec - tasks focus on implementation only

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile Flutter**: `lib/features/`, `supabase/migrations/`
- All paths relative to repository root: `C:\Users\KreshOS\Documents\00-Progetti\Fin`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database schema and migration infrastructure for Italian categories and budgets

- [X] T001 [P] Create database migration `supabase/migrations/026_category_budgets_table.sql` for `category_budgets` table with indexes
- [X] T002 [P] Create database migration `supabase/migrations/027_user_category_usage_table.sql` for `user_category_usage` table with indexes
- [X] T003 [P] Create database migration `supabase/migrations/028_batch_reassign_orphaned.sql` for RPC function `batch_reassign_orphaned_expenses`
- [X] T004 [P] Create database migration `supabase/migrations/029_get_category_budget_stats.sql` for RPC function `get_category_budget_stats`
- [X] T005 [P] Create database migration `supabase/migrations/030_get_overall_group_budget_stats.sql` for RPC function `get_overall_group_budget_stats`
- [X] T006 [P] Create database migration `supabase/migrations/031_category_budgets_rls.sql` for RLS policies on `category_budgets` table
- [X] T007 [P] Create database migration `supabase/migrations/032_user_category_usage_rls.sql` for RLS policies on `user_category_usage` table
- [X] T008 Create index migration `supabase/migrations/033_expenses_category_month_index.sql` for optimized category-month queries on expenses table

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data migration and default Italian categories that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 Create migration `supabase/migrations/034_orphan_expenses_italian_categories.sql` to set all expenses `category_id` to NULL and delete English categories
- [X] T010 Create migration `supabase/migrations/035_seed_italian_categories.sql` to insert default Italian categories (Spesa, Benzina, Ristoranti, Bollette, Salute, Trasporti, Casa, Svago, Abbigliamento, Varie) for all groups
- [X] T011 Run all migrations to Supabase using `supabase db push` from repository root
- [X] T012 [P] Create domain entity `lib/features/categories/domain/entities/category_entity.dart` for Italian expense categories
- [X] T013 [P] Create domain entity `lib/features/categories/domain/entities/user_category_usage_entity.dart` for virgin category tracking
- [X] T014 [P] Create domain entity `lib/features/budgets/domain/entities/category_budget_entity.dart` for monthly category budgets
- [X] T015 [P] Create domain entity `lib/features/budgets/domain/entities/monthly_budget_stats_entity.dart` for calculated budget statistics
- [X] T016 [P] Create domain entity `lib/features/budgets/domain/entities/overall_group_budget_stats_entity.dart` for dashboard aggregated stats
- [X] T017 Create config file `lib/core/config/default_italian_categories.dart` with Italian category seed data constants

**Checkpoint**: Foundation ready - database has Italian categories, all domain entities created, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Italian Category Names (Priority: P1) 🎯 MVP

**Goal**: Display all expense categories in Italian throughout the application for natural Italian user experience

**Independent Test**: View category list in settings and during expense creation, confirm all categories display in Italian (Spesa, Benzina, etc.)

### Implementation for User Story 1

- [ ] T018 [P] [US1] Create data model `lib/features/categories/data/models/category_model.dart` extending CategoryEntity with fromJson/toJson
- [ ] T019 [P] [US1] Create repository interface `lib/features/categories/domain/repositories/category_repository.dart` with category CRUD methods
- [ ] T020 [US1] Create remote datasource `lib/features/categories/data/datasources/category_remote_datasource.dart` with Supabase queries for categories
- [ ] T021 [US1] Implement repository `lib/features/categories/data/repositories/category_repository_impl.dart` calling remote datasource
- [ ] T022 [US1] Create Riverpod provider `lib/features/categories/presentation/providers/category_provider.dart` for category list state management
- [ ] T023 [US1] Create widget `lib/features/categories/presentation/widgets/category_list_widget.dart` displaying Italian category names
- [ ] T024 [US1] Modify expense creation screen `lib/features/expenses/presentation/screens/add_expense_screen.dart` to show Italian category picker
- [ ] T025 [US1] Modify expense detail screen `lib/features/expenses/presentation/screens/expense_detail_screen.dart` to display Italian category names
- [ ] T026 [US1] Update expense repository `lib/features/expenses/data/repositories/expense_repository_impl.dart` to handle NULL category_id for orphaned expenses

**Checkpoint**: At this point, User Story 1 should be fully functional - all categories display in Italian throughout the app

---

## Phase 4: User Story 2 - Default Categories with Budgets (Priority: P2)

**Goal**: Allow users to configure default categories with specific monthly budget amounts in settings

**Independent Test**: Navigate to settings, create/edit categories with budget amounts, verify budgets are stored and displayed correctly

### Implementation for User Story 2

- [ ] T027 [P] [US2] Create data model `lib/features/budgets/data/models/category_budget_model.dart` extending CategoryBudgetEntity with fromJson/toJson
- [ ] T028 [P] [US2] Create repository interface `lib/features/budgets/domain/repositories/budget_repository.dart` with category budget CRUD methods
- [ ] T029 [US2] Create remote datasource `lib/features/budgets/data/datasources/budget_remote_datasource.dart` with Supabase category budget queries
- [ ] T030 [US2] Implement repository `lib/features/budgets/data/repositories/budget_repository_impl.dart` calling remote datasource
- [ ] T031 [US2] Create Riverpod provider `lib/features/budgets/presentation/providers/budget_provider.dart` for category budgets state management
- [ ] T032 [US2] Create screen `lib/features/categories/presentation/screens/category_management_screen.dart` for managing categories and their budgets
- [ ] T033 [US2] Create widget `lib/features/categories/presentation/widgets/category_budget_card.dart` showing category with editable budget field
- [ ] T034 [US2] Add budget amount input field and validation to category management screen for creating/editing budgets
- [ ] T035 [US2] Implement save/update/delete budget logic in category management screen calling budget repository methods

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - Italian categories displayed, budgets configurable in settings

---

## Phase 5: User Story 3 - Budget Prompt for First-Time Category Use (Priority: P3)

**Goal**: Prompt users to set budget when they use a virgin category for the first time, building budget structure organically

**Independent Test**: Create expense in previously unused category, verify budget prompt appears, confirm user choice is properly applied

### Implementation for User Story 3

- [ ] T036 [P] [US3] Create data model `lib/features/categories/data/models/user_category_usage_model.dart` extending UserCategoryUsageEntity with fromJson/toJson
- [ ] T037 [US3] Add virgin category tracking methods to category remote datasource `lib/features/categories/data/datasources/category_remote_datasource.dart`
- [ ] T038 [US3] Add virgin category check methods to category repository interface `lib/features/categories/domain/repositories/category_repository.dart`
- [ ] T039 [US3] Implement virgin category methods in category repository `lib/features/categories/data/repositories/category_repository_impl.dart`
- [ ] T040 [US3] Create widget `lib/features/categories/presentation/widgets/budget_prompt_dialog.dart` for virgin category budget setup
- [ ] T041 [US3] Modify add expense screen `lib/features/expenses/presentation/screens/add_expense_screen.dart` to check virgin category and show prompt
- [ ] T042 [US3] Implement budget prompt logic: save budget if user sets amount, use "Varie" budget if declined
- [ ] T043 [US3] Create user_category_usage record after first expense creation in virgin category
- [ ] T044 [US3] Add per-user tracking to ensure each family member gets prompted independently

**Checkpoint**: All user stories 1-3 should now work independently - Italian categories, configurable budgets, virgin prompts per user

---

## Phase 6: User Story 4 - Dashboard Budget Overview (Priority: P2)

**Goal**: Display comprehensive budget monitoring on dashboard showing individual category budgets and overall budget status

**Independent Test**: Create categories with budgets, add expenses, verify dashboard displays current status for each category and overall totals

### Implementation for User Story 4

- [ ] T045 [P] [US4] Create data model `lib/features/budgets/data/models/monthly_budget_stats_model.dart` extending MonthlyBudgetStatsEntity with fromJson
- [ ] T046 [P] [US4] Create data model `lib/features/budgets/data/models/overall_group_budget_stats_model.dart` extending OverallGroupBudgetStatsEntity with fromJson
- [ ] T047 [US4] Add RPC method `getCategoryBudgetStats` to budget remote datasource `lib/features/budgets/data/datasources/budget_remote_datasource.dart`
- [ ] T048 [US4] Add RPC method `getOverallGroupBudgetStats` to budget remote datasource `lib/features/budgets/data/datasources/budget_remote_datasource.dart`
- [ ] T049 [US4] Add budget stats methods to budget repository interface `lib/features/budgets/domain/repositories/budget_repository.dart`
- [ ] T050 [US4] Implement budget stats methods in budget repository `lib/features/budgets/data/repositories/budget_repository_impl.dart`
- [ ] T051 [US4] Create Riverpod provider `lib/features/budgets/presentation/providers/monthly_budget_stats_provider.dart` for category budget stats
- [ ] T052 [US4] Create Riverpod provider `lib/features/budgets/presentation/providers/overall_budget_stats_provider.dart` for dashboard overall stats
- [ ] T053 [US4] Create widget `lib/features/dashboard/presentation/widgets/budget_summary_widget.dart` for overall budget summary display
- [ ] T054 [US4] Create widget `lib/features/dashboard/presentation/widgets/category_budget_list_widget.dart` for individual category budget cards
- [ ] T055 [US4] Create widget `lib/features/budgets/presentation/widgets/category_budget_indicator.dart` showing progress bar and over-budget highlights
- [ ] T056 [US4] Modify dashboard screen `lib/features/dashboard/presentation/screens/dashboard_screen.dart` to include budget summary and category list widgets
- [ ] T057 [US4] Implement visual highlighting for over-budget categories using color indicators in category budget indicator widget
- [ ] T058 [US4] Add zero-state handling for dashboard when no budgets exist (show "Set up budgets" prompt)

**Checkpoint**: Dashboard displays all budget information - category budgets with spending percentages and overall budget totals

---

## Phase 7: User Story 5 - Expense Detail Budget Context (Priority: P3)

**Goal**: Show budget context information in expense detail screen to help users understand individual transaction impact

**Independent Test**: Open any expense detail screen, verify budget context (category budget status, remaining, percentage) displays in lower section

### Implementation for User Story 5

- [ ] T059 [US5] Create widget `lib/features/expenses/presentation/widgets/budget_context_widget.dart` displaying category budget status for an expense
- [ ] T060 [US5] Modify expense detail screen `lib/features/expenses/presentation/screens/expense_detail_screen.dart` to show budget context widget in lower section
- [ ] T061 [US5] Fetch category budget stats for the expense's category in expense detail screen using budget stats provider
- [ ] T062 [US5] Display remaining budget amount and percentage used in budget context widget
- [ ] T063 [US5] Add special indicator in budget context widget when expense uses generic "Varie" budget
- [ ] T064 [US5] Highlight in budget context widget when the category budget was exceeded by this expense
- [ ] T065 [US5] Handle null category_id case (orphaned expenses) by showing "No budget assigned" message in budget context widget

**Checkpoint**: All user stories 1-5 complete - expense details show contextual budget information for every transaction

---

## Phase 8: Orphaned Expense Handling (Foundational Feature)

**Goal**: Provide UI for users to re-categorize orphaned expenses created during migration from English to Italian categories

**Independent Test**: View orphaned expenses screen, select multiple expenses, bulk assign to Italian category, verify expenses updated

### Implementation for Orphaned Expense Handling

- [ ] T066 [P] Create screen `lib/features/categories/presentation/screens/orphaned_expenses_screen.dart` for displaying uncategorized expenses
- [ ] T067 [P] Create Riverpod provider `lib/features/expenses/presentation/providers/orphaned_expenses_provider.dart` for orphaned expense list
- [ ] T068 Add query method `getOrphanedExpenses` to expense remote datasource `lib/features/expenses/data/datasources/expense_remote_datasource.dart`
- [ ] T069 Add orphaned expenses method to expense repository interface `lib/features/expenses/domain/repositories/expense_repository.dart`
- [ ] T070 Implement orphaned expenses method in expense repository `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- [ ] T071 Implement multi-select UI in orphaned expenses screen with long-press to enter selection mode
- [ ] T072 Add bottom action sheet to orphaned expenses screen with "Assegna categoria" button
- [ ] T073 Create category picker modal for bulk re-categorization in orphaned expenses screen
- [ ] T074 Add RPC method `batchReassignOrphanedExpenses` to expense remote datasource calling `batch_reassign_orphaned_expenses` function
- [ ] T075 Implement batch update logic in orphaned expenses screen calling RPC method with selected expense IDs
- [ ] T076 Add notification on app launch to alert user of orphaned expenses count with navigation to orphaned expenses screen
- [ ] T077 Add loading indicator and error handling for batch re-categorization operations

**Checkpoint**: Users can efficiently re-categorize all orphaned expenses from migration using bulk selection UI

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Refinements and quality improvements across all user stories

- [ ] T078 [P] Add monthly budget reset documentation in `lib/core/utils/budget_calculator.dart` comments explaining implicit reset via date queries
- [ ] T079 [P] Verify all budget calculations use TimezoneHandler for month boundaries in budget remote datasource
- [ ] T080 [P] Add validation in category budget forms to prevent negative budget amounts
- [ ] T081 [P] Add confirmation dialog before deleting category budgets in category management screen
- [ ] T082 [P] Implement optimistic UI updates for budget modifications using Riverpod state management
- [ ] T083 [P] Add error handling and user feedback (SnackBars) for all budget operations throughout the app
- [ ] T084 Add navigation from dashboard budget widgets to detailed category budget view in category management screen
- [ ] T085 Verify RLS policies enforce group membership for all budget queries by testing with multiple users
- [ ] T086 Test budget calculations with edge cases (deleted expenses, category changes, month boundaries)
- [ ] T087 Verify virgin category prompts work correctly for multiple family members independently
- [ ] T088 Test overall budget auto-calculation updates when category budgets are added/removed/modified
- [ ] T089 Run performance testing on dashboard with 1000 expenses to ensure <3s load time
- [ ] T090 Validate all Italian category names display correctly throughout the app without English fallbacks

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (migrations and database setup)
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories (data migration + domain entities)
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Italian Categories) - Can start after Foundational - No dependencies on other stories
  - US2 (Default Budgets) - Can start after Foundational - May integrate with US1 but independently testable
  - US3 (Virgin Prompts) - Depends on US1 (categories) and US2 (budgets) - Should implement after US1+US2
  - US4 (Dashboard) - Depends on US2 (needs budgets to display) - Should implement after US2
  - US5 (Expense Details) - Depends on US2 (needs budget stats) - Can implement anytime after US2
- **Orphaned Expenses (Phase 8)**: Depends on US1 (needs Italian categories for re-assignment)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Uses categories from US1 but independently testable
- **User Story 3 (P3)**: Should start after US1 + US2 - Requires categories and budget infrastructure
- **User Story 4 (P2)**: Should start after US2 - Requires category budgets to display stats
- **User Story 5 (P3)**: Can start after US2 - Requires budget stats calculation

### Within Each User Story

- Domain entities before data models
- Data models before datasources
- Datasources before repositories
- Repositories before providers
- Providers before UI widgets/screens
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks (T001-T008) can run in parallel - different migration files
- All Foundational domain entities (T012-T016) can run in parallel - different files
- Data models within each story can run in parallel (different files)
- US1 and US2 can be worked on in parallel by different developers after Foundational phase
- US4 and US5 can be worked on in parallel after US2 completes
- Orphaned expense handling (Phase 8) can be developed in parallel with user stories 3-5

---

## Parallel Example: User Story 1

```bash
# Launch all domain entities together (Foundational phase):
Task: "Create domain entity lib/features/categories/domain/entities/category_entity.dart"
Task: "Create domain entity lib/features/categories/domain/entities/user_category_usage_entity.dart"
Task: "Create domain entity lib/features/budgets/domain/entities/category_budget_entity.dart"

# Launch all US1 data models together:
Task: "Create data model lib/features/categories/data/models/category_model.dart"
```

## Parallel Example: User Story 4

```bash
# Launch all US4 data models together:
Task: "Create data model lib/features/budgets/data/models/monthly_budget_stats_model.dart"
Task: "Create data model lib/features/budgets/data/models/overall_group_budget_stats_model.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (database migrations)
2. Complete Phase 2: Foundational (data migration + domain entities - CRITICAL)
3. Complete Phase 3: User Story 1 (Italian category names)
4. **STOP and VALIDATE**: Test User Story 1 independently - all categories in Italian
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Italian categories in database
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (budget configuration)
4. Add Phase 8 (Orphaned Expenses) → Let users re-categorize → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo (dashboard budgets)
6. Add User Story 3 → Test independently → Deploy/Demo (virgin prompts)
7. Add User Story 5 → Test independently → Deploy/Demo (expense detail context)
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Italian categories)
   - Developer B: User Story 2 (budget configuration)
   - Developer C: Phase 8 (orphaned expenses UI)
3. After US1 + US2 complete:
   - Developer A: User Story 4 (dashboard)
   - Developer B: User Story 3 (virgin prompts)
   - Developer C: User Story 5 (expense details)
4. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Database migrations (Phase 1) must be deployed via `supabase db push` before testing
- Italian category migration (Phase 2) is destructive - backs up no data, requires user re-categorization
- Monthly budget "reset" is implicit via date-range queries - no cron jobs needed
- Virgin category tracking is per-user - each family member gets independent prompts
- All amounts stored in cents (INTEGER) to avoid floating-point errors
- Overall budget is auto-calculated sum of category budgets (FR-014)
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
