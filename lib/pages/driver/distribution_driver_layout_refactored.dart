import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_route_page.dart';
import 'driver_deliveries_page.dart';
import 'driver_journey_map_page.dart';
import 'driver_history_page.dart';

/// Main Distribution Driver Layout - Refactored version
/// 
/// This layout manages 4 main pages for the driver interface:
/// - Trang chủ: Dashboard with daily stats and current deliveries
/// - Giao hàng: Delivery management with 4 tabs (Chờ nhận, Chờ kho, Đang giao, Đã giao)
/// - Hành trình: Journey map with GPS tracking and route optimization
/// - Lịch sử: Delivery history with date filters
class DistributionDriverLayout extends ConsumerStatefulWidget {
  const DistributionDriverLayout({super.key});

  @override
  ConsumerState<DistributionDriverLayout> createState() => _DistributionDriverLayoutState();
}

class _DistributionDriverLayoutState extends ConsumerState<DistributionDriverLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DriverRoutePage(),       // Trang chủ
    DriverDeliveriesPage(),  // Giao hàng
    DriverJourneyMapPage(),  // Hành trình
    DriverHistoryPage(),     // Lịch sử
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Trang chủ'),
                _buildNavItem(1, Icons.local_shipping_outlined, Icons.local_shipping, 'Giao hàng'),
                _buildNavItem(2, Icons.map_outlined, Icons.map, 'Hành trình'),
                _buildNavItem(3, Icons.history_outlined, Icons.history, 'Lịch sử'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? Colors.orange : Colors.grey.shade500,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey.shade500,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
