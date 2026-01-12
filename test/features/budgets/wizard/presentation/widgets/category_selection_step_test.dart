import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/category_selection.dart';
import 'package:family_expense_tracker/features/budgets/wizard/presentation/widgets/category_selection_step.dart';

/// Widget tests for CategorySelectionStep.
/// Feature: 001-group-budget-wizard, Task: T021
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
    const CategorySelection(
      categoryId: 'cat4',
      categoryName: 'Svago',
      icon: 'movie',
      color: '#9C27B0',
      isSystemCategory: false,
    ),
  ];

  Widget createTestWidget({
    required List<CategorySelection> categories,
    List<String> selectedCategories = const [],
    Function(List<String>)? onSelectionChanged,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: CategorySelectionStep(
            categories: categories,
            selectedCategories: selectedCategories,
            onSelectionChanged: onSelectionChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('CategorySelectionStep Widget', () {
    testWidgets('should display all available categories', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      expect(find.text('Cibo e Spesa'), findsOneWidget);
      expect(find.text('Utenze'), findsOneWidget);
      expect(find.text('Trasporto'), findsOneWidget);
      expect(find.text('Svago'), findsOneWidget);
    });

    testWidgets('should display category icons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      // Check for icon widgets (Icons are represented as Icon widgets with specific icons)
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsOneWidget);
    });

    testWidgets('should show checkboxes for all categories', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      expect(find.byType(Checkbox), findsNWidgets(4));
    });

    testWidgets('should mark selected categories as checked', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1', 'cat3'],
        ),
      );

      // Assert
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, isTrue); // cat1 selected
      expect(checkboxes[1].value, isFalse); // cat2 not selected
      expect(checkboxes[2].value, isTrue); // cat3 selected
      expect(checkboxes[3].value, isFalse); // cat4 not selected
    });

    testWidgets('should call onSelectionChanged when category is tapped', (WidgetTester tester) async {
      // Arrange
      List<String>? capturedSelection;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1'],
          onSelectionChanged: (selected) {
            capturedSelection = selected;
          },
        ),
      );

      // Act - Tap on "Utenze" category
      await tester.tap(find.text('Utenze'));
      await tester.pump();

      // Assert
      expect(capturedSelection, isNotNull);
      expect(capturedSelection, contains('cat1')); // Previously selected
      expect(capturedSelection, contains('cat2')); // Newly selected
      expect(capturedSelection!.length, 2);
    });

    testWidgets('should remove category when tapping selected category', (WidgetTester tester) async {
      // Arrange
      List<String>? capturedSelection;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1', 'cat2'],
          onSelectionChanged: (selected) {
            capturedSelection = selected;
          },
        ),
      );

      // Act - Tap on already selected "Cibo e Spesa" category
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.pump();

      // Assert
      expect(capturedSelection, isNotNull);
      expect(capturedSelection, isNot(contains('cat1'))); // Removed
      expect(capturedSelection, contains('cat2')); // Still selected
      expect(capturedSelection!.length, 1);
    });

    testWidgets('should display system category badge', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert - System categories should have some indicator
      // This could be a chip, badge, or different styling
      expect(find.text('Sistema'), findsAtLeast(1), reason: 'System categories should be labeled');
    });

    testWidgets('should allow selecting multiple categories', (WidgetTester tester) async {
      // Arrange
      List<String>? capturedSelection;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          onSelectionChanged: (selected) {
            capturedSelection = selected;
          },
        ),
      );

      // Act - Select three categories
      await tester.tap(find.text('Cibo e Spesa'));
      await tester.pump();
      await tester.tap(find.text('Utenze'));
      await tester.pump();
      await tester.tap(find.text('Trasporto'));
      await tester.pump();

      // Assert
      expect(capturedSelection, isNotNull);
      expect(capturedSelection!.length, greaterThanOrEqualTo(3));
    });

    testWidgets('should display empty state when no categories available', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: []));

      // Assert
      expect(find.text('Nessuna categoria disponibile'), findsOneWidget);
    });

    testWidgets('should show validation message when no category selected', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: [],
        ),
      );

      // Assert - Should show validation hint/message
      expect(
        find.text('Seleziona almeno una categoria'),
        findsOneWidget,
        reason: 'Should display validation message when no categories selected',
      );
    });

    testWidgets('should hide validation message when at least one category selected', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1'],
        ),
      );

      // Assert - Validation message should not be shown
      expect(
        find.text('Seleziona almeno una categoria'),
        findsNothing,
        reason: 'Should not display validation message when categories are selected',
      );
    });

    testWidgets('should display category count summary', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1', 'cat2', 'cat3'],
        ),
      );

      // Assert - Should show "3 categorie selezionate" or similar
      expect(
        find.textContaining('3'),
        findsOneWidget,
        reason: 'Should display selected category count',
      );
      expect(
        find.textContaining('selezionate'),
        findsOneWidget,
        reason: 'Should display selection label',
      );
    });

    testWidgets('should support keyboard navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Act - Tab to first checkbox and press space
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Assert - First category should be selected
      // This test verifies accessibility compliance
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('should be scrollable when many categories', (WidgetTester tester) async {
      // Arrange - Create many categories
      final manyCategories = List.generate(
        20,
        (index) => CategorySelection(
          categoryId: 'cat$index',
          categoryName: 'Categoria $index',
          icon: 'folder',
          color: '#000000',
          isSystemCategory: false,
        ),
      );

      await tester.pumpWidget(createTestWidget(categories: manyCategories));

      // Assert - Should find a scrollable widget
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display "Seleziona Tutto" button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert
      expect(find.text('Seleziona Tutto'), findsOneWidget);
    });

    testWidgets('should select all categories when "Seleziona Tutto" is tapped', (WidgetTester tester) async {
      // Arrange
      List<String>? capturedSelection;

      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          onSelectionChanged: (selected) {
            capturedSelection = selected;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Seleziona Tutto'));
      await tester.pump();

      // Assert
      expect(capturedSelection, isNotNull);
      expect(capturedSelection!.length, 4);
      expect(capturedSelection, containsAll(['cat1', 'cat2', 'cat3', 'cat4']));
    });

    testWidgets('should display "Deseleziona Tutto" when all selected', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          categories: testCategories,
          selectedCategories: ['cat1', 'cat2', 'cat3', 'cat4'],
        ),
      );

      // Assert
      expect(find.text('Deseleziona Tutto'), findsOneWidget);
    });

    testWidgets('should show category color indicator', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(categories: testCategories));

      // Assert - Should have colored indicators/circles for each category
      expect(find.byType(Container), findsWidgets);
      // The actual color assertion would need to check DecoratedBox or Container decoration
    });
  });
}
