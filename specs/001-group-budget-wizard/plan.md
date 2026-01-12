# Implementation Plan: Group Budget Setup Wizard

**Branch**: `001-group-budget-wizard` | **Date**: 2026-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-group-budget-wizard/spec.md`

## Summary

This feature implements a guided onboarding wizard that automatically triggers when a group administrator first accesses a group. The wizard guides administrators through:
1. Selecting default expense categories for the group
2. Setting collective monthly budget amounts per category (shared across all members)
3. Distributing group budget allocations by manually specifying percentage shares for each member (must total 100%)

Members subsequently view their allocated group spending in a hierarchical "Group Spending" category within their personal budget dashboard, with expandable sub-categories showing detailed breakdowns. Personal budget calculations automatically incorporate group allocations. Monthly budgets reset at the start of each calendar month while preserving historical data.

**Technical Approach**: Extend existing budget infrastructure (group_budgets, category_budgets tables) with wizard UI flow, add wizard completion tracking to profiles table, implement hierarchical category rendering in personal budget views using existing Riverpod state management.

## Technical Context

**Language/Version**: Dart 3.0+ with Flutter framework
**Primary Dependencies**:
- State Management: flutter_riverpod (^2.4.0), riverpod_annotation (^2.3.0)
- Backend: supabase_flutter (^2.0.0) with PostgreSQL database
- Local Storage: drift (^2.14.0) with SQLCipher, hive_flutter (^1.1.0)
- UI Components: wolt_modal_sheet (^0.6.0), fl_chart (^0.65.0), google_fonts (^6.2.1)
- Navigation: go_router (^12.0.0)
- Functional: dartz (^0.10.1) for Either/Result pattern

**Storage**:
- Primary: PostgreSQL via Supabase (cloud-hosted)
- Existing tables: profiles, family_groups, group_budgets, category_budgets, expense_categories, personal_budgets
- Local cache: Hive for dashboard, Drift for offline sync with encryption
- New migrations required for wizard tracking field

**Testing**:
- Flutter Test framework with Mockito (^5.4.0)
- Current coverage minimal (4 test files); this feature requires comprehensive widget + integration tests
- Test structure: test/features/budgets/wizard/ for unit/widget tests

**Target Platform**:
- Primary: Android mobile (min SDK 24)
- Secondary: iOS support configured
- Tertiary: Web/Desktop capable
- Italian localization only

**Project Type**: Full-stack mobile app with Clean Architecture
- Feature-based structure: lib/features/budgets/wizard/
- Clean Architecture layers: data/ (models, repos), domain/ (entities, use cases), presentation/ (screens, providers)

**Performance Goals**:
- Wizard completion <5 minutes (SC-001)
- Budget allocation changes reflected in member views within 5 seconds (SC-006)
- Zero calculation errors for personal budget totals (SC-003)

**Constraints**:
- Legacy system requires wizard completion at first admin access (blocking mandatory flow)
- Monthly budget cycle aligned to calendar months (1st to last day)
- Percentage allocations must total exactly 100%
- Must integrate with existing 7 Italian category defaults: Cibo, Utenze, Trasporto, Sanità, Intrattenimento, Casa, Altro

**Scale/Scope**:
- Multi-tenant via family_groups (group_id scoping)
- Expected: <10 members per group typical, <20 categories per group
- Historical data retention for all previous months (unbounded growth)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: Constitution template is placeholder only. Project does not have specific constitution defined. Proceeding with standard best practices:

✓ **Clean Architecture**: Feature follows existing pattern (data/domain/presentation layers)
✓ **Testability**: Unit tests for business logic, widget tests for UI, integration tests for flows
✓ **Modularity**: Wizard is self-contained feature under lib/features/budgets/wizard/
✓ **Existing Patterns**: Leverages established Riverpod providers, Supabase repositories, Either error handling
✓ **No Breaking Changes**: Extends existing budget tables, backward compatible with current budget flows

**Gates**:
- ✓ Feature uses existing tech stack (Dart/Flutter/Supabase)
- ✓ Follows Clean Architecture pattern already established
- ✓ Integrates with existing RBAC (is_group_admin flag)
- ✓ No new external dependencies required
- ⚠ **Test Coverage**: Currently minimal (4 files); must add comprehensive tests for wizard (TDD approach recommended)

**Re-evaluation After Phase 1**: Will verify data model changes maintain referential integrity and RLS policy consistency.

## Project Structure

### Documentation (this feature)

```text
specs/001-group-budget-wizard/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output - technical decisions
├── data-model.md        # Phase 1 output - database schema changes
├── quickstart.md        # Phase 1 output - developer onboarding
├── contracts/           # Phase 1 output - API contracts
│   ├── wizard_service.yaml       # Wizard data operations
│   └── budget_calculation.yaml   # Personal budget calculation APIs
└── tasks.md             # Phase 2 output (/speckit.tasks - not yet created)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── budgets/
│       ├── wizard/                        # NEW: Wizard feature module
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── wizard_state_model.dart          # Wizard step state
│       │   │   │   ├── category_selection_model.dart    # Selected categories
│       │   │   │   └── member_allocation_model.dart     # Percentage allocations
│       │   │   ├── datasources/
│       │   │   │   ├── wizard_remote_datasource.dart    # Supabase operations
│       │   │   │   └── wizard_local_datasource.dart     # Hive cache
│       │   │   └── repositories/
│       │   │       └── wizard_repository_impl.dart      # Repository implementation
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── wizard_configuration.dart        # Wizard config entity
│       │   │   │   └── budget_allocation.dart           # Member allocation entity
│       │   │   ├── repositories/
│       │   │   │   └── wizard_repository.dart           # Abstract repository
│       │   │   └── usecases/
│       │   │       ├── get_wizard_initial_data.dart     # Load categories + members
│       │   │       ├── save_wizard_configuration.dart   # Persist config
│       │   │       └── mark_wizard_completed.dart       # Update profile flag
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── wizard_state_provider.dart       # Wizard flow state
│       │       │   ├── category_selection_provider.dart # Category checkboxes
│       │       │   └── allocation_provider.dart         # Percentage inputs
│       │       ├── screens/
│       │       │   └── budget_wizard_screen.dart        # Main wizard container
│       │       └── widgets/
│       │           ├── wizard_stepper.dart              # Multi-step indicator
│       │           ├── category_selection_step.dart     # Step 1: Select categories
│       │           ├── budget_amount_step.dart          # Step 2: Set category budgets
│       │           ├── member_allocation_step.dart      # Step 3: Distribute percentages
│       │           └── wizard_summary_step.dart         # Step 4: Review & confirm
│       │
│       ├── personal/                      # MODIFIED: Existing personal budget feature
│       │   ├── presentation/
│       │   │   ├── providers/
│       │   │   │   └── personal_budget_provider.dart    # MODIFY: Include group allocations
│       │   │   ├── screens/
│       │   │   │   └── personal_budget_screen.dart      # MODIFY: Add hierarchical category
│       │   │   └── widgets/
│       │   │       ├── group_spending_category.dart     # NEW: Expandable parent category
│       │   │       └── group_sub_category_item.dart     # NEW: Sub-category row
│       │   └── domain/
│       │       └── usecases/
│       │           └── calculate_personal_budget.dart   # MODIFY: Sum group allocations
│       │
│       └── category/                      # EXISTING: Category budget management
│           └── [existing structure]
│
├── app/
│   └── router/
│       └── app_router.dart                # MODIFY: Add wizard route + guard logic
│
└── shared/
    └── widgets/
        └── percentage_input_field.dart    # NEW: Reusable percentage input (0-100% validation)

test/
├── features/
│   └── budgets/
│       └── wizard/                        # NEW: Wizard tests
│           ├── data/
│           │   ├── models/
│           │   │   └── wizard_state_model_test.dart
│           │   └── repositories/
│           │       └── wizard_repository_impl_test.dart
│           ├── domain/
│           │   └── usecases/
│           │       ├── save_wizard_configuration_test.dart
│           │       └── mark_wizard_completed_test.dart
│           └── presentation/
│               ├── providers/
│               │   ├── wizard_state_provider_test.dart
│               │   └── allocation_provider_test.dart
│               └── widgets/
│                   ├── wizard_stepper_test.dart
│                   ├── category_selection_step_test.dart
│                   ├── budget_amount_step_test.dart
│                   └── member_allocation_step_test.dart
│
└── integration_test/
    └── wizard_flow_test.dart              # NEW: End-to-end wizard completion test

supabase/migrations/
└── 20260109000000_add_wizard_completion_tracking.sql  # NEW: Add budget_wizard_completed field
```

**Structure Decision**: Single-project Flutter app with feature-based Clean Architecture. Wizard is a new sub-feature under existing `lib/features/budgets/` module. Follows established pattern: data layer (models, datasources, repos) → domain layer (entities, use cases) → presentation layer (providers, screens, widgets). Integration with existing personal budget feature through shared providers and modified calculation logic.

## Complexity Tracking

> No Constitution violations detected. This feature follows all established patterns and adds no unjustified complexity. Proceeding without complexity exceptions.

---

## Phase 0: Outline & Research

### Research Questions

The following unknowns require investigation before proceeding to detailed design:

1. **Wizard State Persistence**: How should wizard progress be saved if user exits mid-flow? Options:
   - Hive cache (local only, lost on reinstall)
   - Supabase table (persistent, synced across devices)
   - No persistence (force completion in one session)

2. **Wizard Re-accessibility**: How can administrator modify budget configuration after initial setup?
   - Re-trigger wizard from group settings with pre-populated values
   - Separate "Edit Budget" screen (different UI from wizard)
   - Inline editing in budget management screen

3. **Percentage Allocation UX**: How to make percentage distribution intuitive?
   - Manual input with live total validation
   - Slider with automatic remaining % distribution
   - Pie chart visualization with drag-to-adjust
   - Auto-suggest equal distribution with manual override

4. **Category Budget Defaults**: Should wizard suggest default budget amounts per category?
   - No defaults (admin must enter all amounts)
   - Suggest based on Italian household averages (ISTAT data)
   - Learn from similar groups' configurations (privacy concerns)

5. **Wizard Blocking Behavior**: What happens if admin cancels wizard?
   - Hard block: Cannot access group until wizard completed
   - Soft block: Warning message, can proceed with limited functionality
   - Defer: "Complete later" option with reminder notifications

6. **Monthly Reset Automation**: How to trigger budget resets at month start?
   - Supabase Edge Function (cron trigger at 00:00 on 1st of month)
   - Client-side check on app launch (inconsistent timing)
   - Database trigger on first expense of new month

7. **Historical Data Archival**: How to structure historical budget data for efficient queries?
   - Append-only with effective_date ranges
   - Separate history table with foreign keys
   - Partition by month (PostgreSQL native partitioning)

8. **Hierarchical Category Rendering**: Best approach for expandable "Group Spending" category?
   - Custom ExpansionTile widget
   - ListView with conditional rendering
   - TreeView package (additional dependency)

### Research Tasks

These will be dispatched as autonomous research agents to resolve above questions and document findings in research.md.

---

## Phase 1: Design & Contracts

*Prerequisites: research.md completed with all technical decisions resolved*

### Planned Artifacts

1. **data-model.md**:
   - Extended profiles table schema (budget_wizard_completed flag)
   - Wizard state cache structure (Hive schema)
   - Historical budget data archival pattern
   - Relationships between group_budgets, category_budgets, and member allocations

2. **contracts/** (API contracts as OpenAPI/GraphQL schemas):
   - **wizard_service.yaml**: Wizard data operations
     - GET /wizard/initial-data?group_id={id} → Categories list + members list + existing config
     - POST /wizard/configuration → Save wizard config (categories, budgets, allocations)
     - PATCH /profiles/{id} → Mark wizard completed
   - **budget_calculation.yaml**: Personal budget calculation APIs
     - GET /budgets/personal?user_id={id}&month={YYYY-MM} → Includes group allocations
     - GET /budgets/group-spending-breakdown?user_id={id} → Hierarchical category data

3. **quickstart.md**:
   - Developer setup for wizard feature
   - Testing strategy (unit, widget, integration)
   - Database migration instructions
   - Supabase RLS policy updates

### Agent Context Update

After contracts generation, will run:
```bash
.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude
```

This updates `.claude/` context files with new wizard APIs, data models, and testing patterns for future AI-assisted development.

---

## Phase 2: Task Breakdown

*Note: This phase is NOT executed by `/speckit.plan`. User must run `/speckit.tasks` after approving this plan.*

Task generation will produce dependency-ordered tasks.md covering:
- Database migration creation
- Wizard UI implementation (4 steps)
- Personal budget calculation modification
- Hierarchical category rendering
- Router integration with guard logic
- RLS policy updates
- Comprehensive test suite
- Integration testing

Each task will be marked with:
- `[P]` if parallelizable
- User story reference (US1, US2, US3)
- File paths from source structure above

---

## Next Steps

1. **Approve This Plan**: Review technical approach, structure decisions, and research questions
2. **Phase 0 Execution**: Run research agents to resolve unknowns → generate research.md
3. **Phase 1 Execution**: Generate data-model.md, contracts/, quickstart.md based on research findings
4. **Re-evaluate Constitution**: Verify final design maintains RLS integrity and follows patterns
5. **Run `/speckit.tasks`**: Generate dependency-ordered implementation tasks (Phase 2)

**Estimated Completion**: Phase 0-1 automated execution ~10-15 minutes. Task generation immediate after approval.
