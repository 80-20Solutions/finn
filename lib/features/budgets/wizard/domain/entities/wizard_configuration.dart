import 'package:equatable/equatable.dart';

/// Wizard configuration entity representing complete budget setup.
/// Feature: 001-group-budget-wizard, Task: T006
///
/// This is the aggregate root for the wizard domain, combining category
/// selections, budget allocations, and member percentage distributions.
class WizardConfiguration extends Equatable {
  const WizardConfiguration({
    required this.groupId,
    required this.selectedCategories,
    required this.categoryBudgets,
    required this.memberAllocations,
    this.currentStep = 0,
  });

  /// The family group ID this configuration belongs to
  final String groupId;

  /// List of selected expense category IDs (step 1 selection)
  final List<String> selectedCategories;

  /// Budget amounts per category in cents
  /// Key: category_id, Value: amount in cents (e.g., 50000 = €500.00)
  final Map<String, int> categoryBudgets;

  /// Member allocation percentages (must sum to 100.00%)
  /// Key: user_id, Value: percentage (e.g., 33.33)
  final Map<String, double> memberAllocations;

  /// Current wizard step index (0-based)
  final int currentStep;

  /// Validate configuration completeness
  bool get isValid {
    return selectedCategories.isNotEmpty &&
        categoryBudgets.length == selectedCategories.length &&
        _isBudgetAmountsValid() &&
        _isMemberAllocationsValid();
  }

  /// Check if all budget amounts are positive
  bool _isBudgetAmountsValid() {
    return categoryBudgets.values.every((amount) => amount > 0);
  }

  /// Check if member allocations sum to exactly 100%
  bool _isMemberAllocationsValid() {
    if (memberAllocations.isEmpty) return false;
    final total = memberAllocations.values.fold(0.0, (sum, val) => sum + val);
    // Allow ±0.01% tolerance for floating-point rounding
    return (total - 100.0).abs() <= 0.01;
  }

  /// Get total group budget across all categories
  int get totalGroupBudget {
    return categoryBudgets.values.fold(0, (sum, amount) => sum + amount);
  }

  /// Create a copy with updated fields
  WizardConfiguration copyWith({
    String? groupId,
    List<String>? selectedCategories,
    Map<String, int>? categoryBudgets,
    Map<String, double>? memberAllocations,
    int? currentStep,
  }) {
    return WizardConfiguration(
      groupId: groupId ?? this.groupId,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      memberAllocations: memberAllocations ?? this.memberAllocations,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        selectedCategories,
        categoryBudgets,
        memberAllocations,
        currentStep,
      ];

  @override
  String toString() {
    return 'WizardConfiguration(groupId: $groupId, '
        'categories: ${selectedCategories.length}, '
        'totalBudget: €${totalGroupBudget / 100}, '
        'members: ${memberAllocations.length})';
  }
}
