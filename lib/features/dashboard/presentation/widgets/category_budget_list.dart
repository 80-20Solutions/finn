// Widget: Category Budget List for Dashboard
// Feature: Italian Categories and Budget Management (004)
// Tasks: T056-T058

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../budgets/presentation/providers/category_budget_provider.dart';
import '../../../budgets/presentation/providers/budget_repository_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

/// Widget showing list of category budgets with progress bars
class CategoryBudgetList extends ConsumerWidget {
  const CategoryBudgetList({
    super.key,
    this.maxItems = 5,
    this.onViewAll,
  });

  final int maxItems;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final groupId = ref.watch(currentGroupIdProvider);

    final budgetState = ref.watch(
      categoryBudgetProvider((
        groupId: groupId,
        year: now.year,
        month: now.month,
      )),
    );

    final categoryState = ref.watch(categoryProvider(groupId));

    if (budgetState.isLoading || categoryState.isLoading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget per categoria',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (budgetState.errorMessage != null || categoryState.errorMessage != null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget per categoria',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Errore nel caricamento dei budget',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (budgetState.budgets.isEmpty) {
      return Card(
        elevation: 2,
        child: InkWell(
          onTap: onViewAll,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget per categoria',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nessun budget impostato per le categorie',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Imposta budget'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get budget stats for each budget and sort by spending
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget per categoria',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Vedi tutti'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...budgetState.budgets.take(maxItems).map((budget) {
              final categoryId = budget['category_id'] as String;
              final budgetAmount = budget['amount'] as int;

              // Find category name
              final category = categoryState.categories
                  .where((c) => c.id == categoryId)
                  .firstOrNull;

              if (category == null) return const SizedBox.shrink();

              return _CategoryBudgetListItem(
                categoryId: categoryId,
                categoryName: category.name,
                budgetAmount: budgetAmount,
                groupId: groupId,
                year: now.year,
                month: now.month,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Individual list item for a category budget
class _CategoryBudgetListItem extends ConsumerWidget {
  const _CategoryBudgetListItem({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.groupId,
    required this.year,
    required this.month,
  });

  final String categoryId;
  final String categoryName;
  final int budgetAmount;
  final String groupId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 2,
    );

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchCategoryBudgetStats(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              categoryName,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final stats = snapshot.data!;
        final spentAmount = (stats['spent_amount'] as int?) ?? 0;
        final remainingAmount = (stats['remaining_amount'] as int?) ?? 0;
        final percentageUsed = (stats['percentage_used'] as double?) ?? 0.0;
        final isOverBudget = (stats['is_over_budget'] as bool?) ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          categoryName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isOverBudget) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${currencyFormat.format(spentAmount / 100)} / ${currencyFormat.format(budgetAmount / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverBudget
                          ? Colors.red.shade700
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentageUsed / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? Colors.red.shade700
                        : percentageUsed >= 90
                            ? Colors.orange.shade700
                            : percentageUsed >= 75
                                ? Colors.amber.shade700
                                : Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentageUsed.toStringAsFixed(0)}% utilizzato',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    isOverBudget
                        ? 'Oltre di ${currencyFormat.format(remainingAmount.abs() / 100)}'
                        : 'Rimasti ${currencyFormat.format(remainingAmount / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverBudget
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchCategoryBudgetStats(WidgetRef ref) async {
    final repository = ref.read(budgetRepositoryProvider);

    final result = await repository.getCategoryBudgetStats(
      groupId: groupId,
      categoryId: categoryId,
      year: year,
      month: month,
    );

    return result.fold(
      (failure) => null,
      (stats) => stats as Map<String, dynamic>?,
    );
  }
}
