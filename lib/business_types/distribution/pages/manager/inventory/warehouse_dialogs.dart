// Warehouse Dialog Operations - Reusable dialogs for warehouse management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;
import 'package:geocoding/geocoding.dart';
import '../../../models/odori_product.dart';
import '../../../../../providers/auth_provider.dart';
import 'inventory_constants.dart';

// ==================== WAREHOUSE VALIDATION ====================
/// Validates that a new warehouse is properly set up
Future<void> _validateWarehouseSetup(String warehouseId, String companyId) async {
  debugPrint('🔍 Validating warehouse setup for: $warehouseId');
  
  try {
    // 1. Verify warehouse record
    final warehouse = await supabase
        .from('warehouses')
        .select('id, name, is_primary, is_active')
        .eq('id', warehouseId)
        .single();
    
    debugPrint('✓ Warehouse record verified');
    
    // 2. Check is_primary
    if (warehouse['is_primary'] == null) {
      debugPrint('⚠️  WARNING: is_primary is NULL');
    } else {
      debugPrint('✓ is_primary = ${warehouse['is_primary']}');
    }
    
    // 3. Check is_active
    if (!warehouse['is_active']) {
      debugPrint('⚠️  WARNING: Warehouse is not active');
    } else {
      debugPrint('✓ Warehouse is active');
    }
    
    // 4. Test inventory queries work
    final inventoryTest = await supabase
        .from('inventory')
        .select('id')
        .eq('warehouse_id', warehouseId)
        .limit(1);
    
    debugPrint('✓ Inventory query works (${(inventoryTest as List).isEmpty ? 'empty' : 'has data'})');
    
    // 5. Test inventory_movements queries work
    final movementsTest = await supabase
        .from('inventory_movements')
        .select('id')
        .eq('warehouse_id', warehouseId)
        .limit(1);
    
    debugPrint('✓ Inventory movements query works (${(movementsTest as List).isEmpty ? 'empty' : 'has data'})');
    
    debugPrint('✅ Warehouse validation complete - all systems ready!');
    
  } catch (e) {
    debugPrint('❌ Validation error: $e');
    // Don't throw - just log. Warehouse is still created.
  }
}

/// Shows the add/edit warehouse bottom sheet
class WarehouseFormSheet {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    Map<String, dynamic>? warehouse, // null for add, non-null for edit
    required VoidCallback onSuccess,
  }) {
    final isEdit = warehouse != null;
    final nameController = TextEditingController(text: warehouse?['name'] ?? '');
    final codeController = TextEditingController(text: warehouse?['code'] ?? '');
    final streetNumberController = TextEditingController(text: warehouse?['street_number'] ?? '');
    final streetController = TextEditingController(text: warehouse?['street'] ?? '');
    String selectedType = warehouse?['type'] ?? 'main';
    bool isActive = warehouse?['is_active'] ?? true;

    // Vietnamese Address Selection
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];

    // Initialize to Ho Chi Minh City by default
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;

      if (isEdit) {
        // Try to match existing address
        final warehouseDistrict = warehouse['district'] ?? '';
        final warehouseWard = warehouse['ward'] ?? '';

        if (warehouseDistrict.isNotEmpty) {
          for (var d in districts) {
            if (d.name.contains(warehouseDistrict) ||
                warehouseDistrict.contains(d.name.replaceAll('Quận ', '').replaceAll('Huyện ', ''))) {
              selectedDistrict = d;
              wards = d.children;
              break;
            }
          }
        }

        if (warehouseWard.isNotEmpty && selectedDistrict != null) {
          for (var w in wards) {
            if (w.name.contains(warehouseWard) ||
                warehouseWard.contains(w.name.replaceAll('Phường ', '').replaceAll('Xã ', ''))) {
              selectedWard = w;
              break;
            }
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isEdit ? Icons.edit : Icons.add_business, color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Sửa thông tin kho' : 'Thêm kho mới',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isEdit ? 'Cập nhật thông tin kho' : 'Điền thông tin kho cần tạo',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên kho *',
                          hintText: 'VD: Kho Bình Thạnh',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã kho',
                          hintText: 'VD: KHO-BT-01',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Loại kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildTypeChip('main', 'Kho chính', Icons.home_work, Colors.blue, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('transit', 'Kho phụ', Icons.warehouse, Colors.orange, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('vehicle', 'Xe giao hàng', Icons.local_shipping, Colors.green, selectedType, (v) => setSheetState(() => selectedType = v)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Address Section Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Địa chỉ kho',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.teal.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Địa chỉ chính xác giúp tài xế xác định điểm xuất phát',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Street Number + Street Name
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: streetNumberController,
                              decoration: InputDecoration(
                                labelText: 'Số nhà',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: streetController,
                              decoration: InputDecoration(
                                labelText: 'Tên đường',
                                hintText: 'VD: Lê Văn Thọ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // District Dropdown
                      DropdownButtonFormField<dvhcvn.Level2>(
                        value: selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'Quận/Huyện *',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: districts.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedDistrict = value;
                            selectedWard = null;
                            wards = value?.children ?? [];
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Ward Dropdown
                      DropdownButtonFormField<dvhcvn.Level3>(
                        value: selectedWard,
                        decoration: InputDecoration(
                          labelText: 'Phường/Xã *',
                          prefixIcon: const Icon(Icons.house),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: wards.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) => setSheetState(() => selectedWard = value),
                      ),
                      const SizedBox(height: 20),

                      // Active Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.check_circle : Icons.block, color: isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? Colors.green.shade700 : Colors.red.shade700),
                                  ),
                                  Text(
                                    isActive ? 'Kho này có thể nhận và xuất hàng' : 'Kho này không còn hoạt động',
                                    style: TextStyle(fontSize: 12, color: isActive ? Colors.green.shade600 : Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setSheetState(() => isActive = v),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên kho')),
                        );
                        return;
                      }

                      try {
                        // Build full address from structured fields
                        final addressParts = <String>[];
                        if (streetNumberController.text.trim().isNotEmpty) {
                          addressParts.add(streetNumberController.text.trim());
                        }
                        if (streetController.text.trim().isNotEmpty) {
                          addressParts.add(streetController.text.trim());
                        }
                        if (selectedWard != null) {
                          addressParts.add(selectedWard!.name);
                        }
                        if (selectedDistrict != null) {
                          addressParts.add(selectedDistrict!.name);
                        }
                        if (selectedCity != null) {
                          addressParts.add(selectedCity!.name);
                        }
                        final fullAddress = addressParts.join(', ');

                        // Auto geocode from address
                        double? lat;
                        double? lng;
                        if (fullAddress.isNotEmpty) {
                          try {
                            final locations = await locationFromAddress(fullAddress);
                            if (locations.isNotEmpty) {
                              lat = locations.first.latitude;
                              lng = locations.first.longitude;
                            }
                          } catch (e) {
                            debugPrint('Geocoding failed: $e');
                          }
                        }

                        final data = {
                          'name': nameController.text,
                          'code': codeController.text.isEmpty ? null : codeController.text,
                          'type': selectedType,
                          'street_number': streetNumberController.text.trim().isEmpty ? null : streetNumberController.text.trim(),
                          'street': streetController.text.trim().isEmpty ? null : streetController.text.trim(),
                          'ward': selectedWard?.name.replaceAll('Phường ', '').replaceAll('Xã ', '').replaceAll('Thị trấn ', ''),
                          'district': selectedDistrict?.name.replaceAll('Quận ', '').replaceAll('Huyện ', '').replaceAll('Thành phố ', '').replaceAll('Thị xã ', ''),
                          'city': selectedCity?.name.replaceAll('Thành phố ', '').replaceAll('Tỉnh ', ''),
                          'address': fullAddress.isEmpty ? null : fullAddress,
                          'lat': lat,
                          'lng': lng,
                          'is_active': isActive,
                        };

                        if (isEdit) {
                          await supabase.from('warehouses').update(data).eq('id', warehouse['id']);
                        } else {
                          final companyId = ref.read(authProvider).user?.companyId ?? '';
                          data['company_id'] = companyId;
                          
                          // ⚠️ CRITICAL: Check if this is the first warehouse for company
                          final existingWarehouses = await supabase
                              .from('warehouses')
                              .select('id')
                              .eq('company_id', companyId);
                          
                          final isFirstWarehouse = (existingWarehouses as List).isEmpty;
                          
                          // If first warehouse: MUST set is_primary = true
                          if (isFirstWarehouse) {
                            data['is_primary'] = true;
                            debugPrint('⭐ First warehouse for company - automatically setting is_primary = TRUE');
                          } else {
                            // For secondary warehouses: default to false if not explicitly set
                            data['is_primary'] = data['is_primary'] ?? false;
                            debugPrint('📦 Secondary warehouse - is_primary = ${data['is_primary']}');
                          }
                          
                          // Ensure is_active defaults to true
                          data['is_active'] = data['is_active'] ?? true;
                          
                          // Create warehouse
                          final response = await supabase.from('warehouses').insert(data).select();
                          final newWarehouseId = response[0]['id'];
                          
                          debugPrint('✅ Created warehouse: $newWarehouseId');
                          
                          // Validate warehouse setup
                          await _validateWarehouseSetup(newWarehouseId, companyId);
                        }

                        if (context.mounted) Navigator.pop(context);
                        onSuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Đã cập nhật kho' : 'Đã thêm kho mới'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEdit ? 'Cập nhật kho' : 'Thêm kho',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTypeChip(String value, String label, IconData icon, Color color, String selected, Function(String) onSelect) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

/// Stock In Dialog
class StockInSheet {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> warehouse,
    required List<OdoriProduct> products,
    required VoidCallback onSuccess,
  }) {
    final warehouseId = warehouse['id'];
    final warehouseName = warehouse['name'] ?? 'Kho';
    String? selectedProductId;
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_box, color: Colors.green),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nhập hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Vào kho: $warehouseName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn sản phẩm *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedProductId,
                        decoration: InputDecoration(
                          hintText: 'Chọn sản phẩm',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: products.map((p) => DropdownMenuItem<String>(
                          value: p.id,
                          child: Text('${p.name} (${p.sku})'),
                        )).toList(),
                        onChanged: (v) => setSheetState(() => selectedProductId = v),
                      ),
                      const SizedBox(height: 16),
                      const Text('Số lượng nhập *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Nhập số lượng',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'VD: Nhập hàng từ NCC ABC',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedProductId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng chọn sản phẩm'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            final qty = int.tryParse(quantityController.text) ?? 0;
                            if (qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Số lượng phải > 0'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            try {
                              final companyId = ref.read(authProvider).user?.companyId ?? '';
                              final userId = ref.read(authProvider).user?.id ?? '';

                              // Only create movement - trigger will handle inventory update
                              await supabase.from('inventory_movements').insert({
                                'company_id': companyId,
                                'warehouse_id': warehouseId,
                                'product_id': selectedProductId,
                                'type': 'in',
                                'quantity': qty,
                                'notes': noteController.text.isNotEmpty ? noteController.text : 'Nhập hàng vào kho',
                                'created_by': userId,
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã nhập hàng thành công'), backgroundColor: Colors.green),
                                );
                                onSuccess();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Nhập hàng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stock Out Dialog  
class StockOutSheet {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> warehouse,
    required Future<List<Map<String, dynamic>>> Function(String) getWarehouseStock,
    required VoidCallback onSuccess,
  }) {
    final warehouseId = warehouse['id'];
    final warehouseName = warehouse['name'] ?? 'Kho';
    String? selectedProductId;
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    int currentStock = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.outbox, color: Colors.orange),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Xuất hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Từ kho: $warehouseName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: getWarehouseStock(warehouseId),
                  builder: (context, snapshot) {
                    final stocks = snapshot.data ?? [];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chọn sản phẩm *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedProductId,
                            decoration: InputDecoration(
                              hintText: 'Chọn sản phẩm trong kho',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: stocks.map((s) {
                              final p = s['products'] as Map<String, dynamic>? ?? {};
                              return DropdownMenuItem<String>(
                                value: p['id'],
                                child: Text('${p['name']} (Tồn: ${s['quantity']})'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              final selected = stocks.firstWhere((s) => (s['products']?['id']) == v, orElse: () => {});
                              setSheetState(() {
                                selectedProductId = v;
                                currentStock = selected['quantity'] ?? 0;
                              });
                            },
                          ),
                          if (currentStock > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Tồn kho hiện tại: $currentStock', style: const TextStyle(color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text('Số lượng xuất *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Nhập số lượng xuất',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'VD: Xuất hàng cho đơn #123',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (selectedProductId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng chọn sản phẩm'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                final qty = int.tryParse(quantityController.text) ?? 0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Số lượng phải > 0'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                if (qty > currentStock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Không đủ hàng (Tồn: $currentStock)'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                try {
                                  final companyId = ref.read(authProvider).user?.companyId ?? '';
                                  final userId = ref.read(authProvider).user?.id ?? '';

                                  // 1. Update inventory (decrease stock)
                                  final existingInventory = await supabase
                                      .from('inventory')
                                      .select('id, quantity')
                                      .eq('company_id', companyId)
                                      .eq('warehouse_id', warehouseId)
                                      .eq('product_id', selectedProductId!)
                                      .maybeSingle();

                                  if (existingInventory != null) {
                                    final newQty = (existingInventory['quantity'] ?? 0) - qty;
                                    await supabase
                                        .from('inventory')
                                        .update({
                                          'quantity': newQty > 0 ? newQty : 0,
                                          'updated_at': DateTime.now().toIso8601String()
                                        })
                                        .eq('id', existingInventory['id']);
                                  }

                                  // 2. Create movement record
                                  await supabase.from('inventory_movements').insert({
                                    'company_id': companyId,
                                    'warehouse_id': warehouseId,
                                    'product_id': selectedProductId,
                                    'type': 'out',
                                    'quantity': qty,
                                    'before_quantity': currentStock,
                                    'after_quantity': currentStock - qty,
                                    'notes': noteController.text.isNotEmpty ? noteController.text : 'Xuất hàng khỏi kho',
                                    'created_by': userId,
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xuất hàng thành công'), backgroundColor: Colors.green),
                                    );
                                    onSuccess();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Xuất hàng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transfer Stock Dialog
class TransferStockSheet {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> fromWarehouse,
    required List<Map<String, dynamic>> allWarehouses,
    required Future<List<Map<String, dynamic>>> Function(String) getWarehouseStock,
    required VoidCallback onSuccess,
  }) {
    final fromWarehouseId = fromWarehouse['id'];
    final fromWarehouseName = fromWarehouse['name'] ?? 'Kho';
    String? selectedProductId;
    String? toWarehouseId;
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    int currentStock = 0;

    // Get other warehouses
    final otherWarehouses = allWarehouses.where((w) => w['id'] != fromWarehouseId && (w['is_active'] ?? true)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.swap_horiz, color: Colors.purple),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chuyển kho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Từ: $fromWarehouseName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: getWarehouseStock(fromWarehouseId),
                  builder: (context, snapshot) {
                    final stocks = snapshot.data ?? [];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kho đích *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: toWarehouseId,
                            decoration: InputDecoration(
                              hintText: 'Chọn kho nhận',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: otherWarehouses.map((w) => DropdownMenuItem<String>(
                              value: w['id'],
                              child: Text(w['name'] ?? 'Kho'),
                            )).toList(),
                            onChanged: (v) => setSheetState(() => toWarehouseId = v),
                          ),
                          const SizedBox(height: 16),
                          const Text('Chọn sản phẩm *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedProductId,
                            decoration: InputDecoration(
                              hintText: 'Chọn sản phẩm cần chuyển',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: stocks.map((s) {
                              final p = s['products'] as Map<String, dynamic>? ?? {};
                              return DropdownMenuItem<String>(
                                value: p['id'],
                                child: Text('${p['name']} (Tồn: ${s['quantity']})'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              final selected = stocks.firstWhere((s) => (s['products']?['id']) == v, orElse: () => {});
                              setSheetState(() {
                                selectedProductId = v;
                                currentStock = selected['quantity'] ?? 0;
                              });
                            },
                          ),
                          if (currentStock > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Tồn kho hiện tại: $currentStock', style: const TextStyle(color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text('Số lượng chuyển *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Nhập số lượng',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'VD: Chuyển hàng bổ sung',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (toWarehouseId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng chọn kho đích'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                if (selectedProductId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng chọn sản phẩm'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                final qty = int.tryParse(quantityController.text) ?? 0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Số lượng phải > 0'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                if (qty > currentStock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Không đủ hàng (Tồn: $currentStock)'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                try {
                                  final companyId = ref.read(authProvider).user?.companyId ?? '';
                                  final userId = ref.read(authProvider).user?.id ?? '';
                                  final toWarehouse = allWarehouses.firstWhere((w) => w['id'] == toWarehouseId, orElse: () => {});
                                  final toWarehouseName = toWarehouse['name'] ?? 'kho đích';
                                  final transferNote = noteController.text.isNotEmpty
                                      ? noteController.text
                                      : 'Chuyển từ $fromWarehouseName sang $toWarehouseName';

                                  // Create 2 separate movement records for better tracking
                                  // 1. Transfer-out from source warehouse
                                  await supabase.from('inventory_movements').insert({
                                    'company_id': companyId,
                                    'warehouse_id': fromWarehouseId,
                                    'product_id': selectedProductId,
                                    'type': 'transfer-out',
                                    'quantity': qty,
                                    'destination_warehouse_id': toWarehouseId,
                                    'before_quantity': currentStock,
                                    'after_quantity': currentStock - qty,
                                    'notes': 'Chuyển sang $toWarehouseName${noteController.text.isNotEmpty ? " - ${noteController.text}" : ""}',
                                    'created_by': userId,
                                  });

                                  // 2. Transfer-in to destination warehouse
                                  // Get current stock in destination
                                  final destInventory = await supabase
                                      .from('inventory')
                                      .select('quantity')
                                      .eq('warehouse_id', toWarehouseId!)
                                      .eq('product_id', selectedProductId!)
                                      .maybeSingle();
                                  
                                  final destBeforeQty = destInventory?['quantity'] ?? 0;
                                  
                                  await supabase.from('inventory_movements').insert({
                                    'company_id': companyId,
                                    'warehouse_id': toWarehouseId,
                                    'product_id': selectedProductId,
                                    'type': 'transfer-in',
                                    'quantity': qty,
                                    'before_quantity': destBeforeQty,
                                    'after_quantity': destBeforeQty + qty,
                                    'notes': 'Nhận từ $fromWarehouseName${noteController.text.isNotEmpty ? " - ${noteController.text}" : ""}',
                                    'created_by': userId,
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã chuyển kho thành công'), backgroundColor: Colors.green),
                                    );
                                    onSuccess();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Chuyển kho'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
