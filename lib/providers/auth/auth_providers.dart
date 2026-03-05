import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart' as app_user;
import 'auth_state.dart';
import 'auth_notifier.dart';

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
