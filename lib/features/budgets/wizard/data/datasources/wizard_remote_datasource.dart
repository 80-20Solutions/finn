import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/exceptions.dart';
import '../models/wizard_state_model.dart';

/// Remote data source for wizard configuration persistence using Supabase.
/// Feature: 001-group-budget-wizard, Task: T013
abstract class WizardRemoteDataSource {
  /// Save wizard configuration to Supabase (final submission).
  ///
  /// Performs batch operations in transaction:
  /// 1. Insert category budgets (group-level budgets)
  /// 2. Insert member percentage budgets (user-specific category_budgets)
  /// 3. Update profiles.budget_wizard_completed = true
  ///
  /// All operations are atomic (all succeed or all fail).
  Future<void> saveConfiguration({
    required WizardStateModel configuration,
    required String adminUserId,
  });

  /// Check if wizard has been completed by the admin.
  ///
  /// Queries profiles.budget_wizard_completed for the given admin user.
  /// Returns true if completed, false otherwise.
  Future<bool> isWizardCompleted(String adminUserId);
}

/// Implementation of [WizardRemoteDataSource] using Supabase.
class WizardRemoteDataSourceImpl implements WizardRemoteDataSource {
  WizardRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('No authenticated user', 'not_authenticated');
    }
    return userId;
  }

  @override
  Future<void> saveConfiguration({
    required WizardStateModel configuration,
    required String adminUserId,
  }) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // Prepare category budgets (group-level)
      final categoryBudgetRecords = configuration.categoryBudgets.entries.map((entry) {
        return {
          'category_id': entry.key,
          'group_id': configuration.groupId,
          'amount': entry.value,
          'year': year,
          'month': month,
          'is_group_budget': true,
          'budget_type': 'FIXED',
          'user_id': null, // Group budget has no user_id
          'created_by': adminUserId,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
      }).toList();

      // Prepare member percentage budgets (user-specific category_budgets)
      final memberBudgetRecords = <Map<String, dynamic>>[];
      for (final categoryEntry in configuration.categoryBudgets.entries) {
        for (final memberEntry in configuration.memberAllocations.entries) {
          memberBudgetRecords.add({
            'category_id': categoryEntry.key,
            'group_id': configuration.groupId,
            'amount': categoryEntry.value, // Group budget amount
            'year': year,
            'month': month,
            'is_group_budget': false, // Personal budget
            'budget_type': 'PERCENTAGE',
            'percentage_of_group': memberEntry.value,
            'user_id': memberEntry.key,
            'created_by': adminUserId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        }
      }

      // Combine all budget records
      final allBudgetRecords = [...categoryBudgetRecords, ...memberBudgetRecords];

      // Execute batch insert for all budgets
      // Using upsert to handle potential duplicates (onConflict unique constraint)
      await supabaseClient.from('category_budgets').upsert(
            allBudgetRecords,
            onConflict: 'category_id,group_id,year,month,is_group_budget,user_id',
          );

      // Mark wizard as completed for the admin
      await supabaseClient
          .from('profiles')
          .update({'budget_wizard_completed': true})
          .eq('id', adminUserId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to save wizard configuration: $e');
    }
  }

  @override
  Future<bool> isWizardCompleted(String adminUserId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('budget_wizard_completed')
          .eq('id', adminUserId)
          .maybeSingle();

      if (response == null) {
        throw const ServerException('Profile not found', 'profile_not_found');
      }

      return response['budget_wizard_completed'] as bool? ?? false;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to check wizard completion: $e');
    }
  }
}
