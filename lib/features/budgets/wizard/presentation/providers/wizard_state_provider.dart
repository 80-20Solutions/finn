import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wizard_configuration.dart';
import '../../domain/usecases/get_wizard_initial_data.dart';
import '../../domain/usecases/save_wizard_configuration.dart';

/// Provider for wizard state management.
/// Feature: 001-group-budget-wizard, Task: T029
///
/// Manages the complete wizard flow state including:
/// - Current step (0-3)
/// - Selected categories
/// - Category budgets
/// - Member allocations
/// - Draft saving and loading

class WizardStateNotifier extends StateNotifier<WizardState> {
  WizardStateNotifier({
    required this.getWizardInitialData,
    required this.saveWizardConfiguration,
    required this.groupId,
  }) : super(const WizardState.initial()) {
    _loadInitialData();
  }

  final GetWizardInitialData getWizardInitialData;
  final SaveWizardConfiguration saveWizardConfiguration;
  final String groupId;

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);

    final result = await getWizardInitialData(
      GetWizardInitialDataParams(groupId: groupId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (data) {
        state = state.copyWith(
          isLoading: false,
          categories: data.categories,
          members: data.members,
          configuration: data.existingDraft,
        );
      },
    );
  }

  void updateCurrentStep(int step) {
    if (step < 0 || step > 3) return;

    final updatedConfig = state.configuration?.copyWith(currentStep: step) ??
        WizardConfiguration(
          groupId: groupId,
          selectedCategories: const [],
          categoryBudgets: const {},
          memberAllocations: const {},
          currentStep: step,
        );

    state = state.copyWith(configuration: updatedConfig);
  }

  void updateSelectedCategories(List<String> categoryIds) {
    final updatedConfig = state.configuration?.copyWith(
          selectedCategories: categoryIds,
        ) ??
        WizardConfiguration(
          groupId: groupId,
          selectedCategories: categoryIds,
          categoryBudgets: const {},
          memberAllocations: const {},
        );

    state = state.copyWith(configuration: updatedConfig);
  }

  void updateCategoryBudgets(Map<String, int> budgets) {
    final updatedConfig = state.configuration?.copyWith(
          categoryBudgets: budgets,
        ) ??
        WizardConfiguration(
          groupId: groupId,
          selectedCategories: const [],
          categoryBudgets: budgets,
          memberAllocations: const {},
        );

    state = state.copyWith(configuration: updatedConfig);
  }

  void updateMemberAllocations(Map<String, double> allocations) {
    final updatedConfig = state.configuration?.copyWith(
          memberAllocations: allocations,
        ) ??
        WizardConfiguration(
          groupId: groupId,
          selectedCategories: const [],
          categoryBudgets: const {},
          memberAllocations: allocations,
        );

    state = state.copyWith(configuration: updatedConfig);
  }

  Future<bool> submitConfiguration(String adminUserId) async {
    if (state.configuration == null || !state.configuration!.isValid) {
      state = state.copyWith(
        errorMessage: 'Configurazione non valida. Controlla tutti i campi.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    final result = await saveWizardConfiguration(
      SaveWizardConfigurationParams(
        configuration: state.configuration!,
        adminUserId: adminUserId,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSubmitting: false,
          isCompleted: true,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  bool canProceedToNextStep() {
    if (state.configuration == null) return false;

    switch (state.configuration!.currentStep) {
      case 0:
        // Step 1: Category selection
        return state.configuration!.selectedCategories.isNotEmpty;
      case 1:
        // Step 2: Budget amounts
        return state.configuration!.categoryBudgets.length ==
                state.configuration!.selectedCategories.length &&
            state.configuration!.categoryBudgets.values.every((v) => v > 0);
      case 2:
        // Step 3: Member allocations
        if (state.configuration!.memberAllocations.isEmpty) return false;
        final total = state.configuration!.memberAllocations.values
            .fold(0.0, (sum, val) => sum + val);
        return (total - 100.0).abs() <= 0.01; // ±0.01% tolerance
      case 3:
        // Step 4: Summary (always can proceed)
        return true;
      default:
        return false;
    }
  }
}

class WizardState {
  const WizardState({
    required this.isLoading,
    required this.isSubmitting,
    required this.isCompleted,
    required this.categories,
    required this.members,
    this.configuration,
    this.errorMessage,
  });

  const WizardState.initial()
      : isLoading = false,
        isSubmitting = false,
        isCompleted = false,
        categories = const [],
        members = const [],
        configuration = null,
        errorMessage = null;

  final bool isLoading;
  final bool isSubmitting;
  final bool isCompleted;
  final List categories;
  final List members;
  final WizardConfiguration? configuration;
  final String? errorMessage;

  WizardState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isCompleted,
    List? categories,
    List? members,
    WizardConfiguration? configuration,
    String? errorMessage,
  }) {
    return WizardState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      categories: categories ?? this.categories,
      members: members ?? this.members,
      configuration: configuration ?? this.configuration,
      errorMessage: errorMessage,
    );
  }
}

// Provider definition
final wizardStateProvider =
    StateNotifierProvider.family<WizardStateNotifier, WizardState, String>(
  (ref, groupId) {
    // Dependencies would be injected here
    throw UnimplementedError('Provider dependencies not set up yet');
  },
);
