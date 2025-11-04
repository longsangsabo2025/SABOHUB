import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart' as user_model;
import '../../pages/auth/email_verification_page.dart';
import '../../pages/auth/employee_signup_page.dart';
import '../../pages/auth/forgot_password_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/signup_page_new.dart';
import '../../pages/company/company_settings_page.dart';
import '../../pages/employees/create_employee_page.dart';
import '../../pages/employees/create_invitation_page.dart';
import '../../pages/employees/employee_list_page.dart';
import '../../pages/onboarding/onboarding_page.dart';
import '../../pages/role_based_dashboard.dart';
import '../../pages/staff/staff_checkin_page.dart';
import '../../pages/staff/staff_messages_page.dart';
import '../../pages/staff/staff_profile_page.dart';
import '../../pages/staff/staff_tables_page.dart';
import '../../pages/staff/staff_tasks_page.dart';
import '../../pages/user/user_profile_page.dart';
import '../../layouts/manager_main_layout.dart';
import '../../layouts/shift_leader_main_layout.dart';
import '../../pages/ceo/ceo_main_layout.dart';
import '../../providers/auth_provider.dart';
import '../navigation/navigation_models.dart' as nav;

/// Route names for type-safe navigation
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboard/:token'; // Employee onboarding
  static const String profile = '/profile';

  // Staff routes
  static const String staffCheckin = '/staff/checkin';
  static const String staffTables = '/staff/tables';
  static const String staffTasks = '/staff/tasks';
  static const String staffMessages = '/staff/messages';
  static const String staffProfile = '/staff/profile';

  // Shift Leader routes
  static const String shiftLeaderTeam = '/shift-leader/team';
  static const String shiftLeaderReports = '/shift-leader/reports';

  // Manager routes
  static const String managerDashboard = '/manager/dashboard';
  static const String managerEmployees = '/manager/employees';
  static const String managerFinance = '/manager/finance';

  // CEO routes
  static const String ceoAnalytics = '/ceo/analytics';
  static const String ceoCompanies = '/ceo/companies';
  static const String ceoSettings = '/ceo/settings';

  // Company routes
  static const String companySettings = '/company/settings';
  static const String createEmployee = '/employees/create';
  static const String createInvitation = '/employees/invite';
  static const String employeeList = '/employees/list';
  static const String joinInvitation = '/join/:code';

  // Commission routes (NEW!)
  static const String myCommission = '/commission/my-commission';
  static const String billsManagement = '/commission/bills';
  static const String commissionRules = '/commission/rules';
  static const String uploadBill = '/commission/upload-bill';

  // Debug routes (temporarily disabled)
  // static const String debugSettings = '/debug/settings';
}

/// Current user role provider (based on auth state)
final currentUserRoleProvider = Provider<nav.UserRole>((ref) {
  // Watch authProvider to reactively update when auth state changes
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated && authState.user?.role != null) {
    // Map from User model UserRole to Navigation UserRole
    switch (authState.user!.role) {
      case user_model.UserRole.ceo:
        return nav.UserRole.ceo;
      case user_model.UserRole.manager:
        return nav.UserRole.manager;
      case user_model.UserRole.shiftLeader:
        return nav.UserRole.shiftLeader;
      case user_model.UserRole.staff:
        return nav.UserRole.staff;
    }
  }

  return nav.UserRole.staff; // Default fallback
});

/// Route guard that checks user permissions
class RouteGuard {
  static String? checkAccess(nav.UserRole userRole, String route) {
    // Get allowed routes for the current user role
    final allowedItems = nav.NavigationConfig.getItemsForRole(userRole);
    final allowedRoutes = allowedItems.map((item) => item.route).toList();

    // Add routes that are always accessible
    allowedRoutes.add(AppRoutes.home);
    allowedRoutes.add(AppRoutes.profile);

    // Check if route is allowed
    if (!allowedRoutes.contains(route)) {
      // Redirect to appropriate dashboard based on role
      switch (userRole) {
        case nav.UserRole.staff:
          return AppRoutes.staffCheckin;
        case nav.UserRole.shiftLeader:
          return AppRoutes.shiftLeaderTeam;
        case nav.UserRole.manager:
          return AppRoutes.managerDashboard;
        case nav.UserRole.ceo:
          return AppRoutes.ceoAnalytics;
      }
    }

    return null; // Access granted
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final userRole = ref.watch(currentUserRoleProvider);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Email verification is accessible for both logged in and logged out users
      // Check if path starts with email verification (to handle query parameters)
      final isEmailVerification =
          state.matchedLocation.startsWith(AppRoutes.emailVerification) ||
              state.uri.path == AppRoutes.emailVerification;

      // Onboarding is public - no auth required
      final isOnboarding = state.uri.path.startsWith('/onboard/');

      // If not logged in and not on auth/public pages, redirect to login
      if (!isLoggedIn &&
          !isAuthRoute &&
          !isEmailVerification &&
          !isOnboarding) {
        return AppRoutes.login;
      }

      // If logged in and on auth pages (but not email verification), redirect to home
      if (isLoggedIn && isAuthRoute && !isEmailVerification) {
        return AppRoutes.home;
      }

      // Check role-based access for authenticated users (skip email verification and onboarding)
      if (isLoggedIn && !isEmailVerification && !isOnboarding) {
        return RouteGuard.checkAccess(userRole, state.matchedLocation);
      }

      return null;
    },
    routes: [
      // Login route
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // Signup route
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpPageNew(),
      ),

      // Email Verification route
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationPage(email: email);
        },
      ),

      // Forgot Password route
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Employee Onboarding route (public - no auth required)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return OnboardingPage(inviteToken: token);
        },
      ),

      // Home route
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          return RoleBasedDashboard(roleParam: roleParam);
        },
      ),

      // Profile route - accessible by all roles
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const UserProfilePage(),
      ),

      // Staff routes
      GoRoute(
        path: AppRoutes.staffCheckin,
        builder: (context, state) => const StaffCheckinPage(),
      ),
      GoRoute(
        path: AppRoutes.staffTables,
        builder: (context, state) => const StaffTablesPage(),
      ),
      GoRoute(
        path: AppRoutes.staffTasks,
        builder: (context, state) => const StaffTasksPage(),
      ),
      GoRoute(
        path: AppRoutes.staffMessages,
        builder: (context, state) => const StaffMessagesPage(),
      ),
      GoRoute(
        path: AppRoutes.staffProfile,
        builder: (context, state) => const StaffProfilePage(),
      ),

      // Shift Leader routes
      GoRoute(
        path: AppRoutes.shiftLeaderTeam,
        builder: (context, state) => const ShiftLeaderMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.shiftLeaderReports,
        builder: (context, state) => const ShiftLeaderMainLayout(),
      ),

      // Manager routes
      GoRoute(
        path: AppRoutes.managerDashboard,
        builder: (context, state) => const ManagerMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.managerEmployees,
        builder: (context, state) => const ManagerMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.managerFinance,
        builder: (context, state) => const ManagerMainLayout(),
      ),

      // CEO routes
      GoRoute(
        path: AppRoutes.ceoAnalytics,
        builder: (context, state) => CEOMainLayout(key: ceoMainLayoutKey),
      ),
      GoRoute(
        path: AppRoutes.ceoCompanies,
        builder: (context, state) => CEOMainLayout(key: ceoMainLayoutKey),
      ),
      GoRoute(
        path: AppRoutes.ceoSettings,
        builder: (context, state) => CEOMainLayout(key: ceoMainLayoutKey),
      ),

      // Company routes
      GoRoute(
        path: AppRoutes.companySettings,
        builder: (context, state) => const CompanySettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.createEmployee,
        builder: (context, state) => const CreateEmployeePage(),
      ),
      GoRoute(
        path: AppRoutes.createInvitation,
        builder: (context, state) => const CreateInvitationPage(),
      ),
      GoRoute(
        path: AppRoutes.employeeList,
        builder: (context, state) => const EmployeeListPage(),
      ),
      GoRoute(
        path: AppRoutes.joinInvitation,
        builder: (context, state) {
          final code = state.pathParameters['code'];
          if (code == null) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid invitation link'),
              ),
            );
          }
          return EmployeeSignupPage(invitationCode: code);
        },
      ),

      // Debug routes (temporarily disabled)
      // if (kDebugMode)
      //   GoRoute(
      //     path: AppRoutes.debugSettings,
      //     builder: (context, state) => const DebugSettingsPage(),
      //   ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Route not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Navigation helper extensions
extension AppNavigationExtension on BuildContext {
  /// Navigate to route with type safety
  void goToRoute(String route) {
    go(route);
  }

  /// Push route with type safety
  void pushRoute(String route) {
    push(route);
  }

  /// Pop current route
  void popRoute() {
    pop();
  }
}
