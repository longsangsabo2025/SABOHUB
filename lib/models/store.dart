class Store {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? ownerId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const Store({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.ownerId,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Create Store from Supabase JSON response
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      ownerId: json['owner_id'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  /// Convert Store to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'owner_id': ownerId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Copy with modifications
  Store copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? ownerId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'Store(id: $id, name: $name, address: $address, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
