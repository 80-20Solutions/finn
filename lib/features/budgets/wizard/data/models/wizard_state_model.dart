import '../../domain/entities/wizard_configuration.dart';

/// Wizard state model for JSON serialization/deserialization.
/// Feature: 001-group-budget-wizard, Task: T009
///
/// Extends WizardConfiguration entity with Hive cache persistence capabilities.
class WizardStateModel extends WizardConfiguration {
  const WizardStateModel({
    required super.groupId,
    required super.selectedCategories,
    required super.categoryBudgets,
    required super.memberAllocations,
    super.currentStep,
    this.timestamp,
  });

  /// Cache timestamp for expiry calculation
  final DateTime? timestamp;

  /// Create from JSON (Hive cache format)
  factory WizardStateModel.fromJson(Map<String, dynamic> json) {
    return WizardStateModel(
      groupId: json['group_id'] as String,
      selectedCategories:
          List<String>.from(json['selected_category_ids'] as List),
      categoryBudgets: Map<String, int>.from(
        (json['category_budgets'] as Map).map(
          (key, value) => MapEntry(key as String, value as int),
        ),
      ),
      memberAllocations: Map<String, double>.from(
        (json['member_allocations'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      currentStep: json['current_step'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Convert to JSON (Hive cache format)
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'selected_category_ids': selectedCategories,
      'category_budgets': categoryBudgets,
      'member_allocations': memberAllocations,
      'current_step': currentStep,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Check if cache is expired (>24 hours old)
  bool get isExpired {
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp!).inHours >= 24;
  }

  /// Create from domain entity
  factory WizardStateModel.fromEntity(WizardConfiguration entity) {
    return WizardStateModel(
      groupId: entity.groupId,
      selectedCategories: entity.selectedCategories,
      categoryBudgets: entity.categoryBudgets,
      memberAllocations: entity.memberAllocations,
      currentStep: entity.currentStep,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to domain entity
  WizardConfiguration toEntity() {
    return WizardConfiguration(
      groupId: groupId,
      selectedCategories: selectedCategories,
      categoryBudgets: categoryBudgets,
      memberAllocations: memberAllocations,
      currentStep: currentStep,
    );
  }

  @override
  WizardStateModel copyWith({
    String? groupId,
    List<String>? selectedCategories,
    Map<String, int>? categoryBudgets,
    Map<String, double>? memberAllocations,
    int? currentStep,
    DateTime? timestamp,
  }) {
    return WizardStateModel(
      groupId: groupId ?? this.groupId,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      memberAllocations: memberAllocations ?? this.memberAllocations,
      currentStep: currentStep ?? this.currentStep,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
