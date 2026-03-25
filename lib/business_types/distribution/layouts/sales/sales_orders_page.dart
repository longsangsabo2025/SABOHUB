import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/quick_date_range_picker.dart';
import '../../pages/manager/orders_management_page.dart';
import 'sales_create_order_page.dart';

/// Sales Orders Page - dùng lại UI order list của manager nhưng filter theo sale_id.
class SalesOrdersPage extends ConsumerStatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  ConsumerState<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends ConsumerState<SalesOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateFilter;
  int _refreshSeed = 0;
  bool _collapseHero = false;

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

  Future<void> _openCreateOrderPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const SalesCreateOrderPage()),
    );

    if (!mounted) return;
    setState(() {
      _tabController.animateTo(0);
      _refreshSeed++;
    });
  }

  String _buildKey(String tab) {
    final start = _dateFilter?.start.toIso8601String() ?? 'none';
    final end = _dateFilter?.end.toIso8601String() ?? 'none';
    return 'sales-$tab-$_refreshSeed-$start-$end';
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool outlined = false,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(outlined ? 0.45 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final salesName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Nhân viên sale';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis != Axis.vertical) return false;
            final shouldCollapse = notification.metrics.pixels > 64;
            if (shouldCollapse != _collapseHero) {
              setState(() => _collapseHero = shouldCollapse);
            }
            return false;
          },
          child: Column(
            children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _collapseHero
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade700,
                            Colors.green.shade600,
                            Colors.orange.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.18),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.tune,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Sales Order Hub',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Đơn hàng của tôi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Theo dõi pipeline đơn hàng, sửa đơn chờ duyệt và tạo đơn mới nhanh cho $salesName.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildInfoChip(
                                icon: Icons.person,
                                label: salesName,
                                color: Colors.white,
                                outlined: true,
                              ),
                              _buildInfoChip(
                                icon: Icons.layers,
                                label: '5 trạng thái theo dõi',
                                color: Colors.white,
                                outlined: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoChip(
                                  icon: Icons.calendar_today,
                                  label: _dateFilter != null
                                      ? getDateRangeLabel(_dateFilter!)
                                      : 'Lọc theo ngày',
                                  color: Colors.white,
                                  outlined: true,
                                  onTap: () async {
                                    final picked = await showQuickDateRangePicker(
                                      context,
                                      current: _dateFilter,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _dateFilter = picked.start.year == 1970
                                            ? null
                                            : picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: _openCreateOrderPage,
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Tạo đơn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal.shade800,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    secondChild: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Đơn hàng của tôi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openCreateOrderPage,
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Tạo đơn'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.teal.shade800,
                        unselectedLabelColor: Colors.grey.shade700,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        indicatorPadding: EdgeInsets.zero,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Tất cả'),
                          Tab(text: 'Chờ duyệt'),
                          Tab(text: 'Đã duyệt'),
                          Tab(text: 'Đang giao'),
                          Tab(text: 'Hoàn thành'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  OrderListByStatus(
                    key: ValueKey(_buildKey('all')),
                    saleId: user?.id,
                    dateFilter: _dateFilter,
                    showManagementActions: false,
                    showCreateButton: false,
                    allowEdit: true,
                    allowCancel: false,
                    allowDelete: false,
                  ),
                  OrderListByStatus(
                    key: ValueKey(_buildKey('pending')),
                    status: 'pending_approval',
                    saleId: user?.id,
                    dateFilter: _dateFilter,
                    showManagementActions: false,
                    showCreateButton: false,
                    allowEdit: true,
                    allowCancel: false,
                    allowDelete: false,
                  ),
                  OrderListByStatus(
                    key: ValueKey(_buildKey('approved')),
                    statusList: const ['confirmed', 'ready'],
                    saleId: user?.id,
                    dateFilter: _dateFilter,
                    showManagementActions: false,
                    showCreateButton: false,
                    allowEdit: false,
                    allowCancel: false,
                    allowDelete: false,
                  ),
                  OrderListByStatus(
                    key: ValueKey(_buildKey('delivering')),
                    statusList: const ['processing', 'completed'],
                    deliveryStatusNotIn: const ['delivered'],
                    saleId: user?.id,
                    dateFilter: _dateFilter,
                    showManagementActions: false,
                    showCreateButton: false,
                    allowEdit: false,
                    allowCancel: false,
                    allowDelete: false,
                  ),
                  OrderListByStatus(
                    key: ValueKey(_buildKey('completed')),
                    status: 'completed',
                    deliveryStatus: 'delivered',
                    saleId: user?.id,
                    dateFilter: _dateFilter,
                    showManagementActions: false,
                    showCreateButton: false,
                    allowEdit: false,
                    allowCancel: false,
                    allowDelete: false,
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}


