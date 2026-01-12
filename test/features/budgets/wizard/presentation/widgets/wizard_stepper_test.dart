import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_expense_tracker/features/budgets/wizard/presentation/widgets/wizard_stepper.dart';

/// Widget tests for WizardStepper navigation.
/// Feature: 001-group-budget-wizard, Task: T024
void main() {
  Widget createTestWidget({
    int currentStep = 0,
    Function(int)? onStepChanged,
    Function()? onComplete,
    bool canProceed = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: WizardStepper(
            currentStep: currentStep,
            onStepChanged: onStepChanged ?? (_) {},
            onComplete: onComplete ?? () {},
            canProceed: canProceed,
          ),
        ),
      ),
    );
  }

  group('WizardStepper Widget', () {
    testWidgets('should display all 4 wizard steps', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Should show step labels
      expect(find.text('Categorie'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Allocazioni'), findsOneWidget);
      expect(find.text('Riepilogo'), findsOneWidget);
    });

    testWidgets('should display Stepper widget', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Stepper), findsOneWidget);
    });

    testWidgets('should highlight current step', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 1));

      // Assert - Step 1 (Budget) should be active
      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.currentStep, 1);
    });

    testWidgets('should display "Avanti" button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Avanti'), findsOneWidget);
    });

    testWidgets('should display "Indietro" button on steps after first', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 1));

      // Assert
      expect(find.text('Indietro'), findsOneWidget);
    });

    testWidgets('should not display "Indietro" button on first step', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 0));

      // Assert
      expect(find.text('Indietro'), findsNothing);
    });

    testWidgets('should call onStepChanged when "Avanti" is tapped', (WidgetTester tester) async {
      // Arrange
      int? capturedStep;

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 0,
          onStepChanged: (step) {
            capturedStep = step;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Avanti'));
      await tester.pump();

      // Assert
      expect(capturedStep, 1);
    });

    testWidgets('should call onStepChanged when "Indietro" is tapped', (WidgetTester tester) async {
      // Arrange
      int? capturedStep;

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 2,
          onStepChanged: (step) {
            capturedStep = step;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Indietro'));
      await tester.pump();

      // Assert
      expect(capturedStep, 1);
    });

    testWidgets('should display "Completa" button on last step', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 3));

      // Assert
      expect(find.text('Completa'), findsOneWidget);
      expect(find.text('Avanti'), findsNothing);
    });

    testWidgets('should call onComplete when "Completa" is tapped', (WidgetTester tester) async {
      // Arrange
      bool completeCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 3,
          onComplete: () {
            completeCalled = true;
          },
        ),
      );

      // Act
      await tester.tap(find.text('Completa'));
      await tester.pump();

      // Assert
      expect(completeCalled, isTrue);
    });

    testWidgets('should disable "Avanti" button when canProceed is false', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          currentStep: 0,
          canProceed: false,
        ),
      );

      // Assert - Button should be disabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Avanti'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should enable "Avanti" button when canProceed is true', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          currentStep: 0,
          canProceed: true,
        ),
      );

      // Assert - Button should be enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Avanti'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should display step numbers', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Should show step numbers 1-4
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should mark completed steps as done', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 2));

      // Assert - Steps 0 and 1 should be marked as complete
      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.steps[0].state, StepState.complete);
      expect(stepper.steps[1].state, StepState.complete);
      expect(stepper.steps[2].state, StepState.editing);
      expect(stepper.steps[3].state, StepState.indexed);
    });

    testWidgets('should allow jumping to previous completed steps', (WidgetTester tester) async {
      // Arrange
      int? capturedStep;

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 2,
          onStepChanged: (step) {
            capturedStep = step;
          },
        ),
      );

      // Act - Tap on step 0 (should be clickable as it's completed)
      await tester.tap(find.text('1'));
      await tester.pump();

      // Assert
      expect(capturedStep, 0);
    });

    testWidgets('should display progress indicator', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 1));

      // Assert - Should show "Passo 2 di 4" or similar
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
    });

    testWidgets('should display step descriptions', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Steps should have subtitle/description
      expect(find.textContaining('Seleziona le categorie'), findsOneWidget);
      expect(find.textContaining('Imposta i budget'), findsOneWidget);
      expect(find.textContaining('Distribuisci le percentuali'), findsOneWidget);
      expect(find.textContaining('Verifica e conferma'), findsOneWidget);
    });

    testWidgets('should display step icons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Steps should have icons
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should handle rapid navigation clicks gracefully', (WidgetTester tester) async {
      // Arrange
      final steps = <int>[];

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 0,
          onStepChanged: (step) {
            steps.add(step);
          },
        ),
      );

      // Act - Tap "Avanti" multiple times rapidly
      await tester.tap(find.text('Avanti'));
      await tester.tap(find.text('Avanti'));
      await tester.tap(find.text('Avanti'));
      await tester.pump();

      // Assert - Should only register legitimate steps
      expect(steps, isNotEmpty);
    });

    testWidgets('should display cancel button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Annulla'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when cancelling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(currentStep: 2));

      // Act
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      // Assert - Should show confirmation dialog
      expect(find.text('Annullare la configurazione?'), findsOneWidget);
      expect(find.text('Tutti i progressi andranno persi'), findsOneWidget);
    });

    testWidgets('should be vertically scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Stepper should be scrollable
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('should display validation errors for current step', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          currentStep: 0,
          canProceed: false,
        ),
      );

      // Assert - Should show validation message
      expect(
        find.textContaining('Completa questo passaggio'),
        findsOneWidget,
        reason: 'Should display validation prompt',
      );
    });

    testWidgets('should persist step content when navigating back', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          currentStep: 1,
        ),
      );

      // Act - Navigate to step 2, then back to step 1
      await tester.tap(find.text('Avanti'));
      await tester.pump();
      await tester.tap(find.text('Indietro'));
      await tester.pump();

      // Assert - Step 1 content should still be visible
      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.currentStep, 1);
    });

    testWidgets('should display loading indicator during submission', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          currentStep: 3,
        ),
      );

      // Act - Tap complete button (this would trigger async operation)
      await tester.tap(find.text('Completa'));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should navigate to step 0 when tapping first step indicator', (WidgetTester tester) async {
      // Arrange
      int? capturedStep;

      await tester.pumpWidget(
        createTestWidget(
          currentStep: 2,
          onStepChanged: (step) {
            capturedStep = step;
          },
        ),
      );

      // Act - Tap on "Categorie" step
      await tester.tap(find.text('Categorie'));
      await tester.pump();

      // Assert
      expect(capturedStep, 0);
    });

    testWidgets('should show step completion checkmarks', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(currentStep: 2));

      // Assert - Completed steps should have checkmarks
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(2));
    });
  });
}
