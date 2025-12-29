import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for Supabase and external services.
///
/// Values are loaded from .env file in the project root.
/// Initialize by calling `await dotenv.load()` in main.dart before using.
class Env {
  Env._();

  /// Supabase project URL
  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'YOUR_SUPABASE_URL');

  /// Supabase anonymous/public key
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: 'YOUR_SUPABASE_ANON_KEY');

  /// Google Cloud Vision API key (should be in Edge Function, not client)
  /// Only used for development/testing
  static String get gcpVisionApiKey =>
      dotenv.get('GCP_VISION_API_KEY', fallback: '');

  /// Whether we're running in development mode
  static bool get isDevelopment =>
      supabaseUrl == 'YOUR_SUPABASE_URL' || supabaseUrl.contains('localhost');

  /// Validate that required environment variables are set
  static void validate() {
    if (supabaseUrl == 'YOUR_SUPABASE_URL') {
      throw Exception(
        'SUPABASE_URL not configured. '
        'Please ensure .env file exists in project root with SUPABASE_URL set.',
      );
    }
    if (supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception(
        'SUPABASE_ANON_KEY not configured. '
        'Please ensure .env file exists in project root with SUPABASE_ANON_KEY set.',
      );
    }
  }
}
