/// Shared role definitions for SABOHUB
/// Used by both web (sabohub-nexus) and Flutter (sabohub-app)
enum SaboRole {
  superAdmin, // Platform Admin - manages entire system
  ceo,
  manager,
  shiftLeader,
  staff,
  driver,
  warehouse,
  finance,
  shareholder; // Cổ đông - xem thông tin cổ phần

  /// Get display name in Vietnamese
  String get displayName {
    switch (this) {
      case SaboRole.superAdmin:
        return 'Super Admin';
      case SaboRole.ceo:
        return 'CEO';
      case SaboRole.manager:
        return 'Quản lý';
      case SaboRole.shiftLeader:
        return 'Tổ trưởng';
      case SaboRole.staff:
        return 'Nhân viên';
      case SaboRole.driver:
        return 'Tài xế';
      case SaboRole.warehouse:
        return 'Nhân viên kho';
      case SaboRole.finance:
        return 'Kế toán';
      case SaboRole.shareholder:
        return 'Cổ đông';
    }
  }

  /// Convert from string (case-insensitive)
  static SaboRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
      case 'PLATFORM_ADMIN':
        return SaboRole.superAdmin;
      case 'CEO':
        return SaboRole.ceo;
      case 'MANAGER':
        return SaboRole.manager;
      case 'SHIFT_LEADER':
        return SaboRole.shiftLeader;
      case 'STAFF':
        return SaboRole.staff;
      case 'DRIVER':
        return SaboRole.driver;
      case 'WAREHOUSE':
        return SaboRole.warehouse;
      case 'FINANCE':
        return SaboRole.finance;
      case 'SHAREHOLDER':
        return SaboRole.shareholder;
      default:
        return SaboRole.staff; // Default fallback
    }
  }

  /// Convert to database string (lowercase snake_case for DB storage)
  /// DB CHECK constraint accepts: staff, shift_leader, manager, ceo, driver, warehouse, super_admin, finance
  String toDbString() {
    switch (this) {
      case SaboRole.superAdmin:
        return 'super_admin';
      case SaboRole.shiftLeader:
        return 'shift_leader';
      default:
        return name.toLowerCase();
    }
  }

  /// @deprecated Use toDbString() instead. This method returns uppercase which doesn't match DB.
  String toUpperString() => toDbString();

  /// Convert to lowercase string (for web compatibility)
  String toLowerString() {
    return name.toLowerCase();
  }

  /// Check if role is super admin (platform level)
  bool get isSuperAdmin => this == SaboRole.superAdmin;

  /// Check if role can access management features
  bool get isManager => this == SaboRole.manager || this == SaboRole.ceo || this == SaboRole.superAdmin;

  /// Check if role is executive level
  bool get isExecutive => this == SaboRole.ceo || this == SaboRole.superAdmin;

  /// Check if role can manage employees
  bool get canManageEmployees => isManager || isExecutive;

  /// Check if role can view reports
  bool get canViewReports => isManager || isExecutive;
  
  /// Check if role is delivery-related
  bool get isDeliveryRole => this == SaboRole.driver;
  
  /// Check if role is warehouse-related
  bool get isWarehouseRole => this == SaboRole.warehouse;
  
  /// Check if role has platform-wide access
  bool get hasPlatformAccess => this == SaboRole.superAdmin;
  
  /// Check if role is shareholder (cổ đông)
  bool get isShareholder => this == SaboRole.shareholder;
}