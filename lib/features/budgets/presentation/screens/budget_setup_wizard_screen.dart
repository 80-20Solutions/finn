import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_setup_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/guided_step_indicator.dart';
import 'income_entry_screen.dart';
import 'savings_goal_screen.dart';
import 'budget_summary_screen.dart';

/// Main wizard screen for personal budget setup
///
/// Implements FR-001: Personal budget setup
/// - 3-step guided wizard flow
/// - Step 1: Income entry (at least one required)
/// - Step 2: Savings goal (optional)
/// - Step 3: Budget summary and confirmation
///
/// Uses PageView for horizontal swipe navigation
/// Displays step indicator at top
/// Shows contextual next/back buttons
class BudgetSetupWizardScreen extends ConsumerStatefulWidget {
  const BudgetSetupWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetSetupWizardScreen> createState() =>
      _BudgetSetupWizardScreenState();
}

class _BudgetSetupWizardScreenState
    extends ConsumerState<BudgetSetupWizardScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize budget setup provider with page controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetSetupProvider.notifier).initializePageController(_pageController);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(budgetSetupProvider);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go to previous step if not on first step
        if (setupState.currentStep > 0) {
          ref.read(budgetSetupProvider.notifier).previousStep();
          return false;
        }

        // Show confirmation dialog if user has entered data
        if (setupState.incomeSources.isNotEmpty || setupState.savingsGoal != null) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit Budget Setup?'),
              content: const Text(
                'You have unsaved changes. Are you sure you want to exit?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Budget Setup'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Step indicator at top
            GuidedStepIndicator(
              totalSteps: 3,
              currentStep: setupState.currentStep,
              stepTitles: const [
                'Income',
                'Savings',
                'Summary',
              ],
              stepDescriptions: const [
                'Add your income sources',
                'Set your savings goal',
                'Review your budget',
              ],
            ),

            // Wizard pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (page) {
                  ref.read(budgetSetupProvider.notifier).setCurrentStep(page);
                },
                children: const [
                  IncomeEntryScreen(),
                  SavingsGoalScreen(),
                  BudgetSummaryScreen(),
                ],
              ),
            ),

            // Navigation buttons at bottom
            _buildNavigationButtons(context, setupState),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    BudgetSetupState setupState,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(budgetSetupProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button (hidden on first step)
            if (setupState.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: setupState.isLoading
                      ? null
                      : () => notifier.previousStep(),
                  child: const Text('Back'),
                ),
              ),
            if (setupState.currentStep > 0) const SizedBox(width: 16),

            // Next/Complete button
            Expanded(
              flex: setupState.currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: setupState.isLoading || !setupState.canProceedToNextStep
                    ? null
                    : () => _handleNextButton(context, setupState, notifier),
                child: setupState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_getButtonLabel(setupState.currentStep)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonLabel(int currentStep) {
    switch (currentStep) {
      case 0:
        return 'Next';
      case 1:
        return 'Next';
      case 2:
        return 'Complete';
      default:
        return 'Next';
    }
  }

  Future<void> _handleNextButton(
    BuildContext context,
    BudgetSetupState setupState,
    BudgetSetupNotifier notifier,
  ) async {
    if (setupState.currentStep < 2) {
      // Move to next step
      await notifier.nextStep();
    } else {
      // Complete wizard on last step
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) {
        _showErrorDialog(context, 'User not authenticated');
        return;
      }

      final success = await notifier.completeSetup(userId);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home or budget overview
        Navigator.of(context).pop(true);
      } else if (mounted && setupState.errorMessage != null) {
        _showErrorDialog(context, setupState.errorMessage!);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
