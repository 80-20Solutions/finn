import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/strings_it.dart';
import '../providers/personal_budget_provider.dart';
import '../widgets/group_spending_category.dart';

/// Personal budget screen with group spending breakdown.
/// Feature: 001-group-budget-wizard, Task: T053
///
/// Displays the member's personal budget view including the hierarchical
/// "Spesa Gruppo" category with expandable subcategories.
class PersonalBudgetScreen extends ConsumerStatefulWidget {
  const PersonalBudgetScreen({
    super.key,
    required this.userId,
    required this.groupId,
  });

  final String userId;
  final String groupId;

  @override
  ConsumerState<PersonalBudgetScreen> createState() =>
      _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends ConsumerState<PersonalBudgetScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final notifier = ref.read(personalBudgetProvider(widget.userId).notifier);

    await notifier.loadBudgetData(
      userId: widget.userId,
      groupId: widget.groupId,
      year: now.year,
      month: now.month,
    );
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final notifier = ref.read(personalBudgetProvider(widget.userId).notifier);

    await notifier.refresh(
      userId: widget.userId,
      groupId: widget.groupId,
      year: now.year,
      month: now.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalBudgetProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsIt.personalView),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PersonalBudgetState state) {
    if (state.isLoading && state.personalBudget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(context, state.errorMessage!);
    }

    return ListView(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            StringsIt.thisMonth,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),

        // Total Budget Summary Card (Task: T063)
        if (state.personalBudget != null)
          _buildBudgetSummaryCard(context, state.personalBudget!),

        // Budget Breakdown (Personal + Group) (Task: T063)
        if (state.personalBudget != null)
          _buildBudgetBreakdown(context, state.personalBudget!),

        // Group Spending Category (expandable)
        if (state.groupBreakdown != null)
          GroupSpendingCategory(breakdown: state.groupBreakdown!),

        // Empty state if no data
        if (state.personalBudget == null && state.groupBreakdown == null)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  StringsIt.noData,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nessun budget configurato',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build total budget summary card.
  /// Task: T063
  Widget _buildBudgetSummaryCard(BuildContext context, PersonalBudget budget) {
    final percentage = (budget.percentageSpent * 100).round();
    final progressColor = _getProgressColor(budget.percentageSpent);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Totale Budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatCents(budget.totalSpentCents)} / ${_formatCents(budget.totalBudgetCents)} €',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.percentageSpent > 1.0 ? 1.0 : budget.percentageSpent,
              color: progressColor,
              backgroundColor: progressColor.withOpacity(0.2),
            ),
            const SizedBox(height: 8),
            Text(
              '${StringsIt.remaining}: ${_formatCents(budget.remainingCents)} €',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: budget.isOverBudget
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build budget breakdown (personal + group).
  /// Task: T063 - Enhanced with visual distinction
  Widget _buildBudgetBreakdown(BuildContext context, PersonalBudget budget) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dettaglio Budget',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Personal budget section with icon and background
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'PERSONALE',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownRow(
                    context,
                    'Budget:',
                    budget.personalBudgetCents,
                    budget.personalSpentCents,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Group allocation section with icon and background
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'GRUPPO',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownRow(
                    context,
                    'Budget:',
                    budget.groupAllocationCents,
                    budget.groupSpentCents,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 2),
            const SizedBox(height: 8),

            // Total (bold and highlighted)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildBreakdownRow(
                context,
                'TOTALE:',
                budget.totalBudgetCents,
                budget.totalSpentCents,
                isBold: true,
              ),
            ),
            const SizedBox(height: 12),

            // Formula display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatCents(budget.personalBudgetCents)} € + '
                  '${_formatCents(budget.groupAllocationCents)} € = '
                  '${_formatCents(budget.totalBudgetCents)} €',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    int budgetCents,
    int spentCents, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          '${_formatCents(spentCents)} / ${_formatCents(budgetCents)} €',
          style: isBold
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.75) return Colors.orange;
    return Colors.green;
  }

  String _formatCents(int cents) {
    final euros = cents / 100;
    if (euros >= 1000) {
      final formatted = euros.toStringAsFixed(2);
      final parts = formatted.split('.');
      final integerPart = parts[0];
      final decimalPart = parts[1];

      final buffer = StringBuffer();
      final length = integerPart.length;
      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(integerPart[i]);
      }

      return '${buffer.toString()},${decimalPart}';
    } else {
      return euros.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              StringsIt.error,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text(StringsIt.retry),
            ),
          ],
        ),
      ),
    );
  }
}
