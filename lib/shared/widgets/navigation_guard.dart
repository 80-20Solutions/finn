import 'package:flutter/material.dart';

import 'unsaved_changes_dialog.dart';

/// Mixin for screens that need to guard against unsaved changes
mixin UnsavedChangesGuard<T extends StatefulWidget> on State<T> {
  /// Override this to indicate if the screen has unsaved changes
  bool get hasUnsavedChanges;

  /// Show dialog to confirm discarding unsaved changes
  ///
  /// Returns true if user confirms discard, false otherwise
  Future<bool> confirmDiscardChanges(BuildContext context) async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  /// Wrap widget with PopScope to guard navigation
  Widget buildWithNavigationGuard(BuildContext context, Widget child) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await confirmDiscardChanges(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
