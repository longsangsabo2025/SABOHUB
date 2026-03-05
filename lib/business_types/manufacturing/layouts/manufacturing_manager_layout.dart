import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
import '../../../widgets/realtime_notification_widgets.dart';

// Manufacturing services & models
import '../services/manufacturing_service.dart';
import '../models/manufacturing_models.dart';

// Manufacturing standalone pages (for navigation)
import '../pages/manufacturing/materials_page.dart';
import '../pages/manufacturing/production_order_form_page.dart';
import '../pages/manufacturing/purchase_order_form_page.dart';
import '../pages/manufacturing/quality_dashboard_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Manufacturing Manager Layout
/// Layout cho Manager của công ty sản xuất
/// Tabs: Dashboard, Sản xuất, Nguyên liệu, Mua hàng, Công nợ, Chất lượng
class ManufacturingManagerLayout extends ConsumerStatefulWidget {
  const ManufacturingManagerLayout({super.key});

  @override
  ConsumerState<ManufacturingManagerLayout> createState() =>
      _ManufacturingManagerLayoutState();
}

class _ManufacturingManagerLayoutState
    extends ConsumerState<ManufacturingManagerLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.name ?? 'Quản lý';
    final companyName = currentUser?.companyName ?? 'Sản xuất';

    final pages = <Widget>[
      _MfgManagerDashboard(),
      _MfgManagerProduction(),
      _MfgManagerMaterials(),
      _MfgManagerPurchasing(),
      _MfgManagerPayables(),
      const QualityDashboardPage(),
    ];

    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tổng quan',
      ),
      NavigationDestination(
        icon: Icon(Icons.precision_manufacturing_outlined),
        selectedIcon: Icon(Icons.precision_manufacturing),
        label: 'Sản xuất',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_outlined),
        selectedIcon: Icon(Icons.inventory),
        label: 'Nguyên liệu',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Mua hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Công nợ',
      ),
      NavigationDestination(
        icon: Icon(Icons.verified_outlined),
        selectedIcon: Icon(Icons.verified),
        label: 'Chất lượng',
      ),
    ];

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.factory, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '🏭 Quản lý - $userName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã làm mới dữ liệu'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const RealtimeNotificationBell(),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showProfileMenu(context, ref),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Hồ sơ cá nhân'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report_outlined, color: Colors.red.shade400),
              title: const Text('Báo cáo lỗi'),
              onTap: () {
                Navigator.pop(ctx);
                BugReportDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.factory, color: Theme.of(context).colorScheme.surface, size: 40),
                SizedBox(height: 8),
                Text(
                  'Sản Xuất',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quản lý sản xuất',
                  style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Manufacturing-specific drawer items
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'Nhà cung cấp',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.manufacturingSuppliers);
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long_outlined,
            title: 'Định mức BOM',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.manufacturingBOM);
            },
          ),
          _buildDrawerItem(
            icon: Icons.verified_outlined,
            title: 'Kiểm tra chất lượng',
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 5);
            },
          ),
          const Divider(),
          // Shared navigation items
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Hồ sơ cá nhân',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt công ty',
            onTap: () {
              Navigator.pop(context);
              context.push('/company/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

// ===== MANUFACTURING MANAGER INLINE WIDGETS =====

// --- Dashboard ---
class _MfgManagerDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MfgManagerDashboard> createState() =>
      _MfgManagerDashboardState();
}

class _MfgManagerDashboardState extends ConsumerState<_MfgManagerDashboard> {
  late ManufacturingService _service;
  Map<String, dynamic> _prodStats = {};
  Map<String, dynamic> _poStats = {};
  Map<String, dynamic> _payStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(currentUserProvider)?.companyId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        _service.getProductionStats(),
        _service.getPOStats(),
        _service.getPayableStats(),
      ]);
      _prodStats = r[0];
      _poStats = r[1];
      _payStats = r[2];
    } catch (e) {
      AppLogger.error('Manufacturing dashboard load failed', e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard('Sản Xuất', Icons.factory, Colors.blue, {
            'Tổng lệnh': '${_prodStats['totalOrders'] ?? 0}',
            'Đang chạy': '${_prodStats['inProgress'] ?? 0}',
            'Hoàn thành': '${_prodStats['completed'] ?? 0}',
          }),
          const SizedBox(height: 12),
          _infoCard('Mua Hàng', Icons.shopping_cart, Colors.orange, {
            'Tổng PO': '${_poStats['totalOrders'] ?? 0}',
            'Chờ xử lý': '${_poStats['pending'] ?? 0}',
            'Đã nhận': '${_poStats['completed'] ?? 0}',
          }),
          const SizedBox(height: 12),
          _infoCard('Công Nợ', Icons.account_balance_wallet, Colors.red, {
            'Tổng': '${_payStats['total'] ?? 0}',
            'Quá hạn': '${_payStats['overdue'] ?? 0}',
            'Đã trả': '${_payStats['paid'] ?? 0}',
          }),
        ],
      ),
    );
  }

  Widget _infoCard(
      String title, IconData icon, Color color, Map<String, String> data) {
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
            ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(e.value,
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

// --- Production Orders ---
class _MfgManagerProduction extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MfgManagerProduction> createState() =>
      _MfgManagerProductionState();
}

class _MfgManagerProductionState extends ConsumerState<_MfgManagerProduction> {
  late ManufacturingService _service;
  List<ProductionOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(currentUserProvider)?.companyId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await _service.getProductionOrders();
    } catch (e) {
      AppLogger.error('Failed to load production orders', e);
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
          child: Row(children: [
            const Text('Lệnh Sản Xuất',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductionOrderFormPage()),
              ).then((_) => _load()),
            ),
          ]),
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
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: o.status == 'completed'
                                ? Colors.green
                                : o.status == 'in_progress'
                                    ? Colors.orange
                                    : Colors.blue,
                            child: Icon(Icons.factory,
                                color: Theme.of(context).colorScheme.surface, size: 18),
                          ),
                          title: Text('MO-${o.orderNumber}'),
                          subtitle: Text(
                              '${o.status} • SL: ${o.plannedQuantity}'),
                          trailing: o.producedQuantity > 0
                              ? Text('${o.producedQuantity}',
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

// --- Materials ---
class _MfgManagerMaterials extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MfgManagerMaterials> createState() =>
      _MfgManagerMaterialsState();
}

class _MfgManagerMaterialsState extends ConsumerState<_MfgManagerMaterials> {
  late ManufacturingService _service;
  List<ManufacturingMaterial> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(currentUserProvider)?.companyId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _materials = await _service.getMaterials();
    } catch (e) {
      AppLogger.error('Failed to load materials', e);
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
          child: Row(children: [
            const Text('Nguyên Liệu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: 'Xem tất cả',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaterialsPage()),
              ).then((_) => _load()),
            ),
          ]),
        ),
        Expanded(
          child: _materials.isEmpty
              ? const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có nguyên liệu'),
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _materials.length,
                    itemBuilder: (context, i) {
                      final m = _materials[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(m.name[0])),
                          title: Text(m.name),
                          subtitle:
                              Text('${m.materialCode} • ${m.unit}'),
                          trailing: m.minStock > 0
                              ? Text(
                                  'Min: ${m.minStock.toStringAsFixed(0)}')
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

// --- Purchase Orders ---
class _MfgManagerPurchasing extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MfgManagerPurchasing> createState() =>
      _MfgManagerPurchasingState();
}

class _MfgManagerPurchasingState extends ConsumerState<_MfgManagerPurchasing> {
  late ManufacturingService _service;
  List<PurchaseOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(currentUserProvider)?.companyId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await _service.getPurchaseOrders();
    } catch (e) {
      AppLogger.error('Failed to load purchase orders', e);
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
          child: Row(children: [
            const Text('Đơn Mua Hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PurchaseOrderFormPage()),
              ).then((_) => _load()),
            ),
          ]),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có đơn mua hàng'),
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: o.status == 'received'
                                ? Colors.green
                                : o.status == 'cancelled'
                                    ? Colors.red
                                    : Colors.orange,
                            child: Icon(Icons.receipt,
                                color: Theme.of(context).colorScheme.surface, size: 18),
                          ),
                          title: Text('PO-${o.poNumber}'),
                          subtitle: Text(o.status),
                          trailing: Text(
                              '${o.totalAmount.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
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

// --- Payables ---
class _MfgManagerPayables extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MfgManagerPayables> createState() =>
      _MfgManagerPayablesState();
}

class _MfgManagerPayablesState extends ConsumerState<_MfgManagerPayables> {
  late ManufacturingService _service;
  List<Payable> _payables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ManufacturingService(
        companyId: ref.read(currentUserProvider)?.companyId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _payables = await _service.getPayables();
    } catch (e) {
      AppLogger.error('Failed to load payables', e);
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
          child: Row(children: [
            const Text('Công Nợ Phải Trả',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
          ]),
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
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _payables.length,
                    itemBuilder: (context, i) {
                      final p = _payables[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.status == 'paid'
                                ? Colors.green
                                : p.status == 'overdue'
                                    ? Colors.red
                                    : Colors.orange,
                            child: Icon(Icons.payment,
                                color: Theme.of(context).colorScheme.surface, size: 18),
                          ),
                          title:
                              Text('${p.totalAmount.toStringAsFixed(0)}đ'),
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
