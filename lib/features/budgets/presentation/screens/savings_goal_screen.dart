import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/budget_setup_provider.dart';
import '../../../../shared/widgets/currency_input_field.dart';

/// Step 2: Savings Goal Screen
///
/// Implements FR-005, FR-007
/// - Allows setting a monthly savings goal
/// - Validates that savings goal < total income (FR-007)
/// - Optional step - user can skip and proceed
/// - Shows percentage of income being saved
/// - Displays remaining amount after savings
class SavingsGoalScreen extends ConsumerStatefulWidget {
  const SavingsGoalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends ConsumerState<SavingsGoalScreen> {
  int? _savingsAmount; // Amount in cents
  String? _amountError;

  @override
  void initState() {
    super.initState();
    // Pre-fill if user already set a savings goal
    final currentGoal = ref.read(budgetSetupProvider).savingsGoal;
    if (currentGoal != null) {
      _savingsAmount = currentGoal.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(budgetSetupProvider);
    final theme = Theme.of(context);
    final totalIncome = setupState.totalIncome;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Set Your Savings Goal',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a monthly savings target. This is optional but recommended for financial planning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),

          // Total Income Display
          Card(
            color: theme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Income',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    totalIncome.toCurrencyString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Savings Amount Input
          CurrencyInputField(
            initialValue: _savingsAmount,
            label: 'Monthly Savings Goal',
            hint: '0.00',
            helperText: 'Amount you want to save each month',
            errorText: _amountError,
            onChanged: (cents) {
              setState(() {
                _savingsAmount = cents;
                _amountError = _validateSavingsAmount(cents, totalIncome);
              });
            },
            isRequired: false,
            minValue: 0,
            maxValue: totalIncome - 1, // Must be less than total income
          ),
          const SizedBox(height: 24),

          // Savings Percentage Indicator
          if (_savingsAmount != null && _savingsAmount! > 0 && _amountError == null) ...[
            _buildSavingsBreakdown(context, _savingsAmount!, totalIncome),
            const SizedBox(height: 24),
          ],

          // Quick Percentage Buttons
          Text(
            'Quick Select',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPercentageChip(context, '10%', totalIncome),
              _buildPercentageChip(context, '20%', totalIncome),
              _buildPercentageChip(context, '30%', totalIncome),
              _buildPercentageChip(context, '50%', totalIncome),
            ],
          ),
          const SizedBox(height: 24),

          // Set Savings Goal Button
          ElevatedButton(
            onPressed: _canSetSavingsGoal(totalIncome) ? _setSavingsGoal : null,
            child: const Text('Set Savings Goal'),
          ),
          const SizedBox(height: 12),

          // Skip Button
          if (setupState.savingsGoal == null)
            OutlinedButton(
              onPressed: _skipSavingsGoal,
              child: const Text('Skip for Now'),
            ),

          // Info card
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Financial experts recommend saving 20-30% of your income.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
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

  Widget _buildSavingsBreakdown(BuildContext context, int savingsAmount, int totalIncome) {
    final theme = Theme.of(context);
    final percentage = (savingsAmount / totalIncome * 100).toStringAsFixed(1);
    final remaining = totalIncome - savingsAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: savingsAmount / totalIncome,
                minHeight: 24,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown rows
            _buildBreakdownRow(
              context,
              'Savings',
              savingsAmount.toCurrencyString(),
              '$percentage%',
              theme.primaryColor,
            ),
            const Divider(height: 24),
            _buildBreakdownRow(
              context,
              'Remaining for Expenses',
              remaining.toCurrencyString(),
              '${(100 - double.parse(percentage)).toStringAsFixed(1)}%',
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    String amount,
    String percentage,
    Color color,
  ) {
    return Row(
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
            Text(label),
          ],
        ),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              percentage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPercentageChip(BuildContext context, String label, int totalIncome) {
    final percentage = int.parse(label.replaceAll('%', ''));
    final amount = (totalIncome * percentage / 100).round();
    final isSelected = _savingsAmount == amount;

    return ChoiceChip(
      label: Text('$label (${amount.toCurrencyString()})'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _savingsAmount = amount;
            _amountError = _validateSavingsAmount(amount, totalIncome);
          });
        }
      },
    );
  }

  String? _validateSavingsAmount(int? amount, int totalIncome) {
    if (amount == null) return null;

    if (amount < 0) {
      return 'Savings amount cannot be negative';
    }

    // FR-007: Savings goal must be less than total income
    if (amount >= totalIncome) {
      return 'Savings goal must be less than your total income';
    }

    return null;
  }

  bool _canSetSavingsGoal(int totalIncome) {
    if (_savingsAmount == null || _savingsAmount! <= 0) return false;
    return _validateSavingsAmount(_savingsAmount, totalIncome) == null;
  }

  void _setSavingsGoal() {
    if (!_canSetSavingsGoal(ref.read(budgetSetupProvider).totalIncome)) {
      return;
    }

    final newGoal = SavingsGoalEntity(
      id: const Uuid().v4(),
      userId: '', // Will be set by use case
      amount: _savingsAmount!,
      originalAmount: _savingsAmount!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(budgetSetupProvider.notifier).setSavingsGoal(newGoal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Savings goal set: ${_savingsAmount!.toCurrencyString()}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-advance to next step
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(budgetSetupProvider.notifier).nextStep();
      }
    });
  }

  void _skipSavingsGoal() {
    ref.read(budgetSetupProvider.notifier).clearSavingsGoal();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skipped savings goal (you can set it later)'),
        duration: Duration(seconds: 2),
      ),
    );

    // Advance to next step
    ref.read(budgetSetupProvider.notifier).nextStep();
  }
}
