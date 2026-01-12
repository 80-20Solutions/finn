import 'package:fin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration test for User Story 3: Personal Budget Calculation Includes Group Allocation
/// Feature: 001-group-budget-wizard
///
/// Test Scenario:
/// 1. Create personal budget
/// 2. Add personal expenses
/// 3. Verify total includes group allocation (€200 personal + €400 group = €600 total)
/// 4. Admin changes allocation percentage
/// 5. Verify personal budget total updates accordingly
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Budget Calculation with Group Allocation - User Story 3', () {
    testWidgets(
      'Personal budget total correctly includes group allocation',
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

        // Step 2: Navigate to personal budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 3: Verify personal budget section shows personal amount
        expect(find.text('Budget Personale'), findsOneWidget);
        expect(find.text('200,00 €'), findsOneWidget); // €200 personal

        // Step 4: Verify group allocation section shows group amount
        expect(find.text('Spesa Gruppo'), findsOneWidget);
        expect(find.text('350,00 €'), findsOneWidget); // €350 group

        // Step 5: Verify total budget includes both personal + group
        expect(find.text('Totale Budget'), findsOneWidget);
        expect(find.text('550,00 €'), findsOneWidget); // €550 total (200 + 350)

        // Step 6: Verify breakdown is shown
        expect(find.textContaining('200,00 € + 350,00 €'), findsOneWidget);
      },
    );

    testWidgets(
      'Budget calculation has zero rounding errors (SC-003)',
      (tester) async {
        // Step 1: Launch app and login
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'member2@example.com',
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

        // Step 3: Verify amounts are displayed correctly (no rounding errors)
        // Member has 33.33% allocation of €1000 group budget = €333.33
        expect(find.text('333,33 €'), findsOneWidget);

        // Step 4: Verify totals match exactly (personal + group)
        // If personal is €150 and group is €333.33, total should be €483.33
        expect(find.text('150,00 €'), findsOneWidget); // Personal
        expect(find.text('333,33 €'), findsOneWidget); // Group
        expect(find.text('483,33 €'), findsOneWidget); // Total (exact)
      },
    );

    testWidgets(
      'Budget total updates when admin changes allocation percentage',
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

        // Step 3: Capture initial total budget
        expect(find.text('550,00 €'), findsOneWidget); // Initial: 200 + 350

        // Step 4: Logout and login as admin
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Esci'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'admin@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Step 5: Navigate to group settings
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Impostazioni Gruppo'));
        await tester.pumpAndSettle();

        // Step 6: Re-trigger wizard to change allocations
        await tester.tap(find.text('Riconfigura Budget'));
        await tester.pumpAndSettle();

        // Step 7: Navigate to allocation step (skip to step 3)
        await tester.tap(find.text('Avanti'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Avanti'));
        await tester.pumpAndSettle();

        // Step 8: Change member allocation from 35% to 50%
        await tester.enterText(
          find.byKey(const Key('allocation_member')),
          '50',
        );
        await tester.pumpAndSettle();

        // Step 9: Complete wizard
        await tester.tap(find.text('Avanti'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Termina'));
        await tester.pumpAndSettle();

        // Step 10: Logout and login back as member
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Esci'));
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

        // Step 11: Navigate back to budget view
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();

        // Step 12: Verify total budget updated (200 personal + 500 group = 700 total)
        // Group allocation changed from 35% (€350) to 50% (€500) of €1000
        expect(find.text('200,00 €'), findsOneWidget); // Personal unchanged
        expect(find.text('500,00 €'), findsOneWidget); // Group updated
        expect(find.text('700,00 €'), findsOneWidget); // Total updated
      },
    );

    testWidgets(
      'Budget displays personal + group breakdown clearly',
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

        // Step 3: Verify breakdown section exists
        expect(find.text('Breakdown'), findsOneWidget);

        // Step 4: Verify personal budget line item
        expect(find.text('Budget Personale:'), findsOneWidget);
        expect(find.text('200,00 €'), findsOneWidget);

        // Step 5: Verify group allocation line item
        expect(find.text('Allocazione Gruppo:'), findsOneWidget);
        expect(find.text('350,00 €'), findsOneWidget);

        // Step 6: Verify total line item (bold/highlighted)
        expect(find.text('Totale:'), findsOneWidget);
        expect(find.text('550,00 €'), findsAtLeastNWidgets(1));

        // Step 7: Verify formula display
        expect(find.textContaining('200,00 € + 350,00 € = 550,00 €'),
            findsOneWidget);
      },
    );

    testWidgets(
      'Budget handles zero personal budget with group allocation',
      (tester) async {
        // Step 1: Launch app and login as member with no personal budget
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

        // Step 3: Verify personal budget is 0
        expect(find.text('0,00 €'), findsWidgets); // Personal

        // Step 4: Verify group allocation is shown
        expect(find.text('350,00 €'), findsOneWidget); // Group

        // Step 5: Verify total equals group allocation only
        expect(find.text('350,00 €'), findsAtLeastNWidgets(2)); // Total = Group
      },
    );

    testWidgets(
      'Budget handles zero group allocation with personal budget',
      (tester) async {
        // Step 1: Login as member in group with no wizard completed
        await app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'solo@example.com',
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

        // Step 3: Verify personal budget is shown
        expect(find.text('200,00 €'), findsOneWidget); // Personal

        // Step 4: Verify group allocation is 0 or not shown
        expect(find.text('Allocazione Gruppo:'), findsNothing);

        // Step 5: Verify total equals personal budget only
        expect(find.text('200,00 €'), findsAtLeastNWidgets(1)); // Total = Personal
      },
    );
  });
}
