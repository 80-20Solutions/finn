import '../../domain/entities/group_spending_breakdown.dart';
import 'sub_category_spending_model.dart';

/// Group spending breakdown model for JSON serialization.
/// Feature: 001-group-budget-wizard, Task: T049
class GroupSpendingBreakdownModel extends GroupSpendingBreakdown {
  const GroupSpendingBreakdownModel({
    required super.totalAllocatedCents,
    required super.totalSpentCents,
    required super.subCategories,
  });

  /// Create model from JSON (from Supabase RPC response).
  factory GroupSpendingBreakdownModel.fromJson(Map<String, dynamic> json) {
    final subCategoriesList = json['sub_categories'] as List<dynamic>?;

    return GroupSpendingBreakdownModel(
      totalAllocatedCents: json['total_allocated_cents'] as int,
      totalSpentCents: json['total_spent_cents'] as int,
      subCategories: subCategoriesList != null
          ? subCategoriesList
              .map((cat) =>
                  SubCategorySpendingModel.fromJson(cat as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Convert model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'total_allocated_cents': totalAllocatedCents,
      'total_spent_cents': totalSpentCents,
      'sub_categories': subCategories
          .map((cat) => SubCategorySpendingModel.fromEntity(cat).toJson())
          .toList(),
    };
  }

  /// Create model from domain entity.
  factory GroupSpendingBreakdownModel.fromEntity(
    GroupSpendingBreakdown entity,
  ) {
    return GroupSpendingBreakdownModel(
      totalAllocatedCents: entity.totalAllocatedCents,
      totalSpentCents: entity.totalSpentCents,
      subCategories: entity.subCategories,
    );
  }
}
