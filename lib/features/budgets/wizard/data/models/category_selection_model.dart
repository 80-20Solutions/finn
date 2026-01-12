import '../../domain/entities/category_selection.dart';

/// Category selection model for JSON serialization/deserialization.
/// Feature: 001-group-budget-wizard, Task: T011
///
/// Maps expense_categories table schema to CategorySelection domain entity.
class CategorySelectionModel extends CategorySelection {
  const CategorySelectionModel({
    required super.categoryId,
    required super.categoryName,
    super.icon,
    super.color,
    super.isSystemCategory,
  });

  /// Create from JSON (expense_categories table format)
  factory CategorySelectionModel.fromJson(Map<String, dynamic> json) {
    return CategorySelectionModel(
      categoryId: json['id'] as String,
      categoryName: json['name_it'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isSystemCategory: json['is_system_category'] as bool? ?? false,
    );
  }

  /// Convert to JSON (API format)
  Map<String, dynamic> toJson() {
    return {
      'id': categoryId,
      'name_it': categoryName,
      'icon': icon,
      'color': color,
      'is_system_category': isSystemCategory,
    };
  }

  /// Create from domain entity
  factory CategorySelectionModel.fromEntity(CategorySelection entity) {
    return CategorySelectionModel(
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      icon: entity.icon,
      color: entity.color,
      isSystemCategory: entity.isSystemCategory,
    );
  }

  /// Convert to domain entity
  CategorySelection toEntity() {
    return CategorySelection(
      categoryId: categoryId,
      categoryName: categoryName,
      icon: icon,
      color: color,
      isSystemCategory: isSystemCategory,
    );
  }

  @override
  CategorySelectionModel copyWith({
    String? categoryId,
    String? categoryName,
    String? icon,
    String? color,
    bool? isSystemCategory,
  }) {
    return CategorySelectionModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystemCategory: isSystemCategory ?? this.isSystemCategory,
    );
  }
}
