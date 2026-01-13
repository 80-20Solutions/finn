import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_setup_provider.dart';
import '../widgets/income_type_selector.dart';
import '../../../../shared/widgets/currency_input_field.dart';
import '../../domain/entities/income_source_entity.dart';

/// Step 3: Budget Summary Screen
///
/// Implements FR-008: Budget calculation
/// - Displays all income sources
/// - Shows savings goal (if set)
/// - Calculates and displays available budget
/// - Formula: availableBudget = totalIncome - savingsGoal - groupExpenses
/// - Final confirmation before completing setup
class BudgetSummaryScreen extends ConsumerWidget {
  const BudgetSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(budgetSetupProvider);
    final theme = Theme.of(context);

    final totalIncome = setupState.totalIncome;
    final savingsGoal = setupState.savingsGoal?.amount ?? 0;
    final groupExpenses = 0; // Will be populated from group assignments later
    final availableBudget = totalIncome - savingsGoal - groupExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Your Budget Summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your budget breakdown before completing setup.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),

          // Income Sources Section
          _buildSectionHeader(context, 'Income Sources', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          ...setupState.incomeSources.map((source) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CompactIncomeTypeChip(
                  type: source.type,
                  customTypeName: source.customTypeName,
                ),
                title: Text(_getIncomeTypeName(source.type, source.customTypeName)),
                trailing: Text(
                  source.amount.toCurrencyString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          // Total Income Card
          Card(
            color: theme.primaryColor.withOpacity(0.1),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Income',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    totalIncome.toCurrencyString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Savings Goal Section
          _buildSectionHeader(context, 'Savings Goal', Icons.savings),
          const SizedBox(height: 12),
          if (setupState.savingsGoal != null)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.savings,
                  color: theme.primaryColor,
                ),
                title: const Text('Monthly Savings'),
                subtitle: Text(
                  '${((savingsGoal / totalIncome) * 100).toStringAsFixed(1)}% of income',
                ),
                trailing: Text(
                  savingsGoal.toCurrencyString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Card(
              color: theme.colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No savings goal set. You can add one later.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Available Budget Section
          _buildSectionHeader(context, 'Available Budget', Icons.account_balance),
          const SizedBox(height: 12),

          // Visual Budget Breakdown
          _buildBudgetBreakdownCard(
            context,
            totalIncome: totalIncome,
            savingsGoal: savingsGoal,
            groupExpenses: groupExpenses,
            availableBudget: availableBudget,
          ),
          const SizedBox(height: 24),

          // Budget Formula Explanation
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Budget Calculation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available Budget = Total Income - Savings Goal - Group Expenses',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Completion Message
          Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your budget is ready! Click "Complete" to save your budget and start tracking expenses.',
                      style: TextStyle(
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetBreakdownCard(
    BuildContext context, {
    required int totalIncome,
    required int savingsGoal,
    required int groupExpenses,
    required int availableBudget,
  }) {
    final theme = Theme.of(context);

    // Calculate percentages
    final savingsPercent = totalIncome > 0 ? (savingsGoal / totalIncome * 100) : 0.0;
    final groupPercent = totalIncome > 0 ? (groupExpenses / totalIncome * 100) : 0.0;
    final availablePercent = totalIncome > 0 ? (availableBudget / totalIncome * 100) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  // Savings portion
                  if (savingsGoal > 0)
                    Container(
                      height: 40,
                      width: double.infinity,
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Savings',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${savingsPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  // Available Budget portion
                  if (availableBudget > 0)
                    Container(
                      height: 40,
                      width: double.infinity,
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${availablePercent.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown Details
            _buildBreakdownRow('Total Income', totalIncome, theme.primaryColor),
            if (savingsGoal > 0) ...[
              const Divider(height: 16),
              _buildBreakdownRow('- Savings Goal', savingsGoal, Colors.blue, isSubtraction: true),
            ],
            if (groupExpenses > 0) ...[
              const Divider(height: 16),
              _buildBreakdownRow('- Group Expenses', groupExpenses, Colors.orange, isSubtraction: true),
            ],
            const Divider(height: 16, thickness: 2),
            _buildBreakdownRow('= Available Budget', availableBudget, Colors.green, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    int amount,
    Color color, {
    bool isSubtraction = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14,
                ),
              ),
            ],
          ),
          Text(
            amount.toCurrencyString(),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 18 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getIncomeTypeName(IncomeType type, String? customTypeName) {
    if (type == IncomeType.custom && customTypeName != null) {
      return customTypeName;
    }

    switch (type) {
      case IncomeType.salary:
        return 'Salary';
      case IncomeType.freelance:
        return 'Freelance';
      case IncomeType.investment:
        return 'Investment';
      case IncomeType.other:
        return 'Other';
      case IncomeType.custom:
        return 'Custom';
    }
  }
}
