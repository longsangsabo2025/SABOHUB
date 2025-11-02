class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // Manager, Shift Leader, Staff
  final String companyId;
  final bool isActive;
  final DateTime joinDate;
  final String? address;
  final double? salary;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.companyId,
    this.isActive = true,
    required this.joinDate,
    this.address,
    this.salary,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? companyId,
    bool? isActive,
    DateTime? joinDate,
    String? address,
    double? salary,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      joinDate: joinDate ?? this.joinDate,
      address: address ?? this.address,
      salary: salary ?? this.salary,
    );
  }
}
