import 'package:flutter/material.dart';
import '../../../../shared/widgets/currency_input_field.dart';

/// Reusable widget for displaying budget breakdown
///
/// Shows visual breakdown of:
/// - Total Income
/// - Savings Goal (subtracted)
/// - Group Expenses (subtracted)
/// - Available Budget (result)
///
/// Uses color-coded bars and detailed rows
/// Implements FR-008 budget calculation display
class BudgetBreakdownCard extends StatelessWidget {
  final int totalIncome;
  final int savingsGoal;
  final int groupExpenses;
  final int availableBudget;
  final bool showHeader;
  final String? headerTitle;

  const BudgetBreakdownCard({
    Key? key,
    required this.totalIncome,
    this.savingsGoal = 0,
    this.groupExpenses = 0,
    required this.availableBudget,
    this.showHeader = true,
    this.headerTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            // Header (optional)
            if (showHeader) ...[
              Text(
                headerTitle ?? 'Budget Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Visual Progress Bar
            if (totalIncome > 0) ...[
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${savingsPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    // Group Expenses portion
                    if (groupExpenses > 0)
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.orange,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Group Expenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${groupPercent.toStringAsFixed(1)}%',
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${availablePercent.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    // Deficit indicator (if negative)
                    if (availableBudget < 0)
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Deficit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(availableBudget.abs() / totalIncome * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Breakdown Details
            _buildBreakdownRow(
              context,
              'Total Income',
              totalIncome,
              theme.primaryColor,
            ),

            if (savingsGoal > 0) ...[
              const Divider(height: 16),
              _buildBreakdownRow(
                context,
                '- Savings Goal',
                savingsGoal,
                Colors.blue,
                isSubtraction: true,
              ),
            ],

            if (groupExpenses > 0) ...[
              const Divider(height: 16),
              _buildBreakdownRow(
                context,
                '- Group Expenses',
                groupExpenses,
                Colors.orange,
                isSubtraction: true,
              ),
            ],

            const Divider(height: 16, thickness: 2),

            _buildBreakdownRow(
              context,
              '= Available Budget',
              availableBudget,
              availableBudget >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
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
}

/// Compact version of budget breakdown for smaller displays
class CompactBudgetBreakdown extends StatelessWidget {
  final int totalIncome;
  final int savingsGoal;
  final int groupExpenses;
  final int availableBudget;

  const CompactBudgetBreakdown({
    Key? key,
    required this.totalIncome,
    this.savingsGoal = 0,
    this.groupExpenses = 0,
    required this.availableBudget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Total Income
        _buildCompactRow(
          context,
          Icons.account_balance_wallet,
          'Income',
          totalIncome,
          theme.primaryColor,
        ),

        // Savings
        if (savingsGoal > 0)
          _buildCompactRow(
            context,
            Icons.savings,
            'Savings',
            savingsGoal,
            Colors.blue,
          ),

        // Group Expenses
        if (groupExpenses > 0)
          _buildCompactRow(
            context,
            Icons.groups,
            'Group',
            groupExpenses,
            Colors.orange,
          ),

        const Divider(),

        // Available Budget
        _buildCompactRow(
          context,
          Icons.account_balance,
          'Available',
          availableBudget,
          availableBudget >= 0 ? Colors.green : Colors.red,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    IconData icon,
    String label,
    int amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            amount.toCurrencyString(),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
