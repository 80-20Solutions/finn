import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/wizard_configuration.dart';
import '../repositories/wizard_repository.dart';

/// Use case for saving wizard configuration to Supabase.
/// Feature: 001-group-budget-wizard, Task: T027
///
/// Validates the configuration before persisting to ensure data integrity.
class SaveWizardConfiguration {
  SaveWizardConfiguration({required this.repository});

  final WizardRepository repository;

  Future<Either<Failure, Unit>> call(
    SaveWizardConfigurationParams params,
  ) async {
    // Validate configuration before saving
    if (!params.configuration.isValid) {
      return const Left(
        ValidationFailure('Configuration is invalid. Please check all fields.'),
      );
    }

    // Save configuration to Supabase
    return await repository.saveConfiguration(
      params.configuration,
      params.adminUserId,
    );
  }
}

/// Parameters for SaveWizardConfiguration use case
class SaveWizardConfigurationParams {
  const SaveWizardConfigurationParams({
    required this.configuration,
    required this.adminUserId,
  });

  final WizardConfiguration configuration;
  final String adminUserId;
}
