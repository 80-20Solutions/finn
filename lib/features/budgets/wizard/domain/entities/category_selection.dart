import 'package:equatable/equatable.dart';

/// Category selection entity representing a selected expense category in wizard.
/// Feature: 001-group-budget-wizard, Task: T008
///
/// Lightweight entity for wizard step 1 (category selection) before
/// budget amounts are assigned.
class CategorySelection extends Equatable {
  const CategorySelection({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    this.color,
    this.isSystemCategory = false,
  });

  /// Expense category ID
  final String categoryId;

  /// Italian category name
  final String categoryName;

  /// Material icon name
  final String? icon;

  /// Hex color code
  final String? color;

  /// Whether this is a system-defined category (cannot be deleted)
  final bool isSystemCategory;

  /// Create a copy with updated fields
  CategorySelection copyWith({
    String? categoryId,
    String? categoryName,
    String? icon,
    String? color,
    bool? isSystemCategory,
  }) {
    return CategorySelection(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystemCategory: isSystemCategory ?? this.isSystemCategory,
    );
  }

  @override
  List<Object?> get props => [categoryId, categoryName, icon, color, isSystemCategory];

  @override
  String toString() {
    return 'CategorySelection(name: $categoryName, system: $isSystemCategory)';
  }
}
