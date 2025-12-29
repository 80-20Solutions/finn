import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

/// Demo mode flag - set via --dart-define=DEMO_MODE=true
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local caching
  await Hive.initFlutter();
  await Hive.openBox<String>('dashboard_cache');

  if (!kDemoMode) {
    // Validate environment in development
    if (!Env.isDevelopment) {
      Env.validate();
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  runApp(
    const ProviderScope(
      child: FamilyExpenseTrackerApp(),
    ),
  );
}
