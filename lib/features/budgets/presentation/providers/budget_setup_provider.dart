import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/income_source_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/usecases/setup_personal_budget_usecase.dart';
import '../../domain/usecases/add_income_source_usecase.dart';
import 'budget_repository_provider.dart';
import '../../../../core/errors/failures.dart';

/// State for the budget setup wizard
class BudgetSetupState {
  final List<IncomeSourceEntity> incomeSources;
  final SavingsGoalEntity? savingsGoal;
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final bool isComplete;

  const BudgetSetupState({
    this.incomeSources = const [],
    this.savingsGoal,
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isComplete = false,
  });

  BudgetSetupState copyWith({
    List<IncomeSourceEntity>? incomeSources,
    SavingsGoalEntity? savingsGoal,
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool? isComplete,
  }) {
    return BudgetSetupState(
      incomeSources: incomeSources ?? this.incomeSources,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Calculate total income from all sources
  int get totalIncome {
    return incomeSources.fold<int>(0, (sum, source) => sum + source.amount);
  }

  /// Check if can proceed to next step
  bool get canProceedToNextStep {
    switch (currentStep) {
      case 0: // Income entry step
        return true; // FR-022: Allow zero income sources
      case 1: // Savings goal step
        return true; // Always can proceed (savings optional)
      case 2: // Summary step
        return false; // Last step, no next
      default:
        return false;
    }
  }

  /// Check if can go back to previous step
  bool get canGoBack {
    return currentStep > 0 && !isLoading;
  }
}

/// Provider for budget setup wizard state management
class BudgetSetupNotifier extends StateNotifier<BudgetSetupState> {
  final SetupPersonalBudgetUseCase setupUseCase;
  final AddIncomeSourceUseCase addIncomeUseCase;
  final PageController pageController;

  BudgetSetupNotifier({
    required this.setupUseCase,
    required this.addIncomeUseCase,
    required this.pageController,
  }) : super(const BudgetSetupState());

  /// Add an income source to the wizard state
  void addIncomeSource(IncomeSourceEntity incomeSource) {
    state = state.copyWith(
      incomeSources: [...state.incomeSources, incomeSource],
      errorMessage: null,
    );
  }

  /// Remove an income source from the wizard state
  void removeIncomeSource(String id) {
    state = state.copyWith(
      incomeSources: state.incomeSources.where((s) => s.id != id).toList(),
      errorMessage: null,
    );
  }

  /// Update an income source in the wizard state
  void updateIncomeSource(IncomeSourceEntity updatedSource) {
    state = state.copyWith(
      incomeSources: state.incomeSources
          .map((s) => s.id == updatedSource.id ? updatedSource : s)
          .toList(),
      errorMessage: null,
    );
  }

  /// Set the savings goal in the wizard state
  void setSavingsGoal(SavingsGoalEntity? savingsGoal) {
    state = state.copyWith(
      savingsGoal: savingsGoal,
      errorMessage: null,
    );
  }

  /// Clear the savings goal
  void clearSavingsGoal() {
    state = state.copyWith(
      savingsGoal: null,
      errorMessage: null,
    );
  }

  /// Set current step manually (used by PageView onPageChanged)
  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step, errorMessage: null);
  }

  /// Initialize the page controller (called from wizard screen initState)
  void initializePageController(PageController controller) {
    // Page controller is already passed via constructor
    // This method exists for consistency but doesn't need to do anything
  }

  /// Navigate to next step in wizard
  Future<void> nextStep() async {
    if (!state.canProceedToNextStep) return;

    final nextStep = state.currentStep + 1;

    // Update state
    state = state.copyWith(currentStep: nextStep);

    // Animate page controller
    await pageController.animateToPage(
      nextStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navigate to previous step in wizard
  Future<void> previousStep() async {
    if (!state.canGoBack) return;

    final prevStep = state.currentStep - 1;

    // Update state
    state = state.copyWith(currentStep: prevStep, errorMessage: null);

    // Animate page controller
    await pageController.animateToPage(
      prevStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Jump to a specific step
  Future<void> goToStep(int step) async {
    if (step < 0 || step > 2 || step == state.currentStep) return;

    state = state.copyWith(currentStep: step, errorMessage: null);

    await pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Complete the wizard setup
  ///
  /// Calls SetupPersonalBudgetUseCase to persist all data
  /// Returns true if successful, false otherwise
  Future<bool> completeSetup(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await setupUseCase(
        userId: userId,
        incomeSources: state.incomeSources,
        savingsGoal: state.savingsGoal,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (summary) {
          state = state.copyWith(
            isLoading: false,
            isComplete: true,
            errorMessage: null,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to complete setup: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset wizard to initial state
  void reset() {
    state = const BudgetSetupState();
    pageController.jumpToPage(0);
  }

  /// Validate current step data
  String? validateCurrentStep() {
    switch (state.currentStep) {
      case 0: // Income entry
        // FR-022: Allow zero income sources
        return null;

      case 1: // Savings goal
        if (state.savingsGoal != null) {
          if (state.savingsGoal!.amount >= state.totalIncome &&
              state.totalIncome > 0) {
            return 'Savings goal must be less than total income';
          }
          if (state.savingsGoal!.amount < 0) {
            return 'Savings goal cannot be negative';
          }
        }
        return null;

      case 2: // Summary
        return null; // No validation needed for summary

      default:
        return null;
    }
  }
}

/// Use case providers
final setupPersonalBudgetUseCaseProvider =
    Provider<SetupPersonalBudgetUseCase>((ref) {
  return SetupPersonalBudgetUseCase(
    ref.watch(budgetRepositoryProvider),
  );
});

final addIncomeSourceUseCaseProvider = Provider<AddIncomeSourceUseCase>((ref) {
  return AddIncomeSourceUseCase(
    ref.watch(budgetRepositoryProvider),
  );
});

/// Page controller provider - disposed automatically
final budgetSetupPageControllerProvider = Provider.autoDispose<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Budget setup wizard state provider
final budgetSetupProvider =
    StateNotifierProvider.autoDispose<BudgetSetupNotifier, BudgetSetupState>((ref) {
  return BudgetSetupNotifier(
    setupUseCase: ref.watch(setupPersonalBudgetUseCaseProvider),
    addIncomeUseCase: ref.watch(addIncomeSourceUseCaseProvider),
    pageController: ref.watch(budgetSetupPageControllerProvider),
  );
});
