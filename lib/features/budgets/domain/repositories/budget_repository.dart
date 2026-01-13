import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/budget_composition_entity.dart';
import '../entities/budget_stats_entity.dart';
import '../entities/category_budget_entity.dart';
import '../entities/computed_budget_totals_entity.dart';
import '../entities/group_budget_entity.dart';
import '../entities/personal_budget_entity.dart';
import '../entities/virtual_group_expenses_category_entity.dart';
import '../entities/income_source_entity.dart';
import '../entities/savings_goal_entity.dart';
import '../entities/group_expense_assignment_entity.dart';
import '../entities/budget_summary_entity.dart';

/// Abstract budget repository interface.
///
/// Defines the contract for budget operations (both group and personal).
/// Implementations should handle the actual communication with the backend (Supabase).
abstract class BudgetRepository {
  // ========== Group Budget Operations ==========

  /// Set or update a group budget for a specific month/year.
  ///
  /// **DEPRECATED**: Use category budgets instead. Group budget is now calculated as SUM of category budgets.
  /// To set a total budget, distribute it across categories or assign to "Altro" system category.
  ///
  /// Only group administrators can perform this operation.
  /// Returns the created/updated group budget.
  @Deprecated(
    'Use category budgets instead. Group budget = SUM(category budgets). '
    'Use distributeToAltroCategory() to set a catch-all budget.',
  )
  Future<Either<Failure, GroupBudgetEntity>> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get group budget for a specific month/year.
  ///
  /// Returns null if no budget is set for the specified period.
  Future<Either<Failure, GroupBudgetEntity?>> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get group budget statistics for a specific month/year.
  ///
  /// Calculates spent amount, remaining amount, percentage used, etc.
  /// Works even if no budget is set (shows spending without budget comparison).
  Future<Either<Failure, BudgetStatsEntity>> getGroupBudgetStats({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get historical group budgets for a group.
  ///
  /// Returns list of past budgets ordered by year/month descending.
  /// Optionally limit the number of results.
  Future<Either<Failure, List<GroupBudgetEntity>>> getGroupBudgetHistory({
    required String groupId,
    int? limit,
  });

  // ========== Personal Budget Operations ==========

  /// Set or update a personal budget for a specific month/year.
  ///
  /// **DEPRECATED**: Use category budgets with member contributions instead.
  /// Personal budget is now calculated as SUM of user's category contributions.
  ///
  /// Returns the created/updated personal budget.
  @Deprecated(
    'Use category budgets with member contributions instead. '
    'Personal budget = SUM(user contributions). '
    'Use setPersonalPercentageBudget() or createCategoryBudget() with member contributions.',
  )
  Future<Either<Failure, PersonalBudgetEntity>> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get personal budget for a specific month/year.
  ///
  /// Returns null if no budget is set for the specified period.
  Future<Either<Failure, PersonalBudgetEntity?>> getPersonalBudget({
    required String userId,
    required int month,
    required int year,
  });

  /// Get personal budget statistics for a specific month/year.
  ///
  /// Calculates spent amount from both personal expenses AND user's group expenses.
  /// Works even if no budget is set (shows spending without budget comparison).
  Future<Either<Failure, BudgetStatsEntity>> getPersonalBudgetStats({
    required String userId,
    required int month,
    required int year,
  });

  /// Get historical personal budgets for a user.
  ///
  /// Returns list of past budgets ordered by year/month descending.
  /// Optionally limit the number of results.
  Future<Either<Failure, List<PersonalBudgetEntity>>> getPersonalBudgetHistory({
    required String userId,
    int? limit,
  });

  // ========== Category Budget Operations (Feature 004) ==========

  /// Get all category budgets for a specific group and month.
  Future<Either<Failure, List>> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  });

  /// Get a single category budget.
  Future<Either<Failure, dynamic>> getCategoryBudget({
    required String categoryId,
    required String groupId,
    required int year,
    required int month,
  });

  /// Create a new category budget.
  Future<Either<Failure, dynamic>> createCategoryBudget({
    required String categoryId,
    required String groupId,
    required int amount,
    required int month,
    required int year,
    bool isGroupBudget = true, // True for group expenses, false for personal expenses
  });

  /// Update an existing category budget amount.
  Future<Either<Failure, dynamic>> updateCategoryBudget({
    required String budgetId,
    required int amount,
  });

  /// Delete a category budget.
  Future<Either<Failure, Unit>> deleteCategoryBudget(String budgetId);

  /// Get budget statistics for a specific category and month (via RPC).
  Future<Either<Failure, dynamic>> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Get overall group budget statistics for dashboard (via RPC).
  Future<Either<Failure, dynamic>> getOverallGroupBudgetStats({
    required String groupId,
    required int year,
    required int month,
  });

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  /// Get group members with their percentage budget contributions
  Future<Either<Failure, List>> getGroupMembersWithPercentages({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Calculate percentage budget amount
  Future<Either<Failure, int>> calculatePercentageBudget({
    required int groupBudgetAmount,
    required double percentage,
  });

  /// Get budget change notifications for user
  Future<Either<Failure, List>> getBudgetChangeNotifications({
    required String groupId,
    required int year,
    required int month,
    String? userId,
  });

  /// Set personal percentage budget
  Future<Either<Failure, dynamic>> setPersonalPercentageBudget({
    required String categoryId,
    required String groupId,
    required String userId,
    required double percentage,
    required int month,
    required int year,
  });

  /// Get percentage from previous month
  Future<Either<Failure, double?>> getPreviousMonthPercentage({
    required String categoryId,
    required String groupId,
    required String userId,
    required int year,
    required int month,
  });

  /// Get percentage history for a user/category
  Future<Either<Failure, List>> getPercentageHistory({
    required String categoryId,
    required String groupId,
    required String userId,
    int? limit,
  });

  // ========== Unified Budget Composition (New System) ==========

  /// Get complete budget composition for a group in a specific month
  ///
  /// Returns a unified view of:
  /// - Group budget (total monthly budget)
  /// - All category budgets with member contributions
  /// - Aggregate spending statistics
  /// - Validation issues
  ///
  /// This is the main method used by the new unified budget system.
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.getBudgetComposition(
  ///   groupId: 'group123',
  ///   year: 2026,
  ///   month: 1,
  /// );
  /// result.fold(
  ///   (failure) => handleError(failure),
  ///   (composition) => displayBudget(composition),
  /// );
  /// ```
  Future<Either<Failure, BudgetComposition>> getBudgetComposition({
    required String groupId,
    required int year,
    required int month,
  });

  // ========== Computed Budget Totals (Category-Only System) ==========

  /// Get computed budget totals calculated from category budgets
  ///
  /// Returns:
  /// - Total group budget (SUM of all category budgets)
  /// - Total personal budget (SUM of user's contributions)
  /// - Category and member breakdowns
  ///
  /// This replaces manual GroupBudgetEntity and PersonalBudgetEntity
  /// with calculated values from the category budget system.
  Future<Either<Failure, ComputedBudgetTotals>> getComputedBudgetTotals({
    required String groupId,
    required String userId,
    required int year,
    required int month,
  });

  /// Ensure "Altro" system category budget exists for the group/month
  ///
  /// Auto-creates the "Altro" category budget if it doesn't exist.
  /// "Altro" is the catch-all category for uncategorized expenses.
  ///
  /// Returns the existing or newly created "Altro" category budget.
  Future<Either<Failure, CategoryBudgetEntity>> ensureAltroCategory({
    required String groupId,
    required int year,
    required int month,
  });

  /// Distribute an amount to "Altro" system category
  ///
  /// This is the replacement for setGroupBudget() - instead of setting
  /// a manual group budget total, assign the amount to the "Altro" category.
  ///
  /// Only group administrators can perform this operation.
  Future<Either<Failure, CategoryBudgetEntity>> distributeToAltroCategory({
    required String groupId,
    required int amount,
    required int year,
    required int month,
  });

  /// Calculate virtual "Spese di Gruppo" category for personal budget view
  ///
  /// Returns a virtual category showing:
  /// - Budget = SUM of user's contributions in group categories
  /// - Spent = SUM of group expenses created by user
  /// - Category breakdown
  ///
  /// This category is NOT stored in database, computed on-demand.
  /// It appears ONLY in personal budget view, not in group budget view.
  Future<Either<Failure, VirtualGroupExpensesCategory>> calculateVirtualGroupCategory({
    required String groupId,
    required String userId,
    required int year,
    required int month,
  });

  // ========== Personal Income & Savings Operations (Feature 001) ==========

  /// Get all income sources for a user
  Future<Either<Failure, List<IncomeSourceEntity>>> getIncomeSources(
      String userId);

  /// Get a specific income source by ID
  Future<Either<Failure, IncomeSourceEntity>> getIncomeSource(String id);

  /// Add a new income source
  /// Returns the created entity with server-generated ID
  Future<Either<Failure, IncomeSourceEntity>> addIncomeSource(
      IncomeSourceEntity incomeSource);

  /// Update an existing income source
  Future<Either<Failure, IncomeSourceEntity>> updateIncomeSource(
      IncomeSourceEntity incomeSource);

  /// Delete an income source
  Future<Either<Failure, void>> deleteIncomeSource(String id);

  /// Calculate total monthly income from all sources
  Future<Either<Failure, int>> getTotalIncome(String userId);

  /// Get the user's savings goal (null if not set)
  Future<Either<Failure, SavingsGoalEntity?>> getSavingsGoal(String userId);

  /// Set or update the user's savings goal
  /// If a goal already exists, it updates it; otherwise creates a new one
  Future<Either<Failure, SavingsGoalEntity>> setSavingsGoal(
      SavingsGoalEntity savingsGoal);

  /// Update savings goal amount (preserves original_amount if already adjusted)
  Future<Either<Failure, SavingsGoalEntity>> updateSavingsGoalAmount({
    required String userId,
    required int newAmount,
  });

  /// Automatically adjust savings goal due to group expense constraints
  /// Sets original_amount and adjusted_at timestamp
  Future<Either<Failure, SavingsGoalEntity>> autoAdjustSavingsGoal({
    required String userId,
    required int newAmount,
  });

  /// Delete the user's savings goal
  Future<Either<Failure, void>> deleteSavingsGoal(String userId);

  /// Get all group expense assignments for a user
  Future<Either<Failure, List<GroupExpenseAssignmentEntity>>>
      getGroupExpenseAssignments(String userId);

  /// Get a specific group expense assignment by ID
  Future<Either<Failure, GroupExpenseAssignmentEntity>>
      getGroupExpenseAssignment(String id);

  /// Add a new group expense assignment (typically by group admin)
  Future<Either<Failure, GroupExpenseAssignmentEntity>>
      addGroupExpenseAssignment(GroupExpenseAssignmentEntity assignment);

  /// Update an existing group expense assignment
  Future<Either<Failure, GroupExpenseAssignmentEntity>>
      updateGroupExpenseAssignment(GroupExpenseAssignmentEntity assignment);

  /// Delete a group expense assignment (when user leaves group)
  Future<Either<Failure, void>> deleteGroupExpenseAssignment(String id);

  /// Calculate total group expense spending limits
  Future<Either<Failure, int>> getTotalGroupExpenses(String userId);

  /// Compute a complete budget summary for the user
  /// Aggregates income, savings goal, and group expenses
  Future<Either<Failure, BudgetSummaryEntity>> getBudgetSummary(String userId);

  /// Calculate available budget amount
  /// Formula: totalIncome - savingsGoal - totalGroupExpenses
  Future<Either<Failure, int>> getAvailableBudget(String userId);

  /// Add multiple income sources at once (used during wizard setup)
  Future<Either<Failure, List<IncomeSourceEntity>>> addIncomeSources(
      List<IncomeSourceEntity> incomeSources);

  /// Delete all income sources for a user
  Future<Either<Failure, void>> deleteAllIncomeSources(String userId);

  /// Delete all group expense assignments for a user (when leaving all groups)
  Future<Either<Failure, void>> deleteAllGroupExpenseAssignments(String userId);

  /// Stream of income sources for a user (updates when data changes)
  Stream<List<IncomeSourceEntity>> watchIncomeSources(String userId);

  /// Stream of savings goal for a user
  Stream<SavingsGoalEntity?> watchSavingsGoal(String userId);

  /// Stream of group expense assignments for a user
  Stream<List<GroupExpenseAssignmentEntity>> watchGroupExpenseAssignments(
      String userId);

  /// Stream of budget summary (recomputes on any change)
  Stream<BudgetSummaryEntity> watchBudgetSummary(String userId);
}
