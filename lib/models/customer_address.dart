/// Customer Address Model - For multiple delivery addresses per customer
class CustomerAddress {
  final String id;
  final String customerId;
  final String companyId;
  final String name; // Tên cơ sở/chi nhánh: "Kho chính", "Chi nhánh Q7", etc.
  final String address;
  final String? streetNumber;
  final String? street;
  final String? ward;
  final String? district;
  final String? city;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? contactPerson;
  final String? notes;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerAddress({
    required this.id,
    required this.customerId,
    required this.companyId,
    required this.name,
    required this.address,
    this.streetNumber,
    this.street,
    this.ward,
    this.district,
    this.city,
    this.lat,
    this.lng,
    this.phone,
    this.contactPerson,
    this.notes,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get full address string
  String get fullAddress {
    final parts = <String>[];
    if (streetNumber != null && streetNumber!.isNotEmpty) {
      parts.add(streetNumber!);
    }
    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    if (ward != null && ward!.isNotEmpty) {
      parts.add(ward!);
    }
    if (district != null && district!.isNotEmpty) {
      parts.add(district!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return address;
  }

  /// Get display name with address preview
  String get displayName => '$name - ${fullAddress.length > 50 ? '${fullAddress.substring(0, 50)}...' : fullAddress}';

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      streetNumber: json['street_number'] as String?,
      street: json['street'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      contactPerson: json['contact_person'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'company_id': companyId,
      'name': name,
      'address': address,
      'street_number': streetNumber,
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'contact_person': contactPerson,
      'notes': notes,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  /// Create insert payload (without id)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  CustomerAddress copyWith({
    String? id,
    String? customerId,
    String? companyId,
    String? name,
    String? address,
    String? streetNumber,
    String? street,
    String? ward,
    String? district,
    String? city,
    double? lat,
    double? lng,
    String? phone,
    String? contactPerson,
    String? notes,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      address: address ?? this.address,
      streetNumber: streetNumber ?? this.streetNumber,
      street: street ?? this.street,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      contactPerson: contactPerson ?? this.contactPerson,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CustomerAddress($name: $fullAddress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAddress &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
