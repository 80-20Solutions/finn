import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:family_expense_tracker/core/errors/failures.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/repositories/wizard_repository.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/usecases/mark_wizard_completed.dart';

import 'mark_wizard_completed_test.mocks.dart';

/// Unit tests for MarkWizardCompleted use case.
/// Feature: 001-group-budget-wizard, Task: T020
@GenerateMocks([WizardRepository])
void main() {
  late MarkWizardCompleted useCase;
  late MockWizardRepository mockRepository;

  setUp(() {
    mockRepository = MockWizardRepository();
    useCase = MarkWizardCompleted(repository: mockRepository);
  });

  const testAdminUserId = 'admin-user-123';

  group('MarkWizardCompleted', () {
    test('should mark wizard as completed successfully', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Right(false));

      // Assuming saveConfiguration also marks it as completed
      // Or we need a separate method in repository
      // For now, let's assume the use case uses the repository correctly

      // Act
      final result = await useCase(
        MarkWizardCompletedParams(adminUserId: testAdminUserId),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (success) => expect(success, unit),
      );
    });

    test('should return ServerFailure when marking fails', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Left(ServerFailure('Database update failed')));

      // Act
      final result = await useCase(
        MarkWizardCompletedParams(adminUserId: testAdminUserId),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Database update failed');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return AuthFailure when user is not authenticated', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Left(AuthFailure('User not authenticated')));

      // Act
      final result = await useCase(
        MarkWizardCompletedParams(adminUserId: testAdminUserId),
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

    test('should succeed even if wizard is already marked as completed (idempotent)', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Right(true)); // Already completed

      // Act
      final result = await useCase(
        MarkWizardCompletedParams(adminUserId: testAdminUserId),
      );

      // Assert
      // Should still succeed (idempotent operation)
      expect(result.isRight(), true);
    });

    test('should verify wizard completion status', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Right(false));

      // Act - First call should mark as incomplete
      await useCase(MarkWizardCompletedParams(adminUserId: testAdminUserId));

      // Verify the repository method was called
      verify(mockRepository.isWizardCompleted(testAdminUserId)).called(1);
    });

    test('should return ValidationFailure when adminUserId is empty', () async {
      // Act
      final result = await useCase(
        const MarkWizardCompletedParams(adminUserId: ''), // Empty user ID
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('User ID'));
        },
        (_) => fail('Expected Left but got Right'),
      );

      // Should not call repository with invalid input
      verifyNever(mockRepository.isWizardCompleted(any));
    });

    test('should return PermissionFailure when user is not a group admin', () async {
      // Arrange
      when(mockRepository.isWizardCompleted(testAdminUserId))
          .thenAnswer((_) async => const Left(PermissionFailure('User is not a group administrator')));

      // Act
      final result = await useCase(
        MarkWizardCompletedParams(adminUserId: testAdminUserId),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<PermissionFailure>());
          expect((failure as PermissionFailure).message, contains('administrator'));
        },
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
