import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/error_boundary.dart';
import '../pages/sales/journey_plan_page.dart';
import '../pages/sales/sales_activity_page.dart';

// Sub-pages extracted for maintainability
import 'sales/sales_dashboard_page.dart';
import 'sales/sales_orders_page.dart';
import 'sales/sales_customers_page.dart';

/// Distribution Sales Layout - Modern 2026 UI
/// Layout cho nhân viên Sales/ASM của công ty phân phối
/// Chức năng chính: Tạo đơn hàng, quản lý khách hàng, theo dõi đơn
///
/// Sub-files tổ chức trong layouts/sales/:
///   - sales_dashboard_page.dart     → Tổng quan & KPI
///   - sales_orders_page.dart        → Danh sách đơn hàng + action tạo đơn
///   - sales_customers_page.dart     → Quản lý khách hàng
///   - sales_activity_page.dart      → Timeline hoạt động sales
///   - sheets/
///       - sales_order_history_sheet.dart   → Lịch sử đơn hàng
///       - sales_create_order_form.dart     → Form tạo/sửa đơn hàng
///       - sales_customer_form_sheet.dart   → Form tạo/sửa khách hàng
class DistributionSalesLayout extends ConsumerStatefulWidget {
  const DistributionSalesLayout({super.key});

  @override
  ConsumerState<DistributionSalesLayout> createState() =>
      _DistributionSalesLayoutState();
}

class _DistributionSalesLayoutState
    extends ConsumerState<DistributionSalesLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SalesDashboardPage(),
    JourneyPlanPage(),
    SalesActivityPage(),
    SalesOrdersPage(),
    SalesCustomersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            height: 65,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.space_dashboard, color: Colors.orange.shade700),
                ),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.route, color: Colors.blue.shade700),
                ),
                label: 'Hành trình',
              ),
              NavigationDestination(
                icon: Icon(Icons.timeline_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.timeline, color: Colors.deepPurple.shade700),
                ),
                label: 'Hoạt động',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_shopping_cart_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: Colors.teal.shade700),
                ),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.people, color: Colors.indigo.shade700),
                ),
                label: 'Khách hàng',
              ),
            ],
          ),
        ),
      ),
    );
  }
}