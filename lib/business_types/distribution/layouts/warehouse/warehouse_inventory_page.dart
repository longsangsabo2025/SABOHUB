import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../pages/manager/inventory/warehouse_detail_page.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';

class WarehouseInventoryPage extends ConsumerStatefulWidget {
  const WarehouseInventoryPage({super.key});

  @override
  ConsumerState<WarehouseInventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<WarehouseInventoryPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _assignedWarehouse;

  @override
  void initState() {
    super.initState();
    _loadAssignedWarehouse();
  }

  Future<void> _loadAssignedWarehouse() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Query employee's warehouse_id directly from database
      final employeeData = await supabase
          .from('employees')
          .select('warehouse_id')
          .eq('id', userId)
          .maybeSingle();
      
      final warehouseId = employeeData?['warehouse_id'] as String?;
      
      if (warehouseId != null) {
        final warehouseData = await supabase
            .from('warehouses')
            .select('*')
            .eq('id', warehouseId)
            .single();
        
        setState(() {
          _assignedWarehouse = warehouseData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Failed to load assigned warehouse', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user has assigned warehouse, show WarehouseDetailPage directly
    if (_assignedWarehouse != null) {
      final type = _assignedWarehouse!['type'] ?? 'main';
      Color typeColor;
      String typeLabel;
      IconData typeIcon;
      
      switch (type) {
        case 'main':
          typeColor = Colors.blue;
          typeLabel = 'Kho chính';
          typeIcon = Icons.home_work;
          break;
        case 'transit':
          typeColor = Colors.orange;
          typeLabel = 'Trung chuyển';
          typeIcon = Icons.local_shipping;
          break;
        case 'vehicle':
          typeColor = Colors.green;
          typeLabel = 'Xe tải';
          typeIcon = Icons.local_shipping_outlined;
          break;
        case 'virtual':
          typeColor = Colors.purple;
          typeLabel = 'Ảo';
          typeIcon = Icons.cloud_outlined;
          break;
        default:
          typeColor = Colors.grey;
          typeLabel = type;
          typeIcon = Icons.warehouse;
      }

      return WarehouseDetailPage(
        warehouse: _assignedWarehouse!,
        typeColor: typeColor,
        typeLabel: typeLabel,
        typeIcon: typeIcon,
        isEmbedded: true,
      );
    }

    // If no assigned warehouse, show message
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa được phân công kho',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng liên hệ quản lý để được phân công',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
