import 'package:equatable/equatable.dart';

/// User role enumeration
enum UserRole {
  ceo('CEO'),
  manager('MANAGER'),
  shiftLeader('SHIFT_LEADER'),
  staff('STAFF');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.staff,
    );
  }
}

/// User model class
class User extends Equatable {
  final String id;
  final String? name; // Made nullable to match DB schema
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? branchId; // Add branchId for staff/branch association
  final String? companyId; // Add companyId for company association
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
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.branchId, // Add branchId to constructor
    this.companyId, // Add companyId to constructor
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
        phone,
        avatarUrl,
        branchId,
        companyId,
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
    return User(
      id: json['id'] as String,
      name: json['full_name'] as String? ??
          json['name'] as String?, // Try full_name first, fallback to name
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      branchId: json['branch_id'] as String?, // Add branchId
      companyId: json['company_id'] as String?, // Add companyId
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

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name, // Use full_name for DB
      'name': name, // Keep for compatibility
      'email': email,
      'role': role.value,
      'phone': phone,
      'avatar_url': avatarUrl,
      'branch_id': branchId, // Add branchId
      'company_id': companyId, // Add companyId
      'is_active': isActive, // Add isActive
      'invite_token': inviteToken,
      'invite_expires_at': inviteExpiresAt?.toIso8601String(),
      'invited_at': invitedAt?.toIso8601String(),
      'onboarded_at': onboardedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    String? branchId, // Add branchId
    String? companyId, // Add companyId
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
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      branchId: branchId ?? this.branchId, // Add branchId
      companyId: companyId ?? this.companyId, // Add companyId
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
      case UserRole.ceo:
        return '👔 $name (CEO)';
      case UserRole.manager:
        return '📊 $name (Quản lý)';
      case UserRole.shiftLeader:
        return '⏰ $name (Trưởng ca)';
      case UserRole.staff:
        return '👤 $name (Nhân viên)';
    }
  }

  /// Get role display name in Vietnamese
  String get roleDisplayName {
    switch (role) {
      case UserRole.ceo:
        return 'CEO';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.shiftLeader:
        return 'Trưởng ca';
      case UserRole.staff:
        return 'Nhân viên';
    }
  }
}

/// Demo users for testing - Khớp với database thực tế
class DemoUsers {
  static const List<User> users = [
    // CEO accounts
    User(
      id: '1',
      name: 'Nguyễn Văn CEO 1',
      email: 'ceo1@sabohub.com',
      role: UserRole.ceo,
      phone: '0901234567',
    ),
    User(
      id: '2',
      name: 'Trần Thị CEO 2',
      email: 'ceo2@sabohub.com',
      role: UserRole.ceo,
      phone: '0901234568',
    ),
    // Manager account
    User(
      id: '3',
      name: 'Trần Thị Quản Lý 1',
      email: 'manager1@sabohub.com',
      role: UserRole.manager,
      phone: '0902234567',
    ),
    // Shift Leader account (demo)
    User(
      id: '4',
      name: 'Lê Văn Trưởng Ca',
      email: 'shift@sabohub.com',
      role: UserRole.shiftLeader,
      phone: '0903234567',
    ),
    // Staff account
    User(
      id: '5',
      name: 'Phạm Thị Nhân Viên 1',
      email: 'staff1@sabohub.com',
      role: UserRole.staff,
      phone: '0904234567',
      branchId: 'branch-1', // Add branchId for staff
    ),
  ];

  /// Find demo user by email
  static User? findByEmail(String email) {
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Find demo user by role
  static User? findByRole(UserRole role) {
    try {
      return users.firstWhere((user) => user.role == role);
    } catch (e) {
      return null;
    }
  }
}
