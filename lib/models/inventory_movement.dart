/// Model for inventory movements (manual stock in/out/adjustment)
class InventoryMovement {
  final String id;
  final String companyId;
  final String? warehouseId;
  final String productId;
  final String type; // 'in', 'out', 'adjustment', 'transfer'
  final String? reason;
  final int quantity;
  final int beforeQuantity;
  final int afterQuantity;
  final double? unitCost;
  final String? referenceType;
  final String? referenceId;
  final String? referenceNumber;
  final String? destinationWarehouseId;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const InventoryMovement({
    required this.id,
    required this.companyId,
    this.warehouseId,
    required this.productId,
    required this.type,
    this.reason,
    required this.quantity,
    this.beforeQuantity = 0,
    this.afterQuantity = 0,
    this.unitCost,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.destinationWarehouseId,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  bool get isIn => type == 'in';
  bool get isOut => type == 'out';
  bool get isAdjustment => type == 'adjustment';

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      warehouseId: json['warehouse_id'] as String?,
      productId: json['product_id'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      beforeQuantity: (json['before_quantity'] as num?)?.toInt() ?? 0,
      afterQuantity: (json['after_quantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceNumber: json['reference_number'] as String?,
      destinationWarehouseId: json['destination_warehouse_id'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'warehouse_id': warehouseId,
      'product_id': productId,
      'type': type,
      'reason': reason,
      'quantity': quantity,
      'before_quantity': beforeQuantity,
      'after_quantity': afterQuantity,
      'unit_cost': unitCost,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'reference_number': referenceNumber,
      'destination_warehouse_id': destinationWarehouseId,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}
