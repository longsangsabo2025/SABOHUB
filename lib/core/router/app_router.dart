import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart' as user_model;
import '../../pages/auth/dual_login_page.dart';
import '../../pages/auth/email_verification_page.dart';
import '../../pages/auth/employee_signup_page.dart';
import '../../pages/auth/forgot_password_page.dart';
import '../../pages/auth/signup_page_new.dart';
import '../../pages/employees/create_employee_page.dart';
import '../../pages/company/company_settings_page.dart';
import '../../pages/employees/create_invitation_page.dart';
import '../../pages/employees/employee_list_page.dart';
import '../../pages/onboarding/onboarding_page.dart';
import '../../pages/role_based_dashboard.dart';
import '../../pages/staff/staff_profile_page.dart';
import '../../pages/user/user_profile_page.dart';
import '../../layouts/manager_main_layout.dart';
import '../../layouts/shift_leader_main_layout.dart';
import '../../layouts/driver_main_layout.dart';
import '../../layouts/warehouse_main_layout.dart';
import '../../layouts/distribution_warehouse_layout.dart';
import '../../pages/driver/distribution_driver_layout_refactored.dart';
import '../../layouts/distribution_finance_layout.dart';
import '../../layouts/distribution_customer_service_layout.dart';
import '../../pages/staff_main_layout.dart';
import '../../pages/ceo/ceo_main_layout.dart';
import '../../pages/manager/manager_reports_page.dart';
// Odori B2B Module Pages
import '../../pages/customers/odori_customers_page.dart';
import '../../pages/products/odori_products_page.dart';
import '../../pages/orders/odori_orders_page.dart';
import '../../pages/deliveries/odori_deliveries_page.dart';
import '../../pages/receivables/odori_receivables_page.dart';
// Warehouse & Driver Pages - Now using layouts
import '../../pages/delivery/route_planning_page.dart';
// Manufacturing Module Pages
import '../../pages/manufacturing/suppliers_page.dart';
import '../../pages/manufacturing/materials_page.dart';
import '../../pages/manufacturing/bom_page.dart';
import '../../pages/manufacturing/purchase_orders_page.dart';
import '../../pages/manufacturing/production_orders_page.dart';
import '../../pages/manufacturing/payables_page.dart';
// Map & GPS Module Pages - TEMPORARILY DISABLED for web compatibility
// import '../../pages/map/map_overview_page.dart';
// import '../../pages/map/delivery_tracking_page.dart';
// import '../../pages/map/staff_tracking_page.dart';
// import '../../pages/map/route_planning_page.dart';
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

  // Super Admin routes
  static const String superAdminDashboard = '/super-admin/dashboard';

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
  static const String managerReports = '/manager-reports';

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

  // Odori B2B Module routes
  static const String odoriCustomers = '/odori/customers';
  static const String odoriProducts = '/odori/products';
  static const String odoriOrders = '/odori/orders';
  static const String odoriDeliveries = '/odori/deliveries';
  static const String odoriReceivables = '/odori/receivables';
  
  // Direct role layout routes for manager navigation
  static const String warehouse = '/warehouse';
  static const String driver = '/driver';
  static const String finance = '/finance';
  static const String support = '/support';
  
  // Warehouse & Driver routes
  static const String warehousePicking = '/warehouse/picking';
  static const String routePlanning = '/delivery/route-planning';
  static const String driverDashboard = '/driver/dashboard';

  // Manufacturing Module routes
  static const String manufacturingSuppliers = '/manufacturing/suppliers';
  static const String manufacturingMaterials = '/manufacturing/materials';
  static const String manufacturingBOM = '/manufacturing/bom';
  static const String manufacturingPurchaseOrders = '/manufacturing/purchase-orders';
  static const String manufacturingProductionOrders = '/manufacturing/production-orders';
  static const String manufacturingPayables = '/manufacturing/payables';

  // Map & GPS Module routes
  static const String mapOverview = '/map/overview';
  static const String mapDeliveryTracking = '/map/delivery-tracking';
  static const String mapStaffTracking = '/map/staff-tracking';
  static const String mapRoutePlanning = '/map/route-planning';

  // Debug routes (temporarily disabled)
  // static const String debugSettings = '/debug/settings';
}

/// Current user role provider (based on auth state)
final currentUserRoleProvider = Provider<nav.UserRole>((Ref ref) {
  // Watch authProvider to reactively update when auth state changes
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated && authState.user?.role != null) {
    // Map from User model UserRole to Navigation UserRole
    switch (authState.user!.role) {
      case user_model.UserRole.superAdmin:
        return nav.UserRole.superAdmin;
      case user_model.UserRole.ceo:
        return nav.UserRole.ceo;
      case user_model.UserRole.manager:
        return nav.UserRole.manager;
      case user_model.UserRole.shiftLeader:
        return nav.UserRole.shiftLeader;
      case user_model.UserRole.staff:
        return nav.UserRole.staff;
      case user_model.UserRole.driver:
        return nav.UserRole.driver;
      case user_model.UserRole.warehouse:
        return nav.UserRole.warehouse;
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
        case nav.UserRole.superAdmin:
          return AppRoutes.superAdminDashboard;
        case nav.UserRole.staff:
          return AppRoutes.staffCheckin;
        case nav.UserRole.shiftLeader:
          return AppRoutes.shiftLeaderTeam;
        case nav.UserRole.manager:
          return AppRoutes.managerDashboard;
        case nav.UserRole.ceo:
          return AppRoutes.ceoAnalytics;
        case nav.UserRole.driver:
          return AppRoutes.driverDashboard;
        case nav.UserRole.warehouse:
          return AppRoutes.warehousePicking;
      }
    }

    return null; // Access granted
  }
}

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final userRole = ref.watch(currentUserRoleProvider);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // 🔍 DEBUG LOG - Remove after fixing
      print('🚀 [ROUTER] ==================');
      print('🚀 [ROUTER] matchedLocation: ${state.matchedLocation}');
      print('🚀 [ROUTER] isLoggedIn: $isLoggedIn');
      print('🚀 [ROUTER] isLoading: $isLoading');
      print('🚀 [ROUTER] userRole: $userRole');
      print('🚀 [ROUTER] user: ${authState.user?.name} (${authState.user?.role})');
      print('🚀 [ROUTER] isAuthRoute: $isAuthRoute');

      // ✅ FIX: Wait for session restore to complete before redirecting
      // This prevents the race condition where user sees login page briefly
      if (isLoading) {
        print('🚀 [ROUTER] --> WAITING (isLoading)');
        return null; // Stay on current route while loading
      }

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
        print('🚀 [ROUTER] --> REDIRECT TO LOGIN (not logged in)');
        return AppRoutes.login;
      }

      // If logged in and on auth pages (but not email verification), redirect to home
      if (isLoggedIn && isAuthRoute && !isEmailVerification) {
        print('🚀 [ROUTER] --> REDIRECT TO HOME (logged in on auth page)');
        return AppRoutes.home;
      }

      // Check role-based access for authenticated users (skip email verification and onboarding)
      if (isLoggedIn && !isEmailVerification && !isOnboarding) {
        final redirectRoute = RouteGuard.checkAccess(userRole, state.matchedLocation);
        print('🚀 [ROUTER] --> RouteGuard.checkAccess returned: $redirectRoute');
        return redirectRoute;
      }

      print('🚀 [ROUTER] --> NO REDIRECT (null)');
      return null;
    },
    routes: [
      // Login route - Dual authentication (CEO email/password OR Employee company/username/password)
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) => const DualLoginPage(),
      ),

      // Signup route
      GoRoute(
        path: AppRoutes.signup,
        builder: (BuildContext context, GoRouterState state) => const SignUpPageNew(),
      ),

      // Email Verification route
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (BuildContext context, GoRouterState state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationPage(email: email);
        },
      ),

      // Forgot Password route
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordPage(),
      ),

      // Employee Onboarding route (public - no auth required)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          final token = state.pathParameters['token'] ?? '';
          return OnboardingPage(inviteToken: token);
        },
      ),

      // Home route
      GoRoute(
        path: AppRoutes.home,
        builder: (BuildContext context, GoRouterState state) {
          final roleParam = state.uri.queryParameters['role'];
          return RoleBasedDashboard(roleParam: roleParam);
        },
      ),

      // Profile route - accessible by all roles
      GoRoute(
        path: AppRoutes.profile,
        builder: (BuildContext context, GoRouterState state) => const UserProfilePage(),
      ),

      // Staff routes - Use full layout for proper navigation
      GoRoute(
        path: AppRoutes.staffCheckin,
        builder: (BuildContext context, GoRouterState state) => const StaffMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.staffTables,
        builder: (BuildContext context, GoRouterState state) => const StaffMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.staffTasks,
        builder: (BuildContext context, GoRouterState state) => const StaffMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.staffMessages,
        builder: (BuildContext context, GoRouterState state) => const StaffMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.staffProfile,
        builder: (BuildContext context, GoRouterState state) => const StaffProfilePage(),
      ),

      // Shift Leader routes
      GoRoute(
        path: AppRoutes.shiftLeaderTeam,
        builder: (BuildContext context, GoRouterState state) => const ShiftLeaderMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.shiftLeaderReports,
        builder: (BuildContext context, GoRouterState state) => const ShiftLeaderMainLayout(),
      ),

      // Manager routes
      GoRoute(
        path: AppRoutes.managerDashboard,
        builder: (BuildContext context, GoRouterState state) => const ManagerMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.managerEmployees,
        builder: (BuildContext context, GoRouterState state) => const ManagerMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.managerFinance,
        builder: (BuildContext context, GoRouterState state) => const ManagerMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.managerReports,
        builder: (BuildContext context, GoRouterState state) => const ManagerReportsPage(),
      ),

      // CEO routes - Remove GlobalKey to fix navigation conflicts
      GoRoute(
        path: AppRoutes.ceoAnalytics,
        builder: (BuildContext context, GoRouterState state) => const CEOMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.ceoCompanies,
        builder: (BuildContext context, GoRouterState state) => const CEOMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.ceoSettings,
        builder: (BuildContext context, GoRouterState state) => const CEOMainLayout(),
      ),

      // Company routes
      GoRoute(
        path: AppRoutes.companySettings,
        builder: (BuildContext context, GoRouterState state) => const CompanySettingsPage(),
      ),
      // CEO Create Employee route - CLEAN, simple, standalone page
      GoRoute(
        path: AppRoutes.createEmployee,
        builder: (BuildContext context, GoRouterState state) => const CreateEmployeePage(),
      ),
      GoRoute(
        path: AppRoutes.createInvitation,
        builder: (BuildContext context, GoRouterState state) => const CreateInvitationPage(),
      ),
      GoRoute(
        path: AppRoutes.employeeList,
        builder: (BuildContext context, GoRouterState state) => const EmployeeListPage(),
      ),
      GoRoute(
        path: AppRoutes.joinInvitation,
        builder: (BuildContext context, GoRouterState state) {
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

      // Odori B2B Module routes
      GoRoute(
        path: AppRoutes.odoriCustomers,
        builder: (BuildContext context, GoRouterState state) => const OdoriCustomersPage(),
      ),
      GoRoute(
        path: AppRoutes.odoriProducts,
        builder: (BuildContext context, GoRouterState state) => const OdoriProductsPage(),
      ),
      GoRoute(
        path: AppRoutes.odoriOrders,
        builder: (BuildContext context, GoRouterState state) => const OdoriOrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.odoriDeliveries,
        builder: (BuildContext context, GoRouterState state) => const OdoriDeliveriesPage(),
      ),
      GoRoute(
        path: AppRoutes.odoriReceivables,
        builder: (BuildContext context, GoRouterState state) => const OdoriReceivablesPage(),
      ),

      // Direct role layout routes for manager navigation
      GoRoute(
        path: AppRoutes.warehouse,
        builder: (BuildContext context, GoRouterState state) => const DistributionWarehouseLayout(),
      ),
      GoRoute(
        path: AppRoutes.driver,
        builder: (BuildContext context, GoRouterState state) => const DistributionDriverLayout(),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (BuildContext context, GoRouterState state) => const DistributionFinanceLayout(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (BuildContext context, GoRouterState state) => const DistributionCustomerServiceLayout(),
      ),
      
      // Warehouse & Driver routes - Use full layouts for proper navigation
      GoRoute(
        path: AppRoutes.warehousePicking,
        builder: (BuildContext context, GoRouterState state) => const WarehouseMainLayout(),
      ),
      GoRoute(
        path: AppRoutes.routePlanning,
        builder: (BuildContext context, GoRouterState state) => const RoutePlanningPage(),
      ),
      GoRoute(
        path: AppRoutes.driverDashboard,
        builder: (BuildContext context, GoRouterState state) => const DriverMainLayout(),
      ),

      // Manufacturing Module routes
      GoRoute(
        path: AppRoutes.manufacturingSuppliers,
        builder: (BuildContext context, GoRouterState state) => const SuppliersPage(),
      ),
      GoRoute(
        path: AppRoutes.manufacturingMaterials,
        builder: (BuildContext context, GoRouterState state) => const MaterialsPage(),
      ),
      GoRoute(
        path: AppRoutes.manufacturingBOM,
        builder: (BuildContext context, GoRouterState state) => const BOMPage(),
      ),
      GoRoute(
        path: AppRoutes.manufacturingPurchaseOrders,
        builder: (BuildContext context, GoRouterState state) => const PurchaseOrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.manufacturingProductionOrders,
        builder: (BuildContext context, GoRouterState state) => const ProductionOrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.manufacturingPayables,
        builder: (BuildContext context, GoRouterState state) => const PayablesPage(),
      ),

      // Map & GPS routes - TEMPORARILY DISABLED for web compatibility
      // GoRoute(
      //   path: AppRoutes.mapOverview,
      //   builder: (BuildContext context, GoRouterState state) => const MapOverviewPage(),
      // ),
      // GoRoute(
      //   path: AppRoutes.mapDeliveryTracking,
      //   builder: (BuildContext context, GoRouterState state) => const DeliveryTrackingPage(),
      // ),
      // GoRoute(
      //   path: AppRoutes.mapStaffTracking,
      //   builder: (BuildContext context, GoRouterState state) => const StaffTrackingPage(),
      // ),
      // GoRoute(
      //   path: AppRoutes.mapRoutePlanning,
      //   builder: (BuildContext context, GoRouterState state) => const RoutePlanningPage(),
      // ),

      // Debug routes (temporarily disabled)
      // if (kDebugMode)
      //   GoRoute(
      //     path: AppRoutes.debugSettings,
      //     builder: (BuildContext context, GoRouterState state) => const DebugSettingsPage(),
      //   ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
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
