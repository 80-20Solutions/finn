import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/strings_it.dart';
import '../providers/wizard_state_provider.dart';
import '../widgets/budget_amount_step.dart';
import '../widgets/category_selection_step.dart';
import '../widgets/member_allocation_step.dart';
import '../widgets/wizard_stepper.dart';
import '../widgets/wizard_summary_step.dart';

/// Budget wizard main screen.
/// Feature: 001-group-budget-wizard, Task: T037
class BudgetWizardScreen extends ConsumerStatefulWidget {
  const BudgetWizardScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<BudgetWizardScreen> createState() =>
      _BudgetWizardScreenState();
}

class _BudgetWizardScreenState extends ConsumerState<BudgetWizardScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch wizard state
    final wizardState = ref.watch(wizardStateProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsIt.budgetWizardTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context),
        ),
      ),
      body: wizardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wizardState.errorMessage != null
              ? _buildErrorState(context, wizardState.errorMessage!)
              : _buildWizardContent(context, wizardState),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              StringsIt.errorOccurred,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(StringsIt.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardContent(BuildContext context, WizardState state) {
    if (state.configuration == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(wizardStateProvider(widget.groupId).notifier);
    final currentStep = state.configuration!.currentStep;

    return WizardStepper(
      currentStep: currentStep,
      canProceed: notifier.canProceedToNextStep(),
      onStepChanged: (step) => notifier.updateCurrentStep(step),
      onComplete: () => _handleComplete(context, notifier),
      children: [
        // Step 1: Category Selection
        CategorySelectionStep(
          categories: state.categories.cast(),
          selectedCategories: state.configuration!.selectedCategories,
          onSelectionChanged: (selected) {
            notifier.updateSelectedCategories(selected);
          },
        ),

        // Step 2: Budget Amounts
        BudgetAmountStep(
          categories: state.categories.cast(),
          categoryBudgets: state.configuration!.categoryBudgets,
          onBudgetsChanged: (budgets) {
            notifier.updateCategoryBudgets(budgets);
          },
        ),

        // Step 3: Member Allocations
        MemberAllocationStep(
          members: state.members.cast(),
          memberAllocations: state.configuration!.memberAllocations,
          onAllocationsChanged: (allocations) {
            notifier.updateMemberAllocations(allocations);
          },
        ),

        // Step 4: Summary
        WizardSummaryStep(
          configuration: state.configuration!,
          categories: state.categories.cast(),
          members: state.members.cast(),
        ),
      ],
    );
  }

  Future<void> _handleComplete(
    BuildContext context,
    WizardStateNotifier notifier,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Submit configuration
    final success = await notifier.submitConfiguration('current-user-id');

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (success && context.mounted) {
      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StringsIt.configurationSaved),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (context.mounted) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StringsIt.errorSavingConfiguration),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(StringsIt.cancelConfiguration),
        content: const Text(StringsIt.progressWillBeLost),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(StringsIt.continueEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(StringsIt.exit),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
