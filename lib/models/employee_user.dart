// Employee Model (Non-Auth Users)
// For MANAGER, SHIFT_LEADER, STAFF roles
// Login via company_name + username + password

import 'user.dart' as app_user;
import 'business_type.dart';
import '../utils/app_logger.dart';

class EmployeeUser {
  final String id;
  final String companyId;
  final String? companyName;
  final BusinessType? businessType;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final EmployeeRole role;
  final String? department; // Department for sub-role routing (sales, warehouse, etc.)
  final String? branchId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmployeeUser({
    required this.id,
    required this.companyId,
    this.companyName,
    this.businessType,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.department,
    this.branchId,
    this.avatarUrl,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    AppLogger.data('📦 EmployeeUser.fromJson() called', json);
    
    // Parse business type from company data if available
    BusinessType? businessType;
    final company = json['company'];
    AppLogger.data('🏢 Company data from JSON', company);
    
    final typeStr = company?['business_type'] as String? ?? json['business_type'] as String?;
    AppLogger.data('📊 Business type string', typeStr);
    
    if (typeStr != null) {
      businessType = BusinessType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => BusinessType.billiards,
      );
      AppLogger.data('✅ Parsed businessType', businessType.toString());
    }
    
    final employee = EmployeeUser(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      companyName: company?['name'] as String? ?? json['company_name'] as String?,
      businessType: businessType,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: EmployeeRole.fromString(json['role'] as String? ?? 'STAFF'),
      department: json['department'] as String?,
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
    
    AppLogger.success('✅ EmployeeUser created', {
      'id': employee.id,
      'fullName': employee.fullName,
      'role': employee.role.value,
      'companyName': employee.companyName,
      'businessType': employee.businessType?.toString(),
    });
    
    return employee;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'company_name': companyName,
      'business_type': businessType?.toString().split('.').last,
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
    String? companyName,
    BusinessType? businessType,
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
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
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
    AppLogger.data('🔄 EmployeeUser.toUser() called');
    
    final user = app_user.User(
      id: id,
      name: fullName,
      email: email ?? '$username@employee.local',
      role: app_user.UserRole.fromString(role.value),
      department: department, // Add department for sub-role routing
      phone: phone,
      avatarUrl: avatarUrl,
      branchId: branchId,
      companyId: companyId,
      companyName: companyName,
      businessType: businessType,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    
    AppLogger.success('✅ User created from Employee', {
      'id': user.id,
      'name': user.name,
      'role': user.role.toString(),
      'department': user.department,
      'businessType': user.businessType?.toString(),
      'companyName': user.companyName,
    });
    
    return user;
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
