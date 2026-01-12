import 'package:fin/features/budgets/personal/domain/entities/sub_category_spending.dart';
import 'package:fin/features/budgets/personal/presentation/widgets/group_sub_category_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupSubCategoryItem Widget', () {
    const tSubCategory = SubCategorySpending(
      categoryId: 'cat-1',
      categoryName: 'Cibo',
      allocatedCents: 20000, // €200
      spentCents: 15000, // €150
      icon: 'restaurant',
      color: '#FF5722',
    );

    Widget createTestWidget({SubCategorySpending? subCategory}) {
      return MaterialApp(
        home: Scaffold(
          body: GroupSubCategoryItem(
            subCategory: subCategory ?? tSubCategory,
          ),
        ),
      );
    }

    testWidgets('should display category name', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.text('Cibo'), findsOneWidget);
    });

    testWidgets('should display category icon', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('should display allocated amount', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.text('200,00 €'), findsOneWidget);
    });

    testWidgets('should display spent amount', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.text('150,00 €'), findsOneWidget);
    });

    testWidgets('should display percentage progress', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      // 150 / 200 = 75%
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('should display progress indicator', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should use category color for icon', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.restaurant));
      expect(icon.color, const Color(0xFFFF5722)); // #FF5722
    });

    testWidgets('should show green progress when under budget', (tester) async {
      // arrange
      const underBudget = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 20000,
        spentCents: 10000, // 50%
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: underBudget));

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.green);
    });

    testWidgets('should show orange progress when near budget', (tester) async {
      // arrange
      const nearBudget = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 20000,
        spentCents: 17000, // 85%
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: nearBudget));

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.orange);
    });

    testWidgets('should show red progress when over budget', (tester) async {
      // arrange
      const overBudget = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 20000,
        spentCents: 25000, // 125%
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: overBudget));

      // assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.color, Colors.red);
    });

    testWidgets('should handle zero allocated budget', (tester) async {
      // arrange
      const zeroAllocated = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 0,
        spentCents: 0,
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: zeroAllocated));

      // assert - should not crash
      expect(find.text('Cibo'), findsOneWidget);
      expect(find.text('0,00 €'), findsWidgets);
    });

    testWidgets('should be read-only (not tappable)', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert - no InkWell or GestureDetector
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('should display remaining amount', (tester) async {
      // arrange
      await tester.pumpWidget(createTestWidget());

      // assert
      // 200 - 150 = 50 remaining
      expect(find.text('Restante: 50,00 €'), findsOneWidget);
    });

    testWidgets('should show negative remaining when over budget',
        (tester) async {
      // arrange
      const overBudget = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Cibo',
        allocatedCents: 20000,
        spentCents: 25000,
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: overBudget));

      // assert
      expect(find.text('Restante: -50,00 €'), findsOneWidget);
    });

    testWidgets('should format Italian currency correctly', (tester) async {
      // arrange
      const testCategory = SubCategorySpending(
        categoryId: 'cat-1',
        categoryName: 'Test',
        allocatedCents: 123456, // €1234.56
        spentCents: 98765, // €987.65
        icon: 'restaurant',
        color: '#FF5722',
      );

      await tester.pumpWidget(createTestWidget(subCategory: testCategory));

      // assert - Italian formatting uses comma for decimal
      expect(find.text('1.234,56 €'), findsOneWidget);
      expect(find.text('987,65 €'), findsOneWidget);
    });
  });
}
