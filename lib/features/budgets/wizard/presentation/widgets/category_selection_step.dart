import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';
import '../../domain/entities/category_selection.dart';

/// Category selection step widget (Step 1 of wizard).
/// Feature: 001-group-budget-wizard, Task: T033
class CategorySelectionStep extends StatelessWidget {
  const CategorySelectionStep({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onSelectionChanged,
  });

  final List<CategorySelection> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          StringsIt.noCategoriesAvailable,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final allSelected = selectedCategories.length == categories.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and select all button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedCategories.length} ${StringsIt.categoriesSelected}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () {
                if (allSelected) {
                  onSelectionChanged([]);
                } else {
                  onSelectionChanged(
                    categories.map((c) => c.categoryId).toList(),
                  );
                }
              },
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              label: Text(
                allSelected
                    ? StringsIt.deselectAll
                    : StringsIt.selectAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Validation message
        if (selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              StringsIt.selectAtLeastOneCategory,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),

        // Category list
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected =
                  selectedCategories.contains(category.categoryId);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (checked) {
                  final updated = List<String>.from(selectedCategories);
                  if (checked == true) {
                    updated.add(category.categoryId);
                  } else {
                    updated.remove(category.categoryId);
                  }
                  onSelectionChanged(updated);
                },
                title: Text(category.categoryName),
                subtitle: category.isSystemCategory
                    ? const Text(StringsIt.systemCategory)
                    : null,
                secondary: _buildCategoryIcon(category),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(CategorySelection category) {
    if (category.icon == null) {
      return const CircleAvatar(child: Icon(Icons.folder));
    }

    // Parse icon name to IconData
    final iconData = _getIconData(category.icon!);
    final color = category.color != null
        ? _parseColor(category.color!)
        : Colors.grey;

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }

  IconData _getIconData(String iconName) {
    // Map common icon names to IconData
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'bolt':
        return Icons.bolt;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'home':
        return Icons.home;
      case 'restaurant':
        return Icons.restaurant;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'flight':
        return Icons.flight;
      default:
        return Icons.folder;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
