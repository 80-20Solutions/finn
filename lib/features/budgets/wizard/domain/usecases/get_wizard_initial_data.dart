import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../groups/domain/repositories/group_repository.dart';
import '../entities/category_selection.dart';
import '../entities/wizard_configuration.dart';
import '../repositories/wizard_repository.dart';

/// Use case for getting initial wizard data (categories, members, existing draft).
/// Feature: 001-group-budget-wizard, Task: T026
class GetWizardInitialData {
  GetWizardInitialData({
    required this.wizardRepository,
    required this.categoryRepository,
    required this.groupRepository,
  });

  final WizardRepository wizardRepository;
  final CategoryRepository categoryRepository;
  final GroupRepository groupRepository;

  Future<Either<Failure, WizardInitialData>> call(
    GetWizardInitialDataParams params,
  ) async {
    try {
      // Fetch categories
      final categoriesResult = await categoryRepository.getAllCategories();
      if (categoriesResult.isLeft()) {
        return categoriesResult.fold(
          (failure) => Left(failure),
          (_) => const Left(ServerFailure('Unexpected error fetching categories')),
        );
      }

      final categories = categoriesResult.fold(
        (_) => <CategorySelection>[],
        (cats) => cats as List<CategorySelection>,
      );

      // Fetch group members
      final membersResult = await groupRepository.getGroupMembers(params.groupId);
      if (membersResult.isLeft()) {
        return membersResult.fold(
          (failure) => Left(failure),
          (_) => const Left(ServerFailure('Unexpected error fetching members')),
        );
      }

      final members = membersResult.fold(
        (_) => <Map<String, dynamic>>[],
        (mems) => mems as List<Map<String, dynamic>>,
      );

      // Fetch existing draft (if any)
      final draftResult = await wizardRepository.getDraft(params.groupId);
      if (draftResult.isLeft()) {
        // Cache failure is non-critical, continue without draft
        return draftResult.fold(
          (failure) {
            // Only return failure for critical errors
            if (failure is! CacheFailure) {
              return Left(failure);
            }
            // Continue without draft for cache failures
            return Right(WizardInitialData(
              categories: categories,
              members: members,
              existingDraft: null,
            ));
          },
          (_) => const Left(ServerFailure('Unexpected error')),
        );
      }

      final existingDraft = draftResult.fold(
        (_) => null,
        (draft) => draft,
      );

      return Right(WizardInitialData(
        categories: categories,
        members: members,
        existingDraft: existingDraft,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Parameters for GetWizardInitialData use case
class GetWizardInitialDataParams {
  const GetWizardInitialDataParams({required this.groupId});

  final String groupId;
}

/// Result data from GetWizardInitialData use case
class WizardInitialData {
  const WizardInitialData({
    required this.categories,
    required this.members,
    this.existingDraft,
  });

  final List<CategorySelection> categories;
  final List<Map<String, dynamic>> members;
  final WizardConfiguration? existingDraft;
}
