# Implementation Plan: Italian Categories and Budget Management System

**Branch**: `004-italian-categories-budgeting` | **Date**: 2026-01-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-italian-categories-budgeting/spec.md`

## Summary

Migration of expense category system from English to Italian with comprehensive monthly budget management. Replaces existing English categories (Food, Utilities, Transport, etc.) with Italian equivalents (Spesa, Bollette, Trasporti, etc.), marks existing expenses as orphaned for re-categorization, and introduces per-user budget tracking with monthly reset cycles. Users can set budgets per category, receive prompts when using new categories, and view budget status on dashboard and expense details. Built on existing Flutter/Supabase architecture.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Flutter, Supabase (Auth, Database, Storage), fl_chart, Riverpod
**Storage**: Supabase PostgreSQL (cloud) + Drift (local SQLite cache)
**Testing**: flutter_test, integration_test, mockito
**Target Platform**: Android 8.0+ (API 26+), iOS potential via Flutter
**Project Type**: Mobile + API (Flutter app + Supabase backend)
**Performance Goals**: Budget calculations <2s, dashboard load <3s, virgin category prompt <1s
**Constraints**: Monthly budget cycles (calendar month boundaries), EUR currency, Italian language
**Scale/Scope**: Support existing ~100 users, groups up to 10 members, ~1000 expenses per group, 10+ categories per group

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Initial Check (Phase 0)**: ✅ PASSED
- ✅ Clear separation of concerns (UI/Business Logic/Data)
- ✅ Testable architecture with dependency injection
- ✅ Secure authentication and data handling
- ✅ Simple initial implementation (YAGNI principles)

**Post-Design Check (Phase 1)**: ✅ PASSED
- ✅ **Data Migration Strategy**: Orphaning approach preserves data integrity while enabling clean Italian migration
- ✅ **Architecture Consistency**: Follows existing patterns (budget tables with month/year columns, RPC functions, Riverpod providers)
- ✅ **Performance**: All queries indexed and optimized for target scale (1000 expenses, 100 users)
- ✅ **Security**: RLS policies enforce group membership and admin-only budget management
- ✅ **Testability**: Clear domain/data layer separation enables unit and integration testing

## Project Structure

### Documentation (this feature)

```text
specs/004-italian-categories-budgeting/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (below)
├── data-model.md        # Phase 1 output (below)
├── quickstart.md        # Phase 1 output (below)
└── contracts/           # Phase 1 output (API specs)
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── categories/                       # NEW: Italian category management
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── category_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── category_model.dart
│   │   │   │   └── user_category_usage_model.dart
│   │   │   └── repositories/
│   │   │       └── category_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── category_entity.dart
│   │   │   │   └── user_category_usage_entity.dart
│   │   │   └── repositories/
│   │   │       └── category_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── category_provider.dart
│   │       ├── screens/
│   │       │   ├── category_management_screen.dart
│   │       │   └── orphaned_expenses_screen.dart
│   │       └── widgets/
│   │           ├── category_budget_card.dart
│   │           └── budget_prompt_dialog.dart
│   │
│   ├── budgets/                          # ENHANCED: Add monthly budget logic
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── budget_remote_datasource.dart  # MODIFY: Add monthly cycle
│   │   │   ├── models/
│   │   │   │   ├── category_budget_model.dart     # NEW
│   │   │   │   └── monthly_budget_stats_model.dart # NEW
│   │   │   └── repositories/
│   │   │       └── budget_repository_impl.dart    # MODIFY
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── category_budget_entity.dart    # NEW
│   │   │   │   └── monthly_budget_stats_entity.dart # NEW
│   │   │   └── repositories/
│   │   │       └── budget_repository.dart         # MODIFY
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── budget_provider.dart           # MODIFY: Add category budgets
│   │       └── widgets/
│   │           ├── budget_overview_card.dart      # MODIFY: Show monthly data
│   │           └── category_budget_indicator.dart # NEW
│   │
│   ├── dashboard/                        # ENHANCED: Add budget visualization
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── dashboard_screen.dart          # MODIFY: Add budget widgets
│   │       └── widgets/
│   │           ├── budget_summary_widget.dart     # NEW
│   │           └── category_budget_list_widget.dart # NEW
│   │
│   └── expenses/                         # ENHANCED: Add budget context, orphan handling
│       ├── data/
│       │   ├── datasources/
│       │   │   └── expense_remote_datasource.dart # MODIFY: Handle orphaned
│       │   └── repositories/
│       │       └── expense_repository_impl.dart   # MODIFY
│       ├── domain/
│       │   └── repositories/
│       │       └── expense_repository.dart        # MODIFY
│       └── presentation/
│           ├── screens/
│           │   ├── expense_detail_screen.dart     # MODIFY: Add budget context
│           │   └── add_expense_screen.dart        # MODIFY: Add virgin prompt
│           └── widgets/
│               └── budget_context_widget.dart     # NEW
│
└── core/
    ├── utils/
    │   ├── budget_calculator.dart                 # MODIFY: Add monthly logic
    │   └── category_migrator.dart                 # NEW: Delete English, mark orphaned
    └── config/
        └── default_italian_categories.dart        # NEW: Seed data

supabase/migrations/
└── 025_italian_categories_budgeting.sql          # NEW: DB schema changes

test/
├── features/
│   ├── categories/                               # NEW: Category tests
│   │   ├── unit/
│   │   └── widget/
│   └── budgets/                                  # ENHANCED: Budget tests
│       ├── unit/
│       └── widget/
└── integration/
    └── budget_monthly_cycle_test.dart            # NEW
```

**Structure Decision**: Feature-first architecture maintained. New `categories/` feature added for Italian category management. Existing `budgets/` and `expenses/` features enhanced with monthly budget logic, virgin category prompts, and budget context displays.

## Complexity Tracking

| Consideration | Justification | Alternative Rejected |
|---------------|---------------|----------------------|
| Hard delete + orphaning strategy | User requested clean break from English categories (clarification Q2: option D). Preserves expense data while forcing intentional re-categorization. | Migration mapping (A/B) rejected per user preference for fresh start |
| Per-user virgin tracking | Family app context requires individual budget preferences (clarification Q5). Each member has unique spending patterns. | System-wide tracking (B) would cause prompt fatigue after first user |
| Monthly auto-reset | Standard family budgeting pattern (clarification Q1). Aligns with salary cycles and monthly bills. | Annual/rolling windows add complexity without clear user benefit |

---

## Planning Phase Complete ✅

**Date Completed**: 2026-01-04
**Planning Command**: `/speckit.plan`

### Deliverables Created

1. ✅ **plan.md** (this file)
   - Technical context and architecture
   - Project structure with file-level detail
   - Complexity justifications

2. ✅ **research.md**
   - Database schema decisions for monthly budgets
   - Virgin category tracking patterns
   - Bulk re-categorization UI/UX
   - Monthly reset strategy

3. ✅ **data-model.md**
   - Entity definitions (CategoryBudget, UserCategoryUsage)
   - Relationship diagrams
   - Migration strategy
   - State transitions

4. ✅ **contracts/category_budgets_api.md**
   - REST API endpoints
   - RPC function specifications
   - Request/response examples
   - RLS policies

5. ✅ **quickstart.md**
   - Developer onboarding guide
   - 6-phase implementation roadmap
   - Code patterns and examples
   - Common pitfalls and debugging tips

### Key Decisions Documented

| Decision Area | Choice | Rationale |
|---------------|--------|-----------|
| **Budget Period** | Monthly with auto-reset | Aligns with user salary cycles (clarification Q1) |
| **Category Migration** | Delete English, orphan expenses | User requested clean break (clarification Q2) |
| **Overall Budget** | Sum of category budgets | Simpler than separate tracking (clarification Q3) |
| **Default Categories** | 10 Italian categories pre-populated | Reduces setup friction (clarification Q4) |
| **Virgin Tracking** | Per-user junction table | Family app needs individual preferences (clarification Q5) |

### Next Steps

**Ready for Task Generation** (`/speckit.tasks`)

The planning phase is complete. Next command should be:
```
/speckit.tasks
```

This will generate a dependency-ordered task list based on the plan and data model defined above.

**Estimated Implementation Time**: 10-12 days (based on 6-phase roadmap in quickstart.md)

**Critical Path**:
1. Database migrations (1 day)
2. Domain entities & data layer (3 days)
3. Presentation layer & UI (3 days)
4. State management (1 day)
5. Integration & testing (2 days)

