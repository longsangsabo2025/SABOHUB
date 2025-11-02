/// Staff Model
/// Represents a staff member/employee with role and profile information
class Staff {
  final String id;
  final String name;
  final String email;
  final String role; // 'staff', 'shift_leader', 'manager'
  final String? phone;
  final String? avatar;
  final String? companyId;
  final String? companyName;
  final String status; // 'active', 'inactive', 'on_leave'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.companyId,
    this.companyName,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      name:
          json['name'] as String? ?? json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String,
      role: json['role'] as String? ?? 'staff',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      companyId: json['company_id'] as String?,
      companyName: json['company_name'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'company_id': companyId,
      'company_name': companyName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Staff copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    String? companyId,
    String? companyName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get role display name in Vietnamese
  String get roleDisplayName {
    switch (role) {
      case 'ceo':
        return 'Giám đốc điều hành';
      case 'manager':
        return 'Quản lý';
      case 'shift_leader':
        return 'Trưởng ca';
      case 'staff':
        return 'Nhân viên';
      default:
        return role;
    }
  }

  /// Get status display name in Vietnamese
  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'Đang làm việc';
      case 'inactive':
        return 'Ngừng làm';
      case 'on_leave':
        return 'Nghỉ phép';
      default:
        return status;
    }
  }
}
