import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bug_report_dialog.dart';
import '../pages/staff/staff_profile_page.dart';
import '../widgets/realtime_notification_widgets.dart';

import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

/// Distribution Warehouse Layout - Modern 2026 UI
/// Layout cho nhân viên Kho của công ty phân phối
/// Handles: Picking, Packing, Inventory checking
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
          const _WarehouseDashboardPage(),
          _PickingOrdersPage(onPickingCompleted: _goToPackingTab),
          const _PackingPage(),
          _InventoryPage(),
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
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.space_dashboard, color: Colors.teal.shade700),
              ),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment, color: Colors.orange.shade700),
              ),
              label: 'Nhận đơn',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2, color: Colors.green.shade700),
              ),
              label: 'Đóng gói',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warehouse, color: Colors.blue.shade700),
              ),
              label: 'Tồn kho',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WAREHOUSE DASHBOARD PAGE - Modern 2026 UI
// ============================================================================
class _WarehouseDashboardPage extends ConsumerStatefulWidget {
  const _WarehouseDashboardPage();

  @override
  ConsumerState<_WarehouseDashboardPage> createState() => _WarehouseDashboardPageState();
}

class _WarehouseDashboardPageState extends ConsumerState<_WarehouseDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

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

      // Get pending orders count (confirmed, waiting for picking)
      final pendingOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .inFilter('status', ['confirmed', 'pending_approval'])
          .count();

      // Get picking orders count
      final pickingOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'processing')
          .count();

      // Get packed orders count
      final packedOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'completed')
          .count();

      // Get today's completed
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final completedToday = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .inFilter('status', ['shipped', 'ready_for_delivery'])
          .gte('updated_at', startOfDay.toIso8601String())
          .count();

      // Get low stock items count
      final lowStockItems = await supabase
          .from('inventory')
          .select('id')
          .eq('company_id', companyId)
          .lt('quantity', 10)
          .count();

      setState(() {
        _stats = {
          'pending': pendingOrders.count,
          'picking': pickingOrders.count,
          'packed': packedOrders.count,
          'completedToday': completedToday.count,
          'lowStock': lowStockItems.count,
        };
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load warehouse dashboard', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
                            colors: [Colors.teal.shade700, Colors.teal.shade500],
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
                              // Top row
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
                                        (user?.name ?? 'K')[0].toUpperCase(),
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
                                          'Xin chào, ${user?.name ?? 'Nhân viên kho'}! 📦',
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

                              // Date display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Chờ lấy',
                                '${_stats['pending'] ?? 0}',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Đang lấy',
                                '${_stats['picking'] ?? 0}',
                                Icons.shopping_cart,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Đã đóng gói',
                                '${_stats['packed'] ?? 0}',
                                Icons.inventory_2,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today's completed card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade400, Colors.purple.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
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
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hoàn thành hôm nay',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_stats['completedToday'] ?? 0} đơn',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
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

                    // Low stock warning
                    if ((_stats['lowStock'] ?? 0) > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: InkWell(
                            onTap: () => _showLowStockProducts(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.warning_amber, color: Colors.red.shade700, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cảnh báo tồn kho thấp',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${_stats['lowStock']} sản phẩm sắp hết hàng',
                                          style: TextStyle(
                                            color: Colors.red.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.red.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Quick actions - HIDDEN
                    // SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    //     child: const Text(
                    //       'Thao tác nhanh',
                    //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    //     ),
                    //   ),
                    // ),

                    // SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    //     child: Row(
                    //       children: [
                    //         Expanded(
                    //           child: _buildActionButton(
                    //             'Nhận đơn mới',
                    //             Icons.assignment_add,
                    //             Colors.orange,
                    //             () {},
                    //           ),
                    //         ),
                    //         // TODO: Quét barcode - phát triển sau
                    //         // const SizedBox(width: 12),
                    //         // Expanded(
                    //         //   child: _buildActionButton(
                    //         //     'Quét barcode',
                    //         //     Icons.qr_code_scanner,
                    //         //     Colors.blue,
                    //         //     () {},
                    //         //   ),
                    //         // ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    
                    // Add bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
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
              fontSize: 24,
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

  void _showLowStockProducts(BuildContext context) async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;

    // Show low stock items in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLowStockSheet(companyId),
    );
  }

  Widget _buildLowStockSheet(String companyId) {
    return Container(
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
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_amber, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sản phẩm sắp hết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Cần nhập thêm hàng', style: TextStyle(color: Colors.grey)),
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
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getLowStockItems(companyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Không có sản phẩm sắp hết hàng'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item['products'] as Map<String, dynamic>?;
                    final qty = item['quantity'] as int? ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.orange.shade800,
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
                                  product?['name'] ?? 'Sản phẩm',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'SKU: ${product?['sku'] ?? 'N/A'} • ${product?['unit'] ?? 'đơn vị'}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getLowStockItems(String companyId) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('inventory')
        .select('*, products(id, name, sku, unit)')
        .eq('company_id', companyId)
        .lt('quantity', 10)
        .order('quantity');
    return List<Map<String, dynamic>>.from(data);
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PICKING ORDERS PAGE - Modern UI
// ============================================================================
class _PickingOrdersPage extends ConsumerStatefulWidget {
  final VoidCallback? onPickingCompleted;

  const _PickingOrdersPage({this.onPickingCompleted});

  @override
  ConsumerState<_PickingOrdersPage> createState() => _PickingOrdersPageState();
}

class _PickingOrdersPageState extends ConsumerState<_PickingOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _pickingOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Get pending (confirmed, waiting for picking)
      final pending = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_id, quantity, products(name, sku))')
          .eq('company_id', companyId)
          .inFilter('status', ['confirmed', 'pending_approval'])
          .order('created_at', ascending: true)
          .limit(50);

      // Get picking (being picked by this user)
      final picking = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_id, quantity, products(name, sku))')
          .eq('company_id', companyId)
          .eq('status', 'processing')
          .order('updated_at', ascending: true)
          .limit(50);

      setState(() {
        _pendingOrders = List<Map<String, dynamic>>.from(pending);
        _pickingOrders = List<Map<String, dynamic>>.from(picking);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load picking orders', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startPicking(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('sales_orders').update({
        'status': 'processing',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã nhận đơn! Bắt đầu lấy hàng.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      AppLogger.error('Failed to start picking', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _completePicking(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('sales_orders').update({
        'status': 'ready',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('🎉 Hoàn thành! Chuyển sang tab Đóng gói.')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadOrders();
        // Auto navigate to Packing tab
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onPickingCompleted?.call();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to complete picking', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Nhận đơn - Lấy hàng',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadOrders();
                        },
                      ),
                    ],
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
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pending_actions, size: 18),
                              const SizedBox(width: 6),
                              const Text('Chờ lấy'),
                              if (_pendingOrders.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pendingOrders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 18),
                              const SizedBox(width: 6),
                              const Text('Đang lấy'),
                              if (_pickingOrders.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pickingOrders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                        _buildOrderList(_pendingOrders, isPending: true),
                        _buildOrderList(_pickingOrders, isPending: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.inbox_outlined : Icons.shopping_cart_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Không có đơn chờ lấy hàng' : 'Không có đơn đang lấy',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
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
          return _buildOrderCard(order, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isPending}) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPending ? Colors.orange.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'Chờ lấy' : 'Đang lấy',
                    style: TextStyle(
                      color: isPending ? Colors.orange.shade700 : Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                    customer?['name'] ?? 'Khách hàng',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            if (customer?['address'] != null) ...[
              const SizedBox(height: 6),
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

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),

            // Items
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Sản phẩm (${items.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.take(3).map((item) {
              final product = item['products'] as Map<String, dynamic>?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item['quantity']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        product?['name'] ?? 'Sản phẩm',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product?['sku'] ?? '',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... và ${items.length - 3} sản phẩm khác',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => isPending
                    ? _startPicking(order['id'])
                    : _completePicking(order['id']),
                icon: Icon(isPending ? Icons.play_arrow : Icons.check_circle, size: 20),
                label: Text(isPending ? 'Nhận đơn - Bắt đầu lấy hàng' : 'Hoàn thành lấy hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPending ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PACKING PAGE - Modern UI
// ============================================================================
class _PackingPage extends ConsumerStatefulWidget {
  const _PackingPage();

  @override
  ConsumerState<_PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends ConsumerState<_PackingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _packedOrders = [];
  List<Map<String, dynamic>> _readyForDriverOrders = [];
  List<Map<String, dynamic>> _awaitingPickupOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    await Future.wait([
      _loadPackedOrders(),
      _loadReadyForDriverOrders(),
      _loadAwaitingPickupOrders(),
    ]);
  }

  Future<void> _loadReadyForDriverOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Orders packed and ready for driver to pickup (delivery_status = 'awaiting_pickup')
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .order('updated_at', ascending: false)
          .limit(50);

      setState(() {
        _readyForDriverOrders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load ready for driver orders', e);
    }
  }

  Future<void> _loadAwaitingPickupOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .order('updated_at', ascending: false)
          .limit(50);

      setState(() {
        _awaitingPickupOrders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load awaiting pickup orders', e);
    }
  }

  Future<void> _loadPackedOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Show orders that are ready (picked) and waiting for packing
      // status = 'ready' means picked and ready for packing
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('status', 'ready')
          .eq('delivery_status', 'pending')
          .order('updated_at', ascending: true)
          .limit(50);

      setState(() {
        _packedOrders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load packed orders', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markReadyForDelivery(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('sales_orders').update({
        'status': 'completed',
        'delivery_status': 'awaiting_pickup',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white),
                SizedBox(width: 12),
                Text('Đơn hàng sẵn sàng để giao!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadAllOrders();
      }
    } catch (e) {
      AppLogger.error('Failed to mark ready', e);
    }
  }

  Future<void> _confirmHandoverToDriver(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      // Confirm handover - change to delivering
      await supabase.from('sales_orders').update({
        'delivery_status': 'delivering',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Also update delivery record status to in_progress
      await supabase.from('deliveries').update({
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xác nhận giao hàng cho tài xế!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadAllOrders();
      }
    } catch (e) {
      AppLogger.error('Failed to confirm handover', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with TabBar
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Đóng gói & Giao hàng',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadAllOrders();
                          },
                        ),
                      ],
                    ),
                  ),
                  // TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.green.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontSize: 11),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 14),
                              const SizedBox(width: 4),
                              const Text('Đóng gói'),
                              if (_packedOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_packedOrders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping, size: 14),
                              const SizedBox(width: 4),
                              const Text('Sẵn sàng'),
                              if (_readyForDriverOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_readyForDriverOrders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delivery_dining, size: 14),
                              const SizedBox(width: 4),
                              const Text('Chờ giao'),
                              if (_awaitingPickupOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_awaitingPickupOrders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        _buildPackedOrdersList(),
                        _buildReadyForDriverList(),
                        _buildAwaitingPickupList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyForDriverList() {
    if (_readyForDriverOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping_outlined, size: 48, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn sẵn sàng giao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Sẵn sàng giao" ở tab Đóng gói\nđể đơn hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _readyForDriverOrders.length,
        itemBuilder: (context, index) {
          final order = _readyForDriverOrders[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_shipping, color: Colors.blue.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderNumber',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              customer?['name'] ?? order['customer_name'] ?? 'Khách hàng',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Chờ tài xế',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (customer?['address'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer!['address'],
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang chờ tài xế đến nhận hàng',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackedOrdersList() {
    if (_packedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn đã đóng gói',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _packedOrders.length,
        itemBuilder: (context, index) {
          final order = _packedOrders[index];
          return _buildPackedOrderCard(order);
        },
      ),
    );
  }

  Widget _buildPackedOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2, color: Colors.green.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$orderNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        customer?['name'] ?? 'Khách hàng',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã đóng gói',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (customer?['address'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer!['address'],
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markReadyForDelivery(order['id']),
                icon: const Icon(Icons.local_shipping, size: 20),
                label: const Text('Sẵn sàng giao cho tài xế'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwaitingPickupList() {
    if (_awaitingPickupOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delivery_dining_outlined, size: 48, color: Colors.purple.shade300),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn chờ giao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Các đơn tài xế đã nhận sẽ hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _awaitingPickupOrders.length,
        itemBuilder: (context, index) {
          final order = _awaitingPickupOrders[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final orderNumber = order['order_number'] ?? 'N/A';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delivery_dining, color: Colors.purple.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderNumber',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              customer?['name'] ?? order['customer_name'] ?? 'Khách hàng',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_empty, size: 14, color: Colors.purple.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Tài xế đã nhận',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (customer?['address'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer!['address'],
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Confirm handover button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmHandoverToDriver(order['id']),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Xác nhận đã giao cho tài xế'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// INVENTORY PAGE - Modern UI with Stock Import Feature
// ============================================================================
class _InventoryPage extends ConsumerStatefulWidget {
  const _InventoryPage();

  @override
  ConsumerState<_InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<_InventoryPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _warehouses = [];
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
    _loadMovements();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('inventory_movements')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _movements = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load movements', e);
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .order('name');

      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load warehouses', e);
    }
  }

  Future<void> _loadInventory() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var query = supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId);

      if (_showLowStockOnly) {
        query = query.lt('quantity', 10);
      }

      final data = await query.order('products(name)');

      setState(() {
        _inventory = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load inventory', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredInventory {
    if (_searchQuery.isEmpty) return _inventory;
    return _inventory.where((item) {
      final product = item['products'] as Map<String, dynamic>?;
      final name = (product?['name'] ?? '').toString().toLowerCase();
      final sku = (product?['sku'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          sku.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showStockImportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockImportSheet(
        inventory: _inventory,
        onSuccess: () {
          _loadInventory();
          _loadMovements();
        },
      ),
    );
  }

  void _showStockAdjustSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockAdjustSheet(
        item: item,
        onSuccess: () {
          _loadInventory();
          _loadMovements();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _inventory.where((item) => (item['quantity'] as int? ?? 0) < 10).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStockImportSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('Nhập kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                      const Text(
                        'Quản lý kho',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (lowStockCount > 0)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showLowStockOnly = !_showLowStockOnly;
                              _isLoading = true;
                            });
                            _loadInventory();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showLowStockOnly ? Colors.orange : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: _showLowStockOnly ? Colors.white : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$lowStockCount sắp hết',
                                  style: TextStyle(
                                    color: _showLowStockOnly ? Colors.white : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadInventory();
                          _loadMovements();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc SKU...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.teal.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.teal,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Tồn kho', icon: Icon(Icons.inventory_2_outlined, size: 20)),
                      Tab(text: 'Lịch sử', icon: Icon(Icons.history, size: 20)),
                      Tab(text: 'DS Kho', icon: Icon(Icons.warehouse_outlined, size: 20)),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Inventory list
                  _buildInventoryList(),
                  // Tab 2: Movement history
                  _buildMovementHistory(),
                  // Tab 3: Warehouse management
                  _buildWarehouseList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredInventory.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy sản phẩm',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showStockImportSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Nhập kho ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadInventory();
                  await _loadMovements();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _filteredInventory.length,
                  itemBuilder: (context, index) {
                    final item = _filteredInventory[index];
                    return _buildInventoryCard(item);
                  },
                ),
              );
  }

  Widget _buildMovementHistory() {
    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử nhập/xuất kho',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          final movement = _movements[index];
          return _buildMovementCard(movement);
        },
      ),
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final product = movement['products'] as Map<String, dynamic>?;
    final type = movement['type'] as String? ?? 'in';
    final quantity = movement['quantity'] as int? ?? 0;
    final reason = movement['reason'] as String?;
    final createdAt = movement['created_at'] as String?;
    
    // Determine color and icon based on type
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    
    switch (type) {
      case 'in':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = 'Nhập kho';
        break;
      case 'out':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Xuất kho';
        break;
      case 'transfer':
        typeColor = Colors.blue;
        typeIcon = Icons.swap_horiz;
        typeLabel = 'Chuyển kho';
        break;
      case 'adjustment':
        typeColor = Colors.orange;
        typeIcon = Icons.edit;
        typeLabel = 'Điều chỉnh';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.sync;
        typeLabel = type;
    }

    // Format date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.2)),
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
          // Type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product?['name'] ?? 'Sản phẩm',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (reason != null && reason.isNotEmpty)
                  Text(
                    reason,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${type == 'out' ? '-' : '+'}$quantity',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    final quantity = item['quantity'] as int? ?? 0;
    final isLowStock = quantity < 10;

    return GestureDetector(
      onTap: () => _showStockAdjustSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLowStock ? Border.all(color: Colors.orange.shade200, width: 1.5) : null,
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isLowStock ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isLowStock ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?['name'] ?? 'Sản phẩm',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SKU: ${product?['sku'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product?['unit'] ?? 'đơn vị',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 18),
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WAREHOUSE LIST TAB - Danh sách kho (Thêm/Sửa/Xóa)
  // ============================================================================
  Widget _buildWarehouseList() {
    return RefreshIndicator(
      onRefresh: _loadWarehouses,
      child: _warehouses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warehouse_outlined, size: 48, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có kho nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddWarehouseSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm kho mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return _buildWarehouseCard(warehouse);
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showAddWarehouseSheet(),
                    backgroundColor: Colors.teal,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Thêm kho', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWarehouseCard(Map<String, dynamic> warehouse) {
    final name = warehouse['name'] ?? 'Kho';
    final code = warehouse['code'] ?? '';
    final type = warehouse['type'] ?? 'main';
    final address = warehouse['address'] ?? '';
    final isActive = warehouse['is_active'] ?? true;
    
    // Type color
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isActive ? Border.all(color: Colors.red.shade200) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditWarehouseSheet(warehouse),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isActive ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ),
                              if (!isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Ngưng HĐ',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (code.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Mã: $code',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')])),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(children: [
                            Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Ngưng hoạt động' : 'Kích hoạt'),
                          ]),
                        ),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditWarehouseSheet(warehouse);
                        } else if (value == 'toggle') {
                          _toggleWarehouseStatus(warehouse);
                        } else if (value == 'delete') {
                          _confirmDeleteWarehouse(warehouse);
                        }
                      },
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWarehouseSheet() {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy công ty'), backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WarehouseFormSheet(
        companyId: companyId,
        onSaved: () => _loadWarehouses(),
      ),
    );
  }

  void _showEditWarehouseSheet(Map<String, dynamic> warehouse) {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy công ty'), backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WarehouseFormSheet(
        companyId: companyId,
        warehouse: warehouse,
        onSaved: () => _loadWarehouses(),
      ),
    );
  }

  Future<void> _toggleWarehouseStatus(Map<String, dynamic> warehouse) async {
    try {
      final supabase = Supabase.instance.client;
      final isActive = warehouse['is_active'] ?? true;
      
      await supabase
          .from('warehouses')
          .update({'is_active': !isActive})
          .eq('id', warehouse['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Đã ngưng hoạt động kho' : 'Đã kích hoạt kho'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWarehouses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteWarehouse(Map<String, dynamic> warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa kho "${warehouse['name']}"?\n\nLưu ý: Không thể xóa kho đang có tồn kho hoặc đơn hàng liên quan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWarehouse(warehouse);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWarehouse(Map<String, dynamic> warehouse) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('warehouses').delete().eq('id', warehouse['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa kho'), backgroundColor: Colors.green),
        );
        _loadWarehouses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================================
// WAREHOUSE FORM SHEET - Thêm/Sửa kho
// ============================================================================
class _WarehouseFormSheet extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic>? warehouse;
  final VoidCallback onSaved;

  const _WarehouseFormSheet({
    required this.companyId,
    this.warehouse,
    required this.onSaved,
  });

  @override
  State<_WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<_WarehouseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedType = 'main';
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _warehouseTypes = [
    {'value': 'main', 'label': 'Kho chính', 'icon': Icons.home_work, 'color': Colors.blue},
    {'value': 'transit', 'label': 'Trung chuyển', 'icon': Icons.local_shipping, 'color': Colors.orange},
    {'value': 'vehicle', 'label': 'Xe tải', 'icon': Icons.local_shipping_outlined, 'color': Colors.green},
    {'value': 'virtual', 'label': 'Ảo', 'icon': Icons.cloud_outlined, 'color': Colors.purple},
  ];

  bool get _isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _nameController.text = widget.warehouse!['name'] ?? '';
      _codeController.text = widget.warehouse!['code'] ?? '';
      _addressController.text = widget.warehouse!['address'] ?? '';
      _selectedType = widget.warehouse!['type'] ?? 'main';
      _isActive = widget.warehouse!['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  child: Icon(
                    _isEditing ? Icons.edit : Icons.add_business,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Sửa thông tin kho' : 'Thêm kho mới',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEditing ? 'Cập nhật thông tin kho' : 'Điền thông tin kho cần tạo',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warehouse Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên kho *',
                        hintText: 'VD: Kho Bình Thạnh',
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên kho' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Warehouse Code
                    TextFormField(
                      controller: _codeController,
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

                    // Warehouse Type
                    const Text(
                      'Loại kho',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _warehouseTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return InkWell(
                          onTap: () => setState(() => _selectedType = type['value']),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? (type['color'] as Color).withOpacity(0.1) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? type['color'] as Color : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? type['color'] as Color : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? type['color'] as Color : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        hintText: 'Nhập địa chỉ kho',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.location_on_outlined),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Active Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isActive ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle : Icons.block,
                            color: _isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  _isActive 
                                    ? 'Kho này có thể nhận và xuất hàng' 
                                    : 'Kho này không còn hoạt động',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isActive ? Colors.green.shade600 : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Submit Button
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWarehouse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Cập nhật kho' : 'Tạo kho mới',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      final data = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        'type': _selectedType,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'is_active': _isActive,
      };

      if (_isEditing) {
        // Update existing warehouse
        await supabase
            .from('warehouses')
            .update(data)
            .eq('id', widget.warehouse!['id']);
      } else {
        // Insert new warehouse with company_id
        data['company_id'] = widget.companyId;
        await supabase.from('warehouses').insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật kho' : 'Đã tạo kho mới'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ============================================================================
// STOCK IMPORT SHEET - Nhập kho mới
// ============================================================================
class _StockImportSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> inventory;
  final VoidCallback onSuccess;

  const _StockImportSheet({
    required this.inventory,
    required this.onSuccess,
  });

  @override
  ConsumerState<_StockImportSheet> createState() => _StockImportSheetState();
}

class _StockImportSheetState extends ConsumerState<_StockImportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProduct;
  String _reason = 'Nhập hàng từ nhà cung cấp';
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  String _searchQuery = '';

  final List<String> _commonReasons = [
    'Nhập hàng từ nhà cung cấp',
    'Trả hàng từ khách',
    'Chuyển kho nội bộ',
    'Điều chỉnh sau kiểm kê',
    'Sản xuất hoàn thành',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('products')
          .select('id, name, sku, unit')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load products', e);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             sku.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) throw Exception('Vui lòng đăng nhập lại');

      final supabase = Supabase.instance.client;
      final quantity = int.parse(_quantityController.text);

      // Get default warehouse
      final warehouses = await supabase
          .from('warehouses')
          .select('id')
          .eq('company_id', companyId)
          .limit(1);

      String? warehouseId;
      if (warehouses.isNotEmpty) {
        warehouseId = warehouses[0]['id'];
      } else {
        // Create default warehouse if none exists
        final newWarehouse = await supabase
            .from('warehouses')
            .insert({
              'company_id': companyId,
              'code': 'MAIN',
              'name': 'Kho chính',
              'type': 'main',
              'is_active': true,
            })
            .select()
            .single();
        warehouseId = newWarehouse['id'];
      }

      // Get current stock for before_quantity
      final currentStock = await supabase
          .from('inventory')
          .select('quantity')
          .eq('company_id', companyId)
          .eq('product_id', _selectedProductId!)
          .maybeSingle();

      final beforeQty = currentStock?['quantity'] as int? ?? 0;

      // Insert inventory movement
      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'warehouse_id': warehouseId,
        'product_id': _selectedProductId,
        'type': 'in',
        'reason': _reason,
        'quantity': quantity,
        'before_quantity': beforeQty,
        'after_quantity': beforeQty + quantity,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_by': userId,
      });

      // Update or insert inventory
      final existingInventory = await supabase
          .from('inventory')
          .select('id, quantity')
          .eq('company_id', companyId)
          .eq('product_id', _selectedProductId!)
          .eq('warehouse_id', warehouseId!)
          .maybeSingle();

      if (existingInventory != null) {
        await supabase
            .from('inventory')
            .update({'quantity': (existingInventory['quantity'] as int) + quantity})
            .eq('id', existingInventory['id']);
      } else {
        await supabase.from('inventory').insert({
          'company_id': companyId,
          'warehouse_id': warehouseId,
          'product_id': _selectedProductId,
          'quantity': quantity,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Đã nhập $quantity ${_selectedProduct?['unit'] ?? 'đơn vị'} vào kho'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_circle, color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhập kho',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Thêm hàng vào kho',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product selection
                  const Text(
                    'Chọn sản phẩm *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm sản phẩm...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product list
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy sản phẩm',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isSelected = _selectedProductId == product['id'];
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.green.shade50,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'SKU: ${product['sku'] ?? 'N/A'} • ${product['unit'] ?? 'đơn vị'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: Colors.green.shade700)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = product['id'];
                                    _selectedProduct = product;
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã chọn: ${_selectedProduct!['name']}',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${_selectedProduct!['unit'] ?? 'đơn vị'}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Quantity
                  const Text(
                    'Số lượng nhập *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Nhập số lượng',
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                      suffixText: _selectedProduct?['unit'] ?? 'đơn vị',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) return 'Số lượng phải lớn hơn 0';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Reason
                  const Text(
                    'Lý do nhập kho',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonReasons.map((reason) {
                      final isSelected = _reason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _reason = reason);
                          }
                        },
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Notes
                  const Text(
                    'Ghi chú (tùy chọn)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Thêm ghi chú...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Đang xử lý...' : 'Xác nhận nhập kho',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STOCK ADJUST SHEET - Điều chỉnh tồn kho
// ============================================================================
class _StockAdjustSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSuccess;

  const _StockAdjustSheet({
    required this.item,
    required this.onSuccess,
  });

  @override
  ConsumerState<_StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<_StockAdjustSheet> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _adjustType = 'in'; // in, out, adjustment
  String _reason = '';
  bool _isLoading = false;

  final Map<String, List<String>> _reasonsByType = {
    'in': ['Nhập hàng từ nhà cung cấp', 'Trả hàng từ khách', 'Điều chỉnh sau kiểm kê', 'Khác'],
    'out': ['Xuất hàng bán', 'Hàng bị hỏng/hết hạn', 'Trả nhà cung cấp', 'Chuyển kho', 'Khác'],
    'adjustment': ['Kiểm kê điều chỉnh', 'Sai lệch hệ thống', 'Khác'],
  };

  @override
  void initState() {
    super.initState();
    _reason = _reasonsByType['in']!.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _currentStock => widget.item['quantity'] as int? ?? 0;
  Map<String, dynamic>? get _product => widget.item['products'] as Map<String, dynamic>?;

  Future<void> _submit() async {
    final qtyStr = _quantityController.text.trim();
    if (qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final qty = int.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng phải lớn hơn 0'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_adjustType == 'out' && qty > _currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đủ hàng trong kho (tồn: $_currentStock)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) throw Exception('Vui lòng đăng nhập lại');

      final supabase = Supabase.instance.client;
      final productId = _product?['id'];
      final warehouseId = widget.item['warehouse_id'];

      // Calculate new quantity
      int newQty;
      if (_adjustType == 'in') {
        newQty = _currentStock + qty;
      } else if (_adjustType == 'out') {
        newQty = _currentStock - qty;
      } else {
        // adjustment - set exact quantity
        newQty = qty;
      }

      // Insert movement record
      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'warehouse_id': warehouseId,
        'product_id': productId,
        'type': _adjustType == 'adjustment' ? 'adjustment' : _adjustType,
        'reason': _reason,
        'quantity': _adjustType == 'adjustment' ? (qty - _currentStock).abs() : qty,
        'before_quantity': _currentStock,
        'after_quantity': newQty,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_by': userId,
      });

      // Update inventory
      await supabase
          .from('inventory')
          .update({'quantity': newQty})
          .eq('id', widget.item['id']);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();

        String message;
        if (_adjustType == 'in') {
          message = 'Đã nhập thêm $qty ${_product?['unit'] ?? 'đơn vị'}';
        } else if (_adjustType == 'out') {
          message = 'Đã xuất $qty ${_product?['unit'] ?? 'đơn vị'}';
        } else {
          message = 'Đã điều chỉnh tồn kho thành $newQty';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with product info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$_currentStock',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product?['name'] ?? 'Sản phẩm',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tồn kho hiện tại: $_currentStock ${_product?['unit'] ?? 'đơn vị'}',
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

          // Form content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Adjustment type
                const Text(
                  'Loại điều chỉnh',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTypeChip('in', 'Nhập kho', Icons.add_circle_outline, Colors.green),
                    const SizedBox(width: 8),
                    _buildTypeChip('out', 'Xuất kho', Icons.remove_circle_outline, Colors.red),
                    const SizedBox(width: 8),
                    _buildTypeChip('adjustment', 'Đặt SL', Icons.edit_outlined, Colors.blue),
                  ],
                ),

                const SizedBox(height: 20),

                // Quantity
                Text(
                  _adjustType == 'adjustment' ? 'Số lượng mới *' : 'Số lượng *',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _adjustType == 'adjustment' ? 'Nhập số lượng tồn kho mới' : 'Nhập số lượng',
                    prefixIcon: Icon(
                      _adjustType == 'in' ? Icons.add : _adjustType == 'out' ? Icons.remove : Icons.edit,
                      color: _adjustType == 'in' ? Colors.green : _adjustType == 'out' ? Colors.red : Colors.blue,
                    ),
                    suffixText: _product?['unit'] ?? 'đơn vị',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                const SizedBox(height: 20),

                // Reason
                const Text(
                  'Lý do',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_reasonsByType[_adjustType] ?? []).map((reason) {
                    final isSelected = _reason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _reason = reason);
                        }
                      },
                      selectedColor: _adjustType == 'in'
                          ? Colors.green.shade100
                          : _adjustType == 'out'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (_adjustType == 'in'
                                ? Colors.green.shade800
                                : _adjustType == 'out'
                                    ? Colors.red.shade800
                                    : Colors.blue.shade800)
                            : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Notes
                const Text(
                  'Ghi chú (tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Đang xử lý...' : 'Xác nhận',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adjustType == 'in'
                        ? Colors.green
                        : _adjustType == 'out'
                            ? Colors.red
                            : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _adjustType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _adjustType = type;
            _reason = _reasonsByType[type]?.first ?? '';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WAREHOUSE PROFILE PAGE - Modern UI
// ============================================================================
class _WarehouseProfilePage extends ConsumerWidget {
  const _WarehouseProfilePage();

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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal.shade700, Colors.teal.shade500],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'K')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Nhân viên kho',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warehouse, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Nhân viên kho',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.companyName ?? 'Công ty',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        icon: Icons.person_outline,
                        iconColor: Colors.blue,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Xem và chỉnh sửa thông tin',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.warehouse_outlined,
                        iconColor: Colors.teal,
                        title: 'Kho phụ trách',
                        subtitle: 'Xem thông tin kho',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bar_chart_outlined,
                        iconColor: Colors.green,
                        title: 'Thống kê công việc',
                        subtitle: 'Xem hiệu suất làm việc',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.purple,
                        title: 'Thông báo',
                        subtitle: 'Quản lý thông báo',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        iconColor: Colors.grey,
                        title: 'Cài đặt',
                        subtitle: 'Tùy chỉnh ứng dụng',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bug report
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        icon: Icons.help_outline,
                        iconColor: Colors.orange,
                        title: 'Trợ giúp',
                        subtitle: 'Hướng dẫn sử dụng',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        iconColor: Colors.red,
                        title: 'Báo cáo lỗi',
                        subtitle: 'Gửi phản hồi về vấn đề gặp phải',
                        onTap: () => BugReportDialog.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(authProvider.notifier).logout();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
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

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}

// ============================================================================
// LOW STOCK BOTTOM SHEET
// ============================================================================
class _LowStockBottomSheet extends StatefulWidget {
  final String companyId;

  const _LowStockBottomSheet({required this.companyId});

  @override
  State<_LowStockBottomSheet> createState() => _LowStockBottomSheetState();
}

class _LowStockBottomSheetState extends State<_LowStockBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final supabase = Supabase.instance.client;

      // Get low stock products from inventory
      final results = await supabase
          .from('inventory')
          .select('id, quantity, product:product_id(id, name, sku, unit, min_stock_level)')
          .eq('company_id', widget.companyId)
          .lt('quantity', 10)
          .order('quantity', ascending: true);

      setState(() {
        _lowStockProducts = List<Map<String, dynamic>>.from(results);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading low stock products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_amber, color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sản phẩm tồn kho thấp',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_lowStockProducts.length} sản phẩm cần nhập thêm',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lowStockProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Không có sản phẩm nào sắp hết hàng',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lowStockProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _lowStockProducts[index];
                          final product = item['product'] as Map<String, dynamic>?;
                          final quantity = item['quantity'] ?? 0;
                          final minLevel = product?['min_stock_level'] ?? 10;
                          final isOutOfStock = quantity == 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isOutOfStock ? Colors.red.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOutOfStock ? Colors.red.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isOutOfStock ? Colors.red.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isOutOfStock ? Icons.error : Icons.inventory,
                                      color: isOutOfStock ? Colors.red.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product?['name'] ?? 'Không tên',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'SKU: ${product?['sku'] ?? 'N/A'}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock ? Colors.red : Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$quantity ${product?['unit'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Min: $minLevel',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
