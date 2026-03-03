import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration
/// Loads credentials from .env file
/// NOTE: Service role key intentionally NOT exposed in client code.
/// Use Supabase Edge Functions for admin operations.
class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
