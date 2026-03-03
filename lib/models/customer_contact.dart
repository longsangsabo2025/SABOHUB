/// Customer Contact Model - For multiple contacts per customer
/// Each contact can be linked to a specific address/branch
class CustomerContact {
  final String id;
  final String customerId;
  final String? companyId;
  final String? addressId; // Optional: link to specific address/branch
  final String name;
  final String? position; // Chức vụ: Chủ cửa hàng, Kế toán, Thủ kho, etc.
  final String? phone;
  final String? email;
  final bool isPrimary;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined data
  final String? addressName; // Name of linked address if any

  const CustomerContact({
    required this.id,
    required this.customerId,
    this.companyId,
    this.addressId,
    required this.name,
    this.position,
    this.phone,
    this.email,
    this.isPrimary = false,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.addressName,
  });

  /// Get display title (name + position)
  String get displayTitle {
    if (position != null && position!.isNotEmpty) {
      return '$name - $position';
    }
    return name;
  }

  /// Get contact summary for display
  String get summary {
    final parts = <String>[];
    if (position != null && position!.isNotEmpty) parts.add(position!);
    if (phone != null && phone!.isNotEmpty) parts.add(phone!);
    return parts.isNotEmpty ? parts.join(' • ') : 'Chưa có thông tin';
  }

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    return CustomerContact(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      companyId: json['company_id'] as String?,
      addressId: json['address_id'] as String?,
      name: json['name'] as String,
      position: json['position'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      addressName: json['customer_addresses'] != null
          ? json['customer_addresses']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'company_id': companyId,
      'address_id': addressId,
      'name': name,
      'position': position,
      'phone': phone,
      'email': email,
      'is_primary': isPrimary,
      'is_active': isActive,
      'notes': notes,
    };
  }

  /// Create insert payload (without id)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  CustomerContact copyWith({
    String? id,
    String? customerId,
    String? companyId,
    String? addressId,
    String? name,
    String? position,
    String? phone,
    String? email,
    bool? isPrimary,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? addressName,
  }) {
    return CustomerContact(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      companyId: companyId ?? this.companyId,
      addressId: addressId ?? this.addressId,
      name: name ?? this.name,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addressName: addressName ?? this.addressName,
    );
  }

  @override
  String toString() => 'CustomerContact($name: $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerContact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Common contact positions for Vietnamese B2B
class ContactPositions {
  static const List<String> common = [
    'Chủ cửa hàng',
    'Quản lý',
    'Kế toán',
    'Thủ kho',
    'Nhân viên bán hàng',
    'Nhân viên đặt hàng',
    'Nhân viên nhận hàng',
    'Khác',
  ];
}
