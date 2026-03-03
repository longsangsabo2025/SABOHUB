// Manufacturing Service - Supabase integration for Flutter
// Date: 2024-01-15

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/manufacturing_models.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_client.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId và companyId từ authProvider

class ManufacturingService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // ⚠️ Lưu companyId và employeeId từ caller thay vì dùng auth
  final String? companyId;
  final String? employeeId;
  
  ManufacturingService({this.companyId, this.employeeId});

  /// Helper method to get company ID with fallback to override
  String _getCompanyId(String? overrideCompanyId) {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    return cid;
  }

  // ===== SUPPLIERS =====
  Future<List<Supplier>> getSuppliers({
    String? category,
    bool? isActive,
    String? search,
    String? overrideCompanyId,
  }) async {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    
    var query = _client
        .from('manufacturing_suppliers')
        .select()
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (category != null) {
      query = query.eq('category', category);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,supplier_code.ilike.%$search%');
    }

    final response = await query.order('name');
    return (response as List).map((json) => Supplier.fromJson(json)).toList();
  }

  Future<Supplier> createSupplier(Supplier supplier, {String? overrideCompanyId}) async {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    
    final response = await _client.from('manufacturing_suppliers').insert({
      ...supplier.toJson(),
      'company_id': cid,
    }).select().single();

    return Supplier.fromJson(response);
  }

  Future<Supplier> updateSupplier(String id, Map<String, dynamic> updates) async {
    final response = await _client
        .from('manufacturing_suppliers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Supplier.fromJson(response);
  }

  Future<void> deleteSupplier(String id) async {
    await _client
        .from('manufacturing_suppliers')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ===== MATERIALS =====
  Future<List<ManufacturingMaterial>> getMaterials({
    String? categoryId,
    bool? isActive,
    String? search,
    bool? lowStock,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_materials')
        .select('*, category:manufacturing_material_categories(name)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,material_code.ilike.%$search%');
    }

    final response = await query.order('name');
    return (response as List).map((json) => ManufacturingMaterial.fromJson(json)).toList();
  }

  Future<ManufacturingMaterial> createMaterial(ManufacturingMaterial material, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    final response = await _client.from('manufacturing_materials').insert({
      ...material.toJson(),
      'company_id': cid,
    }).select().single();

    return ManufacturingMaterial.fromJson(response);
  }

  Future<MaterialInventory?> getMaterialInventory(String materialId, {String? warehouseId, String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_material_inventory')
        .select()
        .eq('company_id', cid)
        .eq('material_id', materialId);

    if (warehouseId != null) {
      query = query.eq('warehouse_id', warehouseId);
    }

    final response = await query.maybeSingle();
    return response != null ? MaterialInventory.fromJson(response) : null;
  }

  // ===== BOM =====
  Future<List<BOM>> getBOMs({String? productId, String? status, String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_bom')
        .select('*, product:odori_products(name, sku)')
        .eq('company_id', cid);

    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => BOM.fromJson(json)).toList();
  }

  Future<BOM> createBOM(BOM bom, {String? overrideCompanyId, String? overrideEmployeeId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    final eid = overrideEmployeeId ?? employeeId;
    
    final response = await _client.from('manufacturing_bom').insert({
      ...bom.toJson(),
      'company_id': cid,
      'created_by': eid,
    }).select().single();

    return BOM.fromJson(response);
  }

  Future<List<BOMItem>> getBOMItems(String bomId) async {
    final response = await _client
        .from('manufacturing_bom_items')
        .select('*, material:manufacturing_materials(material_code, name, unit)')
        .eq('bom_id', bomId)
        .order('sequence', ascending: true);

    return (response as List).map((json) => BOMItem.fromJson(json)).toList();
  }

  // ===== PURCHASE ORDERS =====
  Future<List<PurchaseOrder>> getPurchaseOrders({
    String? supplierId,
    String? status,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_purchase_orders')
        .select('*, supplier:manufacturing_suppliers(name)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (supplierId != null) {
      query = query.eq('supplier_id', supplierId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('order_date', ascending: false);
    return (response as List).map((json) => PurchaseOrder.fromJson(json)).toList();
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po, {String? overrideCompanyId, String? overrideEmployeeId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    final eid = overrideEmployeeId ?? employeeId;
    
    // Generate PO number via RPC
    final poNumber = await _client.rpc('generate_po_number', params: {
      'p_company_id': cid,
    });

    final response = await _client.from('manufacturing_purchase_orders').insert({
      ...po.toJson(),
      'company_id': cid,
      'po_number': poNumber,
      'created_by': eid,
    }).select().single();

    return PurchaseOrder.fromJson(response);
  }

  Future<List<PurchaseOrderItem>> getPOItems(String poId) async {
    final response = await _client
        .from('manufacturing_purchase_order_items')
        .select('*, material:manufacturing_materials(material_code, name, unit)')
        .eq('po_id', poId);

    return (response as List).map((json) => PurchaseOrderItem.fromJson(json)).toList();
  }

  // ===== PRODUCTION ORDERS =====
  Future<List<ProductionOrder>> getProductionOrders({
    String? productId,
    String? status,
    String? priority,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_production_orders')
        .select('*, product:odori_products(name, sku)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }

    final response = await query.order('planned_start_date', ascending: false);
    return (response as List).map((json) => ProductionOrder.fromJson(json)).toList();
  }

  Future<ProductionOrder> createProductionOrder(ProductionOrder po, {String? overrideCompanyId, String? overrideEmployeeId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    final eid = overrideEmployeeId ?? employeeId;
    
    // Generate production number via RPC
    final productionNumber = await _client.rpc('generate_production_number', params: {
      'p_company_id': cid,
    });

    final response = await _client.from('manufacturing_production_orders').insert({
      ...po.toJson(),
      'company_id': cid,
      'production_number': productionNumber,
      'created_by': eid,
    }).select().single();

    // Auto-create material requirements from BOM
    await _client.rpc('create_production_materials', params: {
      'p_production_id': response['id'],
    });

    return ProductionOrder.fromJson(response);
  }

  Future<ProductionOrder> updateProductionStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    
    if (status == 'in_progress') {
      updates['actual_start_date'] = DateTime.now().toIso8601String();
    } else if (status == 'completed') {
      updates['actual_end_date'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from('manufacturing_production_orders')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ProductionOrder.fromJson(response);
  }

  Future<List<ProductionOutput>> getProductionOutputs(String productionOrderId) async {
    final response = await _client
        .from('manufacturing_production_output')
        .select()
        .eq('production_order_id', productionOrderId)
        .order('output_date', ascending: false);

    return (response as List).map((json) => ProductionOutput.fromJson(json)).toList();
  }

  Future<ProductionOutput> recordOutput(ProductionOutput output, {String? overrideEmployeeId}) async {
    final eid = overrideEmployeeId ?? employeeId;
    
    final response = await _client.from('manufacturing_production_output').insert({
      ...output.toJson(),
      'recorded_by': eid,
    }).select().single();

    return ProductionOutput.fromJson(response);
  }

  // ===== PAYABLES =====
  Future<List<Payable>> getPayables({
    String? supplierId,
    String? status,
    bool? overdue,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    var query = _client
        .from('manufacturing_payables')
        .select('*, supplier:manufacturing_suppliers(name)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (supplierId != null) {
      query = query.eq('supplier_id', supplierId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (overdue == true) {
      query = query.eq('status', 'overdue');
    }

    final response = await query.order('due_date', ascending: true);
    return (response as List).map((json) => Payable.fromJson(json)).toList();
  }

  Future<Payable> createPayable(Payable payable, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);
    
    final response = await _client.from('manufacturing_payables').insert({
      ...payable.toJson(),
      'company_id': cid,
    }).select().single();

    return Payable.fromJson(response);
  }

  Future<PayablePayment> recordPayment(PayablePayment payment, {String? overrideEmployeeId}) async {
    final eid = overrideEmployeeId ?? employeeId;
    
    final response = await _client.from('manufacturing_payable_payments').insert({
      ...payment.toJson(),
      'created_by': eid,
    }).select().single();

    return PayablePayment.fromJson(response);
  }

  Future<List<PayablePayment>> getPayments(String payableId) async {
    final response = await _client
        .from('manufacturing_payable_payments')
        .select()
        .eq('payable_id', payableId)
        .order('payment_date', ascending: false);

    return (response as List).map((json) => PayablePayment.fromJson(json)).toList();
  }

  // ===== STATISTICS =====
  Future<Map<String, dynamic>> getSupplierStats() async {
    final suppliers = await getSuppliers();
    final total = suppliers.length;
    final active = suppliers.where((s) => s.isActive).length;

    return {
      'total': total,
      'active': active,
      'inactive': total - active,
    };
  }

  Future<Map<String, dynamic>> getPOStats() async {
    final orders = await getPurchaseOrders();
    final totalOrders = orders.length;
    final totalValue = orders.fold<double>(0, (sum, po) => sum + po.totalAmount);
    final pending = orders.where((po) => po.status == 'pending' || po.status == 'draft').length;
    final inProgress = orders.where((po) => po.status == 'ordered' || po.status == 'partial').length;
    final completed = orders.where((po) => po.status == 'received').length;

    return {
      'totalOrders': totalOrders,
      'totalValue': totalValue,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
    };
  }

  Future<Map<String, dynamic>> getProductionStats() async {
    final orders = await getProductionOrders();
    final total = orders.length;
    final inProgress = orders.where((po) => po.status == 'in_progress').length;
    final completed = orders.where((po) => po.status == 'completed').length;
    final urgent = orders.where((po) => po.priority == 'urgent' && po.status != 'completed').length;

    final totalPlanned = orders.fold<double>(0, (sum, po) => sum + po.plannedQuantity);
    final totalActual = orders.fold<double>(0, (sum, po) => sum + po.producedQuantity);
    final completionRate = totalPlanned > 0 ? (totalActual / totalPlanned) * 100 : 0.0;

    return {
      'totalOrders': total,
      'inProgress': inProgress,
      'completed': completed,
      'urgent': urgent,
      'completionRate': completionRate,
    };
  }

  Future<Map<String, dynamic>> getPayableStats() async {
    final payables = await getPayables();
    final total = payables.length;
    final totalOutstanding = payables.fold<double>(0, (sum, p) => sum + p.remainingAmount);
    final overdue = payables.where((p) => p.status == 'overdue').length;
    final paid = payables.where((p) => p.status == 'paid').length;

    return {
      'total': total,
      'totalOutstanding': totalOutstanding,
      'overdue': overdue,
      'paid': paid,
    };
  }
}
