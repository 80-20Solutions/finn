import 'package:fin/features/budgets/personal/domain/entities/group_spending_breakdown.dart';
import 'package:fin/features/budgets/personal/domain/entities/sub_category_spending.dart';
import 'package:fin/features/budgets/personal/presentation/widgets/group_spending_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupSpendingCategory Widget', () {
    final tSubCategories = [
      SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 20000, // €200
        spentCents: 15000, // €150
        icon: 'restaurant',
        color: '#FF5722',
      ),
      SubCategorySpending(
        categoryId: 'cat-2',
        categoryName: 'Utenze',
        allocatedCents: 15000, // €150
        spentCents: 14500, // €145
        icon: 'power',
        color: '#2196F3',
      ),
    ];

    final tBreakdown = GroupSpendingBreakdown(
      totalAllocatedCents: 35000, // €350
      totalSpentCents: 29500, // €295
      subCategories: tSubCategories,
    );

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: GroupSpendingCategory(breakdown: tBreakdown),
        ),
      );
    }

    testWidgets('should display parent category "Spesa Gruppo"', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.text('Spesa Gruppo'), findsOneWidget);
    });

    testWidgets('should display total allocated and spent amounts',
        (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.text('350,00 €'), findsOneWidget); // Total allocated
      expect(find.text('295,00 €'), findsOneWidget); // Total spent
    });

    testWidgets('should display percentage progress', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      // 295 / 350 = 84.3%
      expect(find.text('84%'), findsOneWidget);
    });

    testWidgets('should be collapsible (ExpansionTile)', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert - initially collapsed
      expect(find.text('Cibo'), findsNothing);
      expect(find.text('Utenze'), findsNothing);

      // act - expand
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // assert - now expanded
      expect(find.text('Cibo'), findsOneWidget);
      expect(find.text('Utenze'), findsOneWidget);
    });

    testWidgets('should display all subcategories when expanded',
        (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // act - expand
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Cibo'), findsOneWidget);
      expect(find.text('200,00 €'), findsOneWidget); // Cibo allocated
      expect(find.text('150,00 €'), findsOneWidget); // Cibo spent

      expect(find.text('Utenze'), findsOneWidget);
      expect(find.text('145,00 €'), findsOneWidget); // Utenze spent
    });

    testWidgets('should display progress indicator', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should show green progress when under budget', (tester) async {
      // arrange
      final underBudgetBreakdown = GroupSpendingBreakdown(
        totalAllocatedCents: 35000,
        totalSpentCents: 20000, // 57% - under budget
        subCategories: tSubCategories,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupSpendingCategory(breakdown: underBudgetBreakdown),
          ),
        ),
      );

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.green);
    });

    testWidgets('should show orange progress when near budget', (tester) async {
      // arrange
      final nearBudgetBreakdown = GroupSpendingBreakdown(
        totalAllocatedCents: 35000,
        totalSpentCents: 30000, // 85% - near budget
        subCategories: tSubCategories,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupSpendingCategory(breakdown: nearBudgetBreakdown),
          ),
        ),
      );

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.orange);
    });

    testWidgets('should show red progress when over budget', (tester) async {
      // arrange
      final overBudgetBreakdown = GroupSpendingBreakdown(
        totalAllocatedCents: 35000,
        totalSpentCents: 40000, // 114% - over budget
        subCategories: tSubCategories,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupSpendingCategory(breakdown: overBudgetBreakdown),
          ),
        ),
      );

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.red);
    });

    testWidgets('should handle zero allocated budget', (tester) async {
      // arrange
      final zeroAllocatedBreakdown = GroupSpendingBreakdown(
        totalAllocatedCents: 0,
        totalSpentCents: 0,
        subCategories: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupSpendingCategory(breakdown: zeroAllocatedBreakdown),
          ),
        ),
      );

      // assert - should not crash
      expect(find.text('Spesa Gruppo'), findsOneWidget);
      expect(find.text('0,00 €'), findsWidgets);
    });

    testWidgets('should display read-only badge or icon', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
