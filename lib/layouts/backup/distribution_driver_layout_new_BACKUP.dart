import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import refactored pages
import '../pages/driver/driver_route_page.dart';
import '../pages/driver/driver_deliveries_page.dart';
import '../pages/driver/driver_journey_map_page.dart';
import '../pages/driver/driver_history_page.dart';

/// Distribution Driver Layout - Modern 2026 UI
/// Layout cho Tài xế giao hàng của công ty phân phối
/// Handles: Delivery pickup, Route navigation, Delivery confirmation
class DistributionDriverLayoutNew extends ConsumerStatefulWidget {
  const DistributionDriverLayoutNew({super.key});

  @override
  ConsumerState<DistributionDriverLayoutNew> createState() => _DistributionDriverLayoutNewState();
}

class _DistributionDriverLayoutNewState extends ConsumerState<DistributionDriverLayoutNew> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DriverRoutePage(),
          DriverDeliveriesPage(),
          DriverJourneyMapPage(),
          DriverHistoryPage(),
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
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.space_dashboard, color: Colors.blue.shade700),
              ),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.local_shipping, color: Colors.orange.shade700),
              ),
              label: 'Giao hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.map, color: Colors.teal.shade700),
              ),
              label: 'Hành trình',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.history, color: Colors.green.shade700),
              ),
              label: 'Lịch sử',
            ),
          ],
        ),
      ),
    );
  }
}
