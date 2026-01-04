// Screen: Budget Management
// Feature: Italian Categories and Budget Management (004)
// Tasks: T032-T035

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/providers/category_budget_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_budget_card.dart';

/// Screen for managing monthly budgets for each category
class BudgetManagementScreen extends ConsumerWidget {
  const BudgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final groupId = ref.watch(currentGroupIdProvider);

    // Watch categories and budgets
    final categoryState = ref.watch(categoryProvider(groupId));
    final budgetState = ref.watch(
      categoryBudgetProvider((
        groupId: groupId,
        year: now.year,
        month: now.month,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Budget'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Text(
              _getMonthYearText(now),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: categoryState.isLoading || budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryState.errorMessage != null
              ? _buildErrorState(
                  context,
                  ref,
                  groupId,
                  categoryState.errorMessage!,
                )
              : budgetState.errorMessage != null
                  ? _buildErrorState(
                      context,
                      ref,
                      groupId,
                      budgetState.errorMessage!,
                    )
                  : _buildBudgetList(
                      context,
                      ref,
                      groupId,
                      categoryState,
                      budgetState,
                      now,
                    ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String errorMessage,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(categoryProvider(groupId).notifier).loadCategories();
                ref
                    .read(categoryBudgetProvider((
                      groupId: groupId,
                      year: DateTime.now().year,
                      month: DateTime.now().month,
                    )).notifier)
                    .loadBudgets();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    CategoryState categoryState,
    CategoryBudgetState budgetState,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final categories = categoryState.categories;

    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nessuna categoria disponibile',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Le categorie verranno visualizzate qui',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informazioni',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Imposta un budget mensile per ogni categoria. '
                      'Il budget verrà utilizzato per tenere traccia delle tue spese '
                      'e ricevere notifiche quando ti avvicini al limite.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final category = categories[index - 1];

        // Find budget for this category
        final budget = _findBudgetForCategory(budgetState.budgets, category.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CategoryBudgetCard(
            categoryId: category.id,
            categoryName: category.name,
            categoryColor: theme.colorScheme.primaryContainer.toARGB32(),
            currentBudget: budget?['amount'] as int?,
            budgetId: budget?['id'] as String?,
            onSaveBudget: (amount) async {
              final budgetNotifier = ref.read(
                categoryBudgetProvider((
                  groupId: groupId,
                  year: now.year,
                  month: now.month,
                )).notifier,
              );

              if (budget != null) {
                // Update existing budget
                return await budgetNotifier.updateBudget(
                  budgetId: budget['id'] as String,
                  amount: amount,
                );
              } else {
                // Create new budget
                return await budgetNotifier.createBudget(
                  categoryId: category.id,
                  amount: amount,
                );
              }
            },
            onDeleteBudget: () async {
              if (budget == null) return false;

              final budgetNotifier = ref.read(
                categoryBudgetProvider((
                  groupId: groupId,
                  year: now.year,
                  month: now.month,
                )).notifier,
              );

              return await budgetNotifier.deleteBudget(budget['id'] as String);
            },
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _findBudgetForCategory(
    List<dynamic> budgets,
    String categoryId,
  ) {
    try {
      return budgets.firstWhere(
        (b) => b['category_id'] == categoryId,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _getMonthYearText(DateTime date) {
    const monthNames = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }
}
