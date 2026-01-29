import 'business_type.dart';

class Company {
  final String id;
  final String name;
  final BusinessType type;
  final String address;
  final int tableCount;
  final double monthlyRevenue;
  final int employeeCount;
  final String? phone;
  final String? email;
  final String? logo;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt; // Soft delete timestamp
  
  // Check-in location settings
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkInRadius; // in meters
  
  // Bank account for VietQR
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? bankBin;

  const Company({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.tableCount,
    required this.monthlyRevenue,
    required this.employeeCount,
    this.phone,
    this.email,
    this.logo,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInRadius,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.bankBin,
  });

  // Getter alias for businessType
  BusinessType get businessType => type;

  /// Create Company from Supabase JSON response
  factory Company.fromJson(Map<String, dynamic> json) {
    // Parse business type from string or default to billiards
    final typeStr = json['business_type'] as String? ?? 'billiards';
    BusinessType businessType;
    try {
      businessType = BusinessType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => BusinessType.billiards,
      );
    } catch (_) {
      businessType = BusinessType.billiards;
    }

    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      type: businessType,
      address: json['address'] as String? ?? '',
      // These fields will be calculated from other tables
      // Not stored directly in companies table anymore
      tableCount: 0, // Will be fetched separately
      monthlyRevenue: 0.0, // Will be calculated from revenue tables
      employeeCount: 0, // Will be fetched from users table
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logo: json['logo'] as String?,
      status: json['is_active'] == false ? 'inactive' : 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      checkInLatitude: json['check_in_latitude'] as double?,
      checkInLongitude: json['check_in_longitude'] as double?,
      checkInRadius: json['check_in_radius'] as double?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankBin: json['bank_bin'] as String?,
    );
  }

  /// Convert Company to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_type': type.toString().split('.').last,
      'address': address,
      'table_count': tableCount,
      'monthly_revenue': monthlyRevenue,
      'employee_count': employeeCount,
      'phone': phone,
      'email': email,
      'logo': logo,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Copy with method for immutable updates
  Company copyWith({
    String? id,
    String? name,
    BusinessType? type,
    String? address,
    int? tableCount,
    double? monthlyRevenue,
    int? employeeCount,
    String? phone,
    String? email,
    String? logo,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkInRadius,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? bankBin,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      tableCount: tableCount ?? this.tableCount,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      employeeCount: employeeCount ?? this.employeeCount,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInRadius: checkInRadius ?? this.checkInRadius,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankBin: bankBin ?? this.bankBin,
    );
  }
}
