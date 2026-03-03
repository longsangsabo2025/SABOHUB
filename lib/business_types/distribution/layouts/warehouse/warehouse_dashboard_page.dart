import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/bug_report_dialog.dart';
import '../../../../pages/staff/staff_profile_page.dart';
import '../../../../widgets/realtime_notification_widgets.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

/// Trang tổng quan kho - Dashboard
class WarehouseDashboardPage extends ConsumerStatefulWidget {
  const WarehouseDashboardPage({super.key});

  @override
  ConsumerState<WarehouseDashboardPage> createState() => _WarehouseDashboardPageState();
}

class _WarehouseDashboardPageState extends ConsumerState<WarehouseDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  DateTimeRange? _dateFilter;

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

      final pendingOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .inFilter('status', ['confirmed', 'pending_approval'])
          .count();

      final pickingOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'processing')
          .count();

      final packedOrders = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'completed')
          .count();

      final today = DateTime.now();
      final DateTimeRange effectiveRange = _dateFilter ?? DateTimeRange(
        start: DateTime(today.year, today.month, today.day),
        end: DateTime(today.year, today.month, today.day),
      );
      final completedToday = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .inFilter('status', ['completed', 'ready'])
          .gte('updated_at', effectiveRange.start.toIso8601String())
          .lte('updated_at', effectiveRange.end.add(const Duration(days: 1)).toIso8601String())
          .count();

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

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showQuickDateRangePicker(context, current: _dateFilter);
                                    if (picked != null) {
                                      setState(() {
                                        _dateFilter = picked.start.year == 1970 ? null : picked;
                                        _isLoading = true;
                                      });
                                      _loadDashboardData();
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        _dateFilter != null ? getDateRangeLabel(_dateFilter!) : DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                    ],
                                  ),
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
                            Expanded(child: _buildStatCard('Chờ lấy', '${_stats['pending'] ?? 0}', Icons.pending_actions, Colors.orange)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Đang lấy', '${_stats['picking'] ?? 0}', Icons.shopping_cart, Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Đã đóng gói', '${_stats['packed'] ?? 0}', Icons.inventory_2, Colors.green)),
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
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_stats['completedToday'] ?? 0} đơn',
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                        ),
                                        Text(
                                          '${_stats['lowStock']} sản phẩm sắp hết hàng',
                                          style: TextStyle(color: Colors.red.shade600, fontSize: 13),
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

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showLowStockProducts(BuildContext context) async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;

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
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text('$qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product?['name'] ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('SKU: ${product?['sku'] ?? 'N/A'} • ${product?['unit'] ?? 'đơn vị'}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
}
