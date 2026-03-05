import 'package:equatable/equatable.dart';

import '../constants/roles.dart';
import 'business_type.dart';

/// User role enumeration (alias to shared SaboRole for backward compatibility)
typedef UserRole = SaboRole;

/// User model class
class User extends Equatable {
  final String id;
  final String? name; // Made nullable to match DB schema
  final String? email; // Made nullable for employees table
  final UserRole role;
  final String? department; // Department for sub-role routing (sales, warehouse, etc.)
  final String? phone;
  final String? avatarUrl;
  final String? branchId; // Add branchId for staff/branch association
  final String? companyId; // Add companyId for company association
  final String? companyName; // Company name for display
  final BusinessType? businessType; // Business type for layout routing
  final String? warehouseId; // Warehouse ID for warehouse staff
  final bool? isActive; // Active status for employee accounts
  final String? inviteToken; // Invite token for employee onboarding
  final DateTime? inviteExpiresAt; // When invite expires
  final DateTime? invitedAt; // When invitation was created
  final DateTime? onboardedAt; // When employee completed onboarding
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.name, // Made optional
    this.email, // Made optional for employees
    required this.role,
    this.department, // Add department
    this.phone,
    this.avatarUrl,
    this.branchId, // Add branchId to constructor
    this.companyId, // Add companyId to constructor
    this.companyName, // Add companyName to constructor
    this.businessType, // Add businessType to constructor
    this.warehouseId, // Add warehouseId to constructor
    this.isActive, // Add isActive to constructor
    this.inviteToken,
    this.inviteExpiresAt,
    this.invitedAt,
    this.onboardedAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        department,
        phone,
        avatarUrl,
        branchId,
        companyId,
        companyName,
        businessType,
        warehouseId,
        isActive,
        inviteToken,
        inviteExpiresAt,
        invitedAt,
        onboardedAt,
        createdAt,
        updatedAt,
      ];

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Parse business type from company data if available, OR from direct field (for local storage restore)
    BusinessType? businessType;
    final company = json['companies'];
    if (company != null) {
      final typeStr = company['business_type'] as String?;
      if (typeStr != null) {
        businessType = BusinessType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => BusinessType.billiards,
        );
      }
    } else if (json['business_type'] != null) {
      // Restore from direct field (local storage)
      final typeStr = json['business_type'] as String?;
      if (typeStr != null) {
        businessType = BusinessType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => BusinessType.billiards,
        );
      }
    }

    // Get company name from joined data OR from direct field
    final companyName = company?['name'] as String? ?? json['company_name'] as String?;
    
    return User(
      id: json['id'] as String,
      name: json['full_name'] as String? ??
          json['name'] as String?, // Try full_name first, fallback to name
      email: json['email'] as String? ?? json['username'] as String?, // email can be null, use username if available
      role: UserRole.fromString(json['role'] as String),
      department: json['department'] as String?, // Add department
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      branchId: json['branch_id'] as String?, // Add branchId
      companyId: json['company_id'] as String?, // Add companyId
      companyName: companyName, // Add companyName from joined data OR direct field
      businessType: businessType, // Add businessType from joined data OR direct field
      warehouseId: json['warehouse_id'] as String?, // Add warehouseId
      isActive: json['is_active'] as bool?, // Add isActive
      inviteToken: json['invite_token'] as String?,
      inviteExpiresAt: json['invite_expires_at'] != null
          ? DateTime.parse(json['invite_expires_at'] as String)
          : null,
      invitedAt: json['invited_at'] != null
          ? DateTime.parse(json['invited_at'] as String)
          : null,
      onboardedAt: json['onboarded_at'] != null
          ? DateTime.parse(json['onboarded_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for local storage / serialization (includes all fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'name': name, // Local compatibility only — NOT a DB column
      'email': email,
      'role': role.toUpperString(),
      'department': department,
      'phone': phone,
      'avatar_url': avatarUrl,
      'branch_id': branchId,
      'company_id': companyId,
      'company_name': companyName, // Local storage only — NOT a DB column
      'business_type': businessType?.toString().split('.').last, // Local storage only — NOT a DB column
      'warehouse_id': warehouseId,
      'is_active': isActive,
      'invite_token': inviteToken,
      'invite_expires_at': inviteExpiresAt?.toIso8601String(),
      'invited_at': invitedAt?.toIso8601String(),
      'onboarded_at': onboardedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for database operations (only DB-valid columns)
  Map<String, dynamic> toJsonForDb() {
    return {
      'full_name': name,
      'email': email,
      'role': role.toUpperString(),
      'department': department,
      'phone': phone,
      'avatar_url': avatarUrl,
      'branch_id': branchId,
      'company_id': companyId,
      'warehouse_id': warehouseId,
      'is_active': isActive,
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department, // Add department
    String? phone,
    String? avatarUrl,
    String? branchId, // Add branchId
    String? companyId, // Add companyId
    String? companyName, // Add companyName
    BusinessType? businessType, // Add businessType
    String? warehouseId, // Add warehouseId
    bool? isActive, // Add isActive
    String? inviteToken,
    DateTime? inviteExpiresAt,
    DateTime? invitedAt,
    DateTime? onboardedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department, // Add department
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      branchId: branchId ?? this.branchId, // Add branchId
      companyId: companyId ?? this.companyId, // Add companyId
      companyName: companyName ?? this.companyName, // Add companyName
      businessType: businessType ?? this.businessType, // Add businessType
      warehouseId: warehouseId ?? this.warehouseId, // Add warehouseId
      isActive: isActive ?? this.isActive, // Add isActive
      inviteToken: inviteToken ?? this.inviteToken,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
      invitedAt: invitedAt ?? this.invitedAt,
      onboardedAt: onboardedAt ?? this.onboardedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has permission for specific role
  bool hasRole(UserRole requiredRole) {
    // CEO has access to everything
    if (role == UserRole.ceo) return true;

    // MANAGER has access to MANAGER, SHIFT_LEADER, STAFF
    if (role == UserRole.manager) {
      return requiredRole == UserRole.manager ||
          requiredRole == UserRole.shiftLeader ||
          requiredRole == UserRole.staff;
    }

    // SHIFT_LEADER has access to SHIFT_LEADER, STAFF
    if (role == UserRole.shiftLeader) {
      return requiredRole == UserRole.shiftLeader ||
          requiredRole == UserRole.staff;
    }

    // STAFF only has access to STAFF
    return role == requiredRole;
  }

  /// Check if user has any of the required roles
  bool hasAnyRole(List<UserRole> requiredRoles) {
    return requiredRoles.any((role) => hasRole(role));
  }

  /// Get user display name based on role
  String get displayName {
    switch (role) {
      case UserRole.superAdmin:
        return '🛡️ $name (Super Admin)';
      case UserRole.ceo:
        return '👔 $name (CEO)';
      case UserRole.manager:
        return '📊 $name (Quản lý)';
      case UserRole.shiftLeader:
        return '⏰ $name (Trưởng ca)';
      case UserRole.staff:
        return '👤 $name (Nhân viên)';
      case UserRole.driver:
        return '🚗 $name (Tài xế)';
      case UserRole.warehouse:
        return '📦 $name (Nhân viên kho)';
      case UserRole.finance:
        return '💰 $name (Kế toán)';
      case UserRole.shareholder:
        return '📈 $name (Cổ đông)';
    }
  }

  /// Get role display name in Vietnamese
  String get roleDisplayName {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.ceo:
        return 'CEO';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.shiftLeader:
        return 'Trưởng ca';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.driver:
        return 'Tài xế';
      case UserRole.warehouse:
        return 'Nhân viên kho';
      case UserRole.finance:
        return 'Kế toán';
      case UserRole.shareholder:
        return 'Cổ đông';
    }
  }
}

/// Demo users for debug testing only
/// Disabled in release builds — see auth_provider.dart kDebugMode guard
class DemoUsers {
  static const List<User> users = [];

  static User? findByEmail(String email) => null;
  static User? findByRole(UserRole role) => null;
}
