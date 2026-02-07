/// Odori B2B Product Model - Matches actual database schema
class OdoriProduct {
  final String id;
  final String companyId;
  final String? categoryId;
  final String? categoryName;
  final String sku;
  final String? barcode;
  final String name;
  final String? description;
  final String? brand;
  final String unit;
  final double costPrice;
  final double sellingPrice; // DB uses 'selling_price' not 'base_price'
  final double? wholesalePrice;
  final int? minWholesaleQty;
  final bool trackInventory;
  final int? minStock;
  final int? maxStock;
  final int? reorderPoint;
  final int? reorderQuantity;
  final double? weight;
  final String? weightUnit;
  final String status; // DB uses 'status' not 'is_active'
  final String? imageUrl;
  final List<String>? images;
  final Map<String, dynamic>? attributes;
  final List<String>? tags;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const OdoriProduct({
    required this.id,
    required this.companyId,
    this.categoryId,
    this.categoryName,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.brand,
    required this.unit,
    this.costPrice = 0,
    required this.sellingPrice,
    this.wholesalePrice,
    this.minWholesaleQty,
    this.trackInventory = true,
    this.minStock,
    this.maxStock,
    this.reorderPoint,
    this.reorderQuantity,
    this.weight,
    this.weightUnit,
    this.status = 'active',
    this.imageUrl,
    this.images,
    this.attributes,
    this.tags,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Profit margin percentage
  double get margin => sellingPrice > 0 
      ? ((sellingPrice - costPrice) / sellingPrice * 100) 
      : 0;
  
  /// Check if product is active
  bool get isActive => status == 'active';
  
  /// Check if product needs reordering
  bool get needsReorder => reorderPoint != null && minStock != null;

  factory OdoriProduct.fromJson(Map<String, dynamic> json) {
    return OdoriProduct(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['product_categories']?['name'] as String?,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String? ?? 'cái',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (json['wholesale_price'] as num?)?.toDouble(),
      minWholesaleQty: (json['min_wholesale_qty'] as num?)?.toInt(),
      trackInventory: json['track_inventory'] as bool? ?? true,
      minStock: (json['min_stock'] as num?)?.toInt(),
      maxStock: (json['max_stock'] as num?)?.toInt(),
      reorderPoint: (json['reorder_point'] as num?)?.toInt(),
      reorderQuantity: (json['reorder_quantity'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String?,
      status: json['status'] as String? ?? 'active',
      imageUrl: json['image_url'] as String?,
      images: json['images'] != null ? List<String>.from(json['images'] as List) : null,
      attributes: json['attributes'] as Map<String, dynamic>?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
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
      'category_id': categoryId,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'brand': brand,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'min_wholesale_qty': minWholesaleQty,
      'track_inventory': trackInventory,
      'min_stock': minStock,
      'max_stock': maxStock,
      'reorder_point': reorderPoint,
      'reorder_quantity': reorderQuantity,
      'weight': weight,
      'weight_unit': weightUnit,
      'status': status,
      'image_url': imageUrl,
      'images': images,
      'attributes': attributes,
      'tags': tags,
    };
  }

  OdoriProduct copyWith({
    String? id,
    String? companyId,
    String? categoryId,
    String? categoryName,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    String? brand,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    double? wholesalePrice,
    int? minWholesaleQty,
    bool? trackInventory,
    int? minStock,
    int? maxStock,
    int? reorderPoint,
    int? reorderQuantity,
    double? weight,
    String? weightUnit,
    String? status,
    String? imageUrl,
    List<String>? images,
    Map<String, dynamic>? attributes,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return OdoriProduct(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minWholesaleQty: minWholesaleQty ?? this.minWholesaleQty,
      trackInventory: trackInventory ?? this.trackInventory,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      attributes: attributes ?? this.attributes,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

/// Product Category Model
class OdoriProductCategory {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const OdoriProductCategory({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory OdoriProductCategory.fromJson(Map<String, dynamic> json) {
    return OdoriProductCategory(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
