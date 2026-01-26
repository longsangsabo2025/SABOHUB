/// Navigation models for role-based navigation system
library;

import 'package:flutter/material.dart';

/// User roles in the system
enum UserRole {
  superAdmin,
  staff,
  shiftLeader,
  manager,
  ceo,
  driver,
  warehouse,
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

/// Navigation group configuration
class NavigationGroup {
  final String title;
  final IconData icon;
  final List<NavigationItem> items;
  final List<UserRole> allowedRoles;

  const NavigationGroup({
    required this.title,
    required this.icon,
    required this.items,
    required this.allowedRoles,
  });

  /// Check if this group is accessible for the given role
  bool isAccessibleFor(UserRole role) => allowedRoles.contains(role);
}

/// Base class for navigation configuration
abstract class NavigationBase {
  const NavigationBase();
}

/// Single navigation item wrapper
class SingleNav extends NavigationBase {
  final NavigationItem item;
  const SingleNav(this.item);
}

/// Group navigation wrapper
class GroupNav extends NavigationBase {
  final NavigationGroup group;
  const GroupNav(this.group);
}

/// Navigation configuration for different user roles
class NavigationConfig {
  // Driver-specific navigation
  static const List<NavigationItem> driverNavItems = [
    NavigationItem(
      route: '/driver/deliveries',
      icon: Icons.local_shipping,
      activeIcon: Icons.local_shipping,
      label: 'Giao hàng',
      allowedRoles: [UserRole.driver],
    ),
    NavigationItem(
      route: '/driver/history',
      icon: Icons.history,
      activeIcon: Icons.history,
      label: 'Lịch sử',
      allowedRoles: [UserRole.driver],
    ),
    NavigationItem(
      route: '/driver/profile',
      icon: Icons.person,
      activeIcon: Icons.person,
      label: 'Cá nhân',
      allowedRoles: [UserRole.driver],
    ),
  ];

  // Warehouse-specific navigation
  static const List<NavigationItem> warehouseNavItems = [
    NavigationItem(
      route: '/warehouse/inventory',
      icon: Icons.inventory,
      activeIcon: Icons.inventory,
      label: 'Tồn kho',
      allowedRoles: [UserRole.warehouse],
    ),
    NavigationItem(
      route: '/warehouse/orders',
      icon: Icons.receipt_long,
      activeIcon: Icons.receipt_long,
      label: 'Đơn hàng',
      allowedRoles: [UserRole.warehouse],
    ),
    NavigationItem(
      route: '/warehouse/profile',
      icon: Icons.person,
      activeIcon: Icons.person,
      label: 'Cá nhân',
      allowedRoles: [UserRole.warehouse],
    ),
  ];

  // Staff-specific simple navigation
  static const List<NavigationItem> staffNavItems = [
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
  ];

  // Grouped navigation structure for managers and CEOs
  static List<NavigationBase> get navigationStructure => [
    // Home
    SingleNav(const NavigationItem(
      route: '/',
      icon: Icons.home,
      activeIcon: Icons.home,
      label: 'Trang chủ',
      allowedRoles: [UserRole.ceo, UserRole.manager],
    )),
    
    // CEO Dashboard
    SingleNav(const NavigationItem(
      route: '/ceo/analytics',
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'CEO Dashboard',
      allowedRoles: [UserRole.ceo],
    )),

    // Core Operations Group
    GroupNav(NavigationGroup(
      title: 'Vận hành',
      icon: Icons.bolt,
      allowedRoles: const [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
      items: const [
        NavigationItem(
          route: '/manager/dashboard',
          icon: Icons.speed,
          label: 'TT Vận hành',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
        NavigationItem(
          route: '/manager/staff',
          icon: Icons.people,
          label: 'Nhân viên',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
        NavigationItem(
          route: '/staff/tasks',
          icon: Icons.task_alt,
          label: 'Công việc',
          allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
        ),
        NavigationItem(
          route: '/staff/checkin',
          icon: Icons.fingerprint,
          label: 'Chấm công',
          allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
        ),
        NavigationItem(
          route: '/manager/attendance',
          icon: Icons.access_time,
          label: 'Lịch làm việc',
          allowedRoles: [UserRole.manager, UserRole.ceo],
        ),
        NavigationItem(
          route: '/shift-leader/reports',
          icon: Icons.assessment,
          label: 'Báo cáo ngày',
          allowedRoles: [UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
        ),
      ],
    )),

    // Analytics & Reports Group
    GroupNav(NavigationGroup(
      title: 'Phân tích & Báo cáo',
      icon: Icons.analytics,
      allowedRoles: const [UserRole.ceo, UserRole.manager],
      items: const [
        NavigationItem(
          route: '/manager/analytics',
          icon: Icons.bar_chart,
          label: 'KPI Dashboard',
          allowedRoles: [UserRole.manager, UserRole.ceo],
        ),
        NavigationItem(
          route: '/manager/analytics',
          icon: Icons.insights,
          label: 'Thống kê',
          allowedRoles: [UserRole.manager, UserRole.ceo],
        ),
      ],
    )),

    // Financial Group
    GroupNav(NavigationGroup(
      title: 'Tài chính',
      icon: Icons.attach_money,
      allowedRoles: const [UserRole.ceo, UserRole.manager],
      items: const [
        NavigationItem(
          route: '/commission/my-commission',
          icon: Icons.account_balance_wallet,
          label: 'Hoa hồng',
          allowedRoles: [UserRole.staff, UserRole.shiftLeader, UserRole.manager, UserRole.ceo],
        ),
        NavigationItem(
          route: '/commission/bills',
          icon: Icons.receipt_long,
          label: 'Bills',
          allowedRoles: [UserRole.manager, UserRole.ceo],
        ),
      ],
    )),

    // B2B Sales (Odori) Group
    GroupNav(NavigationGroup(
      title: 'Bán hàng B2B',
      icon: Icons.shopping_cart,
      allowedRoles: const [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
      items: const [
        NavigationItem(
          route: '/odori/customers',
          icon: Icons.business,
          label: 'Khách hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/odori/products',
          icon: Icons.inventory_2,
          label: 'Sản phẩm',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/odori/orders',
          icon: Icons.shopping_bag,
          label: 'Đơn hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/warehouse/picking',
          icon: Icons.inventory,
          label: 'Soạn hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
        NavigationItem(
          route: '/delivery/route-planning',
          icon: Icons.route,
          label: 'Lộ trình giao',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
        NavigationItem(
          route: '/odori/deliveries',
          icon: Icons.local_shipping,
          label: 'Giao hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/driver/dashboard',
          icon: Icons.directions_car,
          label: 'Tài xế',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.staff],
        ),
        NavigationItem(
          route: '/odori/receivables',
          icon: Icons.credit_card,
          label: 'Công nợ phải thu',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
      ],
    )),

    // Manufacturing (Odori) Group
    GroupNav(NavigationGroup(
      title: 'Sản xuất',
      icon: Icons.factory,
      allowedRoles: const [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
      items: const [
        NavigationItem(
          route: '/manufacturing/suppliers',
          icon: Icons.business_center,
          label: 'Nhà cung cấp',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/manufacturing/materials',
          icon: Icons.inventory,
          label: 'Nguyên vật liệu',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/manufacturing/bom',
          icon: Icons.list_alt,
          label: 'Định mức (BOM)',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
        NavigationItem(
          route: '/manufacturing/purchase-orders',
          icon: Icons.shopping_basket,
          label: 'Đơn mua hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/manufacturing/production-orders',
          icon: Icons.precision_manufacturing,
          label: 'Lệnh sản xuất',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/manufacturing/payables',
          icon: Icons.payment,
          label: 'Công nợ phải trả',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
      ],
    )),

    // Inventory Group
    GroupNav(NavigationGroup(
      title: 'Kho hàng',
      icon: Icons.warehouse,
      allowedRoles: const [UserRole.ceo, UserRole.manager, UserRole.shiftLeader],
      items: const [
        NavigationItem(
          route: '/odori/inventory',
          icon: Icons.inventory_2,
          label: 'Tồn kho',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader],
        ),
        NavigationItem(
          route: '/odori/payments',
          icon: Icons.payments,
          label: 'Thanh toán',
          allowedRoles: [UserRole.ceo, UserRole.manager],
        ),
      ],
    )),

    // Map & GPS Group
    GroupNav(NavigationGroup(
      title: 'Bản đồ & GPS',
      icon: Icons.map,
      allowedRoles: const [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
      items: const [
        NavigationItem(
          route: '/map/overview',
          icon: Icons.map_outlined,
          label: 'Bản đồ tổng quan',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader],
        ),
        NavigationItem(
          route: '/map/delivery-tracking',
          icon: Icons.local_shipping,
          label: 'Theo dõi giao hàng',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
        NavigationItem(
          route: '/map/staff-tracking',
          icon: Icons.person_pin_circle,
          label: 'Theo dõi nhân viên',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader],
        ),
        NavigationItem(
          route: '/map/route-planning',
          icon: Icons.route,
          label: 'Tuyến đường',
          allowedRoles: [UserRole.ceo, UserRole.manager, UserRole.shiftLeader, UserRole.staff],
        ),
      ],
    )),

    // Settings
    SingleNav(const NavigationItem(
      route: '/ceo/settings',
      icon: Icons.settings,
      activeIcon: Icons.settings,
      label: 'Cài đặt',
      allowedRoles: [UserRole.ceo, UserRole.manager],
    )),
  ];

  /// Legacy allItems for backward compatibility
  static const List<NavigationItem> allItems = [
    NavigationItem(
      route: '/',
      icon: Icons.home,
      activeIcon: Icons.home,
      label: 'Trang chủ',
      allowedRoles: [UserRole.ceo, UserRole.manager],
    ),
    NavigationItem(
      route: '/ceo/analytics',
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'CEO Dashboard',
      allowedRoles: [UserRole.ceo],
    ),
    NavigationItem(
      route: '/ceo/settings',
      icon: Icons.settings,
      activeIcon: Icons.settings,
      label: 'Cài đặt',
      allowedRoles: [UserRole.ceo],
    ),
    NavigationItem(
      route: '/company/settings',
      icon: Icons.business,
      activeIcon: Icons.business,
      label: 'Công ty',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),
    NavigationItem(
      route: '/commission/my-commission',
      icon: Icons.account_balance_wallet,
      activeIcon: Icons.account_balance_wallet,
      label: 'Hoa hồng',
      allowedRoles: [
        UserRole.staff,
        UserRole.shiftLeader,
        UserRole.manager,
        UserRole.ceo
      ],
    ),
    NavigationItem(
      route: '/commission/bills',
      icon: Icons.receipt_long,
      activeIcon: Icons.receipt_long,
      label: 'Bills',
      allowedRoles: [UserRole.manager, UserRole.ceo],
    ),
    NavigationItem(
      route: '/commission/rules',
      icon: Icons.rule,
      activeIcon: Icons.rule,
      label: 'Quy tắc',
      allowedRoles: [UserRole.ceo],
    ),
  ];

  /// Get navigation items for a specific role
  static List<NavigationItem> getItemsForRole(UserRole role) {
    // Return role-specific navigation lists
    switch (role) {
      case UserRole.driver:
        return driverNavItems;
      case UserRole.warehouse:
        return warehouseNavItems;
      case UserRole.staff:
      case UserRole.shiftLeader:
        return staffNavItems;
      default:
        return allItems.where((item) => item.isAccessibleFor(role)).toList();
    }
  }

  /// Get filtered navigation structure for a role
  static List<NavigationBase> getNavigationForRole(UserRole role) {
    // Driver gets driver-specific navigation
    if (role == UserRole.driver) {
      return driverNavItems.map((item) => SingleNav(item)).toList();
    }
    
    // Warehouse gets warehouse-specific navigation
    if (role == UserRole.warehouse) {
      return warehouseNavItems.map((item) => SingleNav(item)).toList();
    }
    
    // Staff and ShiftLeader get simple navigation
    if (role == UserRole.staff || role == UserRole.shiftLeader) {
      return staffNavItems.map((item) => SingleNav(item)).toList();
    }

    // Filter groups and items by role for managers/CEOs
    return navigationStructure.where((navBase) {
      if (navBase is SingleNav) {
        return navBase.item.isAccessibleFor(role);
      } else if (navBase is GroupNav) {
        final filteredItems = navBase.group.items
            .where((item) => item.isAccessibleFor(role))
            .toList();
        return filteredItems.isNotEmpty && navBase.group.isAccessibleFor(role);
      }
      return false;
    }).toList();
  }
}
