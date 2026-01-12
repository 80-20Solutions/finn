import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';

/// Wizard stepper widget for navigating through 4 wizard steps.
/// Feature: 001-group-budget-wizard, Task: T032
class WizardStepper extends StatelessWidget {
  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
    required this.onComplete,
    required this.canProceed,
    this.children = const [],
  });

  final int currentStep;
  final Function(int) onStepChanged;
  final VoidCallback onComplete;
  final bool canProceed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: currentStep,
      onStepContinue: canProceed
          ? () {
              if (currentStep < 3) {
                onStepChanged(currentStep + 1);
              } else {
                onComplete();
              }
            }
          : null,
      onStepCancel: currentStep > 0
          ? () => onStepChanged(currentStep - 1)
          : null,
      onStepTapped: (step) {
        // Allow jumping to completed steps
        if (step <= currentStep) {
          onStepChanged(step);
        }
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: [
              if (details.stepIndex > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text(StringsIt.back),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(
                  details.stepIndex == 3
                      ? StringsIt.complete
                      : StringsIt.next,
                ),
              ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text(StringsIt.categories),
          subtitle: const Text(StringsIt.selectCategories),
          content: children.isNotEmpty ? children[0] : const SizedBox.shrink(),
          isActive: currentStep >= 0,
          state: _getStepState(0),
        ),
        Step(
          title: const Text(StringsIt.budget),
          subtitle: const Text(StringsIt.setBudgets),
          content: children.length > 1 ? children[1] : const SizedBox.shrink(),
          isActive: currentStep >= 1,
          state: _getStepState(1),
        ),
        Step(
          title: const Text(StringsIt.allocations),
          subtitle: const Text(StringsIt.distributePercentages),
          content: children.length > 2 ? children[2] : const SizedBox.shrink(),
          isActive: currentStep >= 2,
          state: _getStepState(2),
        ),
        Step(
          title: const Text(StringsIt.summary),
          subtitle: const Text(StringsIt.reviewAndConfirm),
          content: children.length > 3 ? children[3] : const SizedBox.shrink(),
          isActive: currentStep >= 3,
          state: _getStepState(3),
        ),
      ],
    );
  }

  StepState _getStepState(int step) {
    if (step < currentStep) {
      return StepState.complete;
    } else if (step == currentStep) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }
}
