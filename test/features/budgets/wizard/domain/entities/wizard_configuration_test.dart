import 'package:flutter_test/flutter_test.dart';

import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/wizard_configuration.dart';

/// Unit tests for WizardConfiguration entity validation.
/// Feature: 001-group-budget-wizard, Task: T016-T017
void main() {
  group('WizardConfiguration', () {
    const groupId = 'test-group-id';
    const selectedCategories = ['cat1', 'cat2', 'cat3'];
    const categoryBudgets = {
      'cat1': 50000, // €500.00
      'cat2': 30000, // €300.00
      'cat3': 20000, // €200.00
    };
    const memberAllocations = {
      'user1': 50.0,
      'user2': 30.0,
      'user3': 20.0,
    };

    group('Constructor and Basic Properties', () {
      test('creates instance with valid data', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
          currentStep: 0,
        );

        expect(config.groupId, groupId);
        expect(config.selectedCategories, selectedCategories);
        expect(config.categoryBudgets, categoryBudgets);
        expect(config.memberAllocations, memberAllocations);
        expect(config.currentStep, 0);
      });

      test('currentStep defaults to 0 when not provided', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        expect(config.currentStep, 0);
      });
    });

    group('Validation - isValid', () {
      test('returns true for valid configuration', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        expect(config.isValid, isTrue);
      });

      test('returns false when selectedCategories is empty', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: const [],
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when categoryBudgets length does not match selectedCategories', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: const {
            'cat1': 50000,
            'cat2': 30000,
            // Missing cat3
          },
          memberAllocations: memberAllocations,
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when budget amount is zero', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: const {
            'cat1': 0, // Invalid: zero amount
            'cat2': 30000,
            'cat3': 20000,
          },
          memberAllocations: memberAllocations,
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when budget amount is negative', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: const {
            'cat1': -10000, // Invalid: negative amount
            'cat2': 30000,
            'cat3': 20000,
          },
          memberAllocations: memberAllocations,
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when memberAllocations is empty', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {},
        );

        expect(config.isValid, isFalse);
      });
    });

    group('Percentage Validation (±0.01% tolerance)', () {
      test('returns true when percentages sum to exactly 100%', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 50.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isTrue);
      });

      test('returns true when percentages sum to 100.01% (within tolerance)', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 50.01,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isTrue);
      });

      test('returns true when percentages sum to 99.99% (within tolerance)', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 49.99,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isTrue);
      });

      test('returns false when percentages sum to 100.02% (outside tolerance)', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 50.02,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when percentages sum to 99.98% (outside tolerance)', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 49.98,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when percentages sum to 95%', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 45.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isFalse);
      });

      test('returns false when percentages sum to 105%', () {
        final config = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: const {
            'user1': 55.0,
            'user2': 30.0,
            'user3': 20.0,
          },
        );

        expect(config.isValid, isFalse);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated groupId', () {
        final original = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        final updated = original.copyWith(groupId: 'new-group-id');

        expect(updated.groupId, 'new-group-id');
        expect(updated.selectedCategories, selectedCategories);
        expect(updated.categoryBudgets, categoryBudgets);
        expect(updated.memberAllocations, memberAllocations);
      });

      test('creates new instance with updated selectedCategories', () {
        final original = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        const newCategories = ['cat1', 'cat2'];
        final updated = original.copyWith(selectedCategories: newCategories);

        expect(updated.selectedCategories, newCategories);
        expect(updated.groupId, groupId);
      });

      test('creates new instance with updated currentStep', () {
        final original = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
          currentStep: 0,
        );

        final updated = original.copyWith(currentStep: 2);

        expect(updated.currentStep, 2);
        expect(updated.groupId, groupId);
      });

      test('preserves original values when no parameters provided', () {
        final original = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
          currentStep: 1,
        );

        final updated = original.copyWith();

        expect(updated.groupId, original.groupId);
        expect(updated.selectedCategories, original.selectedCategories);
        expect(updated.categoryBudgets, original.categoryBudgets);
        expect(updated.memberAllocations, original.memberAllocations);
        expect(updated.currentStep, original.currentStep);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final config1 = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        final config2 = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('two instances with different groupId are not equal', () {
        final config1 = WizardConfiguration(
          groupId: groupId,
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        final config2 = WizardConfiguration(
          groupId: 'different-group-id',
          selectedCategories: selectedCategories,
          categoryBudgets: categoryBudgets,
          memberAllocations: memberAllocations,
        );

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
