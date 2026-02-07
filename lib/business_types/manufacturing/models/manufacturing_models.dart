// Manufacturing Models for Flutter - Plain Dart (no freezed)

// ===== SUPPLIER =====
class Supplier {
  final String id;
  final String companyId;
  final String supplierCode;
  final String name;
  final String? taxCode;
  final String? phone;
  final String? email;
  final String? contactPerson;
  final String? address;
  final String? city;
  final String? district;
  final int paymentTerms;
  final double creditLimit;
  final String currency;
  final String? category;
  final bool isActive;
  final int? rating;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    required this.id,
    required this.companyId,
    required this.supplierCode,
    required this.name,
    this.taxCode,
    this.phone,
    this.email,
    this.contactPerson,
    this.address,
    this.city,
    this.district,
    this.paymentTerms = 30,
    this.creditLimit = 0,
    this.currency = 'VND',
    this.category,
    this.isActive = true,
    this.rating,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      supplierCode: json['supplier_code'] as String,
      name: json['name'] as String,
      taxCode: json['tax_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      contactPerson: json['contact_person'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      paymentTerms: json['payment_terms'] as int? ?? 30,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'supplier_code': supplierCode,
    'name': name,
    'tax_code': taxCode,
    'phone': phone,
    'email': email,
    'contact_person': contactPerson,
    'address': address,
    'city': city,
    'district': district,
    'payment_terms': paymentTerms,
    'credit_limit': creditLimit,
    'currency': currency,
    'category': category,
    'is_active': isActive,
    'rating': rating,
    'notes': notes,
  };
}

// ===== MATERIAL =====
class ManufacturingMaterial {
  final String id;
  final String companyId;
  final String materialCode;
  final String name;
  final String? description;
  final String? categoryId;
  final String unit;
  final double unitCost;
  final double minStock;
  final double? maxStock;
  final String? defaultSupplierId;
  final int leadTimeDays;
  final String? storageLocation;
  final int? shelfLifeDays;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ManufacturingMaterial({
    required this.id,
    required this.companyId,
    required this.materialCode,
    required this.name,
    this.description,
    this.categoryId,
    required this.unit,
    this.unitCost = 0,
    this.minStock = 0,
    this.maxStock,
    this.defaultSupplierId,
    this.leadTimeDays = 7,
    this.storageLocation,
    this.shelfLifeDays,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ManufacturingMaterial.fromJson(Map<String, dynamic> json) {
    return ManufacturingMaterial(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      materialCode: json['material_code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String? ?? 'unit',
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0,
      maxStock: (json['max_stock'] as num?)?.toDouble(),
      defaultSupplierId: json['default_supplier_id'] as String?,
      leadTimeDays: json['lead_time_days'] as int? ?? 7,
      storageLocation: json['storage_location'] as String?,
      shelfLifeDays: json['shelf_life_days'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'material_code': materialCode,
    'name': name,
    'description': description,
    'category_id': categoryId,
    'unit': unit,
    'unit_cost': unitCost,
    'min_stock': minStock,
    'max_stock': maxStock,
    'default_supplier_id': defaultSupplierId,
    'lead_time_days': leadTimeDays,
    'storage_location': storageLocation,
    'shelf_life_days': shelfLifeDays,
    'is_active': isActive,
  };
}

// ===== MATERIAL INVENTORY =====
class MaterialInventory {
  final String id;
  final String companyId;
  final String materialId;
  final String? warehouseId;
  final double quantity;
  final double reservedQuantity;
  final double availableQuantity;
  final DateTime? lastReceivedAt;
  final DateTime? lastIssuedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaterialInventory({
    required this.id,
    required this.companyId,
    required this.materialId,
    this.warehouseId,
    this.quantity = 0,
    this.reservedQuantity = 0,
    this.availableQuantity = 0,
    this.lastReceivedAt,
    this.lastIssuedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialInventory.fromJson(Map<String, dynamic> json) {
    return MaterialInventory(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      materialId: json['material_id'] as String,
      warehouseId: json['warehouse_id'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      reservedQuantity: (json['reserved_quantity'] as num?)?.toDouble() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toDouble() ?? 0,
      lastReceivedAt: json['last_received_at'] != null 
          ? DateTime.parse(json['last_received_at'] as String) 
          : null,
      lastIssuedAt: json['last_issued_at'] != null 
          ? DateTime.parse(json['last_issued_at'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'material_id': materialId,
    'warehouse_id': warehouseId,
    'quantity': quantity,
    'reserved_quantity': reservedQuantity,
    'available_quantity': availableQuantity,
  };
}

// ===== BOM (Bill of Materials) =====
class BOM {
  final String id;
  final String companyId;
  final String productId;
  final String bomCode;
  final String? name;
  final String version;
  final String? description;
  final double outputQuantity;
  final String? outputUnit;
  final int? productionTimeMinutes;
  final int setupTimeMinutes;
  final String status;
  final bool isDefault;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;

  BOM({
    required this.id,
    required this.companyId,
    required this.productId,
    required this.bomCode,
    this.name,
    this.version = '1.0',
    this.description,
    this.outputQuantity = 1,
    this.outputUnit,
    this.productionTimeMinutes,
    this.setupTimeMinutes = 0,
    this.status = 'draft',
    this.isDefault = false,
    this.effectiveFrom,
    this.effectiveTo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
  });

  factory BOM.fromJson(Map<String, dynamic> json) {
    return BOM(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      productId: json['product_id'] as String,
      bomCode: json['bom_code'] as String,
      name: json['name'] as String?,
      version: json['version'] as String? ?? '1.0',
      description: json['description'] as String?,
      outputQuantity: (json['output_quantity'] as num?)?.toDouble() ?? 1,
      outputUnit: json['output_unit'] as String?,
      productionTimeMinutes: json['production_time_minutes'] as int?,
      setupTimeMinutes: json['setup_time_minutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      isDefault: json['is_default'] as bool? ?? false,
      effectiveFrom: json['effective_from'] != null 
          ? DateTime.parse(json['effective_from'] as String) 
          : null,
      effectiveTo: json['effective_to'] != null 
          ? DateTime.parse(json['effective_to'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'product_id': productId,
    'bom_code': bomCode,
    'name': name,
    'version': version,
    'description': description,
    'output_quantity': outputQuantity,
    'output_unit': outputUnit,
    'production_time_minutes': productionTimeMinutes,
    'setup_time_minutes': setupTimeMinutes,
    'status': status,
    'is_default': isDefault,
    'created_by': createdBy,
    'approved_by': approvedBy,
  };
}

// ===== BOM Item =====
class BOMItem {
  final String id;
  final String bomId;
  final String materialId;
  final double quantity;
  final String? unit;
  final double wastePercent;
  final String? substituteMaterialId;
  final int sequence;
  final String? notes;
  final DateTime? createdAt;

  BOMItem({
    required this.id,
    required this.bomId,
    required this.materialId,
    required this.quantity,
    this.unit,
    this.wastePercent = 0,
    this.substituteMaterialId,
    this.sequence = 0,
    this.notes,
    this.createdAt,
  });

  factory BOMItem.fromJson(Map<String, dynamic> json) {
    return BOMItem(
      id: json['id'] as String,
      bomId: json['bom_id'] as String,
      materialId: json['material_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      wastePercent: (json['waste_percent'] as num?)?.toDouble() ?? 0,
      substituteMaterialId: json['substitute_material_id'] as String?,
      sequence: json['sequence'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bom_id': bomId,
    'material_id': materialId,
    'quantity': quantity,
    'unit': unit,
    'waste_percent': wastePercent,
    'substitute_material_id': substituteMaterialId,
    'sequence': sequence,
    'notes': notes,
  };
}

// ===== PURCHASE ORDER =====
class PurchaseOrder {
  final String id;
  final String companyId;
  final String poNumber;
  final String supplierId;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String status;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final int? paymentTerms;
  final String paymentStatus;
  final String? shippingAddress;
  final String? notes;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    required this.id,
    required this.companyId,
    required this.poNumber,
    required this.supplierId,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    this.status = 'draft',
    this.subtotal = 0,
    this.taxPercent = 10,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.paymentTerms,
    this.paymentStatus = 'unpaid',
    this.shippingAddress,
    this.notes,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      poNumber: json['po_number'] as String,
      supplierId: json['supplier_id'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDate: json['expected_date'] != null 
          ? DateTime.parse(json['expected_date'] as String) 
          : null,
      receivedDate: json['received_date'] != null 
          ? DateTime.parse(json['received_date'] as String) 
          : null,
      status: json['status'] as String? ?? 'draft',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 10,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paymentTerms: json['payment_terms'] as int?,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'po_number': poNumber,
    'supplier_id': supplierId,
    'order_date': orderDate.toIso8601String(),
    'expected_date': expectedDate?.toIso8601String(),
    'status': status,
    'subtotal': subtotal,
    'tax_percent': taxPercent,
    'tax_amount': taxAmount,
    'discount_amount': discountAmount,
    'total_amount': totalAmount,
    'payment_terms': paymentTerms,
    'payment_status': paymentStatus,
    'shipping_address': shippingAddress,
    'notes': notes,
    'created_by': createdBy,
    'approved_by': approvedBy,
  };
}

// ===== PURCHASE ORDER ITEM =====
class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String materialId;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final double receivedQuantity;
  final String? notes;
  final DateTime? createdAt;

  PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.materialId,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.receivedQuantity = 0,
    this.notes,
    this.createdAt,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as String,
      purchaseOrderId: json['purchase_order_id'] as String,
      materialId: json['material_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      receivedQuantity: (json['received_quantity'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'purchase_order_id': purchaseOrderId,
    'material_id': materialId,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'received_quantity': receivedQuantity,
    'notes': notes,
  };
}

// ===== PRODUCTION ORDER =====
class ProductionOrder {
  final String id;
  final String companyId;
  final String orderNumber;
  final String productId;
  final String? bomId;
  final int plannedQuantity;
  final int producedQuantity;
  final String unit;
  final DateTime plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final String status;
  final String priority;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductionOrder({
    required this.id,
    required this.companyId,
    required this.orderNumber,
    required this.productId,
    this.bomId,
    required this.plannedQuantity,
    this.producedQuantity = 0,
    this.unit = 'unit',
    required this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.status = 'draft',
    this.priority = 'normal',
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductionOrder.fromJson(Map<String, dynamic> json) {
    return ProductionOrder(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      orderNumber: json['order_number'] as String,
      productId: json['product_id'] as String,
      bomId: json['bom_id'] as String?,
      plannedQuantity: json['planned_quantity'] as int? ?? 0,
      producedQuantity: json['produced_quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'unit',
      plannedStartDate: DateTime.parse(json['planned_start_date'] as String),
      plannedEndDate: json['planned_end_date'] != null 
          ? DateTime.parse(json['planned_end_date'] as String) 
          : null,
      actualStartDate: json['actual_start_date'] != null 
          ? DateTime.parse(json['actual_start_date'] as String) 
          : null,
      actualEndDate: json['actual_end_date'] != null 
          ? DateTime.parse(json['actual_end_date'] as String) 
          : null,
      status: json['status'] as String? ?? 'draft',
      priority: json['priority'] as String? ?? 'normal',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'order_number': orderNumber,
    'product_id': productId,
    'bom_id': bomId,
    'planned_quantity': plannedQuantity,
    'produced_quantity': producedQuantity,
    'unit': unit,
    'planned_start_date': plannedStartDate.toIso8601String(),
    'planned_end_date': plannedEndDate?.toIso8601String(),
    'actual_start_date': actualStartDate?.toIso8601String(),
    'actual_end_date': actualEndDate?.toIso8601String(),
    'status': status,
    'priority': priority,
    'notes': notes,
    'created_by': createdBy,
  };
}

// ===== PRODUCTION OUTPUT =====
class ProductionOutput {
  final String id;
  final String productionOrderId;
  final int quantity;
  final int passedQuantity;
  final int defectQuantity;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  ProductionOutput({
    required this.id,
    required this.productionOrderId,
    required this.quantity,
    this.passedQuantity = 0,
    this.defectQuantity = 0,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory ProductionOutput.fromJson(Map<String, dynamic> json) {
    return ProductionOutput(
      id: json['id'] as String,
      productionOrderId: json['production_order_id'] as String,
      quantity: json['quantity'] as int,
      passedQuantity: json['passed_quantity'] as int? ?? 0,
      defectQuantity: json['defect_quantity'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'production_order_id': productionOrderId,
    'quantity': quantity,
    'passed_quantity': passedQuantity,
    'defect_quantity': defectQuantity,
    'notes': notes,
    'created_by': createdBy,
  };
}

// ===== PAYABLE =====
class Payable {
  final String id;
  final String companyId;
  final String supplierId;
  final String? purchaseOrderId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payable({
    required this.id,
    required this.companyId,
    required this.supplierId,
    this.purchaseOrderId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Payable.fromJson(Map<String, dynamic> json) {
    return Payable(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      supplierId: json['supplier_id'] as String,
      purchaseOrderId: json['purchase_order_id'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'supplier_id': supplierId,
    'purchase_order_id': purchaseOrderId,
    'invoice_number': invoiceNumber,
    'invoice_date': invoiceDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'remaining_amount': remainingAmount,
    'status': status,
    'notes': notes,
  };
}

// ===== PAYABLE PAYMENT =====
class PayablePayment {
  final String id;
  final String payableId;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  PayablePayment({
    required this.id,
    required this.payableId,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory PayablePayment.fromJson(Map<String, dynamic> json) {
    return PayablePayment(
      id: json['id'] as String,
      payableId: json['payable_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      referenceNumber: json['reference_number'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payable_id': payableId,
    'amount': amount,
    'payment_method': paymentMethod,
    'reference_number': referenceNumber,
    'payment_date': paymentDate.toIso8601String(),
    'notes': notes,
    'created_by': createdBy,
  };
}
