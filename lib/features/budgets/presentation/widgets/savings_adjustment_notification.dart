import 'package:flutter/material.dart';
import '../../domain/usecases/adjust_savings_for_group_usecase.dart';
import '../../../../shared/widgets/currency_input_field.dart';

/// Notification widget for savings adjustment
///
/// Implements FR-016: Notify user when savings automatically adjusted
/// Displays:
/// - Reason for adjustment
/// - Old savings amount
/// - New savings amount
/// - Difference
/// - Dismissible action
///
/// Uses SnackBar + persistent banner pattern per research.md
/// Part of User Story 3: Group Integration
class SavingsAdjustmentNotification {
  /// Show a snackbar notification for savings adjustment
  static void showSnackBar(
    BuildContext context,
    SavingsAdjustment adjustment,
  ) {
    final difference = adjustment.difference.abs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Savings Goal Adjusted',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Reduced by ${difference.toCurrencyString()} to accommodate group expenses',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _showDetailsDialog(context, adjustment);
          },
        ),
      ),
    );
  }

  /// Show detailed dialog about savings adjustment
  static void _showDetailsDialog(
    BuildContext context,
    SavingsAdjustment adjustment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.savings, color: Colors.orange),
            SizedBox(width: 12),
            Text('Savings Adjusted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your savings goal has been automatically adjusted to accommodate your group expense assignment.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            _buildAmountRow(
              context,
              'Original Savings',
              adjustment.originalAmount,
              Icons.savings_outlined,
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              context,
              'New Savings',
              adjustment.adjustedAmount,
              Icons.savings,
              isHighlighted: true,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildAmountRow(
              context,
              'Reduction',
              adjustment.difference,
              Icons.arrow_downward,
              isNegative: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _buildAmountRow(
    BuildContext context,
    String label,
    int amount,
    IconData icon, {
    bool isHighlighted = false,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);
    final color = isNegative
        ? Colors.red
        : isHighlighted
            ? theme.primaryColor
            : theme.textTheme.bodyMedium?.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          '${isNegative ? "-" : ""}${amount.toCurrencyString()}',
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Persistent banner widget for showing savings adjustment warning
class SavingsAdjustmentBanner extends StatelessWidget {
  final SavingsAdjustment adjustment;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const SavingsAdjustmentBanner({
    Key? key,
    required this.adjustment,
    this.onDismiss,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difference = adjustment.difference.abs();

    return Material(
      color: Colors.orange.withOpacity(0.1),
      child: InkWell(
        onTap: onViewDetails,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Savings Goal Adjusted',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your savings were reduced by ${difference.toCurrencyString()} to accommodate group expenses',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider for tracking dismissed adjustment notifications
///
/// Stores adjustment IDs that have been dismissed by user
/// to avoid showing same notification multiple times
class DismissedAdjustmentsNotifier extends ChangeNotifier {
  final Set<String> _dismissedIds = {};

  bool isDismissed(String adjustmentId) {
    return _dismissedIds.contains(adjustmentId);
  }

  void dismiss(String adjustmentId) {
    _dismissedIds.add(adjustmentId);
    notifyListeners();
  }

  void clearAll() {
    _dismissedIds.clear();
    notifyListeners();
  }
}
