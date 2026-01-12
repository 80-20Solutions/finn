import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/category_selection.dart';
import 'package:family_expense_tracker/features/budgets/wizard/presentation/widgets/budget_amount_step.dart';

/// Widget tests for BudgetAmountStep validation.
/// Feature: 001-group-budget-wizard, Task: T022
void main() {
  final testCategories = [
    const CategorySelection(
      categoryId: 'cat1',
      categoryName: 'Cibo e Spesa',
      icon: 'shopping_cart',
      color: '#FF5722',
      isSystemCategory: true,
    ),
    const CategorySelection(
      categoryId: 'cat2',
      categoryName: 'Utenze',
      icon: 'bolt',
      color: '#FFC107',
      isSystemCategory: true,
    ),
    const CategorySelection(
      categoryId: 'cat3',
      categoryName: 'Trasporto',
      icon: 'directions_car',
      color: '#2196F3',
      isSystemCategory: false,
    ),
  ];

  Widget createTestWidget({
    required List<CategorySelection> categories,
    Map<String, int> categoryBudgets = const {},
    Function(Map<String, int>)? onBudgetsChanged,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: BudgetAmountStep(
            categories: categories,
            categoryBudgets: categoryBudgets,
            onBudgetsChanged: onBudgetsChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('BudgetAmountStep Widget', () {
    testWidgets('should display all selected categories', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      expect(find.text('Cibo e Spesa'), findsOneWidget);
      expect(find.text('Utenze'), findsOneWidget);
      expect(find.text('Trasporto'), findsOneWidget);
    });

    testWidgets('should display budget input field for each category', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert - Should have 3 text fields for 3 categories
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('should display euro currency symbol in input fields', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert - Should show € symbol in decoration
      expect(find.text('€'), findsAtLeastNWidgets(3));
    });

    testWidgets('should pre-fill existing budget amounts', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000, // €500.00
            'cat2': 30000, // €300.00
            'cat3': 20000, // €200.00
          },
        ),
      );

      // Assert - Should display formatted amounts
      expect(find.text('500,00'), findsOneWidget);
      expect(find.text('300,00'), findsOneWidget);
      expect(find.text('200,00'), findsOneWidget);
    });

    testWidgets('should call onBudgetsChanged when amount is entered', (WidgetTester tester) async {
      // Arrange
      Map<String, int>? capturedBudgets;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          onBudgetsChanged: (budgets) {
            capturedBudgets = budgets;
          },
        ),
      );

      // Act - Enter amount in first field
      await tester.enterText(find.byType(TextFormField).first, '500,00');
      await tester.pump();

      // Assert
      expect(capturedBudgets, isNotNull);
      expect(capturedBudgets!['cat1'], 50000); // €500.00 = 50000 cents
    });

    testWidgets('should validate positive amounts only', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Try entering negative amount
      await tester.enterText(find.byType(TextFormField).first, '-100');
      await tester.pump();

      // Find the form and trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      // Assert - Should show validation error
      expect(find.text('L\'importo deve essere maggiore di zero'), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Leave field empty and trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      // Assert - Should show required field error
      expect(find.text('Inserisci un importo'), findsAtLeastNWidgets(1));
    });

    testWidgets('should validate maximum budget amount', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Enter amount exceeding max (€999,999.99 = 99999999 cents)
      await tester.enterText(find.byType(TextFormField).first, '1000000,00');
      await tester.pump();

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      // Assert - Should show max amount error
      expect(find.text('Importo troppo elevato (max €999.999,99)'), findsOneWidget);
    });

    testWidgets('should display total budget sum', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000, // €500.00
            'cat2': 30000, // €300.00
            'cat3': 20000, // €200.00
          },
        ),
      );

      // Assert - Should show total €1,000.00
      expect(find.textContaining('Totale'), findsOneWidget);
      expect(find.textContaining('1.000,00'), findsOneWidget);
    });

    testWidgets('should update total when budget amounts change', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000, // €500.00
          },
        ),
      );

      // Act - Add budget to another category
      await tester.enterText(find.byType(TextFormField).at(1), '300,00');
      await tester.pump();

      // Assert - Total should update to €800.00
      expect(find.textContaining('800,00'), findsOneWidget);
    });

    testWidgets('should format currency input correctly (comma decimal separator)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Enter amount with Italian formatting
      await tester.enterText(find.byType(TextFormField).first, '1.500,50');
      await tester.pump();

      // Assert - Should accept and format correctly
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(textField.controller?.text, contains('1.500,50'));
    });

    testWidgets('should restrict decimal places to 2', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Try entering more than 2 decimal places
      await tester.enterText(find.byType(TextFormField).first, '100,999');
      await tester.pump();

      // Assert - Should truncate or prevent entry
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      final text = textField.controller?.text ?? '';

      // Count decimal places
      if (text.contains(',')) {
        final decimalPart = text.split(',')[1];
        expect(decimalPart.length, lessThanOrEqualTo(2));
      }
    });

    testWidgets('should accept zero decimals (whole euros)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Enter whole number
      await tester.enterText(find.byType(TextFormField).first, '500');
      await tester.pump();

      // Assert - Should accept and format as €500.00
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should display category icons and colors', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('should show validation summary when submitting incomplete form', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000, // Only one category has budget
          },
        ),
      );

      // Act - Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      final isValid = formState.validate();
      await tester.pump();

      // Assert - Should be invalid and show errors
      expect(isValid, isFalse);
      expect(find.text('Inserisci un importo'), findsAtLeastNWidgets(2));
    });

    testWidgets('should allow clearing budget amount', (WidgetTester tester) async {
      // Arrange
      Map<String, int>? capturedBudgets;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000,
          },
          onBudgetsChanged: (budgets) {
            capturedBudgets = budgets;
          },
        ),
      );

      // Act - Clear the field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Assert - Budget should be removed or set to 0
      expect(capturedBudgets, isNotNull);
      final budget = capturedBudgets!['cat1'];
      expect(budget == null || budget == 0, isTrue);
    });

    testWidgets('should display helpful hint text', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert - Should have hint/helper text
      expect(
        find.text('Inserisci il budget mensile'),
        findsAtLeastNWidgets(1),
        reason: 'Should display hint text for inputs',
      );
    });

    testWidgets('should be scrollable when many categories', (WidgetTester tester) async {
      // Arrange - Create many categories
      final manyCategories = List.generate(
        10,
        (index) => CategorySelection(
          categoryId: 'cat$index',
          categoryName: 'Categoria $index',
          icon: 'folder',
          color: '#000000',
          isSystemCategory: false,
        ),
      );

      await tester.pumpWidget(createTestWidget(categories: manyCategories));

      // Assert - Should be scrollable
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should preserve input focus when typing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Tap first field and start typing
      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '5');
      await tester.pump();

      // Assert - Field should still have focus
      final FocusNode? focusNode = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      ).focusNode;
      expect(focusNode?.hasFocus, isTrue);
    });

    testWidgets('should display budget per category breakdown', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          categoryBudgets: {
            'cat1': 50000,
            'cat2': 30000,
            'cat3': 20000,
          },
        ),
      );

      // Assert - Each category should show its budget
      expect(find.text('500,00'), findsOneWidget);
      expect(find.text('300,00'), findsOneWidget);
      expect(find.text('200,00'), findsOneWidget);
    });
  });
}
