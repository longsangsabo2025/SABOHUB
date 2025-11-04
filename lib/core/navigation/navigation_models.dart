/// Navigation models for role-based navigation system
library;

import 'package:flutter/material.dart';

/// User roles in the system
enum UserRole {
  staff,
  shiftLeader,
  manager,
  ceo,
}

/// Navigation item configuration
class NavigationItem {
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badge;
  final List<UserRole> allowedRoles;

  const NavigationItem({
    required this.route,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
    required this.allowedRoles,
  });

  /// Check if this item is accessible for the given role
  bool isAccessibleFor(UserRole role) => allowedRoles.contains(role);
}

/// Navigation configuration for different user roles
class NavigationConfig {
  static const List<NavigationItem> allItems = [
    // Staff Navigation
    NavigationItem(
      route: '/staff/tables',
      icon: Icons.table_chart,
      activeIcon: Icons.table_chart,
      label: 'Bàn',
      allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager],
    ),
    NavigationItem(
      route: '/staff/checkin',
      icon: Icons.fingerprint,
      activeIcon: Icons.fingerprint,
      label: 'Check-in',
      allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager],
    ),
    NavigationItem(
      route: '/staff/tasks',
      icon: Icons.task_alt,
      activeIcon: Icons.task_alt,
      label: 'Nhiệm vụ',
      allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager],
    ),
    NavigationItem(
      route: '/staff/messages',
      icon: Icons.message,
      activeIcon: Icons.message,
      label: 'Tin nhắn',
      allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager],
    ),

    // Shift Leader Navigation
    NavigationItem(
      route: '/shift-leader/team',
      icon: Icons.group,
      activeIcon: Icons.group,
      label: 'Đội nhóm',
      allowedRoles: [UserRole.shiftLeader, UserRole.manager],
    ),
    NavigationItem(
      route: '/shift-leader/reports',
      icon: Icons.assessment,
      activeIcon: Icons.assessment,
      label: 'Báo cáo',
      allowedRoles: [UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
    ),

    // Manager Navigation
    NavigationItem(
      route: '/manager/dashboard',
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'Tổng quan',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),
    NavigationItem(
      route: '/manager/tasks',
      icon: Icons.assignment,
      activeIcon: Icons.assignment_turned_in,
      label: 'Công việc',
      allowedRoles: [UserRole.manager],
    ),
    NavigationItem(
      route: '/manager/analytics',
      icon: Icons.analytics,
      activeIcon: Icons.analytics,
      label: 'Phân tích',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),
    NavigationItem(
      route: '/manager/staff',
      icon: Icons.people,
      activeIcon: Icons.people,
      label: 'Nhân viên',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),

    // CEO Navigation
    NavigationItem(
      route: '/ceo/analytics',
      icon: Icons.analytics,
      activeIcon: Icons.analytics,
      label: 'Phân tích',
      allowedRoles: [UserRole.ceo],
    ),
    NavigationItem(
      route: '/ceo/stores',
      icon: Icons.store,
      activeIcon: Icons.store,
      label: 'Cửa hàng',
      allowedRoles: [UserRole.ceo],
    ),
    NavigationItem(
      route: '/ceo/settings',
      icon: Icons.settings,
      activeIcon: Icons.settings,
      label: 'Cài đặt',
      allowedRoles: [UserRole.ceo],
    ),

    // Company settings (accessible by managers and CEOs)
    NavigationItem(
      route: '/company/settings',
      icon: Icons.business,
      activeIcon: Icons.business,
      label: 'Công ty',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),

    // Debug Navigation (temporarily disabled)
    // if (kDebugMode)
    //   NavigationItem(
    //     route: '/debug/settings',
    //     icon: Icons.bug_report,
    //     activeIcon: Icons.bug_report,
    //     label: '🔧 Debug',
    //     allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
    //   ),
  ];

  /// Get navigation items for a specific role
  static List<NavigationItem> getItemsForRole(UserRole role) {
    return allItems.where((item) => item.isAccessibleFor(role)).toList();
  }

  /// Get role-specific navigation configuration
  static List<NavigationItem> getNavigationForRole(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return getItemsForRole(role)
            .take(4)
            .toList(); // First 4 items (removed Profile tab)
      case UserRole.shiftLeader:
        // ShiftLeader has only 3 pages: Tasks, Team, Reports
        return [
          getItemsForRole(UserRole.staff)
              .firstWhere((item) => item.route == '/staff/tasks'),
          ...getItemsForRole(role)
              .where((item) => item.route.startsWith('/shift-leader')),
        ];
      case UserRole.manager:
        return getItemsForRole(role)
            .where((item) =>
                item.route.startsWith('/manager') ||
                item.route.startsWith('/staff/profile'))
            .toList();
      case UserRole.ceo:
        return getItemsForRole(role);
    }
  }
}
