import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../widgets/bug_report_dialog.dart';
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
          _WarehouseProfilePage(),
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
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey.shade600),
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

                    // Quick actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: const Text(
                          'Thao tác nhanh',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                'Nhận đơn mới',
                                Icons.assignment_add,
                                Colors.orange,
                                () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                'Quét barcode',
                                Icons.qr_code_scanner,
                                Colors.blue,
                                () {},
                              ),
                            ),
                          ],
                        ),
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
        'status': 'completed',
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

      // Orders marked ready for driver (delivery_status = 'pending')
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'pending')
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

      // Only show orders that are completed but NOT yet marked ready for driver
      // (delivery_status is null or empty)
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('status', 'completed')
          .or('delivery_status.is.null,delivery_status.eq.')
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
        'delivery_status': 'pending',
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
// INVENTORY PAGE - Modern UI
// ============================================================================
class _InventoryPage extends ConsumerStatefulWidget {
  const _InventoryPage();

  @override
  ConsumerState<_InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<_InventoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventory = [];
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _inventory.where((item) => (item['quantity'] as int? ?? 0) < 10).length;

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
                        'Tồn kho',
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
                                  '$lowStockCount',
                                  style: TextStyle(
                                    color: _showLowStockOnly ? Colors.white : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
                ],
              ),
            ),

            // Inventory list
            Expanded(
              child: _isLoading
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
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadInventory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredInventory.length,
                            itemBuilder: (context, index) {
                              final item = _filteredInventory[index];
                              return _buildInventoryCard(item);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    final quantity = item['quantity'] as int? ?? 0;
    final isLowStock = quantity < 10;

    return Container(
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
          if (isLowStock)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
            ),
        ],
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
