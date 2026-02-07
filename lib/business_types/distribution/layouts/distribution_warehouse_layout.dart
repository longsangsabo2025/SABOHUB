import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'warehouse/warehouse_dashboard_page.dart';
import 'warehouse/warehouse_picking_page.dart';
import 'warehouse/warehouse_packing_page.dart';
import 'warehouse/warehouse_inventory_page.dart';

/// Distribution Warehouse Layout - Modern 2026 UI
/// Layout cho nhân viên Kho của công ty phân phối
/// Handles: Dashboard, Picking, Packing, Inventory
class DistributionWarehouseLayout extends ConsumerStatefulWidget {
  const DistributionWarehouseLayout({super.key});

  @override
  ConsumerState<DistributionWarehouseLayout> createState() =>
      _DistributionWarehouseLayoutState();
}

class _DistributionWarehouseLayoutState
    extends ConsumerState<DistributionWarehouseLayout> {
  int _selectedIndex = 0;

  void _goToPackingTab() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const WarehouseDashboardPage(),
          WarehousePickingPage(onPickingCompleted: _goToPackingTab),
          const WarehousePackingPage(),
          const WarehouseInventoryPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined,
                  color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.space_dashboard, color: Colors.teal.shade700),
              ),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined,
                  color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.assignment, color: Colors.orange.shade700),
              ),
              label: 'Nhận đơn',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined,
                  color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.inventory_2, color: Colors.green.shade700),
              ),
              label: 'Đóng gói',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined,
                  color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.warehouse, color: Colors.blue.shade700),
              ),
              label: 'Tồn kho',
            ),
          ],
        ),
      ),
    );
  }
}
