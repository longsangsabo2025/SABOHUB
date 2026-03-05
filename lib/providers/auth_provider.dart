/// Authentication module - barrel export
/// Split into modular files for maintainability
/// 
/// - [AuthState] - Authentication state model
/// - [AuthNotifier] - Authentication business logic
/// - Derived providers (authProvider, currentUserProvider, etc.)
library;

export 'auth/auth_state.dart';
export 'auth/auth_notifier.dart';
export 'auth/auth_providers.dart';
