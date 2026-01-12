# Quick Start Guide: Group Budget Setup Wizard

**Feature**: 001-group-budget-wizard
**Date**: 2026-01-09
**Target Audience**: Developers implementing this feature

---

## Feature Overview

The **Group Budget Setup Wizard** is a mandatory, multi-step configuration flow that guides family group administrators through initial budget setup. This feature is critical for the app's core value proposition: helping Italian families manage shared household expenses transparently.

**What it does**:
- 4-step wizard: Category selection → Budget amounts → Member percentages → Confirmation
- Hard-blocks admin users until completed (cannot access home screen)
- Saves draft progress to Hive cache (24-hour expiry)
- Creates group budgets and percentage-based personal budgets for all members
- Re-accessible from group settings for reconfiguration

**Why it matters**:
- Ensures all groups have consistent budget configuration before first use
- Eliminates "cold start" problem (members without budgets cannot track spending effectively)
- Enforces business rule: group spending requires pre-configured budgets (legacy constraint per spec.md)

**User Journey**:
1. Admin creates/joins group → Redirected to wizard (router guard)
2. Completes 4 steps → Submits configuration → Profile marked as `budget_wizard_completed = true`
3. Can access app normally → Can reconfigure later from group settings

---

## Prerequisites

### Software Requirements

| Tool | Minimum Version | Purpose | Installation Link |
|------|----------------|---------|------------------|
| Flutter SDK | 3.0.0+ | App framework | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 2.17.0+ | Included with Flutter | N/A |
| Supabase CLI | 1.11.0+ | Database migrations | [supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli) |
| Git | 2.0+ | Version control | [git-scm.com](https://git-scm.com/) |
| VS Code | Latest | IDE (optional) | [code.visualstudio.com](https://code.visualstudio.com/) |

### Project Setup

```bash
# Clone repository
git clone <repository-url>
cd Fin

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor

# Login to Supabase (required for migrations)
supabase login

# Link to your Supabase project
supabase link --project-ref <your-project-ref>

# Start local Supabase (optional for local development)
supabase start
```

### Required Access

- **Supabase Project**: Admin access to production/staging database
- **Test Accounts**: At least 1 admin user and 2 member users in a test group
- **Storage Bucket**: `receipts` bucket created (existing setup)

---

## Database Setup

### 1. Create Migration File

Run this command from repository root:

```bash
# Create new migration file
supabase migration new add_wizard_completion_tracking

# This creates: supabase/migrations/<timestamp>_add_wizard_completion_tracking.sql
```

### 2. Add Migration SQL

Open the newly created migration file and add:

```sql
-- Migration: Add wizard completion tracking to profiles table
-- Feature: Group Budget Setup Wizard (001)

-- Add budget_wizard_completed column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS budget_wizard_completed BOOLEAN NOT NULL DEFAULT FALSE;

-- Create index for router guard checks (frequent query on login)
CREATE INDEX IF NOT EXISTS idx_profiles_wizard_completed
  ON public.profiles(id, budget_wizard_completed)
  WHERE is_group_admin = true;

-- Add column comment
COMMENT ON COLUMN public.profiles.budget_wizard_completed IS
  'Tracks if group admin has completed mandatory budget setup wizard';
```

**What this does**:
- Adds boolean flag to track wizard completion per admin user
- Index optimizes login flow (avoids full table scan for router guard check)
- `DEFAULT FALSE` ensures existing admins are prompted on first login

### 3. Apply Migration

```bash
# Apply to local database (if using supabase start)
supabase db reset

# OR apply to remote database (staging/production)
supabase db push

# Verify migration applied successfully
supabase migration list
```

**Expected Output**:
```
Local migrations
┌─────────────────────┬─────────────────────────────────────────┬──────────┐
│ Version             │ Name                                    │ Status   │
├─────────────────────┼─────────────────────────────────────────┼──────────┤
│ 20260109123456      │ add_wizard_completion_tracking          │ Applied  │
└─────────────────────┴─────────────────────────────────────────┴──────────┘
```

### 4. Verify Schema Changes

```sql
-- Run this query in Supabase SQL Editor
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name = 'budget_wizard_completed';

-- Expected result:
-- column_name              | data_type | column_default
-- -------------------------|-----------|-----------------
-- budget_wizard_completed | boolean   | false
```

### 5. RLS Policy Updates (No Changes Required)

Existing RLS policies on `profiles` table already cover this column:
- Admins can read/update their own profile ✅
- Members can read profiles in their group ✅
- No new policies needed for `budget_wizard_completed` field

---

## Development Workflow

### 1. Feature Branch Setup

```bash
# Create feature branch from main
git checkout -b feature/001-group-budget-wizard

# Verify you're on correct branch
git branch --show-current
```

### 2. File Structure Overview

Refer to `plan.md` section 8 (Source Tree) for complete structure. Key directories:

```
lib/features/budgets/wizard/
├── domain/
│   ├── entities/
│   │   ├── wizard_configuration.dart      # Core domain entity
│   │   ├── budget_allocation.dart
│   │   └── category_selection.dart
│   ├── repositories/
│   │   └── wizard_repository.dart         # Abstract repository
│   └── usecases/
│       ├── save_wizard_configuration.dart
│       ├── load_wizard_draft.dart
│       └── validate_allocations.dart
├── data/
│   ├── models/
│   │   ├── wizard_state_model.dart        # JSON serialization
│   │   └── ...
│   ├── datasources/
│   │   ├── wizard_local_datasource.dart   # Hive cache
│   │   └── wizard_remote_datasource.dart  # Supabase API
│   └── repositories/
│       └── wizard_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── wizard_provider.dart           # Riverpod state
    ├── screens/
    │   └── wizard_screen.dart
    └── widgets/
        ├── category_selection_step.dart   # Step 1
        ├── budget_input_step.dart         # Step 2
        ├── member_allocation_step.dart    # Step 3
        └── confirmation_step.dart         # Step 4
```

### 3. Hive Cache Initialization

Add wizard cache box registration in `main.dart`:

```dart
// In main() function, after existing Hive.initFlutter()
await Hive.openBox<String>('wizard_cache');  // Add this line

// Existing code:
// await Hive.openBox<String>('dashboard_cache');
```

### 4. Router Guard Implementation

Add wizard check in `app_router.dart` (using go_router):

```dart
redirect: (context, state) {
  // Existing auth checks...

  final user = ref.read(authProvider).user;
  if (user != null && user.isGroupAdmin && !user.budgetWizardCompleted) {
    // Prevent navigation if wizard not completed
    if (state.path != '/wizard') {
      return '/wizard';
    }
  }

  return null;  // Allow navigation
}
```

### 5. Run App Locally

```bash
# Run on emulator/device
flutter run

# OR run with specific flavor (if configured)
flutter run --flavor dev

# Hot reload after code changes: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### 6. Testing the Wizard Flow

**Manual Testing Steps**:

1. **Login as Admin** (user with `is_group_admin = true`)
   - Should be immediately redirected to `/wizard` route
   - Cannot navigate back to home screen

2. **Step 1: Select Categories**
   - Select at least 1 category (e.g., "Cibo e Spesa", "Trasporti")
   - Verify "Avanti" button only enabled when ≥1 category selected

3. **Step 2: Enter Budget Amounts**
   - Enter amounts for each selected category (e.g., €500, €300)
   - Verify validation: must be > €0, max €999,999.99
   - Verify total group budget displayed at bottom

4. **Step 3: Allocate Member Percentages**
   - Enter percentages for each group member
   - Test "Dividi Equamente" button (should auto-calculate equal split)
   - Verify live total display shows red text if ≠ 100%
   - Verify "Avanti" button disabled until total = 100%

5. **Step 4: Confirmation**
   - Review summary of all selections
   - Tap "Conferma" → Should save to database
   - Should redirect to home screen

6. **Verify Database Changes**
   ```sql
   -- Check wizard completion flag
   SELECT id, display_name, budget_wizard_completed
   FROM profiles
   WHERE is_group_admin = true;

   -- Check created budgets
   SELECT cb.id, ec.name_it, cb.amount, cb.year, cb.month
   FROM category_budgets cb
   JOIN expense_categories ec ON cb.category_id = ec.id
   WHERE cb.group_id = '<your-test-group-id>'
   ORDER BY cb.created_at DESC;
   ```

7. **Test Draft Saving**
   - Complete steps 1-2, then force-close app
   - Reopen app → Login as same admin
   - Should see dialog: "Hai una bozza salvata. Vuoi continuare?"
   - Verify previously entered data is restored

---

## Testing Strategy

### Unit Tests

**Priority**: High (run on every commit)

**Test Files**:
```
test/features/budgets/wizard/
├── domain/
│   ├── entities/
│   │   └── wizard_configuration_test.dart
│   └── usecases/
│       ├── save_wizard_configuration_test.dart
│       └── validate_allocations_test.dart
├── data/
│   ├── models/
│   │   └── wizard_state_model_test.dart
│   └── repositories/
│       └── wizard_repository_impl_test.dart
└── presentation/
    └── providers/
        └── wizard_provider_test.dart
```

**Sample Unit Test** (validation logic):
```dart
// test/features/budgets/wizard/domain/usecases/validate_allocations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fin/features/budgets/wizard/domain/usecases/validate_allocations.dart';

void main() {
  group('ValidateAllocations', () {
    late ValidateAllocations useCase;

    setUp(() {
      useCase = ValidateAllocations();
    });

    test('should return success when percentages sum to 100', () {
      final allocations = {
        'user1': 50.00,
        'user2': 30.00,
        'user3': 20.00,
      };

      final result = useCase(allocations);

      expect(result.isSuccess, true);
    });

    test('should return failure when percentages sum to 99', () {
      final allocations = {
        'user1': 50.00,
        'user2': 30.00,
        'user3': 19.00,  // Total = 99%
      };

      final result = useCase(allocations);

      expect(result.isFailure, true);
      expect(result.error, contains('Il totale deve essere 100%'));
    });

    test('should allow 0.01% tolerance for floating-point rounding', () {
      final allocations = {
        'user1': 33.33,
        'user2': 33.33,
        'user3': 33.33,  // Total = 99.99% (within tolerance)
      };

      final result = useCase(allocations);

      expect(result.isSuccess, true);
    });
  });
}
```

**Run Unit Tests**:
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/budgets/wizard/domain/entities/wizard_configuration_test.dart

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### Widget Tests

**Priority**: High (run before PR merge)

**Test Files**:
```
test/features/budgets/wizard/presentation/widgets/
├── category_selection_step_test.dart
├── budget_input_step_test.dart
├── member_allocation_step_test.dart
└── confirmation_step_test.dart
```

**Sample Widget Test** (percentage input):
```dart
// test/features/budgets/wizard/presentation/widgets/member_allocation_step_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fin/features/budgets/wizard/presentation/widgets/member_allocation_step.dart';

void main() {
  group('MemberAllocationStep', () {
    testWidgets('should show red total when percentages != 100', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberAllocationStep(
              members: [
                Member(id: '1', name: 'Mario'),
                Member(id: '2', name: 'Anna'),
              ],
              allocations: {'1': 50.0, '2': 30.0},  // Total = 80%
              onAllocationsChanged: (_) {},
            ),
          ),
        ),
      );

      // Find total display text
      final totalText = find.text('Totale: 80.0% (mancano 20.0%)');
      expect(totalText, findsOneWidget);

      // Verify text is red
      final textWidget = tester.widget<Text>(totalText);
      expect((textWidget.style?.color), Colors.red);
    });

    testWidgets('should call "Dividi Equamente" correctly', (tester) async {
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberAllocationStep(
              members: [
                Member(id: '1', name: 'Mario'),
                Member(id: '2', name: 'Anna'),
              ],
              allocations: {},
              onAllocationsChanged: (allocations) {
                capturedAllocations = allocations;
              },
            ),
          ),
        ),
      );

      // Tap "Dividi Equamente" button
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pump();

      // Verify equal split: 50% each
      expect(capturedAllocations, {
        '1': 50.00,
        '2': 50.00,
      });
    });
  });
}
```

**Run Widget Tests**:
```bash
# Run all widget tests
flutter test test/features/budgets/wizard/presentation/widgets/

# Run with verbose output
flutter test --reporter expanded
```

---

### Integration Tests

**Priority**: Medium (run on staging deployment)

**Test Files**:
```
integration_test/
└── wizard_flow_test.dart
```

**Sample Integration Test** (full wizard flow):
```dart
// integration_test/wizard_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wizard Flow E2E', () {
    testWidgets('admin completes full wizard successfully', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Login as admin (assumes test account exists)
      await tester.enterText(find.byKey(Key('email_field')), 'admin@test.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Should redirect to wizard
      expect(find.text('Configura Budget Gruppo'), findsOneWidget);

      // Step 1: Select categories
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.tap(find.text('Trasporti'));
      await tester.tap(find.byKey(Key('next_button')));
      await tester.pumpAndSettle();

      // Step 2: Enter budget amounts
      await tester.enterText(find.byKey(Key('budget_input_0')), '500');
      await tester.enterText(find.byKey(Key('budget_input_1')), '300');
      await tester.tap(find.byKey(Key('next_button')));
      await tester.pumpAndSettle();

      // Step 3: Allocate percentages (use "Dividi Equamente")
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pump();
      await tester.tap(find.byKey(Key('next_button')));
      await tester.pumpAndSettle();

      // Step 4: Confirm
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should redirect to home screen
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Configura Budget Gruppo'), findsNothing);
    });
  });
}
```

**Run Integration Tests**:
```bash
# Run on connected device/emulator
flutter test integration_test/wizard_flow_test.dart

# Run with specific flavor
flutter test integration_test/wizard_flow_test.dart --flavor staging
```

---

## Italian Localization

All user-facing strings must be in Italian. Add these keys to `lib/core/config/strings_it.dart`:

```dart
// lib/core/config/strings_it.dart
class StringsIt {
  // Existing strings...

  // Wizard - General
  static const String wizardTitle = 'Configura Budget Gruppo';
  static const String wizardSubtitle = 'Imposta il budget mensile del tuo gruppo';
  static const String nextButton = 'Avanti';
  static const String backButton = 'Indietro';
  static const String confirmButton = 'Conferma';
  static const String cancelButton = 'Annulla';

  // Wizard - Step 1: Category Selection
  static const String step1Title = 'Seleziona Categorie';
  static const String step1Subtitle = 'Scegli le categorie da includere nel budget';
  static const String step1MinError = 'Devi selezionare almeno una categoria';
  static const String step1MaxError = 'Puoi selezionare massimo 20 categorie';

  // Wizard - Step 2: Budget Amounts
  static const String step2Title = 'Assegna Budget';
  static const String step2Subtitle = 'Imposta l\'importo per ogni categoria';
  static const String budgetInputHint = 'es. 500';
  static const String budgetInputLabel = 'Budget mensile (€)';
  static const String budgetTotalLabel = 'Budget Totale Gruppo';
  static const String budgetAmountError = 'L\'importo deve essere maggiore di zero';
  static const String budgetMaxError = 'Importo troppo elevato (max €999.999,99)';
  static const String budgetRequiredError = 'Inserisci un importo';

  // Wizard - Step 3: Member Allocations
  static const String step3Title = 'Ripartizione Membri';
  static const String step3Subtitle = 'Assegna la percentuale di budget per ogni membro';
  static const String percentageInputLabel = 'Percentuale (%)';
  static const String splitEquallyButton = 'Dividi Equamente';
  static const String percentageTotalLabel = 'Totale';
  static const String percentageMissingLabel = 'mancano';
  static const String percentageTotalError = 'Il totale deve essere 100%';
  static const String percentageRangeError = 'La percentuale deve essere tra 0 e 100';
  static const String percentageDecimalError = 'Usa massimo 2 decimali (es. 33.33)';

  // Wizard - Step 4: Confirmation
  static const String step4Title = 'Riepilogo';
  static const String step4Subtitle = 'Verifica e conferma la configurazione';
  static const String confirmationCategoriesLabel = 'Categorie Selezionate';
  static const String confirmationBudgetLabel = 'Budget per Categoria';
  static const String confirmationMembersLabel = 'Ripartizione Membri';
  static const String confirmationTotalLabel = 'Budget Mensile Totale';

  // Wizard - Save Draft Dialog
  static const String saveDraftTitle = 'Salvare il Progresso?';
  static const String saveDraftMessage = 'Potrai continuare entro 24 ore.';
  static const String saveDraftButton = 'Salva Bozza';
  static const String exitWithoutSaveButton = 'Esci Senza Salvare';

  // Wizard - Resume Draft Dialog
  static const String resumeDraftTitle = 'Bozza Trovata';
  static const String resumeDraftMessage = 'Hai una bozza salvata. Vuoi continuare?';
  static const String resumeDraftButton = 'Continua';
  static const String startNewButton = 'Inizia da Capo';

  // Wizard - Success/Error Messages
  static const String wizardSuccessMessage = 'Configurazione budget salvata con successo';
  static const String wizardErrorMessage = 'Si è verificato un errore. Riprova.';
  static const String wizardNetworkError = 'Errore di connessione. Controlla la tua rete.';

  // Group Spending (for personal budget view)
  static const String groupSpending = 'Spesa Gruppo';
  static const String yourShare = 'La Tua Quota';
  static const String groupStatus = 'Stato Gruppo (Sola Lettura)';
  static const String groupBadgeLabel = 'G';

  // Reconfigure Button (in group settings)
  static const String reconfigureBudgetButton = 'Riconfigura Budget';
  static const String reconfigureConfirmTitle = 'Modificare Budget Esistente?';
  static const String reconfigureConfirmMessage = 'Modificherai il budget esistente. Continuare?';
}
```

**Usage in Widgets**:
```dart
// Example: Using strings in wizard step
Text(StringsIt.step1Title),  // "Seleziona Categorie"
```

---

## File Structure Reference

Complete file structure is documented in `plan.md` section 8. Key highlights:

```
lib/features/budgets/wizard/
├── domain/                     # Business logic (no Flutter dependencies)
│   ├── entities/              # Pure Dart classes
│   ├── repositories/          # Abstract interfaces
│   └── usecases/              # Business operations
├── data/                      # Data access layer
│   ├── models/               # JSON serialization
│   ├── datasources/          # Hive + Supabase
│   └── repositories/         # Repository implementations
└── presentation/              # UI layer
    ├── providers/            # Riverpod state management
    ├── screens/              # Full-screen wizard
    └── widgets/              # Reusable step widgets
```

**Implementation Order** (recommended):
1. Domain entities → 2. Data models → 3. Data sources → 4. Repositories → 5. Use cases → 6. Providers → 7. Widgets → 8. Screens

---

## Common Issues & Troubleshooting

### Issue: "Table 'profiles' has no column 'budget_wizard_completed'"

**Cause**: Migration not applied to database

**Solution**:
```bash
# Check migration status
supabase migration list

# Apply missing migrations
supabase db push

# Verify column exists
supabase db execute "SELECT budget_wizard_completed FROM profiles LIMIT 1;"
```

---

### Issue: "Hive box 'wizard_cache' not found"

**Cause**: Hive box not initialized in `main.dart`

**Solution**:
```dart
// Add to main() before runApp()
await Hive.openBox<String>('wizard_cache');
```

---

### Issue: "Percentages sum to 99.99%, validation fails"

**Cause**: Floating-point precision error

**Solution**: Check validation tolerance in `ValidateAllocations` use case:
```dart
// Should allow ±0.01% tolerance
if ((total - 100.0).abs() <= 0.01) {
  return ValidationResult.success();
}
```

---

### Issue: "Router keeps redirecting to wizard after completion"

**Cause**: Profile not updated or cache stale

**Solution**:
```dart
// Verify profile update in WizardRepository:
await _remoteDataSource.updateProfile(
  userId: adminUserId,
  data: {'budget_wizard_completed': true},
);

// Clear auth cache after wizard completion
ref.invalidate(authProvider);
```

---

### Issue: "Integration test fails with timeout"

**Cause**: Async operations not awaited properly

**Solution**:
```dart
// Use pumpAndSettle() for async UI updates
await tester.tap(find.text('Conferma'));
await tester.pumpAndSettle(Duration(seconds: 5));  // Wait for API call
```

---

## Performance Considerations

| Operation | Target Time | Notes |
|-----------|-------------|-------|
| Wizard screen load | < 500ms | Hive cache read + Supabase query (categories + members) |
| Step navigation | < 100ms | Local state update only |
| Draft save | < 200ms | Hive cache write (local) |
| Final submission | < 2s | Batch insert to `category_budgets` table (5-10 records typical) |
| Router guard check | < 50ms | Indexed query on `profiles.budget_wizard_completed` |

**Optimization Tips**:
- Use `const` constructors for stateless widgets
- Implement `shouldRebuild` in Riverpod providers to avoid unnecessary rebuilds
- Batch Supabase inserts using `.upsert()` with array parameter
- Index `profiles(id, budget_wizard_completed)` for fast login checks

---

## Next Steps After Implementation

1. **Code Review**: Submit PR to `001-family-expense-tracker` branch
2. **QA Testing**: Provide test account credentials to QA team
3. **Staging Deployment**: Deploy to staging environment for user acceptance testing
4. **Documentation**: Update user-facing help docs (if any)
5. **Analytics**: Add event tracking for wizard completion rate (optional)
6. **Production Deploy**: Merge to main and deploy after sign-off

---

## References

### Internal Documentation
- **Specification**: `specs/001-group-budget-wizard/spec.md`
- **Technical Plan**: `specs/001-group-budget-wizard/plan.md`
- **Research Decisions**: `specs/001-group-budget-wizard/research.md`
- **Data Model**: `specs/001-group-budget-wizard/data-model.md`
- **API Contracts**: `specs/001-group-budget-wizard/contracts/*.yaml`

### Codebase Patterns
- **Entity/Model Pattern**: `lib/features/groups/domain/entities/member_entity.dart`
- **Hive Caching**: `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart`
- **Riverpod State**: `lib/features/expenses/presentation/providers/expense_provider.dart`
- **Wizard UI Pattern**: `lib/features/expenses/presentation/widgets/category_selector.dart`

### External Resources
- **Flutter Clean Architecture**: [resocoder.com/flutter-clean-architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- **Riverpod Best Practices**: [riverpod.dev/docs/concepts/reading](https://riverpod.dev/docs/concepts/reading)
- **Hive Documentation**: [docs.hivedb.dev](https://docs.hivedb.dev/)
- **Supabase Flutter Guide**: [supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)

---

## Support

For questions or issues during implementation:
- **Technical Questions**: Review `plan.md` section 6 (Architecture Decisions)
- **Database Issues**: Check Supabase logs via `supabase functions logs`
- **State Management**: Refer to existing Riverpod providers in `lib/features/*/presentation/providers/`

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-09 | 1.0 | Initial quickstart guide |
