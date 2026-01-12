import 'package:dartz/dartz.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../domain/entities/wizard_configuration.dart';
import '../../domain/repositories/wizard_repository.dart';
import '../datasources/wizard_local_datasource.dart';
import '../datasources/wizard_remote_datasource.dart';
import '../models/wizard_state_model.dart';

/// Implementation of [WizardRepository] using local and remote data sources.
/// Feature: 001-group-budget-wizard, Task: T015
class WizardRepositoryImpl implements WizardRepository {
  WizardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final WizardRemoteDataSource remoteDataSource;
  final WizardLocalDataSource localDataSource;

  // ========== Draft Operations (Local Cache) ==========

  @override
  Future<Either<Failure, Unit>> saveDraft(
    WizardConfiguration configuration,
  ) async {
    try {
      final model = WizardStateModel.fromEntity(configuration);
      await localDataSource.cacheDraft(model);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WizardConfiguration?>> getDraft(String groupId) async {
    try {
      final model = await localDataSource.getDraft(groupId);
      if (model == null) return const Right(null);

      // Check if cache is expired
      if (model.isExpired) {
        await localDataSource.clearCache(groupId);
        return const Right(null);
      }

      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCache(String groupId) async {
    try {
      await localDataSource.clearCache(groupId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ========== Final Submission (Remote Persistence) ==========

  @override
  Future<Either<Failure, Unit>> saveConfiguration(
    WizardConfiguration configuration,
    String adminUserId,
  ) async {
    try {
      // Convert to model for persistence
      final model = WizardStateModel.fromEntity(configuration);

      // Save to remote (Supabase)
      await remoteDataSource.saveConfiguration(
        configuration: model,
        adminUserId: adminUserId,
      );

      // Clear local cache after successful save
      await localDataSource.clearCache(configuration.groupId);

      return const Right(unit);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Validation Helpers ==========

  @override
  Future<Either<Failure, bool>> isWizardCompleted(String adminUserId) async {
    try {
      final completed = await remoteDataSource.isWizardCompleted(adminUserId);
      return Right(completed);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
