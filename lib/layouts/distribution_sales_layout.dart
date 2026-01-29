import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/bug_report_dialog.dart';
import '../widgets/realtime_notification_widgets.dart';

import '../providers/auth_provider.dart';
import '../widgets/error_boundary.dart';
import '../utils/app_logger.dart';
import '../pages/staff/staff_profile_page.dart';
import '../pages/sales/journey_plan_page.dart';
import '../pages/sales/sell_in_sell_out_page.dart';

/// Distribution Sales Layout - Modern 2026 UI
/// Layout cho nhân viên Sales/ASM của công ty phân phối
/// Chức năng chính: Tạo đơn hàng, quản lý khách hàng, theo dõi đơn
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
    _SalesDashboardPage(),
    JourneyPlanPage(),
    SellInSellOutPage(),
    _CreateOrderPage(),        // Sử dụng internal CreateOrderPage đúng với schema phân phối
    _SalesOrdersPage(),        // Đổi tên thành SalesOrdersPage với tabs
    _CustomersPage(),          // Sử dụng internal CustomersPage đúng với schema phân phối
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
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
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
                icon: Icon(Icons.swap_horiz_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.swap_horiz, color: Colors.purple.shade700),
                ),
                label: 'Sell-in/out',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_shopping_cart_outlined, color: Colors.grey.shade600),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_shopping_cart, color: Colors.green.shade700),
                ),
                label: 'Tạo đơn',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: Colors.grey.shade600),
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

// ============================================================================
// SALES DASHBOARD PAGE - Modern 2026 UI
// ============================================================================
class _SalesDashboardPage extends ConsumerStatefulWidget {
  const _SalesDashboardPage();

  @override
  ConsumerState<_SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends ConsumerState<_SalesDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
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
      final userId = authState.user?.id;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // Get today's stats
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Orders today - use sale_id and total (matching actual schema)
      final todayOrders = await supabase
          .from('sales_orders')
          .select('id, total')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .gte('created_at', startOfDay.toIso8601String());

      // Orders this month
      final monthOrders = await supabase
          .from('sales_orders')
          .select('id, total, status')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .gte('created_at', startOfMonth.toIso8601String());

      // Recent orders
      final recent = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .order('created_at', ascending: false)
          .limit(5);

      // Calculate stats
      double todayRevenue = 0;
      for (var order in todayOrders) {
        todayRevenue += (order['total'] ?? 0).toDouble();
      }

      double monthRevenue = 0;
      int pendingCount = 0;
      int completedCount = 0;
      for (var order in monthOrders) {
        monthRevenue += (order['total'] ?? 0).toDouble();
        if (order['status'] == 'pending_approval' || order['status'] == 'draft') {
          pendingCount++;
        }
        if (order['status'] == 'completed') {
          completedCount++;
        }
      }

      setState(() {
        _stats = {
          'todayOrders': todayOrders.length,
          'todayRevenue': todayRevenue,
          'monthOrders': monthOrders.length,
          'monthRevenue': monthRevenue,
          'pendingOrders': pendingCount,
          'completedOrders': completedCount,
        };
        _recentOrders = List<Map<String, dynamic>>.from(recent);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load sales dashboard', e);
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
                            colors: [Colors.orange.shade700, Colors.orange.shade500],
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
                                        (user?.name ?? 'S')[0].toUpperCase(),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào, ${user?.name ?? 'Sales'}! 🎯',
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
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const RealtimeNotificationBell(iconColor: Colors.white),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onSelected: (value) async {
                                      if (value == 'profile') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const Scaffold(body: StaffProfilePage()),
                                          ),
                                        );
                                      } else if (value == 'bug_report') {
                                        BugReportDialog.show(context);
                                      } else if (value == 'logout') {
                                        await ref.read(authProvider.notifier).logout();
                                        if (context.mounted) context.go('/login');
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'profile',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 20),
                                            SizedBox(width: 8),
                                            Text('Tài khoản'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'bug_report',
                                        child: Row(
                                          children: [
                                            Icon(Icons.bug_report_outlined, size: 20, color: Colors.red.shade400),
                                            const SizedBox(width: 8),
                                            const Text('Báo cáo lỗi'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'logout',
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Today revenue card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Doanh thu hôm nay',
                                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            currencyFormat.format(_stats['todayRevenue'] ?? 0),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.shopping_cart, color: Colors.orange.shade700, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_stats['todayOrders'] ?? 0} đơn',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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

                    // Monthly Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Tháng này',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Tổng đơn',
                                '${_stats['monthOrders'] ?? 0}',
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Chờ duyệt',
                                '${_stats['pendingOrders'] ?? 0}',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Hoàn thành',
                                '${_stats['completedOrders'] ?? 0}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Month revenue
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Doanh số tháng',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(_stats['monthRevenue'] ?? 0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
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

                    // Recent Orders
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Đơn hàng gần đây',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_recentOrders.isEmpty)
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
                                  child: Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có đơn hàng nào',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tạo đơn đầu tiên ngay!',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = _recentOrders[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, index == _recentOrders.length - 1 ? 100 : 8),
                              child: _buildOrderCard(order),
                            );
                          },
                          childCount: _recentOrders.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final status = order['status'] ?? 'draft';
    final total = (order['total'] ?? 0).toDouble();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    Color statusColor;
    String statusText;
    switch (status) {
      case 'draft':
        statusColor = Colors.grey;
        statusText = 'Nháp';
        break;
      case 'pending':
      case 'pending_approval':
        statusColor = Colors.amber;
        statusText = 'Chờ duyệt';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Đã duyệt';
        break;
      case 'processing':
        statusColor = Colors.purple;
        statusText = 'Đang xử lý';
        break;
      case 'ready':
        statusColor = Colors.indigo;
        statusText = 'Sẵn sàng';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?['name'] ?? 'Khách hàng',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${order['order_number'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CREATE ORDER PAGE - Modern UI
// ============================================================================
class _CreateOrderPage extends ConsumerStatefulWidget {
  const _CreateOrderPage();

  @override
  ConsumerState<_CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<_CreateOrderPage> {
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = true;
  
  final _notesController = TextEditingController();
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomersAndProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomersAndProducts() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final customersData = await supabase
          .from('customers')
          .select('id, name, code, phone, address')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      final productsData = await supabase
          .from('products')
          .select('id, name, sku, unit, selling_price')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(customersData);
        _products = List<Map<String, dynamic>>.from(productsData);
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers/products', e);
      setState(() {
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final existingIndex = _orderItems.indexWhere((item) => item['product']['id'] == product['id']);

    if (existingIndex >= 0) {
      setState(() {
        _orderItems[existingIndex]['quantity']++;
        _orderItems[existingIndex]['line_total'] =
            _orderItems[existingIndex]['quantity'] * _orderItems[existingIndex]['unit_price'];
      });
    } else {
      setState(() {
        _orderItems.add({
          'product': product,
          'quantity': 1,
          'unit_price': (product['selling_price'] ?? 0).toDouble(),
          'line_total': (product['selling_price'] ?? 0).toDouble(),
        });
      });
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _orderItems[index]['quantity'] + delta;
      if (newQty <= 0) {
        _orderItems.removeAt(index);
      } else {
        _orderItems[index]['quantity'] = newQty;
        _orderItems[index]['line_total'] = newQty * _orderItems[index]['unit_price'];
      }
    });
  }

  double get _orderTotal {
    return _orderItems.fold(0.0, (sum, item) => sum + (item['line_total'] ?? 0));
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 12), Text('Vui lòng chọn khách hàng')],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 12), Text('Vui lòng thêm ít nhất 1 sản phẩm')],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) throw Exception('Missing company or user ID');

      final supabase = Supabase.instance.client;
      final orderNumber = 'SO-${DateTime.now().millisecondsSinceEpoch}';

      final orderData = await supabase
          .from('sales_orders')
          .insert({
            'company_id': companyId,
            'customer_id': _selectedCustomer!['id'],
            'sale_id': userId,
            'order_number': orderNumber,
            'order_date': DateTime.now().toIso8601String().split('T')[0],
            'status': 'pending_approval',
            'delivery_status': 'pending',
            'subtotal': _orderTotal,
            'total': _orderTotal,
            'notes': _notesController.text,
          })
          .select()
          .single();

      final orderId = orderData['id'];
      for (var item in _orderItems) {
        await supabase.from('sales_order_items').insert({
          'order_id': orderId,
          'product_id': item['product']['id'],
          'product_name': item['product']['name'],
          'product_sku': item['product']['sku'],
          'unit': item['product']['unit'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'line_total': item['line_total'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Text('✅ Đã tạo đơn hàng $orderNumber')],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        setState(() {
          _selectedCustomer = null;
          _orderItems.clear();
          _notesController.clear();
          _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
        });
      }
    } catch (e) {
      AppLogger.error('Failed to create order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tạo đơn: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.add_shopping_cart, color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tạo đơn hàng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Chọn khách hàng và sản phẩm', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer selector
                    _buildSectionTitle('Khách hàng', Icons.person),
                    const SizedBox(height: 8),
                    _buildCustomerSelector(),

                    const SizedBox(height: 24),

                    // Product selector
                    _buildSectionTitle('Sản phẩm', Icons.inventory_2),
                    const SizedBox(height: 8),
                    _buildProductSelector(),

                    const SizedBox(height: 16),

                    // Order items
                    if (_orderItems.isNotEmpty) ...[
                      _buildSectionTitle('Giỏ hàng (${_orderItems.length})', Icons.shopping_cart),
                      const SizedBox(height: 8),
                      ..._orderItems.asMap().entries.map((entry) => _buildOrderItemCard(entry.key, entry.value)),

                      // Order total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG CỘNG:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            Text(currencyFormat.format(_orderTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Delivery info
                    _buildSectionTitle('Giao hàng', Icons.local_shipping),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ngày giao dự kiến', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _expectedDeliveryDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (picked != null) setState(() => _expectedDeliveryDate = picked);
                                },
                                child: const Text('Đổi'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú',
                              hintText: 'Ghi chú cho đơn hàng...',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Đang tạo...' : 'TẠO ĐƠN HÀNG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    if (_isLoadingCustomers) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      onTap: _showCustomerPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _selectedCustomer != null ? Colors.green : Colors.grey.shade300, width: _selectedCustomer != null ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _selectedCustomer != null ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_selectedCustomer != null ? Icons.check_circle : Icons.person_add, color: _selectedCustomer != null ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCustomer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedCustomer!['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_selectedCustomer!['phone'] ?? ''} • ${_selectedCustomer!['code'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                  : Text('Nhấn để chọn khách hàng', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filter customers based on search
          final filteredCustomers = _customers.where((c) {
            if (searchQuery.isEmpty) return true;
            final name = (c['name'] ?? '').toString().toLowerCase();
            final phone = (c['phone'] ?? '').toString().toLowerCase();
            final code = (c['code'] ?? '').toString().toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query) || phone.contains(query) || code.contains(query);
          }).toList();
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Chọn khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredCustomers.length}',
                              style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) => setModalState(() => searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm khách hàng...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                // Customer list
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Không tìm thấy khách hàng', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected = _selectedCustomer?['id'] == customer['id'];
                            return _buildCustomerPickerCard(customer, isSelected, () {
                              setState(() => _selectedCustomer = customer);
                              Navigator.pop(context);
                            });
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerPickerCard(Map<String, dynamic> customer, bool isSelected, VoidCallback onTap) {
    final name = customer['name'] ?? 'N/A';
    final phone = customer['phone'] ?? '';
    final district = customer['district'] ?? '';
    final channel = customer['channel'] as String?;
    final status = customer['status'] ?? 'active';
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    final paymentTerms = customer['payment_terms'] ?? 0;
    final lastOrderDate = customer['last_order_date'] != null 
        ? DateTime.tryParse(customer['last_order_date'].toString()) 
        : null;
    
    final lastOrderColor = _getLastOrderColorStatic(lastOrderDate);
    final isVIP = creditLimit > 10000000;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar with selection indicator
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _getChannelColorStatic(channel).withOpacity(0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: _getChannelColorStatic(channel),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isVIP) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (channel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getChannelColorStatic(channel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  channel,
                                  style: TextStyle(fontSize: 10, color: _getChannelColorStatic(channel)),
                                ),
                              ),
                            if (district.toString().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  district.toString(),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (phone.toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            phone.toString(),
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
              
              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildPickerKPIItem(
                      '📅',
                      _formatLastOrderStatic(lastOrderDate),
                      'Lần mua',
                      lastOrderColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      '💳',
                      creditLimit > 0 
                          ? NumberFormat.compact(locale: 'vi').format(creditLimit)
                          : '0',
                      'Hạn mức',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      '⏱️',
                      '$paymentTerms',
                      'Ngày TT',
                      Colors.purple,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      status == 'active' ? '✅' : '⛔',
                      status == 'active' ? 'Hoạt động' : 'Ngưng',
                      'Trạng thái',
                      status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerKPIItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  static Color _getChannelColorStatic(String? channel) {
    switch (channel) {
      case 'Horeca': return Colors.purple;
      case 'GT Sỉ': return Colors.blue;
      case 'GT Lẻ': return Colors.green;
      default: return Colors.indigo;
    }
  }

  static Color _getLastOrderColorStatic(DateTime? lastOrderDate) {
    if (lastOrderDate == null) return Colors.grey;
    final days = DateTime.now().difference(lastOrderDate).inDays;
    if (days <= 7) return Colors.green;
    if (days <= 14) return Colors.orange;
    return Colors.red;
  }

  static String _formatLastOrderStatic(DateTime? date) {
    if (date == null) return 'Chưa mua';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${days ~/ 7} tuần';
    return '${days ~/ 30} tháng';
  }

  Widget _buildProductSelector() {
    if (_isLoadingProducts) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      onTap: _showProductPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text('Nhấn để thêm sản phẩm', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Chọn sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final price = (product['selling_price'] ?? 0).toDouble();
                  final inCart = _orderItems.any((item) => item['product']['id'] == product['id']);
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                    ),
                    title: Text(product['name'] ?? 'N/A'),
                    subtitle: Text('${product['sku'] ?? ''} • ${product['unit'] ?? ''}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(price), style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (inCart) Text('Đã thêm', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                      ],
                    ),
                    onTap: () {
                      _addProduct(product);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(int index, Map<String, dynamic> item) {
    final product = item['product'] as Map<String, dynamic>;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${currencyFormat.format(item['unit_price'])} / ${product['unit'] ?? 'đơn vị'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQuantity(index, -1), color: Colors.red, iconSize: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQuantity(index, 1), color: Colors.green, iconSize: 28),
            ],
          ),
          SizedBox(
            width: 90,
            child: Text(currencyFormat.format(item['line_total']), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SALES ORDERS PAGE - Modern UI with Tabs (Nâng cấp từ _MyOrdersPage)
// ============================================================================
class _SalesOrdersPage extends ConsumerStatefulWidget {
  const _SalesOrdersPage();

  @override
  ConsumerState<_SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends ConsumerState<_SalesOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.receipt_long, color: Colors.teal.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.teal.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.teal,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Tất cả'),
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Đã duyệt'),
                      Tab(text: 'Đang giao'),
                      Tab(text: 'Hoàn thành'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _SalesOrderList(statusFilter: null),
                  _SalesOrderList(statusFilter: 'pending_approval'),
                  _SalesOrderList(statusFilter: 'confirmed'),
                  _SalesOrderList(statusFilter: 'processing'),
                  _SalesOrderList(statusFilter: 'completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SALES ORDER LIST - Reusable list widget
// ============================================================================
class _SalesOrderList extends ConsumerStatefulWidget {
  final String? statusFilter;
  const _SalesOrderList({this.statusFilter});

  @override
  ConsumerState<_SalesOrderList> createState() => _SalesOrderListState();
}

class _SalesOrderListState extends ConsumerState<_SalesOrderList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var queryBuilder = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '');

      if (widget.statusFilter != null) {
        queryBuilder = queryBuilder.eq('status', widget.statusFilter!);
      }

      final data = await queryBuilder.order('created_at', ascending: false).limit(50);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load orders', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              widget.statusFilter == null ? 'Tạo đơn hàng đầu tiên!' : 'Không có đơn ở trạng thái này',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final status = order['status'] ?? 'draft';
    final deliveryStatus = order['delivery_status'] ?? 'pending';
    final total = (order['total'] ?? 0).toDouble();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

    Color statusColor;
    String statusText;
    switch (status) {
      case 'draft':
        statusColor = Colors.grey;
        statusText = 'Nháp';
        break;
      case 'pending':
      case 'pending_approval':
        statusColor = Colors.amber;
        statusText = 'Chờ duyệt';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Đã duyệt';
        break;
      case 'processing':
        statusColor = Colors.purple;
        statusText = 'Đang xử lý';
        break;
      case 'ready':
        statusColor = Colors.indigo;
        statusText = 'Sẵn sàng';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    // Delivery status
    String deliveryText = '';
    IconData deliveryIcon = Icons.local_shipping_outlined;
    Color deliveryColor = Colors.grey;
    switch (deliveryStatus) {
      case 'pending':
      case 'planned':  // deliveries table uses 'planned'
        deliveryText = 'Chưa giao';
        deliveryIcon = Icons.schedule;
        deliveryColor = Colors.grey;
        break;
      case 'in_progress':  // was 'in_transit'
      case 'loading':
        deliveryText = 'Đang giao';
        deliveryIcon = Icons.local_shipping;
        deliveryColor = Colors.blue;
        break;
      case 'completed':  // was 'delivered'
        deliveryText = 'Đã giao';
        deliveryIcon = Icons.check_circle;
        deliveryColor = Colors.green;
        break;
      case 'failed':
        deliveryText = 'Giao thất bại';
        deliveryIcon = Icons.error;
        deliveryColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number & status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(order['order_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            
            // Date
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
            
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            
            // Customer info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(
                    (customer?['name'] ?? 'K')[0].toUpperCase(),
                    style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer?['name'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (customer?['phone'] != null)
                        Text(customer!['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Delivery status & Total
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deliveryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deliveryIcon, size: 14, color: deliveryColor),
                      const SizedBox(width: 4),
                      Text(deliveryText, style: TextStyle(fontSize: 11, color: deliveryColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(currencyFormat.format(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Note: Old _MyOrdersPage and _CustomersPage classes have been removed.
// Now using:
// - _SalesOrdersPage (with tabs) for orders
// - _CustomersPage (internal) for customers

// ============================================================================
// CUSTOMERS PAGE - Simple internal page for sales role
// ============================================================================
class _CustomersPage extends ConsumerStatefulWidget {
  const _CustomersPage();

  @override
  ConsumerState<_CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<_CustomersPage> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
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
          .select('*')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((c) {
      final name = (c['name'] ?? '').toLowerCase();
      final phone = (c['phone'] ?? '').toLowerCase();
      final code = (c['code'] ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm KH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Khách hàng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_filteredCustomers.length}', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Không tìm thấy khách hàng', style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomerDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Thêm khách hàng mới'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCustomers,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding for FAB
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return _buildCustomerCard(customer);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _SalesCustomerFormSheet(
          onSaved: () {
            _loadCustomers();
          },
        ),
      ),
    );
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _SalesCustomerFormSheet(
          customer: customer,
          onSaved: () {
            _loadCustomers();
          },
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] ?? 'N/A';
    final phone = customer['phone'] ?? '';
    final district = customer['district'] ?? '';
    final channel = customer['channel'] as String?;
    final status = customer['status'] ?? 'active';
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    final paymentTerms = customer['payment_terms'] ?? 0;
    final lastOrderDate = customer['last_order_date'] != null 
        ? DateTime.tryParse(customer['last_order_date'].toString()) 
        : null;
    
    final lastOrderColor = _getLastOrderColor(lastOrderDate);
    final isVIP = creditLimit > 10000000;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCustomerActions(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _getChannelColor(channel).withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _getChannelColor(channel),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isVIP) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (channel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getChannelColor(channel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  channel,
                                  style: TextStyle(fontSize: 10, color: _getChannelColor(channel)),
                                ),
                              ),
                            if (district.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  district,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      color: Colors.green,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: () => _callCustomer(phone),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    color: Colors.blue,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () => _createOrderForCustomer(customer),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
              
              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildKPIItem(
                      '📅',
                      _formatLastOrder(lastOrderDate),
                      'Lần mua',
                      lastOrderColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '💳',
                      creditLimit > 0 
                          ? NumberFormat.compact(locale: 'vi').format(creditLimit)
                          : '0',
                      'Hạn mức',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '⏱️',
                      '$paymentTerms',
                      'Ngày TT',
                      Colors.purple,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      status == 'active' ? '✅' : '⛔',
                      status == 'active' ? 'Hoạt động' : 'Ngưng',
                      'Trạng thái',
                      status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Color _getChannelColor(String? channel) {
    switch (channel) {
      case 'Horeca': return Colors.purple;
      case 'GT Sỉ': return Colors.blue;
      case 'GT Lẻ': return Colors.green;
      default: return Colors.indigo;
    }
  }

  Color _getLastOrderColor(DateTime? lastOrderDate) {
    if (lastOrderDate == null) return Colors.grey;
    final days = DateTime.now().difference(lastOrderDate).inDays;
    if (days <= 7) return Colors.green;
    if (days <= 14) return Colors.orange;
    return Colors.red;
  }

  String _formatLastOrder(DateTime? date) {
    if (date == null) return 'Chưa mua';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${days ~/ 7} tuần';
    return '${days ~/ 30} tháng';
  }

  void _showCustomerActions(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              customer['name'] ?? 'Khách hàng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildActionTile(Icons.shopping_cart, 'Tạo đơn hàng', Colors.blue, () {
              Navigator.pop(context);
              _createOrderForCustomer(customer);
            }),
            if ((customer['phone'] ?? '').toString().isNotEmpty)
              _buildActionTile(Icons.phone, 'Gọi điện', Colors.green, () {
                Navigator.pop(context);
                _callCustomer(customer['phone']);
              }),
            _buildActionTile(Icons.history, 'Lịch sử mua hàng', Colors.orange, () {
              Navigator.pop(context);
              _showOrderHistory(customer);
            }),
            _buildActionTile(Icons.edit, 'Chỉnh sửa', Colors.purple, () {
              Navigator.pop(context);
              _showEditCustomerDialog(customer);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể gọi số: $phone'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gọi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _createOrderForCustomer(Map<String, dynamic> customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SalesCreateOrderFormPage(preselectedCustomer: customer),
      ),
    );
  }

  void _showOrderHistory(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _SalesOrderHistorySheet(
            customer: customer,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SALES ORDER HISTORY SHEET - Hiển thị lịch sử đơn hàng của khách hàng
// ============================================================================
class _SalesOrderHistorySheet extends StatefulWidget {
  final Map<String, dynamic> customer;
  final ScrollController scrollController;

  const _SalesOrderHistorySheet({
    required this.customer,
    required this.scrollController,
  });

  @override
  State<_SalesOrderHistorySheet> createState() => _SalesOrderHistorySheetState();
}

class _SalesOrderHistorySheetState extends State<_SalesOrderHistorySheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final customerId = widget.customer['id'];
      
      final response = await supabase
          .from('sales_orders')
          .select('id, order_code, total_amount, status, created_at')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      case 'confirmed': return Colors.teal;
      case 'delivered': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'pending': return 'Chờ duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'processing': return 'Đang xử lý';
      case 'confirmed': return 'Đã duyệt';
      case 'delivered': return 'Đã giao';
      default: return status ?? 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.customer['name'] ?? 'Khách hàng', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final createdAt = DateTime.tryParse(order['created_at'] ?? '');
                          final status = order['status'] as String?;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt, color: _getStatusColor(status)),
                              ),
                              title: Text(
                                order['order_code'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                createdAt != null 
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                                    : 'N/A',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(order['total_amount'] ?? 0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(fontSize: 11, color: _getStatusColor(status)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Summary footer
          if (_orders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${_orders.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const Text('Tổng đơn', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        currencyFormat.format(_orders.fold<double>(0, (sum, o) => sum + ((o['total_amount'] ?? 0) as num).toDouble())),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const Text('Tổng giá trị', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SALES CREATE ORDER FORM PAGE - Form tạo đơn hàng với customer đã chọn sẵn
// ============================================================================
class _SalesCreateOrderFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? preselectedCustomer;

  const _SalesCreateOrderFormPage({this.preselectedCustomer});

  @override
  ConsumerState<_SalesCreateOrderFormPage> createState() => _SalesCreateOrderFormPageState();
}

class _SalesCreateOrderFormPageState extends ConsumerState<_SalesCreateOrderFormPage> {
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = true;
  
  final _notesController = TextEditingController();
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
    _loadCustomersAndProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomersAndProducts() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final customersData = await supabase
          .from('customers')
          .select('id, name, code, phone, address')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      final productsData = await supabase
          .from('products')
          .select('id, name, sku, unit, selling_price')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(customersData);
        _products = List<Map<String, dynamic>>.from(productsData);
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers/products', e);
      setState(() {
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final existingIndex = _orderItems.indexWhere((item) => item['product']['id'] == product['id']);

    if (existingIndex >= 0) {
      setState(() {
        _orderItems[existingIndex]['quantity']++;
        _orderItems[existingIndex]['line_total'] =
            _orderItems[existingIndex]['quantity'] * _orderItems[existingIndex]['unit_price'];
      });
    } else {
      setState(() {
        _orderItems.add({
          'product': product,
          'quantity': 1,
          'unit_price': (product['selling_price'] ?? 0).toDouble(),
          'line_total': (product['selling_price'] ?? 0).toDouble(),
        });
      });
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _orderItems[index]['quantity'] + delta;
      if (newQty <= 0) {
        _orderItems.removeAt(index);
      } else {
        _orderItems[index]['quantity'] = newQty;
        _orderItems[index]['line_total'] = newQty * _orderItems[index]['unit_price'];
      }
    });
  }

  double get _orderTotal {
    return _orderItems.fold(0.0, (sum, item) => sum + (item['line_total'] ?? 0));
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      final companyId = authState.user?.companyId;

      if (userId == null || companyId == null) {
        throw Exception('User not authenticated');
      }

      final supabase = Supabase.instance.client;
      
      // Generate order number
      final orderNumber = 'SO${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      // Create order
      final orderResponse = await supabase
          .from('sales_orders')
          .insert({
            'company_id': companyId,
            'customer_id': _selectedCustomer!['id'],
            'customer_name': _selectedCustomer!['name'],
            'order_number': orderNumber,
            'order_date': DateTime.now().toIso8601String().split('T')[0],
            'total': _orderTotal,
            'subtotal': _orderTotal,
            'status': 'pending_approval',
            'payment_status': 'unpaid',
            'delivery_status': 'pending',
            'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
            'created_by': userId,
            'sale_id': userId,
          })
          .select('id')
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      final orderItemsData = _orderItems.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        return {
          'order_id': orderId,
          'product_id': product['id'],
          'product_name': product['name'],
          'product_sku': product['sku'],
          'unit': product['unit'] ?? 'cái',
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'line_total': item['line_total'],
        };
      }).toList();

      await supabase.from('sales_order_items').insert(orderItemsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đơn hàng $orderNumber đã được tạo thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      AppLogger.error('Failed to create order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đơn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tạo đơn hàng'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submitOrder,
            icon: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Tạo đơn'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Khách hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (widget.preselectedCustomer != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Đã chọn sẵn', style: TextStyle(fontSize: 10, color: Colors.green)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _selectedCustomer != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    (_selectedCustomer!['name'] ?? '?')[0].toUpperCase(),
                                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedCustomer!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (_selectedCustomer!['phone'] != null)
                                        Text(_selectedCustomer!['phone'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => setState(() => _selectedCustomer = null),
                                ),
                              ],
                            ),
                          )
                        : _isLoadingCustomers
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<Map<String, dynamic>>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Chọn khách hàng',
                                ),
                                items: _customers.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c['name'] ?? ''),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedCustomer = value),
                              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showProductPicker,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_orderItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Chưa có sản phẩm', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _orderItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _orderItems[index];
                          final product = item['product'] as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                            ),
                            title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(currencyFormat.format(item['unit_price'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateQuantity(index, -1),
                                ),
                                Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes and delivery date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Ghi chú & Giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Ghi chú cho đơn hàng...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.teal),
                      title: const Text('Ngày giao dự kiến'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDeliveryDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng cộng', style: TextStyle(color: Colors.grey.shade600)),
                    Text(
                      currencyFormat.format(_orderTotal),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Tạo đơn hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.inventory, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Chọn sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final existingQty = _orderItems
                              .where((item) => item['product']['id'] == product['id'])
                              .fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
                          
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                            ),
                            title: Text(product['name'] ?? ''),
                            subtitle: Text(
                              '${product['sku'] ?? ''} - ${currencyFormat.format(product['selling_price'] ?? 0)}',
                            ),
                            trailing: existingQty > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('x$existingQty', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  )
                                : const Icon(Icons.add_circle_outline, color: Colors.teal),
                            onTap: () {
                              _addProduct(product);
                              Navigator.pop(context);
                            },
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

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expectedDeliveryDate = picked);
    }
  }
}

// ============================================================================
// SALES CUSTOMER FORM SHEET - Form để tạo/sửa khách hàng cho Sales
// ============================================================================
class _SalesCustomerFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSaved;

  const _SalesCustomerFormSheet({
    this.customer,
    required this.onSaved,
  });

  @override
  ConsumerState<_SalesCustomerFormSheet> createState() => _SalesCustomerFormSheetState();
}

class _SalesCustomerFormSheetState extends ConsumerState<_SalesCustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  
  String _selectedChannel = 'GT Sỉ';
  String _selectedType = 'retail'; // retail, distributor, agent, direct
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!['name'] ?? '';
      _codeController.text = widget.customer!['code'] ?? '';
      _phoneController.text = widget.customer!['phone'] ?? '';
      _addressController.text = widget.customer!['address'] ?? '';
      _districtController.text = widget.customer!['district'] ?? '';
      _creditLimitController.text = (widget.customer!['credit_limit'] ?? 0).toString();
      _paymentTermsController.text = (widget.customer!['payment_terms'] ?? 0).toString();
      _selectedChannel = widget.customer!['channel'] ?? 'GT Sỉ';
      _selectedType = widget.customer!['type'] ?? 'retail';
      _selectedStatus = widget.customer!['status'] ?? 'active';
    } else {
      _creditLimitController.text = '0';
      _paymentTermsController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _creditLimitController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      if (companyId == null || companyId.isEmpty) {
        throw Exception('Không tìm thấy company_id. Vui lòng đăng nhập lại.');
      }

      final supabase = Supabase.instance.client;

      final customerData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().isEmpty 
            ? 'KH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
            : _codeController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'district': _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        'channel': _selectedChannel,
        'type': _selectedType,
        'status': _selectedStatus,
        'credit_limit': double.tryParse(_creditLimitController.text) ?? 0,
        'payment_terms': int.tryParse(_paymentTermsController.text) ?? 0,
        'company_id': companyId,
      };

      if (widget.customer != null) {
        await supabase
            .from('customers')
            .update(customerData)
            .eq('id', widget.customer!['id']);
      } else {
        await supabase.from('customers').insert(customerData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customer != null 
                ? 'Đã cập nhật khách hàng' 
                : 'Đã thêm khách hàng mới'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.person_add,
                      color: Colors.indigo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng mới',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isEditing ? 'Cập nhật thông tin khách hàng' : 'Điền thông tin khách hàng mới',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Form fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên khách hàng *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value?.trim().isEmpty == true 
                    ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Mã KH',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Tự động',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: 'Quận/Huyện',
                        prefixIcon: const Icon(Icons.map),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedChannel,
                      decoration: InputDecoration(
                        labelText: 'Kênh',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Horeca', child: Text('Horeca')),
                        DropdownMenuItem(value: 'GT Sỉ', child: Text('GT Sỉ')),
                        DropdownMenuItem(value: 'GT Lẻ', child: Text('GT Lẻ')),
                      ],
                      onChanged: (value) => setState(() => _selectedChannel = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Loại khách hàng
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Loại khách hàng',
                  prefixIcon: Icon(
                    _selectedType == 'distributor' ? Icons.business : 
                    _selectedType == 'agent' ? Icons.handshake :
                    _selectedType == 'direct' ? Icons.person_pin :
                    Icons.shopping_bag,
                    color: _selectedType == 'distributor' ? Colors.purple : 
                           _selectedType == 'agent' ? Colors.orange :
                           _selectedType == 'direct' ? Colors.teal :
                           Colors.blue,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'retail', child: Text('🛒 Khách lẻ')),
                  DropdownMenuItem(value: 'distributor', child: Text('🏢 Nhà phân phối (NPP)')),
                  DropdownMenuItem(value: 'agent', child: Text('🤝 Đại lý')),
                  DropdownMenuItem(value: 'direct', child: Text('📍 Trực tiếp')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _creditLimitController,
                      decoration: InputDecoration(
                        labelText: 'Hạn mức (VNĐ)',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentTermsController,
                      decoration: InputDecoration(
                        labelText: 'Ngày thanh toán',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: const Icon(Icons.toggle_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Ngưng hoạt động')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isEditing ? Icons.save : Icons.add, size: 20),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
