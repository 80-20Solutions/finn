// Widget: Category Picker Dialog
// Feature: Italian Categories and Budget Management (004)
// Task: T073

import 'package:flutter/material.dart';

import '../../domain/entities/expense_category_entity.dart';

/// Dialog for selecting a category from a list
class CategoryPickerDialog extends StatelessWidget {
  const CategoryPickerDialog({
    super.key,
    required this.categories,
    this.title = 'Seleziona categoria',
  });

  final List<ExpenseCategoryEntity> categories;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Chiudi',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: categories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna categoria disponibile',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.category,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: theme.textTheme.bodyLarge,
                          ),
                          subtitle: category.isDefault
                              ? Text(
                                  'Categoria predefinita',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, category.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show category picker dialog
Future<String?> showCategoryPicker({
  required BuildContext context,
  required List<ExpenseCategoryEntity> categories,
  String title = 'Seleziona categoria',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => CategoryPickerDialog(
      categories: categories,
      title: title,
    ),
  );
}
