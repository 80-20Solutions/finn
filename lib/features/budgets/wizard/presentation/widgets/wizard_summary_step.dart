import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';
import '../../domain/entities/category_selection.dart';
import '../../domain/entities/wizard_configuration.dart';

/// Wizard summary step widget (Step 4 - review).
/// Feature: 001-group-budget-wizard, Task: T036
class WizardSummaryStep extends StatelessWidget {
  const WizardSummaryStep({
    super.key,
    required this.configuration,
    required this.categories,
    required this.members,
  });

  final WizardConfiguration configuration;
  final List<CategorySelection> categories;
  final List<Map<String, dynamic>> members;

  @override
  Widget build(BuildContext context) {
    final totalBudget = configuration.categoryBudgets.values
        .fold(0, (sum, amount) => sum + amount);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            StringsIt.reviewConfiguration,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Selected Categories Section
          _buildSection(
            context,
            title: StringsIt.selectedCategories,
            child: Column(
              children: configuration.selectedCategories.map((categoryId) {
                final category = categories.firstWhere(
                  (c) => c.categoryId == categoryId,
                  orElse: () => CategorySelection(
                    categoryId: categoryId,
                    categoryName: 'Unknown',
                  ),
                );
                final budget = configuration.categoryBudgets[categoryId] ?? 0;

                return ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(category.categoryName),
                  trailing: Text(
                    '${_formatCents(budget)} €',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Total Budget
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    StringsIt.totalBudget,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${_formatCents(totalBudget)} €',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Member Allocations Section
          _buildSection(
            context,
            title: StringsIt.memberAllocations,
            child: Column(
              children: configuration.memberAllocations.entries.map((entry) {
                final member = members.firstWhere(
                  (m) => m['user_id'] == entry.key,
                  orElse: () => {'user_id': entry.key, 'display_name': 'Unknown'},
                );
                final displayName = member['display_name'] as String;
                final personalBudgetCents = (totalBudget * entry.value / 100).round();
                final groupBudgetCents = totalBudget - personalBudgetCents;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(displayName[0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(2)}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Budget personale: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${_formatCents(personalBudgetCents)} €',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.group, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Budget di gruppo: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${_formatCents(groupBudgetCents)} €',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Confirmation message
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          StringsIt.reviewBeforeSubmit,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StringsIt.configurationWillBeSaved,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  String _formatCents(int cents) {
    final euros = cents / 100;
    return euros.toStringAsFixed(2).replaceAll('.', ',');
  }
}
