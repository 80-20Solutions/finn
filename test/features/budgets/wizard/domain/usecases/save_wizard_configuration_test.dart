import 'package:dartz/dartz.dart';
import 'package:flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:family_expense_tracker/core/errors/failures.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/wizard_configuration.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/repositories/wizard_repository.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/usecases/save_wizard_configuration.dart';

import 'save_wizard_configuration_test.mocks.dart';

/// Unit tests for SaveWizardConfiguration use case.
/// Feature: 001-group-budget-wizard, Task: T019
@GenerateMocks([WizardRepository])
void main() {
  late SaveWizardConfiguration useCase;
  late MockWizardRepository mockRepository;

  setUp(() {
    mockRepository = MockWizardRepository();
    useCase = SaveWizardConfiguration(repository: mockRepository);
  });

  final testConfiguration = WizardConfiguration(
    groupId: 'test-group-123',
    selectedCategories: const ['cat1', 'cat2', 'cat3'],
    categoryBudgets: const {
      'cat1': 50000,
      'cat2': 30000,
      'cat3': 20000,
    },
    memberAllocations: const {
      'user1': 50.0,
      'user2': 30.0,
      'user3': 20.0,
    },
    currentStep: 3,
  );

  const testAdminUserId = 'admin-user-123';

  group('SaveWizardConfiguration', () {
    test('should save configuration successfully when validation passes', () async {
      // Arrange
      when(mockRepository.saveConfiguration(testConfiguration, testAdminUserId))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: testConfiguration,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (success) => expect(success, unit),
      );

      verify(mockRepository.saveConfiguration(testConfiguration, testAdminUserId)).called(1);
    });

    test('should return ValidationFailure when configuration is invalid (empty categories)', () async {
      // Arrange
      final invalidConfig = WizardConfiguration(
        groupId: 'test-group-123',
        selectedCategories: const [], // Invalid: empty
        categoryBudgets: const {},
        memberAllocations: const {
          'user1': 100.0,
        },
      );

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: invalidConfig,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('invalid'));
        },
        (_) => fail('Expected Left but got Right'),
      );

      verifyNever(mockRepository.saveConfiguration(any, any));
    });

    test('should return ValidationFailure when percentages do not sum to 100%', () async {
      // Arrange
      final invalidConfig = WizardConfiguration(
        groupId: 'test-group-123',
        selectedCategories: const ['cat1', 'cat2'],
        categoryBudgets: const {
          'cat1': 50000,
          'cat2': 30000,
        },
        memberAllocations: const {
          'user1': 50.0,
          'user2': 30.0, // Total: 80%, should be 100%
        },
      );

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: invalidConfig,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
        },
        (_) => fail('Expected Left but got Right'),
      );

      verifyNever(mockRepository.saveConfiguration(any, any));
    });

    test('should return ValidationFailure when budget amounts are invalid', () async {
      // Arrange
      final invalidConfig = WizardConfiguration(
        groupId: 'test-group-123',
        selectedCategories: const ['cat1', 'cat2'],
        categoryBudgets: const {
          'cat1': 0, // Invalid: zero amount
          'cat2': 30000,
        },
        memberAllocations: const {
          'user1': 60.0,
          'user2': 40.0,
        },
      );

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: invalidConfig,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
        },
        (_) => fail('Expected Left but got Right'),
      );

      verifyNever(mockRepository.saveConfiguration(any, any));
    });

    test('should return ServerFailure when repository save fails', () async {
      // Arrange
      when(mockRepository.saveConfiguration(testConfiguration, testAdminUserId))
          .thenAnswer((_) async => const Left(ServerFailure('Database transaction failed')));

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: testConfiguration,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Database transaction failed');
        },
        (_) => fail('Expected Left but got Right'),
      );

      verify(mockRepository.saveConfiguration(testConfiguration, testAdminUserId)).called(1);
    });

    test('should return AuthFailure when user is not authenticated', () async {
      // Arrange
      when(mockRepository.saveConfiguration(testConfiguration, testAdminUserId))
          .thenAnswer((_) async => const Left(AuthFailure('User not authenticated')));

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: testConfiguration,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect((failure as AuthFailure).message, 'User not authenticated');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return PermissionFailure when user is not group admin', () async {
      // Arrange
      when(mockRepository.saveConfiguration(testConfiguration, testAdminUserId))
          .thenAnswer((_) async => const Left(PermissionFailure('Only group admins can configure budgets')));

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: testConfiguration,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<PermissionFailure>());
          expect((failure as PermissionFailure).message, contains('admin'));
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should accept configuration with percentages within tolerance (100.01%)', () async {
      // Arrange
      final configWithTolerance = WizardConfiguration(
        groupId: 'test-group-123',
        selectedCategories: const ['cat1', 'cat2'],
        categoryBudgets: const {
          'cat1': 50000,
          'cat2': 30000,
        },
        memberAllocations: const {
          'user1': 60.01, // Total: 100.01% (within ±0.01% tolerance)
          'user2': 40.0,
        },
      );

      when(mockRepository.saveConfiguration(configWithTolerance, testAdminUserId))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: configWithTolerance,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.saveConfiguration(configWithTolerance, testAdminUserId)).called(1);
    });

    test('should save draft configuration (intermediate step) even if incomplete', () async {
      // Arrange
      final draftConfig = WizardConfiguration(
        groupId: 'test-group-123',
        selectedCategories: const ['cat1'], // Only one category selected
        categoryBudgets: const {
          'cat1': 50000,
        },
        memberAllocations: const {}, // No allocations yet
        currentStep: 1, // Still on step 1
      );

      // For draft saving, we should use saveDraft instead of saveConfiguration
      // But this test is for saveConfiguration which requires full validation
      // So this should fail validation

      // Act
      final result = await useCase(
        SaveWizardConfigurationParams(
          configuration: draftConfig,
          adminUserId: testAdminUserId,
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
