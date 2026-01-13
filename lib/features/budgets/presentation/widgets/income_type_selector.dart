import 'package:flutter/material.dart';
import '../../domain/entities/income_source_entity.dart';

/// Widget for selecting income type with predefined options
///
/// Implements FR-004: Income type selection
/// - Predefined types: Salary, Freelance, Investment, Other, Custom
/// - Shows text input field when "Custom" is selected
/// - Returns selected IncomeType enum value
class IncomeTypeSelector extends StatefulWidget {
  /// Currently selected income type
  final IncomeType? selectedType;

  /// Custom type name (if type is Custom)
  final String? customTypeName;

  /// Callback when type selection changes
  final ValueChanged<IncomeType>? onTypeChanged;

  /// Callback when custom type name changes
  final ValueChanged<String>? onCustomTypeNameChanged;

  /// Whether the selector is enabled
  final bool enabled;

  /// Error text for validation
  final String? errorText;

  const IncomeTypeSelector({
    Key? key,
    this.selectedType,
    this.customTypeName,
    this.onTypeChanged,
    this.onCustomTypeNameChanged,
    this.enabled = true,
    this.errorText,
  }) : super(key: key);

  @override
  State<IncomeTypeSelector> createState() => _IncomeTypeSelectorState();
}

class _IncomeTypeSelectorState extends State<IncomeTypeSelector> {
  late TextEditingController _customNameController;

  @override
  void initState() {
    super.initState();
    _customNameController = TextEditingController(
      text: widget.customTypeName ?? '',
    );
  }

  @override
  void didUpdateWidget(IncomeTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customTypeName != oldWidget.customTypeName) {
      _customNameController.text = widget.customTypeName ?? '';
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  /// Get display name for income type
  String _getTypeDisplayName(IncomeType type) {
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

  /// Get icon for income type
  IconData _getTypeIcon(IncomeType type) {
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown for income type selection
        DropdownButtonFormField<IncomeType>(
          value: widget.selectedType,
          decoration: InputDecoration(
            labelText: 'Income Type',
            hintText: 'Select income type',
            errorText: widget.errorText,
            prefixIcon: widget.selectedType != null
                ? Icon(_getTypeIcon(widget.selectedType!))
                : const Icon(Icons.category),
            border: const OutlineInputBorder(),
          ),
          items: IncomeType.values.map((type) {
            return DropdownMenuItem<IncomeType>(
              value: type,
              child: Row(
                children: [
                  Icon(_getTypeIcon(type), size: 20),
                  const SizedBox(width: 8),
                  Text(_getTypeDisplayName(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.enabled
              ? (type) {
                  if (type != null) {
                    widget.onTypeChanged?.call(type);

                    // Clear custom name if switching away from custom
                    if (type != IncomeType.custom) {
                      _customNameController.clear();
                      // Don't call onCustomTypeNameChanged here - let the controller's onChanged handle it
                    }
                  }
                }
              : null,
        ),

        // Show custom type name input when Custom is selected
        if (widget.selectedType == IncomeType.custom) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customNameController,
            enabled: widget.enabled,
            decoration: const InputDecoration(
              labelText: 'Custom Type Name',
              hintText: 'e.g., Rental Income, Side Business',
              helperText: 'Enter a name for your custom income type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 100, // Per data model constraint
            onChanged: widget.onCustomTypeNameChanged,
          ),
        ],
      ],
    );
  }
}

/// Compact version of income type selector for list items
class CompactIncomeTypeChip extends StatelessWidget {
  final IncomeType type;
  final String? customTypeName;

  const CompactIncomeTypeChip({
    Key? key,
    required this.type,
    this.customTypeName,
  }) : super(key: key);

  String _getDisplayName() {
    if (type == IncomeType.custom && customTypeName != null) {
      return customTypeName!;
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

  IconData _getIcon() {
    switch (type) {
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

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case IncomeType.salary:
        return Colors.blue;
      case IncomeType.freelance:
        return Colors.purple;
      case IncomeType.investment:
        return Colors.green;
      case IncomeType.other:
        return Colors.orange;
      case IncomeType.custom:
        return theme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_getIcon(), size: 16, color: _getColor(context)),
      label: Text(
        _getDisplayName(),
        style: TextStyle(
          color: _getColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getColor(context).withOpacity(0.1),
    );
  }
}
