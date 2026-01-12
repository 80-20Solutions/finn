import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_selection.dart';

/// Provider for managing category selection state.
/// Feature: 001-group-budget-wizard, Task: T030
///
/// Manages:
/// - Selected category IDs
/// - Category list
/// - Select all/deselect all functionality
class CategorySelectionNotifier extends StateNotifier<CategorySelectionState> {
  CategorySelectionNotifier(List<CategorySelection> categories)
      : super(CategorySelectionState(
          categories: categories,
          selectedCategoryIds: const [],
        ));

  void toggleCategory(String categoryId) {
    final currentSelection = List<String>.from(state.selectedCategoryIds);

    if (currentSelection.contains(categoryId)) {
      currentSelection.remove(categoryId);
    } else {
      currentSelection.add(categoryId);
    }

    state = state.copyWith(selectedCategoryIds: currentSelection);
  }

  void selectAll() {
    final allCategoryIds = state.categories.map((c) => c.categoryId).toList();
    state = state.copyWith(selectedCategoryIds: allCategoryIds);
  }

  void deselectAll() {
    state = state.copyWith(selectedCategoryIds: []);
  }

  void setSelectedCategories(List<String> categoryIds) {
    state = state.copyWith(selectedCategoryIds: categoryIds);
  }

  bool get allSelected =>
      state.selectedCategoryIds.length == state.categories.length;

  bool get noneSelected => state.selectedCategoryIds.isEmpty;

  int get selectedCount => state.selectedCategoryIds.length;
}

class CategorySelectionState {
  const CategorySelectionState({
    required this.categories,
    required this.selectedCategoryIds,
  });

  final List<CategorySelection> categories;
  final List<String> selectedCategoryIds;

  CategorySelectionState copyWith({
    List<CategorySelection>? categories,
    List<String>? selectedCategoryIds,
  }) {
    return CategorySelectionState(
      categories: categories ?? this.categories,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}

// Provider definition
final categorySelectionProvider = StateNotifierProvider.family<
    CategorySelectionNotifier,
    CategorySelectionState,
    List<CategorySelection>>(
  (ref, categories) => CategorySelectionNotifier(categories),
);
