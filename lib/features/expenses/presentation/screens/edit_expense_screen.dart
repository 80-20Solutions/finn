import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/navigation_guard.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_selector.dart';

/// Screen for editing an existing expense.
class EditExpenseScreen extends ConsumerStatefulWidget {
  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  /// The expense to edit.
  final ExpenseEntity expense;

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen>
    with UnsavedChangesGuard {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  // Track initial values for unsaved changes detection
  late final String _initialAmount;
  late final String _initialMerchant;
  late final String _initialNotes;
  late final DateTime _initialDate;
  late final ExpenseCategory _initialCategory;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing expense data
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    _merchantController.text = widget.expense.merchant ?? '';
    _notesController.text = widget.expense.notes ?? '';
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;

    // Store initial values for change detection
    _initialAmount = _amountController.text;
    _initialMerchant = _merchantController.text;
    _initialNotes = _notesController.text;
    _initialDate = _selectedDate;
    _initialCategory = _selectedCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  bool get hasUnsavedChanges {
    return _amountController.text != _initialAmount ||
        _merchantController.text != _initialMerchant ||
        _notesController.text != _initialNotes ||
        _selectedDate != _initialDate ||
        _selectedCategory != _initialCategory;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Validators.parseAmount(_amountController.text);
    if (amount == null) return;

    final formNotifier = ref.read(expenseFormProvider.notifier);
    final listNotifier = ref.read(expenseListProvider.notifier);

    final updatedExpense = await formNotifier.updateExpense(
      expenseId: widget.expense.id,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (updatedExpense != null && mounted) {
      listNotifier.updateExpenseInList(updatedExpense);
      // Refresh dashboard to reflect the updated expense
      ref.read(dashboardProvider.notifier).refresh();
      context.pop(); // Return to previous screen
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormProvider);

    return buildWithNavigationGuard(
      context,
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Modifica spesa'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message
                if (formState.hasError && formState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InlineError(message: formState.errorMessage!),
                  ),

                // Amount field
                AmountTextField(
                  controller: _amountController,
                  validator: Validators.validateAmount,
                  enabled: !formState.isSubmitting,
                  autofocus: false,
                ),
                const SizedBox(height: 16),

                // Date field
                InkWell(
                  onTap: formState.isSubmitting ? null : _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormatter.formatFullDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Merchant field
                CustomTextField(
                  controller: _merchantController,
                  label: 'Negozio',
                  hint: 'Nome del negozio (opzionale)',
                  prefixIcon: Icons.store_outlined,
                  enabled: !formState.isSubmitting,
                  validator: Validators.validateMerchant,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Category selector
                CategorySelector(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  enabled: !formState.isSubmitting,
                ),
                const SizedBox(height: 16),

                // Notes field
                CustomTextField(
                  controller: _notesController,
                  label: 'Note',
                  hint: 'Note aggiuntive (opzionale)',
                  prefixIcon: Icons.notes_outlined,
                  enabled: !formState.isSubmitting,
                  validator: Validators.validateNotes,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Save button
                PrimaryButton(
                  onPressed: _handleSave,
                  label: 'Salva modifiche',
                  isLoading: formState.isSubmitting,
                  loadingLabel: 'Salvataggio...',
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
