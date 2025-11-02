import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isDemoMode;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isDemoMode = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isDemoMode,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Authentication provider
class AuthNotifier extends StateNotifier<AuthState> {
  static const String _authStorageKey = '@auth_user';
  static const String _demoModeKey = '@demo_mode';

  AuthNotifier() : super(const AuthState()) {
    _loadUser();
  }

  /// Load user from storage
  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();

      final demoMode = prefs.getBool(_demoModeKey) ?? false;
      final storedUserJson = prefs.getString(_authStorageKey);

      if (demoMode && storedUserJson != null) {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);

        state = state.copyWith(
          user: user,
          isDemoMode: true,
          isLoading: false,
        );
        return;
      }

      if (storedUserJson != null) {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);

        state = state.copyWith(
          user: user,
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user: $e',
      );
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check demo users first
      final demoUser = DemoUsers.findByEmail(email);
      if (demoUser != null && password == 'demo') {
        await _saveUser(demoUser, isDemoMode: true);

        state = state.copyWith(
          user: demoUser,
          isDemoMode: true,
          isLoading: false,
        );
        return true;
      }

      // TODO: Real authentication with Supabase
      // For now, only demo mode is supported

      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  /// Quick role switch for demo mode
  Future<void> switchRole(UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final demoUser = DemoUsers.findByRole(role);
      if (demoUser != null) {
        await _saveUser(demoUser, isDemoMode: true);

        state = state.copyWith(
          user: demoUser,
          isDemoMode: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Role switch failed: $e',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStorageKey);
      await prefs.remove(_demoModeKey);

      // TODO: Supabase signOut

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: $e',
      );
    }
  }

  /// Save user to storage
  Future<void> _saveUser(User user, {bool isDemoMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authStorageKey, jsonEncode(user.toJson()));
    await prefs.setBool(_demoModeKey, isDemoMode);
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = state.user!.copyWith(
        name: name ?? state.user!.name,
        phone: phone ?? state.user!.phone,
        avatarUrl: avatarUrl ?? state.user!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      await _saveUser(updatedUser, isDemoMode: state.isDemoMode);

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update failed: $e',
      );
    }
  }

  /// Change password (demo mode only shows success)
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.isDemoMode) {
        // Simulate password change in demo mode
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(isLoading: false);
        return true;
      }

      // TODO: Real password change with Supabase

      state = state.copyWith(
        isLoading: false,
        error: 'Password change not implemented yet',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password change failed: $e',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Loading status provider
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Demo mode status provider
final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isDemoMode;
});

/// User role provider
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).user?.role;
});

/// Role checker provider
final hasRoleProvider = Provider.family<bool, UserRole>((ref, requiredRole) {
  final user = ref.watch(currentUserProvider);
  return user?.hasRole(requiredRole) ?? false;
});

/// Multiple roles checker provider
final hasAnyRoleProvider =
    Provider.family<bool, List<UserRole>>((ref, requiredRoles) {
  final user = ref.watch(currentUserProvider);
  return user?.hasAnyRole(requiredRoles) ?? false;
});
