// Widget: Orphaned Expenses Notification
// Feature: Italian Categories and Budget Management (004)
// Task: T076

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../expenses/presentation/providers/orphaned_expenses_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

/// Widget that displays a notification banner when there are orphaned expenses
class OrphanedExpensesNotification extends ConsumerStatefulWidget {
  const OrphanedExpensesNotification({super.key});

  @override
  ConsumerState<OrphanedExpensesNotification> createState() =>
      _OrphanedExpensesNotificationState();
}

class _OrphanedExpensesNotificationState
    extends ConsumerState<OrphanedExpensesNotification> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final groupId = ref.watch(currentGroupIdProvider);
    final orphanedState = ref.watch(orphanedExpensesProvider(groupId));

    // Don't show during loading
    if (orphanedState.isLoading) {
      return const SizedBox.shrink();
    }

    // Don't show if there are no orphaned expenses
    final orphanedCount = orphanedState.expenses.length;
    if (orphanedCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/orphaned-expenses');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spese da categorizzare',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orphanedCount == 1
                            ? '1 spesa necessita di una categoria'
                            : '$orphanedCount spese necessitano di una categoria',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tocca per categorizzare',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.orange.shade700,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDismissed = true;
                    });
                  },
                  tooltip: 'Nascondi',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
