import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:family_expense_tracker/core/errors/failures.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/category_selection.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/entities/wizard_configuration.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/repositories/wizard_repository.dart';
import 'package:family_expense_tracker/features/budgets/wizard/domain/usecases/get_wizard_initial_data.dart';
import 'package:family_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:family_expense_tracker/features/groups/domain/repositories/group_repository.dart';

import 'get_wizard_initial_data_test.mocks.dart';

/// Unit tests for GetWizardInitialData use case.
/// Feature: 001-group-budget-wizard, Task: T018
@GenerateMocks([WizardRepository, CategoryRepository, GroupRepository])
void main() {
  late GetWizardInitialData useCase;
  late MockWizardRepository mockWizardRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockWizardRepository = MockWizardRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockGroupRepository = MockGroupRepository();
    useCase = GetWizardInitialData(
      wizardRepository: mockWizardRepository,
      categoryRepository: mockCategoryRepository,
      groupRepository: mockGroupRepository,
    );
  });

  const testGroupId = 'test-group-123';

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

  final testMembers = [
    {
      'user_id': 'user1',
      'display_name': 'Alice',
    },
    {
      'user_id': 'user2',
      'display_name': 'Bob',
    },
    {
      'user_id': 'user3',
      'display_name': 'Charlie',
    },
  ];

  group('GetWizardInitialData', () {
    test('should return initial data with categories and members when no draft exists', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right(testCategories as dynamic));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => Right(testMembers as dynamic));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (data) {
          expect(data.categories, hasLength(3));
          expect(data.categories[0].categoryName, 'Cibo e Spesa');
          expect(data.members, hasLength(3));
          expect(data.members[0]['display_name'], 'Alice');
          expect(data.existingDraft, isNull);
        },
      );

      // Verify interactions
      verify(mockCategoryRepository.getAllCategories()).called(1);
      verify(mockGroupRepository.getGroupMembers(testGroupId)).called(1);
      verify(mockWizardRepository.getDraft(testGroupId)).called(1);
    });

    test('should return initial data with existing draft when draft exists', () async {
      // Arrange
      final existingDraft = WizardConfiguration(
        groupId: testGroupId,
        selectedCategories: const ['cat1', 'cat2'],
        categoryBudgets: const {
          'cat1': 50000,
          'cat2': 30000,
        },
        memberAllocations: const {
          'user1': 60.0,
          'user2': 40.0,
        },
        currentStep: 2,
      );

      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right(testCategories as dynamic));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => Right(testMembers as dynamic));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => Right(existingDraft));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (data) {
          expect(data.categories, hasLength(3));
          expect(data.members, hasLength(3));
          expect(data.existingDraft, isNotNull);
          expect(data.existingDraft!.currentStep, 2);
          expect(data.existingDraft!.selectedCategories, hasLength(2));
        },
      );
    });

    test('should return ServerFailure when category repository fails', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => const Left(ServerFailure('Database error')));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => Right(testMembers as dynamic));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Database error');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return ServerFailure when group repository fails', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right(testCategories as dynamic));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => const Left(ServerFailure('Group not found')));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Group not found');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return CacheFailure when wizard repository draft retrieval fails', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right(testCategories as dynamic));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => Right(testMembers as dynamic));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Left(CacheFailure('Cache read error')));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect((failure as CacheFailure).message, 'Cache read error');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return empty categories list when no categories exist', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => const Right([]));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => Right(testMembers as dynamic));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (data) {
          expect(data.categories, isEmpty);
          expect(data.members, hasLength(3));
        },
      );
    });

    test('should return empty members list when no group members exist', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right(testCategories as dynamic));
      when(mockGroupRepository.getGroupMembers(testGroupId))
          .thenAnswer((_) async => const Right([]));
      when(mockWizardRepository.getDraft(testGroupId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(GetWizardInitialDataParams(groupId: testGroupId));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (data) {
          expect(data.categories, hasLength(3));
          expect(data.members, isEmpty);
        },
      );
    });
  });
}
