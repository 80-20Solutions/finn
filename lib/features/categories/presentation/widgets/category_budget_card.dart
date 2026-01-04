// Widget: Category Budget Card
// Feature: Italian Categories and Budget Management (004)
// Tasks: T033-T035

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Card widget for displaying and editing a category's monthly budget
class CategoryBudgetCard extends StatefulWidget {
  const CategoryBudgetCard({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.currentBudget,
    this.budgetId,
    required this.onSaveBudget,
    required this.onDeleteBudget,
  });

  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final int? currentBudget; // Amount in cents
  final String? budgetId;
  final Future<bool> Function(int amount) onSaveBudget;
  final Future<bool> Function() onDeleteBudget;

  @override
  State<CategoryBudgetCard> createState() => _CategoryBudgetCardState();
}

class _CategoryBudgetCardState extends State<CategoryBudgetCard> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentBudget != null) {
      _controller.text = (widget.currentBudget! / 100).toStringAsFixed(2);
    }
  }

  @override
  void didUpdateWidget(CategoryBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBudget != oldWidget.currentBudget && !_isEditing) {
      if (widget.currentBudget != null) {
        _controller.text = (widget.currentBudget! / 100).toStringAsFixed(2);
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final euros = double.parse(_controller.text);
      final cents = (euros * 100).toInt();

      final success = await widget.onSaveBudget(cents);

      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget salvato per ${widget.categoryName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nel salvare il budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina budget'),
        content: Text(
          'Vuoi eliminare il budget per "${widget.categoryName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final success = await widget.onDeleteBudget();

      if (mounted) {
        if (success) {
          setState(() {
            _controller.clear();
            _isEditing = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget eliminato per ${widget.categoryName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nell\'eliminare il budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = widget.currentBudget != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(widget.categoryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasBudget && !_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Modifica budget',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget input or display
            if (_isEditing || !hasBudget)
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        autofocus: _isEditing,
                        enabled: !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Budget mensile',
                          prefixText: '€ ',
                          hintText: '500.00',
                          border: const OutlineInputBorder(),
                          helperText: hasBudget
                              ? 'Modifica il budget mensile'
                              : 'Imposta un budget mensile per questa categoria',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci un importo';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Importo non valido';
                          }
                          if (amount < 0) {
                            return 'L\'importo non può essere negativo';
                          }
                          if (amount == 0) {
                            return 'L\'importo deve essere maggiore di zero';
                          }
                          if (amount > 999999.99) {
                            return 'Importo troppo elevato';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _saveBudget(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _saveBudget,
                        tooltip: 'Salva',
                      ),
                      if (_isEditing && hasBudget)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _controller.text =
                                  (widget.currentBudget! / 100).toStringAsFixed(2);
                            });
                          },
                          tooltip: 'Annulla',
                        ),
                    ],
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget mensile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€ ${(widget.currentBudget! / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (hasBudget)
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Elimina'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: _deleteBudget,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
