import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart' as user_model;
import '../../utils/app_logger.dart';
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
import '../../pages/user/user_profile_page.dart';
import '../../layouts/manager_main_layout.dart';
import '../../layouts/shift_leader_main_layout.dart';
import '../../layouts/driver_main_layout.dart';
import '../../layouts/warehouse_main_layout.dart';
import '../../business_types/distribution/layouts/distribution_warehouse_layout.dart';
import '../../business_types/distribution/pages/driver/distribution_driver_layout_refactored.dart';
import '../../business_types/distribution/layouts/distribution_finance_layout.dart';
import '../../business_types/distribution/layouts/distribution_customer_service_layout.dart';
import '../../pages/staff_main_layout.dart';
import '../../pages/ceo/ceo_main_layout.dart';
import '../../pages/manager/manager_reports_page.dart';
// Odori B2B Module Pages
import '../../business_types/distribution/pages/customers/odori_customers_page.dart';
import '../../business_types/distribution/pages/products/odori_products_page.dart';
import '../../business_types/distribution/pages/orders/odori_orders_page.dart';
import '../../business_types/distribution/pages/deliveries/odori_deliveries_page.dart';
import '../../business_types/distribution/pages/receivables/odori_receivables_page.dart';
// Warehouse & Driver Pages - Now using layouts
import '../../pages/delivery/route_planning_page.dart';
// Manufacturing Module Pages
import '../../business_types/manufacturing/pages/manufacturing/suppliers_page.dart';
import '../../business_types/manufacturing/pages/manufacturing/materials_page.dart';
import '../../business_types/manufacturing/pages/manufacturing/bom_page.dart';
import '../../business_types/manufacturing/pages/manufacturing/purchase_orders_page.dart';
import '../../business_types/manufacturing/pages/manufacturing/production_orders_page.dart';
import '../../business_types/manufacturing/pages/manufacturing/payables_page.dart';
// Service Module Pages
import '../../business_types/service/pages/sessions/session_list_page.dart';
import '../../business_types/service/pages/menu/menu_list_page.dart';
// Gamification Module Pages
import '../../pages/gamification/quest_hub_page.dart';
import '../../pages/gamification/ceo_game_profile_page.dart';
import '../../pages/action_center_page.dart';
import '../../pages/gamification/staff_performance_page.dart';
import '../../pages/gamification/uytin_store_page.dart';
import '../../pages/gamification/season_pass_page.dart';
import '../../pages/gamification/company_ranking_page.dart';
import '../../pages/gamification/leaderboard_page.dart';
import '../../pages/gamification/gamification_analytics_page.dart';
import '../../pages/gamification/game_notifications_page.dart';
import '../../pages/gamification/ai_quest_config_page.dart';
// SABO Token Module Pages
import '../../pages/token/sabo_wallet_page.dart';
import '../../pages/token/sabo_token_store_page.dart';
import '../../pages/token/sabo_token_analytics_page.dart';
import '../../pages/token/sabo_achievements_page.dart';
import '../../pages/token/sabo_token_leaderboard_page.dart';
// Referral & Showcase Pages
import '../../pages/referral/referral_page.dart';
import '../../pages/company_showcase/company_showcase_page.dart';
// Travis AI
import '../../pages/travis/travis_chat_page.dart';
// Gym Coach AI
import '../../features/gym_agent/layouts/gym_agent_layout.dart';
// Self-Improvement Coaching
import '../../features/coaching/pages/coaching_page.dart';
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
  static const String actionCenter = '/action-center';

  // Staff routes
  static const String staffCheckin = '/staff/checkin';
  static const String staffTasks = '/staff/tasks';
  static const String staffMessages = '/staff/messages';

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

  // Entertainment Module routes
  static const String entertainmentSessions = '/entertainment/sessions';
  static const String entertainmentMenu = '/entertainment/menu';

  // Map & GPS Module routes
  static const String mapOverview = '/map/overview';
  static const String mapDeliveryTracking = '/map/delivery-tracking';
  static const String mapStaffTracking = '/map/staff-tracking';
  static const String mapRoutePlanning = '/map/route-planning';

  // Gamification routes
  static const String questHub = '/quest-hub';
  static const String ceoGameProfile = '/ceo/game-profile';
  static const String staffPerformance = '/staff-performance';
  static const String uytinStore = '/uytin-store';
  static const String seasonPass = '/season-pass';
  static const String companyRanking = '/company-ranking';
  static const String leaderboard = '/leaderboard';
  static const String gamificationAnalytics = '/gamification-analytics';
  static const String gameNotifications = '/game-notifications';
  static const String aiQuestConfig = '/ai-quest-config';

  // SABO Token routes
  static const String saboWallet = '/sabo-wallet';
  static const String saboTokenStore = '/sabo-token-store';
  static const String saboTokenAnalytics = '/sabo-token-analytics';
  static const String saboAchievements = '/sabo-achievements';
  static const String saboTokenLeaderboard = '/sabo-token-leaderboard';

  // Referral & Showcase routes
  static const String referral = '/referral';
  static const String companyShowcase = '/company-showcase';

  // Travis AI
  static const String travisChat = '/travis';

  // Gym Coach AI
  static const String gymCoach = '/gym-coach';

  // Self-Improvement Coaching
  static const String coaching = '/coaching';

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
      case user_model.UserRole.finance:
        return nav.UserRole.finance;
      case user_model.UserRole.shareholder:
        return nav.UserRole.shareholder;
    }
  }

  return nav.UserRole.staff; // Default fallback
});

/// Route guard that checks user permissions
class RouteGuard {
  static const _sharedRoutes = [
    '/employees/list',
    '/employees/create',
    '/employees/invite',
    '/company/settings',
    '/manager-reports',
    '/entertainment/sessions',
    '/entertainment/menu',
  ];

  static String? checkAccess(nav.UserRole userRole, String route) {
    // CEO has full access to all routes
    if (userRole == nav.UserRole.ceo) return null;

    // Get allowed routes for the current user role
    final allowedItems = nav.NavigationConfig.getItemsForRole(userRole);
    final allowedRoutes = allowedItems.map((item) => item.route).toList();

    // Routes accessible by all authenticated users
    allowedRoutes.add(AppRoutes.home);
    allowedRoutes.add(AppRoutes.profile);

    // Manager gets shared operational routes
    if (userRole == nav.UserRole.manager) {
      allowedRoutes.addAll(_sharedRoutes);
    }

    // Check if route is allowed
    if (!allowedRoutes.contains(route)) {
      switch (userRole) {
        case nav.UserRole.superAdmin:
          return AppRoutes.home; // SuperAdmin goes to home (no dedicated dashboard)
        case nav.UserRole.staff:
          return AppRoutes.staffCheckin;
        case nav.UserRole.shiftLeader:
          return AppRoutes.shiftLeaderTeam;
        case nav.UserRole.manager:
          return AppRoutes.managerDashboard;
        case nav.UserRole.ceo:
          return null;
        case nav.UserRole.driver:
          return AppRoutes.driverDashboard;
        case nav.UserRole.warehouse:
          return AppRoutes.warehousePicking;
        case nav.UserRole.finance:
          return AppRoutes.home; // Finance role redirects to home
        case nav.UserRole.shareholder:
          return AppRoutes.home; // Shareholder role redirects to home
      }
    }

    return null; // Access granted
  }
}

/// Bridge between Riverpod auth state and GoRouter's refreshListenable.
/// When auth state changes, this notifies GoRouter to re-evaluate redirects
/// WITHOUT recreating the entire GoRouter (preserving widget state like CEO login toggle).
class _RouterAuthNotifier extends ChangeNotifier {
  _RouterAuthNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(currentUserRoleProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final routerNotifier = _RouterAuthNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      // ✅ FIX: Use ref.read() instead of ref.watch() so GoRouter is created ONCE.
      // Auth changes trigger redirect re-evaluation via refreshListenable above.
      final authState = ref.read(authProvider);
      final userRole = ref.read(currentUserRoleProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Router navigation logging (debug only)
      assert(() {
        AppLogger.nav('${state.matchedLocation} | auth=$isLoggedIn | role=$userRole');
        return true;
      }());

      // Wait for session restore to complete before redirecting
      if (isLoading) {
        return null; // Stay on current route while loading
      }

      // Email verification is accessible for both logged in and logged out users
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
        final redirectRoute = RouteGuard.checkAccess(userRole, state.matchedLocation);
        return redirectRoute;
      }

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

      // Action Center route - accessible by all roles
      GoRoute(
        path: AppRoutes.actionCenter,
        builder: (BuildContext context, GoRouterState state) => const ActionCenterPage(),
      ),

      // Staff routes - Use full layout for proper navigation
      GoRoute(
        path: AppRoutes.staffCheckin,
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

      // Travis AI Chat
      GoRoute(
        path: AppRoutes.travisChat,
        builder: (BuildContext context, GoRouterState state) => const TravisChatPage(),
      ),

      // Gym Coach AI
      GoRoute(
        path: AppRoutes.gymCoach,
        builder: (BuildContext context, GoRouterState state) => const GymAgentLayout(),
      ),

      // Self-Improvement Coaching
      GoRoute(
        path: AppRoutes.coaching,
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: CoachingPage(),
        ),
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

      // Entertainment Module routes
      GoRoute(
        path: AppRoutes.entertainmentSessions,
        builder: (BuildContext context, GoRouterState state) => const SessionListPage(),
      ),
      GoRoute(
        path: AppRoutes.entertainmentMenu,
        builder: (BuildContext context, GoRouterState state) => const MenuListPage(),
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

      // Gamification routes
      GoRoute(
        path: AppRoutes.questHub,
        builder: (BuildContext context, GoRouterState state) => const QuestHubPage(),
      ),
      GoRoute(
        path: AppRoutes.ceoGameProfile,
        builder: (BuildContext context, GoRouterState state) => const CeoGameProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.staffPerformance,
        builder: (BuildContext context, GoRouterState state) => const StaffPerformancePage(),
      ),
      GoRoute(
        path: AppRoutes.uytinStore,
        builder: (BuildContext context, GoRouterState state) => const UytinStorePage(),
      ),
      GoRoute(
        path: AppRoutes.seasonPass,
        builder: (BuildContext context, GoRouterState state) => SeasonPassPage(),
      ),
      GoRoute(
        path: AppRoutes.companyRanking,
        builder: (BuildContext context, GoRouterState state) => CompanyRankingPage(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (BuildContext context, GoRouterState state) => LeaderboardPage(),
      ),
      GoRoute(
        path: AppRoutes.gamificationAnalytics,
        builder: (BuildContext context, GoRouterState state) => GamificationAnalyticsPage(),
      ),
      GoRoute(
        path: AppRoutes.gameNotifications,
        builder: (BuildContext context, GoRouterState state) => GameNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.aiQuestConfig,
        builder: (BuildContext context, GoRouterState state) => AiQuestConfigPage(),
      ),

      // SABO Token routes
      GoRoute(
        path: AppRoutes.saboWallet,
        builder: (BuildContext context, GoRouterState state) => SaboWalletPage(),
      ),
      GoRoute(
        path: AppRoutes.saboTokenStore,
        builder: (BuildContext context, GoRouterState state) => SaboTokenStorePage(),
      ),
      GoRoute(
        path: AppRoutes.saboTokenAnalytics,
        builder: (BuildContext context, GoRouterState state) => SaboTokenAnalyticsPage(),
      ),
      GoRoute(
        path: AppRoutes.saboAchievements,
        builder: (BuildContext context, GoRouterState state) => SaboAchievementsPage(),
      ),
      GoRoute(
        path: AppRoutes.saboTokenLeaderboard,
        builder: (BuildContext context, GoRouterState state) => SaboTokenLeaderboardPage(),
      ),

      // Referral & Showcase routes
      GoRoute(
        path: AppRoutes.referral,
        builder: (BuildContext context, GoRouterState state) => const ReferralPage(),
      ),
      GoRoute(
        path: AppRoutes.companyShowcase,
        builder: (BuildContext context, GoRouterState state) => CompanyShowcasePage(),
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
            SizedBox(height: 16),
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
