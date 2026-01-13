# Implementation Plan: Personal and Group Budget Management

**Branch**: `001-personal-group-budget` | **Date**: 2026-01-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-personal-group-budget/spec.md`

## Summary

This feature implements a comprehensive personal and group budget management system for the Finn mobile app. Users will complete a guided setup to register monthly income sources (with types like Salary, Freelance, etc.) and set savings goals. The system automatically calculates available spending budget. When users join a family group, group expenses are assigned creating a "Group Expenses" category that affects their personal budget. The system includes smart validation (preventing savings > income, negative income) and automatic savings adjustment when group expenses exceed available budget.

**Technical Approach**: Extends existing Flutter/Supabase architecture with Clean Architecture pattern. Uses Riverpod for state management, Drift for local caching, and Supabase for backend persistence. Implements a multi-step guided flow for budget setup, real-time budget calculations, and notifications for savings adjustments.

## Technical Context

**Language/Version**: Dart 3.0+ / Flutter 3.0+
**Primary Dependencies**: flutter_riverpod ^2.4.0, supabase_flutter ^2.0.0, drift ^2.14.0, go_router ^12.0.0
**Storage**: Supabase PostgreSQL (remote), Drift/SQLite (local cache)
**Testing**: flutter_test, mockito ^5.4.0, integration_test
**Target Platform**: iOS 15+, Android API 24+ (mobile)
**Project Type**: Mobile (Flutter)
**Performance Goals**:
- Budget calculations < 100ms
- Setup completion < 3 minutes (per SC-001)
- Real-time updates < 2 seconds for group operations (per SC-004, SC-005)
**Constraints**:
- Offline-capable with local Drift database
- All monetary values stored as integers (cents/smallest currency unit)
- Single currency per user budget (per A-002)
**Scale/Scope**:
- Supporting 10k+ active users
- ~5-10 screens/widgets for budget flow
- Multi-step guided wizard UI pattern

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: The constitution template is not yet customized for this project. Assuming standard Flutter/mobile best practices:

- ✅ **Clean Architecture**: Feature follows existing lib/features/{feature}/data|domain|presentation structure
- ✅ **State Management**: Uses Riverpod consistently with existing codebase
- ✅ **Offline-First**: Local Drift cache with Supabase sync matches existing patterns
- ✅ **Test Coverage**: Unit, integration, and widget tests required for all business logic
- ✅ **Error Handling**: Standard Failure/Either pattern from existing codebase

**No violations identified** - Feature aligns with existing architecture patterns.

## Project Structure

### Documentation (this feature)

```text
specs/001-personal-group-budget/
├── spec.md                # Feature specification (completed)
├── plan.md                # This file (in progress)
├── research.md            # Phase 0 output (to be generated)
├── data-model.md          # Phase 1 output (to be generated)
├── quickstart.md          # Phase 1 output (to be generated)
├── contracts/             # Phase 1 output (to be generated)
│   ├── income_source.json
│   ├── personal_budget.json
│   ├── group_expense_assignment.json
│   └── budget_notification.json
└── tasks.md               # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── budgets/                    # Existing feature - EXTEND
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── budget_local_datasource.dart      # NEW: Drift local storage
│       │   │   └── budget_remote_datasource.dart     # NEW: Supabase operations
│       │   ├── models/
│       │   │   ├── personal_budget_model.dart        # EXISTS - MODIFY
│       │   │   ├── group_budget_model.dart           # EXISTS - MODIFY
│       │   │   ├── income_source_model.dart          # NEW
│       │   │   ├── savings_goal_model.dart           # NEW
│       │   │   └── group_expense_assignment_model.dart # NEW
│       │   └── repositories/
│       │       └── budget_repository_impl.dart       # NEW: Implements domain repository
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── personal_budget_entity.dart       # EXISTS - MODIFY
│       │   │   ├── group_budget_entity.dart          # EXISTS - MODIFY
│       │   │   ├── income_source_entity.dart         # NEW
│       │   │   ├── savings_goal_entity.dart          # NEW
│       │   │   ├── group_expense_assignment_entity.dart # NEW
│       │   │   └── budget_summary_entity.dart        # NEW: Calculated summary
│       │   ├── repositories/
│       │   │   └── budget_repository.dart            # NEW: Abstract repository
│       │   └── usecases/
│       │       ├── setup_personal_budget_usecase.dart # NEW
│       │       ├── add_income_source_usecase.dart     # NEW
│       │       ├── update_savings_goal_usecase.dart   # NEW
│       │       ├── calculate_available_budget_usecase.dart # NEW
│       │       ├── assign_group_expenses_usecase.dart # NEW
│       │       └── adjust_savings_for_group_usecase.dart # NEW
│       └── presentation/
│           ├── providers/
│           │   ├── budget_setup_provider.dart        # NEW: Multi-step wizard state
│           │   ├── income_sources_provider.dart      # NEW
│           │   ├── budget_summary_provider.dart      # NEW
│           │   └── budget_repository_provider.dart   # EXISTS - MODIFY
│           ├── screens/
│           │   ├── budget_setup_wizard_screen.dart   # NEW: Main guided flow
│           │   ├── income_entry_screen.dart          # NEW: Step 1
│           │   ├── savings_goal_screen.dart          # NEW: Step 2
│           │   ├── budget_summary_screen.dart        # NEW: Final step/view
│           │   └── income_management_screen.dart     # NEW: Edit sources
│           └── widgets/
│               ├── income_type_selector.dart         # NEW
│               ├── income_source_list_item.dart      # NEW
│               ├── budget_breakdown_card.dart        # NEW
│               ├── savings_adjustment_notification.dart # NEW
│               └── guided_step_indicator.dart        # NEW
├── shared/
│   ├── services/
│   │   └── notification_service.dart                 # EXISTS - EXTEND for savings adjustments
│   └── widgets/
│       └── currency_input_field.dart                 # NEW: Reusable currency input
└── core/
    └── database/
        └── drift/
            └── tables/
                ├── income_sources_table.dart          # NEW: Drift table definition
                ├── savings_goals_table.dart           # NEW
                └── group_expense_assignments_table.dart # NEW

test/
├── features/
│   └── budgets/
│       ├── data/
│       │   ├── models/                               # Model conversion tests
│       │   └── repositories/                         # Repository implementation tests
│       ├── domain/
│       │   └── usecases/                             # Use case unit tests
│       └── presentation/
│           ├── providers/                            # Provider logic tests
│           └── screens/                              # Widget tests
└── integration_test/
    └── budgets/
        └── budget_setup_flow_test.dart               # E2E guided setup test
```

**Structure Decision**: Extends existing `lib/features/budgets/` feature following Clean Architecture pattern already established in the codebase. The feature uses:
- **Data Layer**: Drift for local cache, Supabase for remote persistence
- **Domain Layer**: Entities, repositories (abstract), use cases for business logic
- **Presentation Layer**: Riverpod providers, screens, widgets

New Drift tables will be added to `core/database/drift/tables/` following existing patterns from the groups/categories features.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - table not applicable.

---

## Phase 0: Research & Technology Decisions

**Status**: ✅ Complete

Research tasks to resolve before design:

1. **Guided Wizard Flow Pattern**
   - Decision needed: Multi-screen navigation vs. single-screen stepper
   - Research: Best practices for multi-step forms in Flutter
   - Evaluate: go_router nested navigation, PageView with indicators, or WoltModalSheet (already in dependencies)

2. **Budget Calculation Strategy**
   - Decision needed: Real-time recalculation frequency and optimization
   - Research: Performance patterns for computed properties in Riverpod
   - Consider: Memoization, selective rebuild strategies

3. **Supabase Schema Design**
   - Decision needed: Table structure for income sources, savings goals, group expense assignments
   - Research: Foreign key relationships, indexes for query performance
   - Validate: Single currency assumption, monthly vs. arbitrary period budgets

4. **Notification System Integration**
   - Decision needed: In-app notification mechanism for savings adjustments
   - Research: Existing notification_service.dart capabilities
   - Evaluate: Snackbar, dialog, persistent notification banner

5. **Drift Local Cache Strategy**
   - Decision needed: Sync strategy between Supabase and local Drift database
   - Research: Existing patterns in groups/categories features
   - Consider: Optimistic updates, conflict resolution

6. **Localization for Income Types**
   - Decision needed: How to handle predefined income types ("Stipendio") in multiple languages
   - Research: Existing i18n patterns in the codebase
   - Edge case: Currency/language handling (deferred in spec, address here)

**Output**: `research.md` with decisions, rationales, and alternatives considered for each area.

---

## Phase 1: Data Model & Contracts

**Status**: ✅ Complete

**Prerequisites**: `research.md` complete

### Data Model Generation

Extract from spec entities and design:

**Entities to Model**:
1. **IncomeSource** (NEW)
   - id, userId, type (enum: Salary, Freelance, Investment, Other, Custom), customTypeName, amount, createdAt, updatedAt

2. **SavingsGoal** (NEW)
   - id, userId, amount, originalAmount, adjustedAt, createdAt, updatedAt

3. **GroupExpenseAssignment** (NEW)
   - id, groupId, userId, spendingLimit, createdAt, updatedAt

4. **PersonalBudget** (MODIFY)
   - Add relationships to income sources, savings goal
   - Add calculated properties: totalIncome, availableBudget

5. **GroupBudget** (MODIFY)
   - Add relationship to assignments

**Validation Rules**:
- Income amount >= 0 (FR-003)
- Savings goal < total income (FR-007)
- Auto-adjust savings when group expenses exceed (FR-015)

**State Transitions**:
- Savings goal: original → adjusted (when group expenses assigned)
- Personal budget: empty → income_entered → savings_set → complete

### API Contracts

**REST/GraphQL endpoints** (Supabase RPC or direct table access):

1. **POST /income-sources** - Add income source
2. **GET /income-sources?userId={id}** - List user's income sources
3. **PUT /income-sources/{id}** - Update income source
4. **DELETE /income-sources/{id}** - Remove income source
5. **POST /savings-goals** - Set/update savings goal
6. **GET /savings-goals?userId={id}** - Get current savings goal
7. **POST /group-expense-assignments** - Assign expenses to user
8. **GET /budget-summary?userId={id}** - Get calculated budget summary

**Output**:
- `data-model.md` with entity definitions, relationships, validations
- `contracts/*.json` with OpenAPI/JSON schema for each endpoint
- `quickstart.md` with setup instructions for Supabase schema migrations
- Agent context updated via `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude`

---

## Phase 2: Task Generation

**Status**: NOT started (separate `/speckit.tasks` command)

This phase is handled by the `/speckit.tasks` command, which will:
- Break down the implementation into dependency-ordered tasks
- Map tasks to user stories (US1, US2, US3)
- Mark parallelizable tasks
- Output to `tasks.md`

**Note**: Do not create `tasks.md` in this command. It will be generated by `/speckit.tasks`.

---

## Next Steps

1. ✅ **Phase 0**: Run research agents to resolve all technology decisions → `research.md`
2. ✅ **Phase 1**: Generate data model and contracts → `data-model.md`, `contracts/*`, `quickstart.md`
3. ⏸️ **Phase 2**: Run `/speckit.tasks` to generate implementation tasks → `tasks.md`
4. ⏸️ **Phase 3**: Run `/speckit.implement` to execute tasks

**Current Status**: Phase 0 and Phase 1 complete. Ready for `/speckit.tasks` to generate implementation tasks.
