import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:family_expense_tracker/main.dart' as app;

/// Integration test for complete wizard flow.
/// Feature: 001-group-budget-wizard, Task: T025
///
/// Tests the complete user journey:
/// 1. Login as group administrator (first time)
/// 2. Wizard automatically launches
/// 3. Select categories (Cibo, Utenze, Trasporto)
/// 4. Set budget amounts
/// 5. Distribute percentages (must total 100%)
/// 6. Review summary
/// 7. Submit configuration
/// 8. Verify wizard marked as completed
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Budget Wizard Flow Integration Test', () {
    testWidgets('complete wizard flow from login to submission', (WidgetTester tester) async {
      // ========== SETUP ==========
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // ========== STEP 1: LOGIN AS ADMIN ==========
      // Find and tap login button
      expect(find.text('Accedi'), findsOneWidget, reason: 'Login screen should be visible');

      // Enter email
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'admin@test.com',
      );

      // Enter password
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'testpassword',
      );

      // Tap login button
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      // ========== VERIFY: WIZARD LAUNCHES AUTOMATICALLY ==========
      expect(
        find.text('Configurazione Budget Gruppo'),
        findsOneWidget,
        reason: 'Wizard should launch automatically for first-time admin',
      );

      // ========== STEP 2: SELECT CATEGORIES ==========
      // Verify we're on step 1 (Category Selection)
      expect(find.text('Seleziona Categorie'), findsOneWidget);

      // Select "Cibo e Spesa"
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.pump();

      // Select "Utenze"
      await tester.tap(find.text('Utenze'));
      await tester.pump();

      // Select "Trasporto"
      await tester.tap(find.text('Trasporto'));
      await tester.pump();

      // Verify 3 categories selected
      expect(find.textContaining('3 categorie selezionate'), findsOneWidget);

      // Tap "Avanti" to proceed to step 2
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // ========== STEP 3: SET BUDGET AMOUNTS ==========
      // Verify we're on step 2 (Budget Amounts)
      expect(find.text('Imposta Budget'), findsOneWidget);

      // Enter budget for "Cibo e Spesa" (€500.00)
      final ciboField = find.widgetWithText(TextFormField, 'Cibo e Spesa').first;
      await tester.enterText(ciboField, '500,00');
      await tester.pump();

      // Enter budget for "Utenze" (€300.00)
      final utenzeField = find.widgetWithText(TextFormField, 'Utenze').first;
      await tester.enterText(utenzeField, '300,00');
      await tester.pump();

      // Enter budget for "Trasporto" (€200.00)
      final trasportoField = find.widgetWithText(TextFormField, 'Trasporto').first;
      await tester.enterText(trasportoField, '200,00');
      await tester.pump();

      // Verify total budget
      expect(find.textContaining('Totale: 1.000,00 €'), findsOneWidget);

      // Tap "Avanti" to proceed to step 3
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // ========== STEP 4: DISTRIBUTE PERCENTAGES ==========
      // Verify we're on step 3 (Member Allocations)
      expect(find.text('Allocazioni Membri'), findsOneWidget);

      // Use "Dividi Equamente" button for equal distribution
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pumpAndSettle();

      // Verify total is 100%
      expect(find.textContaining('Totale: 100%'), findsOneWidget);

      // Verify success indicator (green checkmark)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap "Avanti" to proceed to step 4 (Summary)
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // ========== STEP 5: REVIEW SUMMARY ==========
      // Verify we're on step 4 (Summary)
      expect(find.text('Riepilogo'), findsOneWidget);

      // Verify selected categories are displayed
      expect(find.text('Cibo e Spesa'), findsOneWidget);
      expect(find.text('Utenze'), findsOneWidget);
      expect(find.text('Trasporto'), findsOneWidget);

      // Verify budget amounts are displayed
      expect(find.textContaining('500,00 €'), findsOneWidget);
      expect(find.textContaining('300,00 €'), findsOneWidget);
      expect(find.textContaining('200,00 €'), findsOneWidget);

      // Verify member allocations are displayed
      expect(find.textContaining('33,33%'), findsWidgets);

      // Verify total budget
      expect(find.textContaining('Totale Budget: 1.000,00 €'), findsOneWidget);

      // ========== STEP 6: SUBMIT CONFIGURATION ==========
      // Tap "Completa" button
      await tester.tap(find.text('Completa'));
      await tester.pumpAndSettle();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for submission to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ========== VERIFY: WIZARD MARKED AS COMPLETED ==========
      // Should navigate to dashboard after successful submission
      expect(
        find.text('Dashboard'),
        findsOneWidget,
        reason: 'Should navigate to dashboard after wizard completion',
      );

      // Wizard should not launch again
      expect(
        find.text('Configurazione Budget Gruppo'),
        findsNothing,
        reason: 'Wizard should not launch again after completion',
      );

      // ========== VERIFY: BUDGETS ARE PERSISTED ==========
      // Navigate to budget page
      await tester.tap(find.byIcon(Icons.account_balance_wallet));
      await tester.pumpAndSettle();

      // Verify configured budgets are visible
      expect(find.text('Cibo e Spesa'), findsOneWidget);
      expect(find.textContaining('500,00'), findsOneWidget);

      // Verify group budget total
      expect(find.textContaining('1.000,00'), findsOneWidget);

      print('✅ Integration test completed successfully');
    });

    testWidgets('wizard should save draft when navigating away', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Login as admin
      await tester.enterText(find.byKey(const Key('email_field')), 'admin@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'testpassword');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      // Wizard launches
      expect(find.text('Configurazione Budget Gruppo'), findsOneWidget);

      // Select some categories
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.pump();
      await tester.tap(find.text('Utenze'));
      await tester.pump();

      // Tap "Annulla" to exit wizard
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      // Confirm cancellation
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();

      // Navigate back to wizard
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configura Budget'));
      await tester.pumpAndSettle();

      // Verify draft is restored
      expect(find.text('Ripristinare la sessione precedente?'), findsOneWidget);

      // Tap "Ripristina"
      await tester.tap(find.text('Ripristina'));
      await tester.pumpAndSettle();

      // Verify previously selected categories are still selected
      final ciboCheckbox = tester.widget<Checkbox>(
        find.ancestor(
          of: find.text('Cibo e Spesa'),
          matching: find.byType(Checkbox),
        ),
      );
      expect(ciboCheckbox.value, isTrue);

      print('✅ Draft persistence test completed successfully');
    });

    testWidgets('wizard should validate before allowing progression', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Login as admin
      await tester.enterText(find.byKey(const Key('email_field')), 'admin@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'testpassword');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      // Wizard launches - try to proceed without selecting categories
      expect(find.text('Configurazione Budget Gruppo'), findsOneWidget);

      // Tap "Avanti" without selecting any categories
      await tester.tap(find.text('Avanti'));
      await tester.pump();

      // Verify error message
      expect(find.text('Seleziona almeno una categoria'), findsOneWidget);

      // Verify we're still on step 1
      expect(find.text('Seleziona Categorie'), findsOneWidget);

      // Now select a category
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.pump();

      // Proceed to step 2
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // Try to proceed without entering budget
      await tester.tap(find.text('Avanti'));
      await tester.pump();

      // Verify error message
      expect(find.text('Inserisci un importo'), findsOneWidget);

      print('✅ Validation test completed successfully');
    });

    testWidgets('wizard should prevent submission with invalid percentage total', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Login and navigate through wizard
      await tester.enterText(find.byKey(const Key('email_field')), 'admin@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'testpassword');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      // Select categories
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // Enter budget
      await tester.enterText(find.byType(TextFormField).first, '500,00');
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();

      // Enter invalid percentages (total = 80%)
      await tester.enterText(find.byType(TextFormField).first, '50');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), '30');
      await tester.pump();

      // Try to proceed
      await tester.tap(find.text('Avanti'));
      await tester.pump();

      // Verify error message
      expect(find.text('Il totale deve essere 100%'), findsOneWidget);

      // Verify "Avanti" button is disabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Avanti'),
      );
      expect(button.onPressed, isNull);

      print('✅ Percentage validation test completed successfully');
    });
  });
}
