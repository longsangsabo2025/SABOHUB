import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../utils/app_logger.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../ceo_profile_page.dart';
import '../ceo_notifications_page.dart';
import '../shared/ceo_more_page.dart';

// Manufacturing services & models
import '../../../business_types/manufacturing/services/manufacturing_service.dart';
import '../../../business_types/manufacturing/models/manufacturing_models.dart';

// Manufacturing standalone pages (for navigation)
import '../../../business_types/manufacturing/pages/manufacturing/production_orders_page.dart';
import '../../../business_types/manufacturing/pages/manufacturing/payables_page.dart';
import '../../../business_types/manufacturing/pages/manufacturing/production_order_form_page.dart';

// Shared CEO pages (these use existing tables, NOT manufacturing tables)
import '../ceo_tasks_page.dart';
import '../ceo_employees_page.dart';

/// Manufacturing CEO Layout — 5 tabs focused on manufacturing business
/// Dashboard | Sản xuất | Mua hàng | Tài chính | Đội ngũ
class ManufacturingCEOLayout extends ConsumerStatefulWidget {
  const ManufacturingCEOLayout({super.key});

  @override
  ConsumerState<ManufacturingCEOLayout> createState() =>
      _ManufacturingCEOLayoutState();
}

class _ManufacturingCEOLayoutState
    extends ConsumerState<ManufacturingCEOLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyName = user?.companyName ?? 'Công ty';

    final pages = <Widget>[
      _ManufacturingCEODashboard(),
      _ManufacturingCEOProduction(),
      _ManufacturingCEOProcurement(),
      _ManufacturingCEOFinance(),
      _ManufacturingCEOTeam(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              'Sản xuất',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          const RealtimeNotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOProfilePage()));
                  break;
                case 'notifications':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CEONotificationsPage()));
                  break;
                case 'more':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOMorePage()));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: ListTile(
                dense: true,
                leading: Icon(Icons.person_outline),
                title: Text('Hồ sơ cá nhân'),
              )),
              PopupMenuItem(value: 'notifications', child: ListTile(
                dense: true,
                leading: Icon(Icons.notifications_outlined),
                title: Text('Thông báo'),
              )),
              PopupMenuItem(value: 'more', child: ListTile(
                dense: true,
                leading: Icon(Icons.apps),
                title: Text('Thêm (Công ty, Tài liệu, AI...)'),
              )),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon:
                Icon(Icons.precision_manufacturing, color: AppColors.primary),
            label: 'Sản xuất',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: AppColors.primary),
            label: 'Mua hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: AppColors.primary),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Đội ngũ',
          ),
        ],
      ),
    );
  }
}

// ===== MANUFACTURING CEO DASHBOARD =====
class _ManufacturingCEODashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManufacturingCEODashboard> createState() =>
      _ManufacturingCEODashboardState();
}

class _ManufacturingCEODashboardState
    extends ConsumerState<_ManufacturingCEODashboard> {
  late ManufacturingService _service;
  Map<String, dynamic> _productionStats = {};
  Map<String, dynamic> _poStats = {};
  Map<String, dynamic> _payableStats = {};
  Map<String, dynamic> _supplierStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(authProvider).user?.companyId);
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getProductionStats(),
        _service.getPOStats(),
        _service.getPayableStats(),
        _service.getSupplierStats(),
      ]);
      setState(() {
        _productionStats = results[0];
        _poStats = results[1];
        _payableStats = results[2];
        _supplierStats = results[3];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Sản Xuất',
            icon: Icons.factory,
            color: Colors.blue,
            rows: [
              _StatRow('Tổng lệnh', '${_productionStats['totalOrders'] ?? 0}'),
              _StatRow('Đang chạy', '${_productionStats['inProgress'] ?? 0}'),
              _StatRow('Hoàn thành', '${_productionStats['completed'] ?? 0}'),
              _StatRow('Gấp', '${_productionStats['urgent'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Mua Hàng',
            icon: Icons.shopping_cart,
            color: Colors.orange,
            rows: [
              _StatRow('Tổng PO', '${_poStats['totalOrders'] ?? 0}'),
              _StatRow('Chờ xử lý', '${_poStats['pending'] ?? 0}'),
              _StatRow('Đang xử lý', '${_poStats['inProgress'] ?? 0}'),
              _StatRow('Đã nhận', '${_poStats['completed'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Công Nợ',
            icon: Icons.account_balance_wallet,
            color: Colors.red,
            rows: [
              _StatRow('Tổng khoản', '${_payableStats['total'] ?? 0}'),
              _StatRow('Quá hạn', '${_payableStats['overdue'] ?? 0}'),
              _StatRow('Đã trả', '${_payableStats['paid'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Nhà Cung Cấp',
            icon: Icons.people,
            color: Colors.green,
            rows: [
              _StatRow('Tổng NCC', '${_supplierStats['total'] ?? 0}'),
              _StatRow('Hoạt động', '${_supplierStats['active'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_StatRow> rows;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.label),
                      Text(r.value,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ===== MANUFACTURING CEO PRODUCTION =====
class _ManufacturingCEOProduction extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManufacturingCEOProduction> createState() =>
      _ManufacturingCEOProductionState();
}

class _ManufacturingCEOProductionState
    extends ConsumerState<_ManufacturingCEOProduction> {
  late ManufacturingService _service;
  List<ProductionOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(authProvider).user?.companyId);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      _orders = await _service.getProductionOrders();
    } catch (e) {
      AppLogger.error('CEO: Failed to load production orders', e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String s) => switch (s) {
        'draft' => Colors.grey,
        'planned' => Colors.blue,
        'in_progress' => Colors.orange,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.grey,
      };

  String _statusText(String s) => switch (s) {
        'draft' => 'Nháp',
        'planned' => 'Kế hoạch',
        'in_progress' => 'Đang SX',
        'completed' => 'Hoàn thành',
        'cancelled' => 'Đã hủy',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        // Action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Lệnh Sản Xuất',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadOrders,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductionOrderFormPage()),
                ).then((_) => _loadOrders()),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Xem tất cả',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductionOrdersPage()),
                ).then((_) => _loadOrders()),
              ),
            ],
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.factory, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Chưa có lệnh sản xuất'),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final o = _orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(o.status),
                            child: const Icon(Icons.factory,
                                color: Colors.white, size: 18),
                          ),
                          title: Text('MO-${o.orderNumber}'),
                          subtitle: Text(
                              '${_statusText(o.status)} • SL: ${o.plannedQuantity}'),
                          trailing: o.producedQuantity > 0
                              ? Text('SX: ${o.producedQuantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ===== MANUFACTURING CEO PROCUREMENT =====
class _ManufacturingCEOProcurement extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManufacturingCEOProcurement> createState() =>
      _ManufacturingCEOProcurementState();
}

class _ManufacturingCEOProcurementState
    extends ConsumerState<_ManufacturingCEOProcurement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ManufacturingService _service;
  List<PurchaseOrder> _pos = [];
  List<Supplier> _suppliers = [];
  List<ManufacturingMaterial> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service = ManufacturingService(
        companyId: ref.read(authProvider).user?.companyId);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getPurchaseOrders(),
        _service.getSuppliers(),
        _service.getMaterials(),
      ]);
      _pos = results[0] as List<PurchaseOrder>;
      _suppliers = results[1] as List<Supplier>;
      _materials = results[2] as List<ManufacturingMaterial>;
    } catch (e) {
      AppLogger.error('CEO: Failed to load procurement data', e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Đơn mua'),
              Tab(text: 'NCC'),
              Tab(text: 'Nguyên liệu'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPOList(),
                    _buildSupplierList(),
                    _buildMaterialList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPOList() {
    if (_pos.isEmpty) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Chưa có đơn mua hàng'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pos.length,
      itemBuilder: (context, index) {
        final po = _pos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: po.status == 'received'
                  ? Colors.green
                  : po.status == 'cancelled'
                      ? Colors.red
                      : Colors.orange,
              child:
                  const Icon(Icons.receipt, color: Colors.white, size: 18),
            ),
            title: Text('PO-${po.poNumber}'),
            subtitle: Text(po.status),
            trailing: Text('${po.totalAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildSupplierList() {
    if (_suppliers.isEmpty) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.business, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Chưa có nhà cung cấp'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final s = _suppliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(s.name[0])),
            title: Text(s.name),
            subtitle: Text(s.phone ?? s.email ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildMaterialList() {
    if (_materials.isEmpty) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Chưa có nguyên liệu'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final m = _materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(m.name[0])),
            title: Text(m.name),
            subtitle: Text('${m.materialCode} • ${m.unit}'),
          ),
        );
      },
    );
  }
}

// ===== MANUFACTURING CEO FINANCE =====
class _ManufacturingCEOFinance extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManufacturingCEOFinance> createState() =>
      _ManufacturingCEOFinanceState();
}

class _ManufacturingCEOFinanceState
    extends ConsumerState<_ManufacturingCEOFinance> {
  late ManufacturingService _service;
  List<Payable> _payables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(authProvider).user?.companyId);
    _loadPayables();
  }

  Future<void> _loadPayables() async {
    setState(() => _loading = true);
    try {
      _payables = await _service.getPayables();
    } catch (e) {
      AppLogger.error('CEO: Failed to load payables', e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Công Nợ Phải Trả',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadPayables,
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Xem chi tiết',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PayablesPage()),
                ).then((_) => _loadPayables()),
              ),
            ],
          ),
        ),
        Expanded(
          child: _payables.isEmpty
              ? const Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Chưa có công nợ phải trả'),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadPayables,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _payables.length,
                    itemBuilder: (context, index) {
                      final p = _payables[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.status == 'paid'
                                ? Colors.green
                                : p.status == 'overdue'
                                    ? Colors.red
                                    : Colors.orange,
                            child: const Icon(Icons.payment,
                                color: Colors.white, size: 18),
                          ),
                          title: Text('${p.totalAmount.toStringAsFixed(0)}đ'),
                          subtitle: Text(p.status == 'paid'
                              ? 'Đã trả'
                              : p.status == 'overdue'
                                  ? 'Quá hạn'
                                  : 'Chờ thanh toán'),
                          trailing: p.paidAmount > 0
                              ? Text(
                                  'Trả: ${p.paidAmount.toStringAsFixed(0)}đ',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.green))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ===== MANUFACTURING CEO TEAM =====
class _ManufacturingCEOTeam extends StatefulWidget {
  @override
  State<_ManufacturingCEOTeam> createState() => _ManufacturingCEOTeamState();
}

class _ManufacturingCEOTeamState extends State<_ManufacturingCEOTeam>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: 'Công việc'),
              Tab(icon: Icon(Icons.people), text: 'Nhân viên'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CEOTasksPage(),
              CEOEmployeesPage(),
            ],
          ),
        ),
      ],
    );
  }
}
