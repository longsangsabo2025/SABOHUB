/// Odori B2B Customer Model - Matches actual database schema
class OdoriCustomer {
  final String id;
  final String companyId;
  final String? branchId;
  final String code; // DB uses 'code' not 'customer_code'
  final String name;
  final String? type; // 'direct', 'distributor', 'agent' - DB uses 'type' not 'customer_type'
  final String? phone;
  final String? phone2;
  final String? email;
  final String? address;
  final String? city;
  final String? district;
  final String? ward;
  final String? streetNumber;
  final String? street;
  final String? route;
  final double? lat; // DB uses 'lat' not 'latitude'
  final double? lng; // DB uses 'lng' not 'longitude'
  final String? taxCode;
  final String? contactPerson;
  final int paymentTerms; // DB uses 'payment_terms' not 'payment_term_days'
  final double creditLimit;
  final String? category;
  final String? channel; // 'horeca', 'retail', 'wholesale'
  final List<String>? tags;
  final String? assignedSaleId; // DB uses 'assigned_sale_id' not 'assigned_employee_id'
  final String? assignedSaleName;
  final String status; // 'active', 'inactive', 'blocked'
  final DateTime? lastOrderDate;
  final DateTime? lastVisitDate;
  final String? purchaseFrequency;
  final String? actionRequired;
  final DateTime? deadline;
  final String? notes;
  final String? customerFeedback;
  final String? customerTypeCsv;
  final String? productLaundry;
  final String? productBleach;
  final String? productSoftener;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const OdoriCustomer({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.code,
    required this.name,
    this.type,
    this.phone,
    this.phone2,
    this.email,
    this.address,
    this.city,
    this.district,
    this.ward,
    this.streetNumber,
    this.street,
    this.route,
    this.lat,
    this.lng,
    this.taxCode,
    this.contactPerson,
    this.paymentTerms = 30,
    this.creditLimit = 0,
    this.category,
    this.channel,
    this.tags,
    this.assignedSaleId,
    this.assignedSaleName,
    required this.status,
    this.lastOrderDate,
    this.lastVisitDate,
    this.purchaseFrequency,
    this.actionRequired,
    this.deadline,
    this.notes,
    this.customerFeedback,
    this.customerTypeCsv,
    this.productLaundry,
    this.productBleach,
    this.productSoftener,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Full address combining all components
  String get fullAddress {
    final parts = <String>[];
    if (streetNumber != null && streetNumber!.isNotEmpty) parts.add(streetNumber!);
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  /// Check if customer has location data
  bool get hasLocation => lat != null && lng != null;

  factory OdoriCustomer.fromJson(Map<String, dynamic> json) {
    return OdoriCustomer(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String,
      type: json['type'] as String?,
      phone: json['phone'] as String?,
      phone2: json['phone2'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      streetNumber: json['street_number'] as String?,
      street: json['street'] as String?,
      route: json['route'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      taxCode: json['tax_code'] as String?,
      contactPerson: json['contact_person'] as String?,
      paymentTerms: (json['payment_terms'] as num?)?.toInt() ?? 30,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      channel: json['channel'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      assignedSaleId: json['assigned_sale_id'] as String?,
      assignedSaleName: json['employees']?['full_name'] as String?,
      status: json['status'] as String? ?? 'active',
      lastOrderDate: json['last_order_date'] != null 
          ? DateTime.parse(json['last_order_date'] as String) 
          : null,
      lastVisitDate: json['last_visit_date'] != null 
          ? DateTime.parse(json['last_visit_date'] as String) 
          : null,
      purchaseFrequency: json['purchase_frequency'] as String?,
      actionRequired: json['action_required'] as String?,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : null,
      notes: json['notes'] as String?,
      customerFeedback: json['customer_feedback'] as String?,
      customerTypeCsv: json['customer_type_csv'] as String?,
      productLaundry: json['product_laundry'] as String?,
      productBleach: json['product_bleach'] as String?,
      productSoftener: json['product_softener'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'code': code,
      'name': name,
      'type': type,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'address': address,
      'city': city,
      'district': district,
      'ward': ward,
      'street_number': streetNumber,
      'street': street,
      'route': route,
      'lat': lat,
      'lng': lng,
      'tax_code': taxCode,
      'contact_person': contactPerson,
      'payment_terms': paymentTerms,
      'credit_limit': creditLimit,
      'category': category,
      'channel': channel,
      'tags': tags,
      'assigned_sale_id': assignedSaleId,
      'status': status,
      'purchase_frequency': purchaseFrequency,
      'action_required': actionRequired,
      'deadline': deadline?.toIso8601String(),
      'notes': notes,
      'customer_feedback': customerFeedback,
      'customer_type_csv': customerTypeCsv,
      'product_laundry': productLaundry,
      'product_bleach': productBleach,
      'product_softener': productSoftener,
    };
  }

  OdoriCustomer copyWith({
    String? id,
    String? companyId,
    String? branchId,
    String? code,
    String? name,
    String? type,
    String? phone,
    String? phone2,
    String? email,
    String? address,
    String? city,
    String? district,
    String? ward,
    String? streetNumber,
    String? street,
    String? route,
    double? lat,
    double? lng,
    String? taxCode,
    String? contactPerson,
    int? paymentTerms,
    double? creditLimit,
    String? category,
    String? channel,
    List<String>? tags,
    String? assignedSaleId,
    String? assignedSaleName,
    String? status,
    DateTime? lastOrderDate,
    DateTime? lastVisitDate,
    String? purchaseFrequency,
    String? actionRequired,
    DateTime? deadline,
    String? notes,
    String? customerFeedback,
    String? customerTypeCsv,
    String? productLaundry,
    String? productBleach,
    String? productSoftener,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return OdoriCustomer(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      streetNumber: streetNumber ?? this.streetNumber,
      street: street ?? this.street,
      route: route ?? this.route,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      taxCode: taxCode ?? this.taxCode,
      contactPerson: contactPerson ?? this.contactPerson,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditLimit: creditLimit ?? this.creditLimit,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      tags: tags ?? this.tags,
      assignedSaleId: assignedSaleId ?? this.assignedSaleId,
      assignedSaleName: assignedSaleName ?? this.assignedSaleName,
      status: status ?? this.status,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      purchaseFrequency: purchaseFrequency ?? this.purchaseFrequency,
      actionRequired: actionRequired ?? this.actionRequired,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      customerFeedback: customerFeedback ?? this.customerFeedback,
      customerTypeCsv: customerTypeCsv ?? this.customerTypeCsv,
      productLaundry: productLaundry ?? this.productLaundry,
      productBleach: productBleach ?? this.productBleach,
      productSoftener: productSoftener ?? this.productSoftener,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
