import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/income_source_entity.dart';
import '../providers/budget_setup_provider.dart';
import '../widgets/income_type_selector.dart';
import '../../../../shared/widgets/currency_input_field.dart';

/// Step 1: Income Entry Screen
///
/// Implements FR-001, FR-003, FR-004
/// - Allows adding multiple income sources
/// - Income type selection (Salary, Freelance, Investment, Other, Custom)
/// - Amount validation (>= 0)
/// - Shows list of added income sources
/// - Requires at least one income source to proceed
class IncomeEntryScreen extends ConsumerStatefulWidget {
  const IncomeEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IncomeEntryScreen> createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends ConsumerState<IncomeEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  IncomeType? _selectedType;
  String? _customTypeName;
  int? _amount; // Amount in cents

  String? _typeError;
  String? _amountError;

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(budgetSetupProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Add Your Income Sources',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your income sources here. You can add multiple sources if you have income from different places. This step is optional - you can skip it if you prefer.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 32),

            // Income Type Selector
            IncomeTypeSelector(
              selectedType: _selectedType,
              customTypeName: _customTypeName,
              onTypeChanged: (type) {
                setState(() {
                  _selectedType = type as IncomeType?;
                  _typeError = null;
                });
              },
              onCustomTypeNameChanged: (name) {
                setState(() {
                  _customTypeName = name;
                  _typeError = null;
                });
              },
              errorText: _typeError,
            ),
            const SizedBox(height: 24),

            // Amount Input
            CurrencyInputField(
              label: 'Monthly Income Amount',
              hint: '0.00',
              helperText: 'Enter your monthly income from this source',
              errorText: _amountError,
              onChanged: (cents) {
                setState(() {
                  _amount = cents;
                  _amountError = null;
                });
              },
              isRequired: true,
              minValue: 0,
            ),
            const SizedBox(height: 24),

            // Add Income Source Button
            ElevatedButton.icon(
              onPressed: _canAddIncomeSource() ? _addIncomeSource : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Income Source'),
            ),
            const SizedBox(height: 32),

            // List of added income sources
            if (setupState.incomeSources.isNotEmpty) ...[
              Text(
                'Your Income Sources',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...setupState.incomeSources.map((source) {
                return _buildIncomeSourceCard(context, source);
              }),
              const SizedBox(height: 16),

              // Total Income Summary
              Card(
                color: theme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Monthly Income',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        setupState.totalIncome.toCurrencyString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Help text when no income sources
            if (setupState.incomeSources.isEmpty) ...[
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
                          'No income sources added yet. You can skip this step if you prefer, or add your income sources now.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSourceCard(BuildContext context, IncomeSourceEntity source) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.2),
          child: Icon(
            _getIncomeTypeIcon(source.type),
            color: theme.primaryColor,
          ),
        ),
        title: Text(_getIncomeTypeName(source)),
        subtitle: Text(source.amount.toCurrencyString()),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeIncomeSource(source.id),
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  String _getIncomeTypeName(IncomeSourceEntity source) {
    if (source.type == IncomeType.custom && source.customTypeName != null) {
      return source.customTypeName!;
    }

    switch (source.type) {
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

  IconData _getIncomeTypeIcon(IncomeType type) {
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

  bool _canAddIncomeSource() {
    if (_selectedType == null) return false;
    if (_amount == null || _amount! <= 0) return false;
    if (_selectedType == IncomeType.custom) {
      if (_customTypeName == null || _customTypeName!.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _addIncomeSource() {
    // Validate
    if (!_canAddIncomeSource()) {
      setState(() {
        if (_selectedType == null) {
          _typeError = 'Please select an income type';
        }
        if (_amount == null || _amount! <= 0) {
          _amountError = 'Please enter a valid amount';
        }
        if (_selectedType == IncomeType.custom &&
            (_customTypeName == null || _customTypeName!.trim().isEmpty)) {
          _typeError = 'Please enter a custom type name';
        }
      });
      return;
    }

    // Create new income source entity
    final newSource = IncomeSourceEntity(
      id: const Uuid().v4(),
      userId: '', // Will be set by use case
      type: _selectedType!,
      customTypeName: _selectedType == IncomeType.custom ? _customTypeName : null,
      amount: _amount!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to provider state
    ref.read(budgetSetupProvider.notifier).addIncomeSource(newSource);

    // Clear form
    setState(() {
      _selectedType = null;
      _customTypeName = null;
      _amount = null;
      _typeError = null;
      _amountError = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Income source added: ${_getIncomeTypeName(newSource)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeIncomeSource(String id) {
    ref.read(budgetSetupProvider.notifier).removeIncomeSource(id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Income source removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
