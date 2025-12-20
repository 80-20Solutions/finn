import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'features/demo/demo_navigation_screen.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese Famiglia - Demo',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DemoNavigationScreen(),
    );
  }
}
