import 'package:intl/intl.dart';

class TokenWallet {
  final String id;
  final String employeeId;
  final String companyId;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final double totalWithdrawn;
  final String? walletAddress; // future on-chain address
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? employeeName;
  final String? employeeAvatar;

  const TokenWallet({
    required this.id,
    required this.employeeId,
    required this.companyId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.totalWithdrawn = 0,
    this.walletAddress,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
    this.employeeAvatar,
  });

  factory TokenWallet.fromJson(Map<String, dynamic> json) {
    return TokenWallet(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      companyId: json['company_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
      walletAddress: json['wallet_address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
      employeeAvatar: json['employee_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'company_id': companyId,
      'balance': balance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'total_withdrawn': totalWithdrawn,
      'wallet_address': walletAddress,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TokenWallet copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    double? balance,
    double? totalEarned,
    double? totalSpent,
    double? totalWithdrawn,
    String? walletAddress,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? employeeName,
    String? employeeAvatar,
  }) {
    return TokenWallet(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      walletAddress: walletAddress ?? this.walletAddress,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeName: employeeName ?? this.employeeName,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
    );
  }

  /// Balance formatted as integer string with comma separators (e.g. "1,234")
  String get formattedBalance {
    return NumberFormat('#,##0').format(balance.toInt());
  }

  /// Available balance = balance (reserved for future hold logic)
  double get availableBalance => balance;

  @override
  String toString() => 'TokenWallet(id: $id, employee: $employeeId, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
