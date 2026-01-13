import 'package:flutter/material.dart';

/// Widget for showing progress through a multi-step guided flow
///
/// Displays a horizontal step indicator showing:
/// - Current step highlighted
/// - Completed steps marked with checkmark
/// - Future steps shown as inactive
/// - Step titles and optional descriptions
class GuidedStepIndicator extends StatelessWidget {
  /// Total number of steps in the wizard
  final int totalSteps;

  /// Current step index (0-based)
  final int currentStep;

  /// Step titles (optional)
  final List<String>? stepTitles;

  /// Step descriptions (optional)
  final List<String>? stepDescriptions;

  /// Callback when a step is tapped (for navigation)
  final ValueChanged<int>? onStepTapped;

  /// Whether to allow tapping on steps
  final bool allowStepTap;

  const GuidedStepIndicator({
    Key? key,
    required this.totalSteps,
    required this.currentStep,
    this.stepTitles,
    this.stepDescriptions,
    this.onStepTapped,
    this.allowStepTap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicators row
          Row(
            children: List.generate(
              totalSteps * 2 - 1, // Steps + connectors
              (index) {
                if (index.isEven) {
                  // Step circle
                  final stepIndex = index ~/ 2;
                  return _StepCircle(
                    stepNumber: stepIndex + 1,
                    isActive: stepIndex == currentStep,
                    isCompleted: stepIndex < currentStep,
                    onTap: allowStepTap && onStepTapped != null
                        ? () => onStepTapped!(stepIndex)
                        : null,
                  );
                } else {
                  // Connector line
                  final stepIndex = index ~/ 2;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: stepIndex < currentStep
                          ? theme.primaryColor
                          : theme.dividerColor,
                    ),
                  );
                }
              },
            ),
          ),

          // Step titles (if provided)
          if (stepTitles != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                totalSteps,
                (index) => Expanded(
                  child: Text(
                    stepTitles![index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: index == currentStep
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: index <= currentStep
                          ? theme.primaryColor
                          : theme.disabledColor,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Step descriptions (if provided)
          if (stepDescriptions != null && stepDescriptions!.length > currentStep) ...[
            const SizedBox(height: 8),
            Text(
              stepDescriptions![currentStep],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepNumber;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepCircle({
    required this.stepNumber,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color contentColor;
    Widget content;

    if (isCompleted) {
      backgroundColor = theme.primaryColor;
      contentColor = Colors.white;
      content = const Icon(Icons.check, color: Colors.white, size: 18);
    } else if (isActive) {
      backgroundColor = theme.primaryColor;
      contentColor = Colors.white;
      content = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else {
      backgroundColor = theme.dividerColor;
      contentColor = theme.disabledColor;
      content = Text(
        '$stepNumber',
        style: TextStyle(
          color: contentColor,
          fontSize: 16,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 4,
                )
              : null,
        ),
        child: Center(child: content),
      ),
    );
  }
}

/// Vertical variant of step indicator (for side navigation)
class VerticalGuidedStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepTitles;
  final List<String>? stepDescriptions;
  final ValueChanged<int>? onStepTapped;
  final bool allowStepTap;

  const VerticalGuidedStepIndicator({
    Key? key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepTitles,
    this.stepDescriptions,
    this.onStepTapped,
    this.allowStepTap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(
        totalSteps,
        (index) => Column(
          children: [
            InkWell(
              onTap: allowStepTap && onStepTapped != null
                  ? () => onStepTapped!(index)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    _StepCircle(
                      stepNumber: index + 1,
                      isActive: index == currentStep,
                      isCompleted: index < currentStep,
                      onTap: null, // Handled by InkWell
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepTitles[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: index == currentStep
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: index <= currentStep
                                  ? theme.primaryColor
                                  : theme.disabledColor,
                            ),
                          ),
                          if (stepDescriptions != null &&
                              stepDescriptions!.length > index) ...[
                            const SizedBox(height: 4),
                            Text(
                              stepDescriptions![index],
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < totalSteps - 1)
              Container(
                margin: const EdgeInsets.only(left: 32),
                height: 24,
                width: 2,
                color: index < currentStep
                    ? theme.primaryColor
                    : theme.dividerColor,
              ),
          ],
        ),
      ),
    );
  }
}
