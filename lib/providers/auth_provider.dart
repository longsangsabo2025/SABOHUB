import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';

import '../models/user.dart' as app_user;
import '../models/business_type.dart';
import '../services/account_storage_service.dart';
import '../constants/roles.dart';
import '../utils/app_logger.dart';

// Get the Supabase client instance
final _supabaseClient = Supabase.instance.client;

/// Authentication state
class AuthState {
  final app_user.User? user;
  final bool isLoading;
  final bool isDemoMode;
  final String? error;
  final bool isInitialized; // Track if auth has completed initial load

  const AuthState({
    this.user,
    this.isLoading = true, // Default to true - auth starts in loading state
    this.isDemoMode = false,
    this.error,
    this.isInitialized = false, // Default to false - not yet initialized
  });

  AuthState copyWith({
    app_user.User? user,
    bool? isLoading,
    bool? isDemoMode,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
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
  final bool _sessionTimeoutEnabled = true;
  bool _isDisposed = false;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  AuthState build() {
    // Cancel previous subscription if build is called again
    _authSubscription?.cancel();
    _isDisposed = false;

    // Clean up on dispose
    ref.onDispose(() {
      _isDisposed = true;
      _authSubscription?.cancel();
    });

    // Set up auth state listener (but don't block build)
    Future.microtask(() {
      _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
        if (_isDisposed) return;
        final event = data.event;

        switch (event) {
          case AuthChangeEvent.signedIn:
            // Session restored automatically
            _resetSessionTimer(); // Phase 3.1: Reset timer on sign in
            break;
          case AuthChangeEvent.signedOut:
            _handleSignOut();
            break;
          case AuthChangeEvent.tokenRefreshed:
            _resetSessionTimer(); // Phase 3.1: Reset timer on token refresh
            break;
          case AuthChangeEvent.userUpdated:
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

    // ✅ FIX: Return loading state initially to prevent race condition
    // Router will wait for session restore before redirecting
    return const AuthState(isLoading: true);
  }

  /// Handle sign out from server or token expiration
  Future<void> _handleSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      state = const AuthState();
    } catch (e) {
      // Ignore errors during sign out cleanup
    }
  }

  /// Restore session from Supabase or local storage
  Future<void> _restoreSession() async {
    // Don't modify state during build - wait for next frame
    await Future.delayed(Duration.zero);

    state = state.copyWith(isLoading: true);

    try {
      // 1. Check Supabase session first (takes priority)
      final session = _supabaseClient.auth.currentSession;

      if (session != null) {
        // Check if email is verified
        if (session.user.emailConfirmedAt == null) {
          await _supabaseClient.auth.signOut();
          state = state.copyWith(isLoading: false);
          return;
        }

        try {
          // 2. Fetch user profile from employees table WITH company data for businessType
          final employeeResponse = await _supabaseClient
              .from('employees')
              .select(
                  'id, full_name, email, role, department, phone, avatar_url, branch_id, company_id, warehouse_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at, companies(name, business_type)')
              .eq('auth_user_id', session.user.id)
              .maybeSingle();

          Map<String, dynamic>? response;
          if (employeeResponse != null) {
            response = {
              ...employeeResponse,
              'id': employeeResponse['id'], // Use employee UUID (exists in employees table)
              'auth_user_id': session.user.id, // Keep auth id for reference
            };
          }

          if (response != null) {
            // Use User.fromJson to properly parse company data and businessType
            final user = app_user.User.fromJson(response);

            // Save user in background, don't wait
            _saveUser(user, isDemoMode: false).catchError((e) {
              // Ignore save errors
            });

            // Reset session timer
            _resetSessionTimer();

            // Single state update with all data
            state = state.copyWith(
              user: user,
              isDemoMode: false,
              isLoading: false,
              isInitialized: true,
            );

            return;
          } else {
            await _supabaseClient.auth.signOut();
          }
        } catch (e) {
          await _supabaseClient.auth.signOut();
        }
      }

      // 3. Fallback to stored user from local storage (Employee login or Demo mode)
      final prefs = await SharedPreferences.getInstance();
      final demoMode = prefs.getBool(_demoModeKey) ?? false;
      final storedUserJson = prefs.getString(_authStorageKey);

      if (storedUserJson != null) {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        final user = app_user.User.fromJson(userMap);

        // Restore user from local storage (works for Employee login too!)
        state = state.copyWith(
          user: user,
          isDemoMode: demoMode,
          isLoading: false,
          isInitialized: true,
        );
        return;
      }

      // No session found
      state = state.copyWith(isLoading: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialized: true);
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
        return;
      }

      // Fetch fresh data from employees table
      final employeeResponse = await _supabaseClient
          .from('employees')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, warehouse_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      Map<String, dynamic>? response;
      if (employeeResponse != null) {
        response = {
          ...employeeResponse,
          'id': employeeResponse['id'], // Use employee UUID
          'auth_user_id': currentUser.id,
        };
      }

      if (response == null) {
        return;
      }

      // Convert to User object
      final updatedUser = app_user.User.fromJson(response);

      // Save to local storage
      await _saveUser(updatedUser);

      // Update state
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      // Ignore errors during user reload
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    // Only set loading once at the start
    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.auth('🔵 [AUTH] Login attempt for: $email');
      
      // 1. Check demo users (ONLY in debug mode)
      if (kDebugMode) {
        final demoUser = app_user.DemoUsers.findByEmail(email);
        if (demoUser != null && password == 'demo') {
          AppLogger.auth('✅ [AUTH] Demo user login successful (debug only)');
          await _saveUser(demoUser, isDemoMode: true);

          // Single state update with all data
          state = state.copyWith(
            user: demoUser,
            isDemoMode: true,
            isLoading: false,
          );

          return true;
        }
      }

      AppLogger.auth('🔄 [AUTH] Attempting Supabase authentication...');
      
      // 2. Real Supabase authentication
      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      AppLogger.auth('📊 [AUTH] Auth response received');

      if (authResponse.user == null) {
        AppLogger.error('❌ [AUTH] No user in response');
        state = state.copyWith(
          isLoading: false,
          error: 'Đăng nhập thất bại',
        );
        return false;
      }

      AppLogger.auth('✅ [AUTH] User authenticated: ${authResponse.user!.id}');

      // 3. Check if email is verified
      if (authResponse.user!.emailConfirmedAt == null) {
        AppLogger.warn('⚠️ [AUTH] Email not verified');
        state = state.copyWith(
          isLoading: false,
          error:
              '⚠️ Email chưa được xác thực!\n\nVui lòng kiểm tra email và nhấn vào link xác thực.\nSau đó thử đăng nhập lại.',
        );
        return false;
      }

      AppLogger.auth('🔄 [AUTH] Fetching user profile...');

      // 4. Fetch user profile from employees table
      final employeeResponse = await _supabaseClient
          .from('employees')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, warehouse_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
          .eq('auth_user_id', authResponse.user!.id)
          .maybeSingle();

      Map<String, dynamic>? response;
      if (employeeResponse != null) {
        response = {
          ...employeeResponse,
          'id': employeeResponse['id'], // Use employee UUID (exists in employees table)
          'auth_user_id': authResponse.user!.id, // Keep auth id for reference
        };
      }

      AppLogger.auth('📊 [AUTH] Profile response: ${response != null ? "found" : "not found"}');

      if (response == null) {
        AppLogger.error('❌ [AUTH] User profile not found in database');
        state = state.copyWith(
          isLoading: false,
          error:
              'Không tìm thấy thông tin người dùng. Vui lòng liên hệ hỗ trợ.',
        );
        return false;
      }

      AppLogger.auth('✅ [AUTH] User profile loaded: ${response['full_name']}');

      // 5. Fetch company info if user has company_id
      String? companyName;
      BusinessType? businessType;
      final companyId = response['company_id'] as String?;
      
      if (companyId != null) {
        AppLogger.auth('🔄 [AUTH] Fetching company info for: $companyId');
        final companyResponse = await _supabaseClient
            .from('companies')
            .select('name, business_type')
            .eq('id', companyId)
            .maybeSingle();
        
        if (companyResponse != null) {
          companyName = companyResponse['name'] as String?;
          final businessTypeStr = companyResponse['business_type'] as String?;
          if (businessTypeStr != null) {
            // Parse business_type string to enum
            try {
              businessType = BusinessType.values.firstWhere(
                (e) => e.name == businessTypeStr,
                orElse: () => BusinessType.distribution,
              );
            } catch (e) {
              AppLogger.warn('⚠️ [AUTH] Unknown business type: $businessTypeStr');
              businessType = BusinessType.distribution;
            }
          }
          AppLogger.auth('✅ [AUTH] Company: $companyName, BusinessType: $businessType');
        }
      }

      // 6. Create User object from database with company info
      final user = app_user.User(
        id: response['id'] as String,
        name: response['full_name'] as String,
        email: response['email'] as String,
        role: SaboRole.fromString(response['role'] as String),
        phone: response['phone'] as String? ?? '',
        companyId: companyId,
        companyName: companyName,
        businessType: businessType,
      );
      
      AppLogger.auth('✅ [AUTH] User created - Role: ${user.role}, BusinessType: ${user.businessType}');

      // 7. Batch all save operations (don't await each one)
      final saveOperations = Future.wait([
        _saveUser(user, isDemoMode: false),
        AccountStorageService.saveAccount(user),
      ]);

      // Reset session timer
      _resetSessionTimer();

      // 8. Update state ONCE with final result (don't wait for save to complete)
      state = state.copyWith(
        user: user,
        isDemoMode: false,
        isLoading: false,
      );

      // Let save operations complete in background
      saveOperations.catchError((e) {
        // Ignore save errors, user is already logged in
        return <void>[];
      });

      return true;
    } on AuthException catch (e) {
      AppLogger.error('❌ [AUTH] AuthException: ${e.message}', e);
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
    } catch (e, stackTrace) {
      AppLogger.error('💥 [AUTH] Unexpected login error', e, stackTrace);
      
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi kết nối: ${e.toString()}\n\nVui lòng kiểm tra kết nối internet và thử lại.',
      );
      return false;
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

    try {
      final authResponse = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name.toUpperCase(),
          'phone': phone ?? '',
        },
      );

      if (authResponse.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể tạo tài khoản. Vui lòng thử lại.',
        );
        return false;
      }

      // 2. Create user profile in database (will be handled by trigger)
      // The database trigger should automatically create user profile

      // 3. DON'T save user to state yet - wait for email verification
      // User needs to verify email before they can login

      state = state.copyWith(
        isLoading: false,
      );

      return true;
    } on AuthException catch (e) {
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
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi hệ thống: $e',
      );
      return false;
    }
  }

  /// Quick role switch for demo mode (debug only)
  Future<void> switchRole(app_user.UserRole role) async {
    if (!kDebugMode) return; // Disabled in production
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
      await _supabaseClient.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw Exception('Không thể gửi lại email: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generate random nonce for security
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      // Sign in to Supabase with Apple token
      final authResponse = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      if (authResponse.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Đăng nhập Apple thất bại',
        );
        return false;
      }

      // Check if user exists in employees table
      final employeeResponse = await _supabaseClient
          .from('employees')
          .select()
          .eq('auth_user_id', authResponse.user!.id)
          .maybeSingle();

      Map<String, dynamic>? response;
      if (employeeResponse != null) {
        response = {
          ...employeeResponse,
          'id': employeeResponse['id'], // Use employee UUID
          'auth_user_id': authResponse.user!.id,
        };
      }

      app_user.User user;
      if (response == null) {
        // New user - create profile in database
        final newUser = {
          'id': authResponse.user!.id,
          'email': authResponse.user!.email ?? credential.email,
          'full_name': credential.givenName != null && credential.familyName != null
              ? '${credential.givenName} ${credential.familyName}'
              : authResponse.user!.userMetadata?['full_name'] ?? 'Apple User',
          'role': 'STAFF', // Default role
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final insertResponse = await _supabaseClient
            .from('employees')
            .insert({
              ...newUser,
              'auth_user_id': authResponse.user!.id,
            })
            .select()
            .single();

        user = app_user.User.fromJson(insertResponse);
      } else {
        // Existing user
        user = app_user.User.fromJson(response);
      }

      // Check if user is active
      if (user.isActive == false) {
        await _supabaseClient.auth.signOut();
        state = state.copyWith(
          isLoading: false,
          error: 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.',
        );
        return false;
      }

      // Save user and update state
      await _saveUser(user);
      _resetSessionTimer();

      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      String errorMessage;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          errorMessage = 'Đăng nhập bị hủy';
          break;
        case AuthorizationErrorCode.failed:
          errorMessage = 'Đăng nhập thất bại';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Phản hồi không hợp lệ từ Apple';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'Yêu cầu không được xử lý';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage = 'Lỗi không xác định';
          break;
        default:
          errorMessage = 'Đăng nhập Apple thất bại: ${e.code}';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đăng nhập Apple thất bại: ${e.message}',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi hệ thống: $e',
      );
      return false;
    }
  }

  /// Generate secure random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Reset password - send reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'sabohub://reset-password', // Deep link for mobile app
      );
    } on AuthException catch (e) {
      throw Exception('Không thể gửi email đặt lại mật khẩu: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStorageKey);
      await prefs.remove(_demoModeKey);

      // 2. Clear remember me credentials for security
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);

      // 3. Sign out from Supabase (CRITICAL!)
      try {
        await _supabaseClient.auth.signOut();
      } catch (e) {
        // Don't fail logout if Supabase signOut fails
        // (user might be in demo mode or offline)
      }

      // Phase 3.1: Clear session timer on logout
      _lastActivityTime = null;

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: $e',
      );
    }
  }

  /// Phase 3.1: Reset session activity timer
  void _resetSessionTimer() {
    _lastActivityTime = DateTime.now();
  }

  /// Phase 3.1: Start periodic session timeout checker
  void _startSessionTimeoutChecker() {
    // Check every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (_isDisposed) return; // Guard: stop recursive checking on dispose
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
      // Auto-logout due to inactivity
      await logout();

      // Clear the timeout flag so we don't repeatedly logout
      _lastActivityTime = null;
    }
  }

  /// Phase 3.1: Call this method on any user interaction to reset timeout
  void recordActivity() {
    _resetSessionTimer();
  }

  /// Login with custom User object (for employee login)
  Future<void> loginWithUser(app_user.User user) async {
    AppLogger.box('🔐 AUTH PROVIDER: loginWithUser', {
      'userId': user.id,
      'userName': user.name,
      'userRole': user.role.toString(),
      'businessType': user.businessType?.toString() ?? 'null',
      'companyName': user.companyName ?? 'null',
    });

    try {
      AppLogger.auth('💾 Saving user to SharedPreferences...');
      await _saveUser(user);
      AppLogger.success('✅ User saved!');

      AppLogger.state('🔄 Updating AuthState...');
      state = AuthState(user: user, isLoading: false);
      AppLogger.success('✅ AuthState updated!', {
        'isAuthenticated': state.isAuthenticated,
        'user': state.user?.name,
      });
    } catch (e, stackTrace) {
      AppLogger.error('💥 Error in loginWithUser', e, stackTrace);
      rethrow;
    }
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

      final client = Supabase.instance.client;
      final result = await client.rpc('change_employee_password', params: {
        'p_employee_id': state.user!.id,
        'p_new_password': newPassword,
      });
      if (result is Map && result['success'] != true) {
        throw Exception(result['error'] ?? 'Không thể đổi mật khẩu');
      }
      state = state.copyWith(isLoading: false);
      return true;
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
