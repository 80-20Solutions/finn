import 'package:fin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration test for User Story 2: Member Views Group Budget in Personal Dashboard
/// Feature: 001-group-budget-wizard
///
/// Test Scenario:
/// 1. After admin completes wizard
/// 2. Login as group member
/// 3. Navigate to personal budget view
/// 4. Verify "Spesa Gruppo" parent category shows total allocated/spent
/// 5. Expand to see sub-categories (Cibo, Utenze, etc.)
/// 6. Verify read-only group status displayed
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Member Budget View - User Story 2', () {
    testWidgets(
      'Member can view hierarchical group budget with expandable subcategories',
      (tester) async {
        // Step 1: Launch app
        await app.main();
        await tester.pumpAndSettle();

        // Step 2: Login as group member (not admin)
        await tester.enterText(
          find.byKey(const Key('email_field')),
          'member@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 3: Navigate to personal budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 4: Verify "Spesa Gruppo" parent category exists
        expect(find.text('Spesa Gruppo'), findsOneWidget);

        // Step 5: Verify total allocated and spent amounts are displayed
        expect(find.text('350,00 €'), findsOneWidget); // Allocated
        expect(find.text('295,00 €'), findsOneWidget); // Spent

        // Step 6: Verify percentage progress is shown
        expect(find.text('84%'), findsOneWidget);

        // Step 7: Verify progress indicator is displayed
        expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));

        // Step 8: Verify read-only indicator (lock icon)
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        // Step 9: Initially, subcategories should be collapsed
        expect(find.text('Cibo'), findsNothing);
        expect(find.text('Utenze'), findsNothing);

        // Step 10: Tap to expand "Spesa Gruppo" category
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        // Step 11: Verify subcategories are now visible
        expect(find.text('Cibo'), findsOneWidget);
        expect(find.text('Utenze'), findsOneWidget);
        expect(find.text('Trasporto'), findsOneWidget);

        // Step 12: Verify subcategory details (Cibo)
        expect(find.text('200,00 €'), findsOneWidget); // Cibo allocated
        expect(find.text('150,00 €'), findsOneWidget); // Cibo spent

        // Step 13: Verify subcategory icons are displayed
        expect(find.byIcon(Icons.restaurant), findsOneWidget); // Cibo
        expect(find.byIcon(Icons.power), findsOneWidget); // Utenze

        // Step 14: Verify remaining amounts are shown
        expect(find.textContaining('Restante:'), findsAtLeastNWidgets(1));

        // Step 15: Attempt to tap subcategory (should be read-only)
        await tester.tap(find.text('Cibo'));
        await tester.pumpAndSettle();

        // Step 16: Verify no edit dialog appeared (read-only)
        expect(find.text('Modifica Budget'), findsNothing);

        // Step 17: Collapse "Spesa Gruppo" category
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        // Step 18: Verify subcategories are collapsed again
        expect(find.text('Cibo'), findsNothing);
        expect(find.text('Utenze'), findsNothing);
      },
    );

    testWidgets(
      'Member can see zero spending when no group expenses recorded',
      (tester) async {
        // Step 1: Launch app and login
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'newmember@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 2: Navigate to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 3: Verify "Spesa Gruppo" exists
        expect(find.text('Spesa Gruppo'), findsOneWidget);

        // Step 4: Verify allocated amount is shown but spent is 0
        expect(find.text('350,00 €'), findsOneWidget); // Allocated
        expect(find.text('0,00 €'), findsOneWidget); // Spent (zero)

        // Step 5: Verify progress is 0%
        expect(find.text('0%'), findsOneWidget);

        // Step 6: Expand and verify all subcategories show 0 spent
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        expect(find.text('0,00 €'), findsAtLeastNWidgets(3)); // Multiple zeros
      },
    );

    testWidgets(
      'Member can see updated spending after group expense is added',
      (tester) async {
        // Step 1: Launch app and login
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'member@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 2: Navigate to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 3: Capture initial spent amount
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        expect(find.text('Cibo'), findsOneWidget);
        final initialSpentText = find.text('150,00 €');
        expect(initialSpentText, findsOneWidget);

        // Step 4: Navigate to add expense screen
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Step 5: Add new group expense (€50 for Cibo)
        await tester.enterText(
          find.byKey(const Key('expense_description')),
          'Spesa supermercato',
        );
        await tester.enterText(
          find.byKey(const Key('expense_amount')),
          '50,00',
        );
        await tester.tap(find.text('Cibo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gruppo')); // Mark as group expense
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('save_expense_button')));
        await tester.pumpAndSettle();

        // Step 6: Navigate back to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 7: Expand "Spesa Gruppo" again
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        // Step 8: Verify spending updated (150 + 50 = 200)
        expect(find.text('200,00 €'), findsOneWidget);

        // Step 9: Verify percentage updated (200 / 200 = 100%)
        expect(find.text('100%'), findsOneWidget);
      },
    );

    testWidgets(
      'Member budget view shows correct color coding for budget status',
      (tester) async {
        // Step 1: Launch app and login
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'member@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 2: Navigate to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 3: Expand "Spesa Gruppo"
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        // Step 4: Find progress indicators
        final progressIndicators = find.byType(LinearProgressIndicator);
        expect(progressIndicators, findsAtLeastNWidgets(1));

        // Step 5: Verify color coding
        // Under 75% = green
        // 75-100% = orange
        // Over 100% = red
        final firstIndicator = tester.widget<LinearProgressIndicator>(
          progressIndicators.first,
        );

        // 150/200 = 75% (should be green or orange depending on threshold)
        expect(
          firstIndicator.color,
          anyOf(Colors.green, Colors.orange),
        );
      },
    );

    testWidgets(
      'Member cannot edit group budget allocations (read-only)',
      (tester) async {
        // Step 1: Launch app and login as member
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'member@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 2: Navigate to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 3: Expand "Spesa Gruppo"
        await tester.tap(find.text('Spesa Gruppo'));
        await tester.pumpAndSettle();

        // Step 4: Verify no edit buttons visible on subcategories
        expect(find.byIcon(Icons.edit), findsNothing);

        // Step 5: Long press on subcategory (attempt edit)
        await tester.longPress(find.text('Cibo'));
        await tester.pumpAndSettle();

        // Step 6: Verify no edit dialog appeared
        expect(find.text('Modifica Budget'), findsNothing);
        expect(find.byKey(const Key('edit_budget_dialog')), findsNothing);

        // Step 7: Verify lock icon is present (read-only indicator)
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      },
    );
  });
}
