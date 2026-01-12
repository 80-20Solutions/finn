import '../../domain/entities/sub_category_spending.dart';

/// Sub-category spending model for JSON serialization.
/// Feature: 001-group-budget-wizard, Task: T050
class SubCategorySpendingModel extends SubCategorySpending {
  const SubCategorySpendingModel({
    required super.categoryId,
    required super.categoryName,
    required super.allocatedCents,
    required super.spentCents,
    required super.icon,
    required super.color,
  });

  /// Create model from JSON (from Supabase RPC response).
  factory SubCategorySpendingModel.fromJson(Map<String, dynamic> json) {
    return SubCategorySpendingModel(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      allocatedCents: json['allocated_cents'] as int,
      spentCents: json['spent_cents'] as int,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }

  /// Convert model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'allocated_cents': allocatedCents,
      'spent_cents': spentCents,
      'icon': icon,
      'color': color,
    };
  }

  /// Create model from domain entity.
  factory SubCategorySpendingModel.fromEntity(SubCategorySpending entity) {
    return SubCategorySpendingModel(
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      allocatedCents: entity.allocatedCents,
      spentCents: entity.spentCents,
      icon: entity.icon,
      color: entity.color,
    );
  }
}
