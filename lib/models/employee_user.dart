// Employee Model (Non-Auth Users)
// For MANAGER, SHIFT_LEADER, STAFF roles
// Login via company_name + username + password

import 'user.dart' as app_user;

class EmployeeUser {
  final String id;
  final String companyId;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final EmployeeRole role;
  final String? branchId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmployeeUser({
    required this.id,
    required this.companyId,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.branchId,
    this.avatarUrl,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    return EmployeeUser(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: EmployeeRole.fromString(json['role'] as String? ?? 'STAFF'),
      branchId: json['branch_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'branch_id': branchId,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EmployeeUser copyWith({
    String? id,
    String? companyId,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    EmployeeRole? role,
    String? branchId,
    String? avatarUrl,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeUser(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to app User model for auth provider
  app_user.User toUser() {
    return app_user.User(
      id: id,
      name: fullName,
      email: email ?? '$username@employee.local',
      role: app_user.UserRole.fromString(role.value),
      phone: phone,
      avatarUrl: avatarUrl,
      branchId: branchId,
      companyId: companyId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Employee Role enumeration
enum EmployeeRole {
  manager('MANAGER'),
  shiftLeader('SHIFT_LEADER'),
  staff('STAFF');

  const EmployeeRole(this.value);
  final String value;

  static EmployeeRole fromString(String value) {
    return EmployeeRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => EmployeeRole.staff,
    );
  }

  String get displayName {
    switch (this) {
      case EmployeeRole.manager:
        return 'Quản lý';
      case EmployeeRole.shiftLeader:
        return 'Trưởng ca';
      case EmployeeRole.staff:
        return 'Nhân viên';
    }
  }
}
