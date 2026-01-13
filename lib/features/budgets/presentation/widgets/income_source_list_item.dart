import 'package:flutter/material.dart';
import '../../domain/entities/income_source_entity.dart';
import '../../../../shared/widgets/currency_input_field.dart';

/// List item widget for displaying an income source
///
/// Shows:
/// - Income type icon and name (or custom name)
/// - Amount formatted as currency
/// - Edit and delete action buttons
/// - Last updated timestamp
///
/// Part of User Story 2: Multiple Income Source Management
class IncomeSourceListItem extends StatelessWidget {
  final IncomeSourceEntity incomeSource;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const IncomeSourceListItem({
    Key? key,
    required this.incomeSource,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return _buildCompactItem(context, theme);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 1,
      child: ListTile(
        leading: _buildLeadingIcon(theme),
        title: Text(
          _getDisplayName(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getSubtitle(),
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: _buildTrailing(context, theme),
        onTap: showActions && onEdit != null ? onEdit : null,
      ),
    );
  }

  Widget _buildCompactItem(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildLeadingIcon(theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _getTypeLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            incomeSource.amount.toCurrencyString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return CircleAvatar(
      backgroundColor: _getIconColor().withOpacity(0.2),
      child: Icon(
        _getIcon(),
        color: _getIconColor(),
        size: 20,
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, ThemeData theme) {
    if (!showActions) {
      return Text(
        incomeSource.amount.toCurrencyString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          incomeSource.amount.toCurrencyString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            if (value == 'edit' && onEdit != null) {
              onEdit!();
            } else if (value == 'delete' && onDelete != null) {
              onDelete!();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDisplayName() {
    if (incomeSource.type == IncomeType.custom &&
        incomeSource.customTypeName != null) {
      return incomeSource.customTypeName!;
    }
    return _getTypeLabel();
  }

  String _getTypeLabel() {
    switch (incomeSource.type) {
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

  String _getSubtitle() {
    final lastUpdated = _formatDate(incomeSource.updatedAt);
    return 'Last updated: $lastUpdated';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getIcon() {
    switch (incomeSource.type) {
      case IncomeType.salary:
        return Icons.work;
      case IncomeType.freelance:
        return Icons.computer;
      case IncomeType.investment:
        return Icons.trending_up;
      case IncomeType.other:
        return Icons.attach_money;
      case IncomeType.custom:
        return Icons.edit;
    }
  }

  Color _getIconColor() {
    switch (incomeSource.type) {
      case IncomeType.salary:
        return Colors.blue;
      case IncomeType.freelance:
        return Colors.purple;
      case IncomeType.investment:
        return Colors.green;
      case IncomeType.other:
        return Colors.orange;
      case IncomeType.custom:
        return Colors.teal;
    }
  }
}

/// Swipeable version with dismiss action
class SwipeableIncomeSourceListItem extends StatelessWidget {
  final IncomeSourceEntity incomeSource;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SwipeableIncomeSourceListItem({
    Key? key,
    required this.incomeSource,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(incomeSource.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Income Source'),
            content: Text(
              'Are you sure you want to delete "${incomeSource.type == IncomeType.custom && incomeSource.customTypeName != null ? incomeSource.customTypeName : _getTypeLabel()}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (onDelete != null) {
          onDelete!();
        }
      },
      child: IncomeSourceListItem(
        incomeSource: incomeSource,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  String _getTypeLabel() {
    switch (incomeSource.type) {
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
