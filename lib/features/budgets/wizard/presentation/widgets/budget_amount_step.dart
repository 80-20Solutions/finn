import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/strings_it.dart';
import '../../../../shared/widgets/currency_input_formatter.dart';
import '../../domain/entities/category_selection.dart';

/// Budget amount step widget (Step 2 of wizard).
/// Feature: 001-group-budget-wizard, Task: T034
class BudgetAmountStep extends StatefulWidget {
  const BudgetAmountStep({
    super.key,
    required this.categories,
    required this.categoryBudgets,
    required this.onBudgetsChanged,
  });

  final List<CategorySelection> categories;
  final Map<String, int> categoryBudgets;
  final Function(Map<String, int>) onBudgetsChanged;

  @override
  State<BudgetAmountStep> createState() => _BudgetAmountStepState();
}

class _BudgetAmountStepState extends State<BudgetAmountStep> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final category in widget.categories) {
      final existingBudget = widget.categoryBudgets[category.categoryId];
      final controller = TextEditingController(
        text: existingBudget != null
            ? _formatCents(existingBudget)
            : '',
      );
      _controllers[category.categoryId] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatCents(int cents) {
    final euros = cents / 100;
    return euros.toStringAsFixed(2).replaceAll('.', ',');
  }

  int _parseCurrency(String text) {
    if (text.isEmpty) return 0;
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0;
    return (value * 100).round();
  }

  int _calculateTotal() {
    return _controllers.entries.fold(0, (sum, entry) {
      return sum + _parseCurrency(entry.value.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    StringsIt.totalBudget,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_formatCents(total)} €',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Budget input fields
          Expanded(
            child: ListView.builder(
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final controller = _controllers[category.categoryId]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: category.categoryName,
                      hintText: StringsIt.enterMonthlyBudget,
                      prefixIcon: const Icon(Icons.euro),
                      suffixText: '€',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}|^\d{1,3}(\.?\d{3})*,?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return StringsIt.enterAmount;
                      }
                      final amount = _parseCurrency(value);
                      if (amount <= 0) {
                        return StringsIt.amountMustBeGreaterThanZero;
                      }
                      if (amount > 99999999) {
                        return StringsIt.amountTooHigh;
                      }
                      return null;
                    },
                    onChanged: (_) {
                      setState(() {
                        final budgets = <String, int>{};
                        for (final entry in _controllers.entries) {
                          final amount = _parseCurrency(entry.value.text);
                          if (amount > 0) {
                            budgets[entry.key] = amount;
                          }
                        }
                        widget.onBudgetsChanged(budgets);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
