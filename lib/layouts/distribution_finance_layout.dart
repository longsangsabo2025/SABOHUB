import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/bug_report_dialog.dart';
import '../widgets/realtime_notification_widgets.dart';

import '../providers/auth_provider.dart';
import '../widgets/error_boundary.dart';
import '../utils/app_logger.dart';
import '../pages/staff/staff_profile_page.dart';

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

  final List<Widget> _pages = const [
    _FinanceDashboardPage(),
    _InvoicesPage(),      // Tab xuất hóa đơn
    _AccountsReceivablePage(),
    _PaymentsPage(),
    _FinanceProfilePage(),
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
              NavigationDestination(
                icon:
                    Icon(Icons.person_outline, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: Colors.purple.shade700),
                ),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FINANCE DASHBOARD PAGE - Modern 2026 UI
// ============================================================================
class _FinanceDashboardPage extends ConsumerStatefulWidget {
  const _FinanceDashboardPage();

  @override
  ConsumerState<_FinanceDashboardPage> createState() =>
      _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<_FinanceDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Get total receivables from customers
      final customersData = await supabase
          .from('customers')
          .select('id, name, total_debt, credit_limit')
          .eq('company_id', companyId)
          .gt('total_debt', 0);

      double totalReceivable = 0;
      double overdueAmount = 0;
      int overdueCustomers = 0;

      for (var customer in customersData) {
        final debt = (customer['total_debt'] ?? 0).toDouble();
        totalReceivable += debt;
        // Giả định nợ quá hạn nếu vượt credit limit
        final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
        if (debt > creditLimit && creditLimit > 0) {
          overdueAmount += (debt - creditLimit);
          overdueCustomers++;
        }
      }

      // Get payments this month
      final paymentsData = await supabase
          .from('customer_payments')
          .select('id, amount, payment_date, customers(name)')
          .eq('company_id', companyId)
          .gte('payment_date', startOfMonth.toIso8601String())
          .order('payment_date', ascending: false);

      double paidThisMonth = 0;
      for (var payment in paymentsData) {
        paidThisMonth += (payment['amount'] ?? 0).toDouble();
      }

      // Recent payments
      final recentPayments = await supabase
          .from('customer_payments')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .order('payment_date', ascending: false)
          .limit(5);

      setState(() {
        _stats = {
          'totalReceivable': totalReceivable,
          'overdueAmount': overdueAmount,
          'overdueCustomers': overdueCustomers,
          'paidThisMonth': paidThisMonth,
          'paymentsCount': paymentsData.length,
          'customersWithDebt': customersData.length,
        };
        _recentPayments = List<Map<String, dynamic>>.from(recentPayments);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load finance dashboard', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    // Modern Header
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal.shade700,
                              Colors.teal.shade500
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (user?.name ?? 'F')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào, ${user?.name ?? 'Kế toán'}! 💰',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user?.companyName ?? 'Công ty',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const RealtimeNotificationBell(
                                      iconColor: Colors.white),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Total receivable card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tổng công nợ phải thu',
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${_stats['customersWithDebt'] ?? 0} KH',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currencyFormat.format(
                                          _stats['totalReceivable'] ?? 0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Stats Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Quá hạn',
                                currencyFormat
                                    .format(_stats['overdueAmount'] ?? 0),
                                '${_stats['overdueCustomers'] ?? 0} KH',
                                Icons.warning_amber,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Đã thu tháng này',
                                currencyFormat
                                    .format(_stats['paidThisMonth'] ?? 0),
                                '${_stats['paymentsCount'] ?? 0} giao dịch',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flash_on,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text('Thao tác nhanh',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAction(
                                    'Ghi nhận\nthanh toán',
                                    Icons.add_card,
                                    Colors.green,
                                    () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Xem\ncông nợ',
                                    Icons.list_alt,
                                    Colors.orange,
                                    () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Báo cáo\ntài chính',
                                    Icons.analytics,
                                    Colors.purple,
                                    () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recent Payments
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text('Thanh toán gần đây',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text('Xem tất cả')),
                          ],
                        ),
                      ),
                    ),

                    if (_recentPayments.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inbox,
                                      size: 40, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                Text('Chưa có thanh toán nào',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final payment = _recentPayments[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16,
                                  index == _recentPayments.length - 1 ? 100 : 8),
                              child: _buildPaymentCard(payment),
                            );
                          },
                          childCount: _recentPayments.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final customer = payment['customers'] as Map<String, dynamic>?;
    final amount = (payment['amount'] ?? 0).toDouble();
    final paymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer?['name'] ?? 'Khách hàng',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (paymentDate != null)
                  Text(DateFormat('dd/MM/yyyy').format(paymentDate),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('+${currencyFormat.format(amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCOUNTS RECEIVABLE PAGE - Modern UI
// ============================================================================
class _AccountsReceivablePage extends ConsumerStatefulWidget {
  const _AccountsReceivablePage();

  @override
  ConsumerState<_AccountsReceivablePage> createState() =>
      _AccountsReceivablePageState();
}

class _AccountsReceivablePageState
    extends ConsumerState<_AccountsReceivablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _customersWithDebt = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('customers')
          .select('id, name, code, phone, address, total_debt, credit_limit')
          .eq('company_id', companyId)
          .gt('total_debt', 0)
          .order('total_debt', ascending: false);

      setState(() {
        _customersWithDebt = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers with debt', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchController.text.toLowerCase();
    var list = _customersWithDebt;

    if (query.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toLowerCase();
        final phone = (c['phone'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    return list;
  }

  List<Map<String, dynamic>> get _overdueCustomers {
    return _filteredCustomers.where((c) {
      final debt = (c['total_debt'] ?? 0).toDouble();
      final creditLimit = (c['credit_limit'] ?? 0).toDouble();
      return debt > creditLimit && creditLimit > 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Công nợ phải thu',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadCustomers();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tất cả'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_filteredCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700)),
                            ),
                          ],
                        )),
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Quá hạn'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_overdueCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red.shade700)),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomerList(_filteredCustomers),
                        _buildCustomerList(_overdueCustomers),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<Map<String, dynamic>> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_circle, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Không có khách hàng nào',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) => _buildDebtCard(customers[index]),
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> customer) {
    final debt = (customer['total_debt'] ?? 0).toDouble();
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    final isOverdue = debt > creditLimit && creditLimit > 0;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue ? Border.all(color: Colors.red.shade200, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
                  child: Text(
                    (customer['name'] ?? 'K')[0].toUpperCase(),
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${customer['phone'] ?? ''} • ${customer['code'] ?? ''}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text('Quá hạn',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Công nợ',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text(currencyFormat.format(debt),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Colors.red.shade700
                                : Colors.orange.shade700)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(customer),
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Thu tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> customer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final debt = (customer['total_debt'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ghi nhận thanh toán',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Customer info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: Text((customer['name'] ?? 'K')[0].toUpperCase(),
                          style: TextStyle(color: Colors.orange.shade700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer['name'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Công nợ: ${currencyFormat.format(debt)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền thanh toán *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: '₫',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: const Icon(Icons.note),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ')));
                      return;
                    }

                    try {
                      final authState = ref.read(authProvider);
                      final companyId = authState.user?.companyId;
                      if (companyId == null) return;

                      final supabase = Supabase.instance.client;
                      await supabase.from('customer_payments').insert({
                        'company_id': companyId,
                        'customer_id': customer['id'],
                        'amount': amount,
                        'payment_date': DateTime.now().toIso8601String(),
                        'note': noteController.text,
                      });

                      // Update customer debt
                      await supabase.from('customers').update({
                        'total_debt': debt - amount,
                      }).eq('id', customer['id']);

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('Đã ghi nhận ${currencyFormat.format(amount)}'),
                          ]),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('❌ Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('XÁC NHẬN THANH TOÁN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAYMENTS PAGE - Modern UI
// ============================================================================
class _PaymentsPage extends ConsumerStatefulWidget {
  const _PaymentsPage();

  @override
  ConsumerState<_PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<_PaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var queryBuilder = supabase
          .from('customer_payments')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId);

      if (_dateFilter != null) {
        queryBuilder = queryBuilder
            .gte('payment_date', _dateFilter!.start.toIso8601String())
            .lte('payment_date', _dateFilter!.end.toIso8601String());
      }

      final data = await queryBuilder
          .order('payment_date', ascending: false)
          .limit(100);

      setState(() {
        _payments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load payments', e);
      setState(() => _isLoading = false);
    }
  }

  double get _totalAmount {
    return _payments.fold(
        0.0, (sum, p) => sum + (p['amount'] ?? 0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Lịch sử thanh toán',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadPayments();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date filter
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateFilter,
                      );
                      if (picked != null) {
                        setState(() => _dateFilter = picked);
                        _loadPayments();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month,
                              color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dateFilter != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_dateFilter!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateFilter!.end)}'
                                  : 'Chọn khoảng thời gian',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          if (_dateFilter != null)
                            IconButton(
                              icon:
                                  Icon(Icons.clear, color: Colors.grey.shade600),
                              onPressed: () {
                                setState(() => _dateFilter = null);
                                _loadPayments();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tổng đã thu',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(_totalAmount),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_payments.length} giao dịch',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payments list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.receipt_long,
                                    size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text('Chưa có thanh toán nào',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPayments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _payments.length,
                            itemBuilder: (context, index) =>
                                _buildPaymentCard(_payments[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final customer = payment['customers'] as Map<String, dynamic>?;
    final amount = (payment['amount'] ?? 0).toDouble();
    final paymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments, color: Colors.green.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer?['name'] ?? 'Khách hàng',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (paymentDate != null)
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(paymentDate),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${currencyFormat.format(amount)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 15)),
              if (payment['note'] != null && payment['note'].isNotEmpty)
                Text(payment['note'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FINANCE PROFILE PAGE - Modern UI
// ============================================================================
class _FinanceProfilePage extends ConsumerWidget {
  const _FinanceProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'F')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Kế toán',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (user?.role ?? 'finance').toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Info cards
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.business,
                      label: 'Công ty',
                      value: user?.companyName ?? 'N/A',
                      color: Colors.blue,
                    ),
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'N/A',
                      color: Colors.orange,
                    ),
                    _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Điện thoại',
                      value: user?.phone ?? 'N/A',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.settings,
                        label: 'Cài đặt',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                const Scaffold(body: StaffProfilePage()),
                          ));
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildMenuItem(
                        icon: Icons.bug_report,
                        label: 'Báo cáo lỗi',
                        color: Colors.red.shade400,
                        onTap: () => BugReportDialog.show(context),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Đăng xuất',
                        color: Colors.red,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('Đăng xuất'),
                              content:
                                  const Text('Bạn có chắc chắn muốn đăng xuất?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy')),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
      onTap: onTap,
    );
  }
}

// ============================================================================
// INVOICES PAGE - Xuất hóa đơn theo mẫu Odori
// ============================================================================
class _InvoicesPage extends ConsumerStatefulWidget {
  const _InvoicesPage();

  @override
  ConsumerState<_InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<_InvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<Map<String, dynamic>> _printedInvoices = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // Đơn chờ xuất hóa đơn (đang chờ giao hoặc đang giao)
      final pending = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .inFilter('delivery_status', ['awaiting_pickup', 'delivering'])
          .isFilter('invoice_number', null)
          .order('created_at', ascending: false);

      // Đơn đã giao - chờ xuất hóa đơn VAT
      final delivered = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'delivered')
          .order('created_at', ascending: false)
          .limit(50);

      // Đơn đã xuất hóa đơn
      final printed = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .not('invoice_number', 'is', null)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _pendingOrders = List<Map<String, dynamic>>.from(pending);
        _deliveredOrders = List<Map<String, dynamic>>.from(delivered);
        _printedInvoices = List<Map<String, dynamic>>.from(printed);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading orders for invoices', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Xuất hóa đơn',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade700,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_pendingOrders.length}'),
                isLabelVisible: _pendingOrders.isNotEmpty,
                child: const Icon(Icons.local_shipping_outlined),
              ),
              text: 'Chờ giao',
            ),
            Tab(
              icon: Badge(
                label: Text('${_deliveredOrders.length}'),
                isLabelVisible: _deliveredOrders.isNotEmpty,
                child: const Icon(Icons.check_circle_outline),
              ),
              text: 'Đã giao',
            ),
            const Tab(
              icon: Icon(Icons.receipt_outlined),
              text: 'Đã xuất HĐ',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_pendingOrders, 'pending'),
                _buildOrdersList(_deliveredOrders, 'delivered'),
                _buildPrintedInvoicesList(),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              type == 'pending' ? 'Không có đơn chờ xuất hóa đơn' : 'Không có đơn đã giao',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, type);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final orderNumber = order['order_number'] ?? order['id']?.toString().substring(0, 8) ?? '';
    final createdAt = order['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['created_at']))
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Text(createdAt, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer info
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer?['name'] ?? 'Khách lẻ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (customer?['address'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer!['address'],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const Divider(height: 24),
            
            // Items summary
            Text(
              '${items.length} sản phẩm',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${currencyFormat.format(total)} đ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetail(order),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _printInvoice(order),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('In hóa đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintedInvoicesList() {
    if (_printedInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có hóa đơn nào được xuất',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _printedInvoices.length,
        itemBuilder: (context, index) {
          final order = _printedInvoices[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final invoiceNumber = order['invoice_number'] ?? '';
          final total = (order['total'] as num?)?.toDouble() ?? 0;
          final createdAt = order['created_at'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['created_at']))
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt, color: Colors.green.shade700),
              ),
              title: Text('HĐ: $invoiceNumber', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${customer?['name'] ?? 'Khách lẻ'} • $createdAt'),
              trailing: Text(
                '${currencyFormat.format(total)} đ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
              onTap: () => _reprintInvoice(order),
            ),
          );
        },
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Customer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khách hàng: ${customer?['name'] ?? 'Khách lẻ'}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (customer?['phone'] != null)
                        Text('SĐT: ${customer!['phone']}'),
                      if (customer?['address'] != null)
                        Text('Địa chỉ: ${customer!['address']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items list
                const Text('Danh sách sản phẩm:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${idx + 1}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['product_name'] ?? 'Sản phẩm',
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${item['quantity']} ${item['unit'] ?? ''} x ${currencyFormat.format(item['unit_price'] ?? 0)} đ',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${currencyFormat.format(item['line_total'] ?? 0)} đ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  );
                }),
                
                const Divider(height: 32),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    Text(
                      '${currencyFormat.format(order['total'] ?? 0)} đ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Print button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _printInvoice(order);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('In hóa đơn', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printInvoice(Map<String, dynamic> order) async {
    try {
      final authState = ref.read(authProvider);
      final employee = authState.user;
      
      // Generate invoice number if not exists
      String invoiceNumber = order['invoice_number'] ?? '';
      if (invoiceNumber.isEmpty) {
        final now = DateTime.now();
        final sequenceNum = now.millisecondsSinceEpoch % 10000;
        invoiceNumber = '${now.month.toString().padLeft(2, '0')}-${sequenceNum.toString().padLeft(4, '0')}';
      }

      final pdf = await _generateInvoicePdf(order, invoiceNumber, employee?.name ?? 'Kế toán');
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name: 'HoaDon_$invoiceNumber.pdf',
      );

      // Update invoice_number in database if not set
      if (order['invoice_number'] == null) {
        final supabase = Supabase.instance.client;
        await supabase
            .from('sales_orders')
            .update({'invoice_number': invoiceNumber})
            .eq('id', order['id']);
        
        // Reload data
        _loadOrders();
      }
    } catch (e) {
      AppLogger.error('Error printing invoice', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in hóa đơn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reprintInvoice(Map<String, dynamic> order) async {
    final authState = ref.read(authProvider);
    final employee = authState.user;
    
    // Need to reload order with items
    final supabase = Supabase.instance.client;
    final fullOrder = await supabase
        .from('sales_orders')
        .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
        .eq('id', order['id'])
        .single();
    
    final pdf = await _generateInvoicePdf(
      fullOrder,
      order['invoice_number'] ?? '',
      employee?.name ?? 'Kế toán',
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf,
      name: 'HoaDon_${order['invoice_number']}.pdf',
    );
  }

  Future<Uint8List> _generateInvoicePdf(
    Map<String, dynamic> order,
    String invoiceNumber,
    String accountantName,
  ) async {
    final pdf = pw.Document();
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final discount = (order['discount'] as num?)?.toDouble() ?? 0;
    final subtotal = total + discount;
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final salesRep = order['created_by_name'] ?? 'Nhân viên';

    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Company info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo placeholder
                  pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text('LOGO', style: pw.TextStyle(font: fontBold, color: PdfColors.grey600)),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('God-Scent Company - Ltd.',
                            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.green800)),
                        pw.SizedBox(height: 4),
                        pw.Text('Tan Thoi Hiep Industrial Zone, Dist. 12, HCMC',
                            style: pw.TextStyle(font: font, fontSize: 9)),
                        pw.Text('VPDD: 100/36 Thien Phuoc, P.9, Q. Tan Binh, TP. HCM',
                            style: pw.TextStyle(font: font, fontSize: 9)),
                        pw.Text('Website: www.odori.com.vn - 028.386.36277',
                            style: pw.TextStyle(font: font, fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Ngay $dateStr', style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('SHD: $invoiceNumber', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Title
              pw.Center(
                child: pw.Text('HOA DON BAN HANG',
                    style: pw.TextStyle(font: fontBold, fontSize: 18)),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customer info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Khach hang: ${customer?['name'] ?? 'Khach le'}',
                        style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text('Dia chi: ${customer?['address'] ?? ''}',
                        style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Dai dien ban hang: $salesRep   Tel: ${customer?['phone'] ?? ''}',
                        style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Items table header
              pw.Text('CHI TIET HOA DON', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              pw.SizedBox(height: 8),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(70),
                  5: const pw.FixedColumnWidth(80),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableCell('TT', fontBold, isHeader: true),
                      _tableCell('Ten hang', fontBold, isHeader: true),
                      _tableCell('DVT', fontBold, isHeader: true),
                      _tableCell('SL', fontBold, isHeader: true),
                      _tableCell('DG', fontBold, isHeader: true),
                      _tableCell('Thanh tien', fontBold, isHeader: true),
                    ],
                  ),
                  // Item rows
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value as Map<String, dynamic>;
                    final qty = item['quantity'] ?? 0;
                    final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
                    final lineTotal = (item['line_total'] as num?)?.toDouble() ?? (qty * price);
                    
                    return pw.TableRow(
                      children: [
                        _tableCell('${idx + 1}', font),
                        _tableCell(item['product_name'] ?? '', font, align: pw.TextAlign.left),
                        _tableCell(item['unit'] ?? '', font),
                        _tableCell('$qty', font),
                        _tableCell(currencyFormat.format(price), font, align: pw.TextAlign.right),
                        _tableCell(currencyFormat.format(lineTotal), font, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                  // Empty rows for manual writing
                  ...List.generate(3, (i) => pw.TableRow(
                    children: [
                      _tableCell('', font),
                      _tableCell('', font),
                      _tableCell('', font),
                      _tableCell('', font),
                      _tableCell('', font),
                      _tableCell('', font),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Tong cong:', style: pw.TextStyle(font: font, fontSize: 11)),
                          pw.SizedBox(width: 40),
                          pw.Text(currencyFormat.format(subtotal),
                              style: pw.TextStyle(font: fontBold, fontSize: 11)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Chiet khau:', style: pw.TextStyle(font: font, fontSize: 11)),
                          pw.SizedBox(width: 40),
                          pw.Text(discount > 0 ? currencyFormat.format(discount) : '--',
                              style: pw.TextStyle(font: font, fontSize: 11)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.green800),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text('Thanh tien:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                            pw.SizedBox(width: 40),
                            pw.Text(currencyFormat.format(total),
                                style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.green800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Khach hang', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Text('________________', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Nhan vien', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Text('________________', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Ke toan', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Text(accountantName, style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Delivery address
              pw.Text('Diem giao: ${customer?['address'] ?? ''}',
                  style: pw.TextStyle(font: font, fontSize: 9, fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _tableCell(String text, pw.Font font, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 10 : 9),
        textAlign: align,
      ),
    );
  }
}
