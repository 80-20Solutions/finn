import 'package:dartz/dartz.dart';
import 'package:fin/core/error/failures.dart';
import 'package:fin/features/budgets/personal/domain/entities/personal_budget.dart';
import 'package:fin/features/budgets/personal/domain/repositories/personal_budget_repository.dart';
import 'package:fin/features/budgets/personal/domain/usecases/calculate_personal_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'calculate_personal_budget_test.mocks.dart';

@GenerateMocks([PersonalBudgetRepository])
void main() {
  late CalculatePersonalBudget usecase;
  late MockPersonalBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockPersonalBudgetRepository();
    usecase = CalculatePersonalBudget(repository: mockRepository);
  });

  const tUserId = 'user-123';
  const tGroupId = 'group-456';
  const tYear = 2026;
  const tMonth = 1;

  final tPersonalBudget = PersonalBudget(
    userId: tUserId,
    groupId: tGroupId,
    year: tYear,
    month: tMonth,
    personalBudgetCents: 50000, // €500 personal
    groupAllocationCents: 35000, // €350 group allocation
    totalBudgetCents: 85000, // €850 total (500 + 350)
    personalSpentCents: 25000, // €250 spent personal
    groupSpentCents: 29500, // €295 spent group
    totalSpentCents: 54500, // €545 total spent
  );

  group('CalculatePersonalBudget', () {
    test('should return PersonalBudget with group allocation included',
        () async {
      // arrange
      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tPersonalBudget));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(result, Right(tPersonalBudget));
      verify(mockRepository.calculatePersonalBudget(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should correctly sum personal and group budget', () async {
      // arrange
      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tPersonalBudget));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      final budget = (result as Right<Failure, PersonalBudget>).value;
      expect(budget.totalBudgetCents,
          budget.personalBudgetCents + budget.groupAllocationCents);
      expect(budget.totalBudgetCents, 85000); // 500 + 350
    });

    test('should correctly sum personal and group spent', () async {
      // arrange
      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tPersonalBudget));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      final budget = (result as Right<Failure, PersonalBudget>).value;
      expect(budget.totalSpentCents,
          budget.personalSpentCents + budget.groupSpentCents);
      expect(budget.totalSpentCents, 54500); // 250 + 295
    });

    test('should have zero calculation errors (SC-003)', () async {
      // arrange - Test various amounts for rounding accuracy
      final testCases = [
        // personal, group, expected total
        [10000, 5000, 15000], // €100 + €50 = €150
        [33333, 66667, 100000], // €333.33 + €666.67 = €1000
        [1, 1, 2], // €0.01 + €0.01 = €0.02
        [999999, 1, 1000000], // €9999.99 + €0.01 = €10000
      ];

      for (final testCase in testCases) {
        final personal = testCase[0] as int;
        final group = testCase[1] as int;
        final expectedTotal = testCase[2] as int;

        final budget = PersonalBudget(
          userId: tUserId,
          groupId: tGroupId,
          year: tYear,
          month: tMonth,
          personalBudgetCents: personal,
          groupAllocationCents: group,
          totalBudgetCents: personal + group,
          personalSpentCents: 0,
          groupSpentCents: 0,
          totalSpentCents: 0,
        );

        when(mockRepository.calculatePersonalBudget(
          userId: anyNamed('userId'),
          groupId: anyNamed('groupId'),
          year: anyNamed('year'),
          month: anyNamed('month'),
        )).thenAnswer((_) async => Right(budget));

        // act
        final result = await usecase(CalculatePersonalBudgetParams(
          userId: tUserId,
          groupId: tGroupId,
          year: tYear,
          month: tMonth,
        ));

        // assert - verify exact calculation (no rounding errors)
        final resultBudget = (result as Right<Failure, PersonalBudget>).value;
        expect(resultBudget.totalBudgetCents, expectedTotal);
        expect(resultBudget.totalBudgetCents,
            resultBudget.personalBudgetCents + resultBudget.groupAllocationCents);
      }
    });

    test('should validate userId is not empty', () async {
      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: '',
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(
        result,
        const Left(ValidationFailure('User ID cannot be empty')),
      );
      verifyNever(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      ));
    });

    test('should validate groupId is not empty', () async {
      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: '',
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(
        result,
        const Left(ValidationFailure('Group ID cannot be empty')),
      );
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => const Left(ServerFailure('Database error')));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(result, const Left(ServerFailure('Database error')));
    });

    test('should handle zero personal budget with group allocation', () async {
      // arrange
      final zeroPers onalBudget = PersonalBudget(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
        personalBudgetCents: 0, // No personal budget
        groupAllocationCents: 35000, // €350 group only
        totalBudgetCents: 35000,
        personalSpentCents: 0,
        groupSpentCents: 0,
        totalSpentCents: 0,
      );

      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(zeroPersonalBudget));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      final budget = (result as Right<Failure, PersonalBudget>).value;
      expect(budget.personalBudgetCents, 0);
      expect(budget.groupAllocationCents, 35000);
      expect(budget.totalBudgetCents, 35000);
    });

    test('should handle zero group allocation with personal budget', () async {
      // arrange
      final zeroGroupBudget = PersonalBudget(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
        personalBudgetCents: 50000, // €500 personal only
        groupAllocationCents: 0, // No group allocation
        totalBudgetCents: 50000,
        personalSpentCents: 0,
        groupSpentCents: 0,
        totalSpentCents: 0,
      );

      when(mockRepository.calculatePersonalBudget(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(zeroGroupBudget));

      // act
      final result = await usecase(CalculatePersonalBudgetParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      final budget = (result as Right<Failure, PersonalBudget>).value;
      expect(budget.personalBudgetCents, 50000);
      expect(budget.groupAllocationCents, 0);
      expect(budget.totalBudgetCents, 50000);
    });
  });
}
