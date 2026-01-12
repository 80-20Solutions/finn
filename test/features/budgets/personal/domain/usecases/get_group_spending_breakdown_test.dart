import 'package:dartz/dartz.dart';
import 'package:fin/core/error/failures.dart';
import 'package:fin/features/budgets/personal/domain/entities/group_spending_breakdown.dart';
import 'package:fin/features/budgets/personal/domain/entities/sub_category_spending.dart';
import 'package:fin/features/budgets/personal/domain/repositories/personal_budget_repository.dart';
import 'package:fin/features/budgets/personal/domain/usecases/get_group_spending_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_group_spending_breakdown_test.mocks.dart';

@GenerateMocks([PersonalBudgetRepository])
void main() {
  late GetGroupSpendingBreakdown usecase;
  late MockPersonalBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockPersonalBudgetRepository();
    usecase = GetGroupSpendingBreakdown(repository: mockRepository);
  });

  const tUserId = 'user-123';
  const tGroupId = 'group-456';
  const tYear = 2026;
  const tMonth = 1;

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

  group('GetGroupSpendingBreakdown', () {
    test('should return GroupSpendingBreakdown from repository', () async {
      // arrange
      when(mockRepository.getGroupSpendingBreakdown(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tBreakdown));

      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(result, Right(tBreakdown));
      verify(mockRepository.getGroupSpendingBreakdown(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(mockRepository.getGroupSpendingBreakdown(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => const Left(ServerFailure('Database error')));

      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(result, const Left(ServerFailure('Database error')));
    });

    test('should validate userId is not empty', () async {
      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
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
      verifyNever(mockRepository.getGroupSpendingBreakdown(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      ));
    });

    test('should validate groupId is not empty', () async {
      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
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

    test('should return breakdown with zero spent when no expenses', () async {
      // arrange
      final tEmptyBreakdown = GroupSpendingBreakdown(
        totalAllocatedCents: 35000,
        totalSpentCents: 0,
        subCategories: [
          SubCategorySpending(
            categoryId: 'cat-1',
            categoryName: 'Cibo',
            allocatedCents: 20000,
            spentCents: 0,
            icon: 'restaurant',
            color: '#FF5722',
          ),
        ],
      );

      when(mockRepository.getGroupSpendingBreakdown(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tEmptyBreakdown));

      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      expect(result, Right(tEmptyBreakdown));
      expect(
        (result as Right<Failure, GroupSpendingBreakdown>)
            .value
            .totalSpentCents,
        0,
      );
    });

    test('should calculate correct totals across all subcategories', () async {
      // arrange
      when(mockRepository.getGroupSpendingBreakdown(
        userId: anyNamed('userId'),
        groupId: anyNamed('groupId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Right(tBreakdown));

      // act
      final result = await usecase(GetGroupSpendingBreakdownParams(
        userId: tUserId,
        groupId: tGroupId,
        year: tYear,
        month: tMonth,
      ));

      // assert
      final breakdown = (result as Right<Failure, GroupSpendingBreakdown>).value;
      final expectedAllocated = tSubCategories.fold<int>(
        0,
        (sum, cat) => sum + cat.allocatedCents,
      );
      final expectedSpent = tSubCategories.fold<int>(
        0,
        (sum, cat) => sum + cat.spentCents,
      );

      expect(breakdown.totalAllocatedCents, expectedAllocated);
      expect(breakdown.totalSpentCents, expectedSpent);
    });
  });
}
