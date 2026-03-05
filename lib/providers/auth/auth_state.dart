import '../../models/user.dart' as app_user;

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
