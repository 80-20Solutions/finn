// Data Model: Category Budget Model extending CategoryBudgetEntity
// Feature: Italian Categories and Budget Management (004)
// Task: T027

import '../../domain/entities/category_budget_entity.dart';

class CategoryBudgetModel extends CategoryBudgetEntity {
  const CategoryBudgetModel({
    required super.id,
    required super.categoryId,
    required super.groupId,
    required super.amount,
    required super.month,
    required super.year,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create CategoryBudgetModel from JSON (Supabase response)
  factory CategoryBudgetModel.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      groupId: json['group_id'] as String,
      amount: json['amount'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert CategoryBudgetModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'group_id': groupId,
      'amount': amount,
      'month': month,
      'year': year,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to CategoryBudgetEntity
  CategoryBudgetEntity toEntity() => this;

  /// Create CategoryBudgetModel from CategoryBudgetEntity
  factory CategoryBudgetModel.fromEntity(CategoryBudgetEntity entity) {
    return CategoryBudgetModel(
      id: entity.id,
      categoryId: entity.categoryId,
      groupId: entity.groupId,
      amount: entity.amount,
      month: entity.month,
      year: entity.year,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
