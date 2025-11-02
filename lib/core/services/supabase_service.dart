import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase Service
/// Provides easy access to Supabase client and common operations
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Get Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth stream for listening to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}

/// Global instance for easy access
final supabase = SupabaseService();
