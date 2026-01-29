import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/warehouse/warehouse_picking_page.dart';
import '../pages/warehouse/warehouse_stock_view_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/realtime_notification_widgets.dart';

/// Warehouse Staff Main Layout
/// Focused interface for warehouse operations
class WarehouseMainLayout extends ConsumerStatefulWidget {
  const WarehouseMainLayout({super.key});

  @override
  ConsumerState<WarehouseMainLayout> createState() => _WarehouseMainLayoutState();
}

class _WarehouseMainLayoutState extends ConsumerState<WarehouseMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    WarehousePickingPage(),
    WarehouseStockViewPage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Soạn hàng',
    ),
    NavigationDestination(
      icon: Icon(Icons.warehouse_outlined),
      selectedIcon: Icon(Icons.warehouse),
      label: 'Tồn kho',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Nhân viên kho';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warehouse, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Nhân viên kho',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Pending orders badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.pending_actions_outlined),
                onPressed: () {
                  // Go to picking page with pending filter
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const RealtimeNotificationBell(),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quét mã QR sản phẩm')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
