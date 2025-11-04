import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user.dart' as app_user;
import '../services/account_storage_service.dart';

// Get the Supabase client instance
final _supabaseClient = Supabase.instance.client;

/// Authentication state
class AuthState {
  final app_user.User? user;
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
    app_user.User? user,
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
class AuthNotifier extends Notifier<AuthState> {
  static const String _authStorageKey = '@auth_user';
  static const String _demoModeKey = '@demo_mode';

  // Phase 3.1: Session Timeout Implementation
  static const Duration _sessionTimeout = Duration(minutes: 30);
  DateTime? _lastActivityTime;
  bool _sessionTimeoutEnabled = true;

  @override
  AuthState build() {
    // Set up auth state listener (but don't block build)
    Future.microtask(() {
      _supabaseClient.auth.onAuthStateChange.listen((data) {
        final event = data.event;

        print('🔵 Auth state changed: $event');

        switch (event) {
          case AuthChangeEvent.signedIn:
            print('🟢 User signed in via state change');
            // Session restored automatically
            _resetSessionTimer(); // Phase 3.1: Reset timer on sign in
            break;
          case AuthChangeEvent.signedOut:
            print('🔴 User signed out from server');
            _handleSignOut();
            break;
          case AuthChangeEvent.tokenRefreshed:
            print('🔄 Token refreshed automatically');
            _resetSessionTimer(); // Phase 3.1: Reset timer on token refresh
            break;
          case AuthChangeEvent.userUpdated:
            print('🔵 User profile updated');
            break;
          default:
            break;
        }
      });

      // Phase 3.1: Start session timeout checker
      _startSessionTimeoutChecker();
    });

    // Auto-restore session on app start (async, doesn't block)
    Future.microtask(() => _restoreSession());

    return const AuthState();
  }

  /// Handle sign out from server or token expiration
  Future<void> _handleSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      state = const AuthState();

      print('🟢 Signed out successfully (server-initiated)');
    } catch (e) {
      print('🔴 Error during server-initiated sign out: $e');
    }
  }

  /// Restore session from Supabase or local storage
  Future<void> _restoreSession() async {
    // Don't modify state during build - wait for next frame
    await Future.delayed(Duration.zero);

    state = state.copyWith(isLoading: true);

    try {
      print('🔵 Attempting to restore session...');

      // 1. Check Supabase session first (takes priority)
      final session = _supabaseClient.auth.currentSession;

      if (session != null) {
        print('🔵 Found active Supabase session: ${session.user.id}');

        // Check if email is verified
        if (session.user.emailConfirmedAt == null) {
          print('⚠️ Email not verified, clearing session');
          await _supabaseClient.auth.signOut();
          state = state.copyWith(isLoading: false);
          return;
        }

        try {
          // 2. Fetch user profile from database - specify columns to avoid relationship ambiguity
          final response = await _supabaseClient
              .from('users')
              .select(
                  'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
              .eq('id', session.user.id)
              .maybeSingle();

          if (response != null) {
            final user = app_user.User(
              id: response['id'] as String,
              name: response['full_name'] as String,
              email: response['email'] as String,
              role: _parseRole(response['role'] as String),
              phone: response['phone'] as String? ?? '',
            );

            await _saveUser(user, isDemoMode: false);

            state = state.copyWith(
              user: user,
              isDemoMode: false,
              isLoading: false,
            );

            // Phase 3.1: Reset session timer on successful restore
            _resetSessionTimer();

            print('🟢 Session restored successfully: ${user.email}');
            return;
          } else {
            print('⚠️ User profile not found, clearing session');
            await _supabaseClient.auth.signOut();
          }
        } catch (e) {
          print('🔴 Error fetching user profile: $e');
          await _supabaseClient.auth.signOut();
        }
      }

      print('🔵 No active Supabase session, checking local storage...');

      // 3. Fallback to demo user from local storage
      await loadUser();

      if (state.user != null) {
        print(
            '🟢 Loaded ${state.isDemoMode ? "demo" : "cached"} user from storage: ${state.user!.email}');
      } else {
        print('ℹ️ No saved session found');
      }
    } catch (e) {
      print('🔴 Failed to restore session: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load user from storage - call this explicitly when needed
  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();

      final demoMode = prefs.getBool(_demoModeKey) ?? false;
      final storedUserJson = prefs.getString(_authStorageKey);

      if (demoMode && storedUserJson != null) {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        final user = app_user.User.fromJson(userMap);

        state = state.copyWith(
          user: user,
          isDemoMode: true,
          isLoading: false,
        );
        return;
      }

      if (storedUserJson != null) {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        final user = app_user.User.fromJson(userMap);

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

  /// Reload user data from database and update state
  /// Use this after updating user profile to refresh UI
  Future<void> reloadUserFromDatabase() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        print('🔴 No authenticated user to reload');
        return;
      }

      print('🔵 Reloading user from database: ${currentUser.id}');

      // Fetch fresh data from database - specify columns to avoid relationship ambiguity
      final response = await _supabaseClient
          .from('users')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        print('🔴 User not found in database');
        return;
      }

      print('🔵 User data fetched from database');

      // Convert to User object
      final updatedUser = app_user.User.fromJson(response);

      // Save to local storage
      await _saveUser(updatedUser);

      // Update state
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );

      print(
          '🟢 User reloaded successfully: ${updatedUser.name ?? updatedUser.email}');
    } catch (e) {
      print('🔴 Error reloading user from database: $e');
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Check demo users first
      final demoUser = app_user.DemoUsers.findByEmail(email);
      if (demoUser != null && password == 'demo') {
        await _saveUser(demoUser, isDemoMode: true);

        state = state.copyWith(
          user: demoUser,
          isDemoMode: true,
          isLoading: false,
        );

        print('🟢 Demo login successful: ${demoUser.email}');
        return true;
      }

      // 2. Real Supabase authentication
      print('🔵 Attempting Supabase login for: $email');

      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('🔴 No user returned from Supabase');
        state = state.copyWith(
          isLoading: false,
          error: 'Đăng nhập thất bại',
        );
        return false;
      }

      print('🔵 Supabase login successful: ${authResponse.user!.id}');

      // 3. Check if email is verified
      if (authResponse.user!.emailConfirmedAt == null) {
        print('⚠️ Email not verified yet');
        state = state.copyWith(
          isLoading: false,
          error:
              '⚠️ Email chưa được xác thực!\n\nVui lòng kiểm tra email và nhấn vào link xác thực.\nSau đó thử đăng nhập lại.',
        );
        return false;
      }

      print('🔵 Email verified, fetching user profile...');

      // 4. Fetch user profile from database - specify columns to avoid relationship ambiguity
      final response = await _supabaseClient
          .from('users')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      if (response == null) {
        print('🔴 User profile not found in database');
        state = state.copyWith(
          isLoading: false,
          error:
              'Không tìm thấy thông tin người dùng. Vui lòng liên hệ hỗ trợ.',
        );
        return false;
      }

      print('🟢 User profile fetched successfully');

      // 5. Create User object from database
      final user = app_user.User(
        id: response['id'] as String,
        name: response['full_name'] as String,
        email: response['email'] as String,
        role: _parseRole(response['role'] as String),
        phone: response['phone'] as String? ?? '',
      );

      // 6. Save to state and storage
      await _saveUser(user, isDemoMode: false);

      state = state.copyWith(
        user: user,
        isDemoMode: false,
        isLoading: false,
      );

      // ✨ Auto-save account for 1-click switching
      await AccountStorageService.saveAccount(user);
      print('💾 Account auto-saved for quick switching');

      // Phase 3.1: Reset session timer on successful login
      _resetSessionTimer();

      print(
          '🟢 Login completed successfully for: ${user.email} (${user.role.name})');
      return true;
    } on AuthException catch (e) {
      print('🔴 Auth Exception: ${e.message}');

      String errorMessage = 'Đăng nhập thất bại';

      if (e.message.contains('Invalid login credentials') ||
          e.message.contains('Invalid email or password')) {
        errorMessage =
            '❌ Email hoặc mật khẩu không đúng!\n\nVui lòng kiểm tra lại thông tin đăng nhập.';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage =
            '⚠️ Email chưa được xác thực!\n\nVui lòng kiểm tra email và nhấn vào link xác thực.';
      } else {
        errorMessage = 'Đăng nhập thất bại: ${e.message}';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      print('🔴 General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi hệ thống: $e',
      );
      return false;
    }
  }

  /// Parse role string to UserRole enum
  app_user.UserRole _parseRole(String roleString) {
    switch (roleString.toUpperCase()) {
      case 'CEO':
        return app_user.UserRole.ceo;
      case 'MANAGER':
        return app_user.UserRole.manager;
      case 'SHIFT_LEADER':
        return app_user.UserRole.shiftLeader;
      case 'STAFF':
        return app_user.UserRole.staff;
      default:
        print('⚠️ Unknown role: $roleString, defaulting to STAFF');
        return app_user.UserRole.staff;
    }
  }

  /// Sign up new user with real Supabase integration
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    required app_user.UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Debug logging
    print('🔵 SignUp started - Email: $email, Role: ${role.name}');

    try {
      print('🔵 Calling Supabase signUp...');
      final authResponse = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name.toUpperCase(),
          'phone': phone ?? '',
        },
      );

      print('🔵 Supabase response: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        print('🔴 No user returned from Supabase');
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể tạo tài khoản. Vui lòng thử lại.',
        );
        return false;
      }

      print('🟢 User created successfully: ${authResponse.user!.id}');

      // 2. Create user profile in database (will be handled by trigger)
      // The database trigger should automatically create user profile

      // 3. DON'T save user to state yet - wait for email verification
      // User needs to verify email before they can login

      print('🟢 SignUp completed - waiting for email verification');

      state = state.copyWith(
        isLoading: false,
      );

      print('🟢 Returning true from signUp()');
      return true;
    } on AuthException catch (e) {
      print('🔴 Auth Exception: ${e.message}');
      print('🔴 Auth Exception statusCode: ${e.statusCode}');

      String errorMessage = 'Đăng ký thất bại';

      // Check for user already exists error
      final message = e.message.toLowerCase();
      if (message.contains('already') ||
          message.contains('exists') ||
          e.statusCode == '400') {
        errorMessage =
            '⚠️ Email này đã được đăng ký!\n\nVui lòng:\n• Đăng nhập nếu bạn đã có tài khoản\n• Sử dụng email khác để đăng ký\n• Nhấn "Quên mật khẩu?" nếu bạn quên mật khẩu';
      } else if (message.contains('password')) {
        errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      } else if (message.contains('email') || message.contains('invalid')) {
        errorMessage = 'Email không đúng định dạng';
      } else {
        errorMessage = 'Đăng ký thất bại: ${e.message}';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      print('🔴 General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi hệ thống: $e',
      );
      return false;
    }
  }

  /// Quick role switch for demo mode
  Future<void> switchRole(app_user.UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final demoUser = app_user.DemoUsers.findByRole(role);
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

  /// Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      print('🔵 Resending verification email to: $email');

      await _supabaseClient.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      print('✅ Verification email resent successfully');
    } on AuthException catch (e) {
      print('🔴 Failed to resend email: ${e.message}');
      throw Exception('Không thể gửi lại email: ${e.message}');
    } catch (e) {
      print('🔴 Error resending email: $e');
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  /// Reset password - send reset email
  Future<void> resetPassword(String email) async {
    try {
      print('🔵 Sending password reset email to: $email');

      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'sabohub://reset-password', // Deep link for mobile app
      );

      print('✅ Password reset email sent successfully');
    } on AuthException catch (e) {
      print('🔴 Failed to send reset email: ${e.message}');
      throw Exception('Không thể gửi email đặt lại mật khẩu: ${e.message}');
    } catch (e) {
      print('🔴 Error sending reset email: $e');
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 Starting logout process...');

      // 1. Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStorageKey);
      await prefs.remove(_demoModeKey);

      print('🔵 Local storage cleared');

      // 2. Clear remember me credentials for security
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);

      print('🔵 Remember me credentials cleared');

      // 3. Sign out from Supabase (CRITICAL!)
      try {
        await _supabaseClient.auth.signOut();
        print('🟢 Supabase session signed out');
      } catch (e) {
        // Don't fail logout if Supabase signOut fails
        // (user might be in demo mode or offline)
        print('⚠️ Supabase signOut warning: $e');
      }

      print('🟢 Logout completed successfully');

      // Phase 3.1: Clear session timer on logout
      _lastActivityTime = null;

      state = const AuthState();
    } catch (e) {
      print('🔴 Logout error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: $e',
      );
    }
  }

  /// Phase 3.1: Reset session activity timer
  void _resetSessionTimer() {
    _lastActivityTime = DateTime.now();
    print('🔵 Session timer reset at: $_lastActivityTime');
  }

  /// Phase 3.1: Start periodic session timeout checker
  void _startSessionTimeoutChecker() {
    // Check every minute
    Future.delayed(const Duration(minutes: 1), () {
      _checkSessionTimeout();
      _startSessionTimeoutChecker(); // Recursive call for continuous checking
    });
  }

  /// Phase 3.1: Check if session has timed out
  Future<void> _checkSessionTimeout() async {
    if (!_sessionTimeoutEnabled ||
        _lastActivityTime == null ||
        !state.isAuthenticated) {
      return; // Skip if timeout disabled, no activity yet, or not logged in
    }

    final now = DateTime.now();
    final timeSinceActivity = now.difference(_lastActivityTime!);

    if (timeSinceActivity >= _sessionTimeout) {
      print('⏰ Session timeout! Last activity: $_lastActivityTime');
      print('⏰ Time since activity: ${timeSinceActivity.inMinutes} minutes');

      // Auto-logout due to inactivity
      await logout();

      // Clear the timeout flag so we don't repeatedly logout
      _lastActivityTime = null;

      print('🔴 User logged out due to session timeout');
    }
  }

  /// Phase 3.1: Call this method on any user interaction to reset timeout
  void recordActivity() {
    _resetSessionTimer();
  }

  /// Save user to storage
  Future<void> _saveUser(app_user.User user, {bool isDemoMode = false}) async {
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
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Current user provider
final currentUserProvider = Provider<app_user.User?>((ref) {
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
final userRoleProvider = Provider<app_user.UserRole?>((ref) {
  return ref.watch(authProvider).user?.role;
});

/// Role checker provider
final hasRoleProvider =
    Provider.family<bool, app_user.UserRole>((ref, requiredRole) {
  final user = ref.watch(currentUserProvider);
  return user?.hasRole(requiredRole) ?? false;
});

/// Multiple roles checker provider
final hasAnyRoleProvider =
    Provider.family<bool, List<app_user.UserRole>>((ref, requiredRoles) {
  final user = ref.watch(currentUserProvider);
  return user?.hasAnyRole(requiredRoles) ?? false;
});
