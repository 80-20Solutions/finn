import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'routes.dart';

/// Main application widget.
class FamilyExpenseTrackerApp extends ConsumerWidget {
  const FamilyExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Spese Famiglia',
      debugShowCheckedModeBanner: false,

      // Localization
      locale: const Locale('it', 'IT'),
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme - Italian Brutalism
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Routing
      routerConfig: router,
    );
  }
}
