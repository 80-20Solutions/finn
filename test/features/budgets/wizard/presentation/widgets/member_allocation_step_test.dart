import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_expense_tracker/features/budgets/wizard/presentation/widgets/member_allocation_step.dart';

/// Widget tests for MemberAllocationStep with "Dividi Equamente" button.
/// Feature: 001-group-budget-wizard, Task: T023
void main() {
  final testMembers = [
    {
      'user_id': 'user1',
      'display_name': 'Alice',
    },
    {
      'user_id': 'user2',
      'display_name': 'Bob',
    },
    {
      'user_id': 'user3',
      'display_name': 'Charlie',
    },
  ];

  Widget createTestWidget({
    required List<Map<String, dynamic>> members,
    Map<String, double> memberAllocations = const {},
    Function(Map<String, double>)? onAllocationsChanged,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: MemberAllocationStep(
            members: members,
            memberAllocations: memberAllocations,
            onAllocationsChanged: onAllocationsChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('MemberAllocationStep Widget', () {
    testWidgets('should display all group members', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('should display percentage input field for each member', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert - Should have 3 percentage fields for 3 members
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('should display "Dividi Equamente" button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert
      expect(find.text('Dividi Equamente'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should distribute percentages equally when "Dividi Equamente" is tapped', (WidgetTester tester) async {
      // Arrange
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          onAllocationsChanged: (allocations) {
            capturedAllocations = allocations;
          },
        ),
      );

      // Act - Tap "Dividi Equamente" button
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pump();

      // Assert - 3 members should each get 33.33%
      expect(capturedAllocations, isNotNull);
      expect(capturedAllocations!['user1'], closeTo(33.33, 0.01));
      expect(capturedAllocations!['user2'], closeTo(33.33, 0.01));
      expect(capturedAllocations!['user3'], closeTo(33.34, 0.01)); // Rounding adjustment

      // Total should be 100%
      final total = capturedAllocations!.values.reduce((a, b) => a + b);
      expect(total, closeTo(100.0, 0.01));
    });

    testWidgets('should pre-fill existing allocation percentages', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        ),
      );

      // Assert - Should display percentages
      expect(find.text('50'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('should call onAllocationsChanged when percentage is entered', (WidgetTester tester) async {
      // Arrange
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          onAllocationsChanged: (allocations) {
            capturedAllocations = allocations;
          },
        ),
      );

      // Act - Enter percentage for first member
      await tester.enterText(find.byType(TextFormField).first, '50');
      await tester.pump();

      // Assert
      expect(capturedAllocations, isNotNull);
      expect(capturedAllocations!['user1'], 50.0);
    });

    testWidgets('should display percentage symbol in input fields', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert - Should show % symbol
      expect(find.text('%'), findsAtLeastNWidgets(3));
    });

    testWidgets('should validate percentages are between 0 and 100', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Act - Try entering invalid percentage (>100)
      await tester.enterText(find.byType(TextFormField).first, '150');
      await tester.pump();

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      // Assert - Should show validation error
      expect(find.text('Percentuale non valida'), findsOneWidget);
    });

    testWidgets('should validate negative percentages', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Act - Try entering negative percentage
      await tester.enterText(find.byType(TextFormField).first, '-10');
      await tester.pump();

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      // Assert - Should show validation error
      expect(find.text('Percentuale non valida'), findsOneWidget);
    });

    testWidgets('should display total percentage sum', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        ),
      );

      // Assert - Should show "Totale: 100%"
      expect(find.textContaining('Totale'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('should update total when percentages change', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
          },
        ),
      );

      // Act - Add percentage for another member
      await tester.enterText(find.byType(TextFormField).at(1), '30');
      await tester.pump();

      // Assert - Total should show 80%
      expect(find.textContaining('80'), findsOneWidget);
    });

    testWidgets('should show warning when total is not 100%', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            // Missing user3, total is 80%
          },
        ),
      );

      // Assert - Should display warning message
      expect(find.text('Il totale deve essere 100%'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should accept percentages within tolerance (100.01%)', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.01, // Total: 100.01% (within ±0.01% tolerance)
            'user2': 30.0,
            'user3': 20.0,
          },
        ),
      );

      // Assert - Should NOT show warning (within tolerance)
      expect(find.text('Il totale deve essere 100%'), findsNothing);
    });

    testWidgets('should show error when percentages exceed tolerance (100.02%)', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.02, // Total: 100.02% (outside ±0.01% tolerance)
            'user2': 30.0,
            'user3': 20.0,
          },
        ),
      );

      // Assert - Should show warning (outside tolerance)
      expect(find.text('Il totale deve essere 100%'), findsOneWidget);
    });

    testWidgets('should show success indicator when total is exactly 100%', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        ),
      );

      // Assert - Should show success indicator (green checkmark)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should allow decimal percentages', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Act - Enter decimal percentage
      await tester.enterText(find.byType(TextFormField).first, '33.33');
      await tester.pump();

      // Assert - Should accept decimal values
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(textField.controller?.text, '33.33');
    });

    testWidgets('should restrict decimal places to 2', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Act - Try entering more than 2 decimal places
      await tester.enterText(find.byType(TextFormField).first, '33.333');
      await tester.pump();

      // Assert - Should truncate or prevent entry
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      final text = textField.controller?.text ?? '';

      if (text.contains('.')) {
        final decimalPart = text.split('.')[1];
        expect(decimalPart.length, lessThanOrEqualTo(2));
      }
    });

    testWidgets('should handle 2-member equal split (50/50)', (WidgetTester tester) async {
      // Arrange
      final twoMembers = testMembers.take(2).toList();
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        createTestWidget(
          members: twoMembers,
          onAllocationsChanged: (allocations) {
            capturedAllocations = allocations;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pump();

      // Assert - Each should get exactly 50%
      expect(capturedAllocations!['user1'], 50.0);
      expect(capturedAllocations!['user2'], 50.0);
    });

    testWidgets('should handle 4-member equal split (25% each)', (WidgetTester tester) async {
      // Arrange
      final fourMembers = [
        ...testMembers,
        {'user_id': 'user4', 'display_name': 'David'},
      ];
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        createTestWidget(
          members: fourMembers,
          onAllocationsChanged: (allocations) {
            capturedAllocations = allocations;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Dividi Equamente'));
      await tester.pump();

      // Assert - Each should get exactly 25%
      expect(capturedAllocations!['user1'], 25.0);
      expect(capturedAllocations!['user2'], 25.0);
      expect(capturedAllocations!['user3'], 25.0);
      expect(capturedAllocations!['user4'], 25.0);
    });

    testWidgets('should display member avatars or initials', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert - Should have CircleAvatar or similar for each member
      expect(find.byType(CircleAvatar), findsAtLeastNWidgets(3));
    });

    testWidgets('should be scrollable when many members', (WidgetTester tester) async {
      // Arrange - Create many members
      final manyMembers = List.generate(
        10,
        (index) => {
          'user_id': 'user$index',
          'display_name': 'User $index',
        },
      );

      await tester.pumpWidget(createTestWidget(members: manyMembers));

      // Assert - Should be scrollable
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display helpful instruction text', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(members: testMembers));

      // Assert - Should have instruction text
      expect(
        find.textContaining('Distribuisci le percentuali'),
        findsOneWidget,
        reason: 'Should display instruction text',
      );
    });

    testWidgets('should show percentage remaining to allocate', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            // 20% remaining
          },
        ),
      );

      // Assert - Should show "Rimanente: 20%"
      expect(find.textContaining('Rimanente'), findsOneWidget);
      expect(find.textContaining('20'), findsWidgets);
    });

    testWidgets('should clear all percentages when starting fresh', (WidgetTester tester) async {
      // Arrange
      Map<String, double>? capturedAllocations;

      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 50.0,
            'user2': 30.0,
            'user3': 20.0,
          },
          onAllocationsChanged: (allocations) {
            capturedAllocations = allocations;
          },
        ),
      );

      // Act - Clear first field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Assert - Should update allocations
      expect(capturedAllocations, isNotNull);
    });

    testWidgets('should validate all fields before proceeding', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          members: testMembers,
          memberAllocations: {
            'user1': 60.0, // Total: 60% (invalid)
          },
        ),
      );

      // Act - Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      final isValid = formState.validate();
      await tester.pump();

      // Assert - Should be invalid
      expect(isValid, isFalse);
      expect(find.text('Il totale deve essere 100%'), findsOneWidget);
    });
  });
}
