import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'features/demo/demo_navigation_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese Famiglia - Demo',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                setState(() => _showSplash = false);
              },
            )
          : const DemoNavigationScreen(),
    );
  }
}
