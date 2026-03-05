/// Shareholder model - Cổ đông công ty
class Shareholder {
  final String id;
  final String companyId;
  final String shareholderName;
  final double cashInvested;
  final double ownershipPercentage;
  final double depreciation;
  final int year;
  final String? notes;
  final String? employeeId; // Link to employees table
  final DateTime? createdAt;

  Shareholder({
    required this.id,
    required this.companyId,
    required this.shareholderName,
    required this.cashInvested,
    required this.ownershipPercentage,
    this.depreciation = 0,
    required this.year,
    this.notes,
    this.employeeId,
    this.createdAt,
  });

  factory Shareholder.fromJson(Map<String, dynamic> json) {
    return Shareholder(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      shareholderName: json['shareholder_name'] ?? '',
      cashInvested: (json['cash_invested'] ?? 0).toDouble(),
      ownershipPercentage: (json['ownership_percentage'] ?? 0).toDouble(),
      depreciation: (json['depreciation'] ?? 0).toDouble(),
      year: json['year'] ?? DateTime.now().year,
      notes: json['notes'],
      employeeId: json['employee_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'shareholder_name': shareholderName,
      'cash_invested': cashInvested,
      'ownership_percentage': ownershipPercentage,
      'depreciation': depreciation,
      'year': year,
      'notes': notes,
      'employee_id': employeeId,
    };
  }
}
