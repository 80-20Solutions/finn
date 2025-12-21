import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/auth_provider.dart';

/// Home screen that redirects based on user state.
///
/// - If user is not authenticated: redirect to login
/// - If user has no group: redirect to no-group screen
/// - If user has a group: redirect to main navigation (dashboard)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading while checking auth state
    if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Caricamento...'),
      );
    }

    // If not authenticated, this screen shouldn't be shown
    // (router should redirect), but handle it anyway
    if (!authState.isAuthenticated || authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    // Check if user has a group
    final user = authState.user!;
    if (!user.hasGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/no-group');
      });
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    // User has a group - redirect to main navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/main');
    });
    return const Scaffold(
      body: LoadingIndicator(),
    );
  }
}
