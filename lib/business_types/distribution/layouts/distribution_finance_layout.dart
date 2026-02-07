import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/finance/finance_pages.dart';
import '../../../widgets/error_boundary.dart';

/// Distribution Finance Layout - Modern 2026 UI
/// Layout cho nhân viên Kế toán/Tài chính của công ty phân phối
/// Chức năng chính: Quản lý công nợ, theo dõi thanh toán
class DistributionFinanceLayout extends ConsumerStatefulWidget {
  const DistributionFinanceLayout({super.key});

  @override
  ConsumerState<DistributionFinanceLayout> createState() =>
      _DistributionFinanceLayoutState();
}

class _DistributionFinanceLayoutState
    extends ConsumerState<DistributionFinanceLayout> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    if (index >= 0 && index <= 4) {
      setState(() => _currentIndex = index);
    }
  }

  List<Widget> get _pages => [
        FinanceDashboardPage(onNavigate: _navigateToTab),
        const OrdersSummaryPage(),
        const InvoicesPage(),
        const AccountsReceivablePage(),
        const PaymentsPage(),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
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
                icon: Icon(Icons.shopping_bag_outlined,
                    color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_bag, color: Colors.indigo.shade700),
                ),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined,
                    color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: Colors.blue.shade700),
                ),
                label: 'Hóa đơn',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet,
                      color: Colors.orange.shade700),
                ),
                label: 'Công nợ',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.payments, color: Colors.green.shade700),
                ),
                label: 'Thu tiền',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
