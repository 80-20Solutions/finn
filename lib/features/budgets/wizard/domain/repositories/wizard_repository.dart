import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failures.dart';
import '../entities/wizard_configuration.dart';

/// Abstract wizard repository interface.
/// Feature: 001-group-budget-wizard, Task: T012
///
/// Defines the contract for wizard configuration persistence operations.
/// Implementations handle both local caching (Hive) and remote persistence (Supabase).
abstract class WizardRepository {
  // ========== Draft Operations (Local Cache) ==========

  /// Save wizard draft to local cache (Hive).
  ///
  /// Called after each step completion (category selection, budget amounts, member allocations).
  /// Cache expires after 24 hours (see research.md Decision 1).
  ///
  /// Returns Unit on success.
  Future<Either<Failure, Unit>> saveDraft(WizardConfiguration configuration);

  /// Get wizard draft from local cache.
  ///
  /// Returns null if no draft exists or cache is expired (>24 hours).
  /// Used on wizard screen mount to restore previous session.
  Future<Either<Failure, WizardConfiguration?>> getDraft(String groupId);

  /// Clear wizard draft from local cache.
  ///
  /// Called after successful final submission or manual cancellation.
  /// Returns Unit on success.
  Future<Either<Failure, Unit>> clearCache(String groupId);

  // ========== Final Submission (Remote Persistence) ==========

  /// Save final wizard configuration to Supabase.
  ///
  /// Performs batch operations:
  /// 1. Insert multiple category_budgets rows (group budgets)
  /// 2. Insert member percentage budgets (user-specific category_budgets)
  /// 3. Update profiles.budget_wizard_completed = true
  /// 4. Clear local cache
  ///
  /// All operations run in a transaction (either all succeed or all fail).
  /// Only group administrators can perform this operation.
  ///
  /// Returns Unit on success.
  Future<Either<Failure, Unit>> saveConfiguration(
    WizardConfiguration configuration,
    String adminUserId,
  );

  // ========== Validation Helpers ==========

  /// Check if wizard has already been completed for this group.
  ///
  /// Queries profiles.budget_wizard_completed for the current admin.
  /// Used by router guard to decide whether to show wizard or dashboard.
  ///
  /// Returns true if completed, false otherwise.
  Future<Either<Failure, bool>> isWizardCompleted(String adminUserId);
}
