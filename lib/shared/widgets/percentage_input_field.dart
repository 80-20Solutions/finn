import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/strings_it.dart';

/// Specialized text field for percentage input (0-100%) with validation.
/// Feature: 001-group-budget-wizard, Task: T003
///
/// Provides:
/// - Decimal input (0.00 to 100.00)
/// - Real-time validation
/// - Automatic % suffix
/// - Italian localization
class PercentageInputField extends StatelessWidget {
  const PercentageInputField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.enabled = true,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.errorText,
    this.helperText,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool autofocus;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: '%',
        errorText: errorText,
        helperText: helperText,
        counterText: '', // Hide character counter
      ),
      inputFormatters: [
        // Allow only numbers and decimal point
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        // Custom formatter to enforce 0-100 range
        _PercentageRangeFormatter(),
      ],
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return StringsIt.percentageInvalid;
            }
            final percentage = double.tryParse(value);
            if (percentage == null || percentage < 0 || percentage > 100) {
              return StringsIt.percentageInvalid;
            }
            return null;
          },
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

/// Custom input formatter to enforce 0-100 range for percentages.
class _PercentageRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty input
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Parse the value
    final value = double.tryParse(newValue.text);

    // If invalid or out of range, revert to old value
    if (value == null || value > 100) {
      return oldValue;
    }

    return newValue;
  }
}
