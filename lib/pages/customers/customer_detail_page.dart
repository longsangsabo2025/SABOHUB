import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;
import '../../services/geocoding_service.dart';
import '../../business_types/distribution/models/odori_customer.dart';
import '../../models/customer_address.dart';
import '../../models/customer_tier.dart';
import '../../models/referrer.dart';
import '../../providers/auth_provider.dart';
import '../../business_types/distribution/providers/odori_providers.dart';
import '../../business_types/distribution/models/product_sample.dart';
import '../../widgets/customer_tier_widgets.dart';
import '../../widgets/customer_avatar.dart';
import '../orders/order_form_page.dart';
import '../../utils/app_logger.dart';

final supabase = Supabase.instance.client;
final _currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

class CustomerDetailPage extends ConsumerStatefulWidget {
  final OdoriCustomer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OdoriCustomer _customer;
  bool _isLoading = true;

  // Data
  List<CustomerAddress> _addresses = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _visits = [];
  Referrer? _referrer; // Người giới thiệu

  // Stats
  double _totalRevenue = 0;
  double _totalDebt = 0;
  int _orderCount = 0;
  int _visitCount = 0;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadAddresses(),
        _loadContacts(),
        _loadOrders(),
        _loadVisits(),
        _loadReferrer(),
      ]);
    } catch (e) {
      AppLogger.error('Error loading customer data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadReferrer() async {
    if (_customer.referrerId == null) return;

    try {
      final response = await supabase
          .from('referrers')
          .select()
          .eq('id', _customer.referrerId!)
          .maybeSingle();

      if (response != null) {
        _referrer = Referrer.fromJson(response);
      }
    } catch (e) {
      AppLogger.error('Error loading referrer: $e');
    }
  }

  Future<void> _loadAddresses() async {
    final response = await supabase
        .from('customer_addresses')
        .select()
        .eq('customer_id', _customer.id)
        .eq('is_active', true)
        .order('is_default', ascending: false);

    _addresses =
        (response as List).map((e) => CustomerAddress.fromJson(e)).toList();
  }

  Future<void> _loadContacts() async {
    await supabase
        .from('customer_contacts')
        .select('*, customer_addresses(name)')
        .eq('customer_id', _customer.id)
        .eq('is_active', true)
        .order('is_primary', ascending: false);
  }

  Future<void> _loadOrders() async {
    final response = await supabase
        .from('sales_orders')
        .select(
            'id, order_number, order_date, total, paid_amount, status, payment_status, delivery_status')
        .eq('customer_id', _customer.id)
        .order('order_date', ascending: false)
        .limit(100);

    _orders = List<Map<String, dynamic>>.from(response);

    // Calculate stats
    _totalRevenue = 0;
    _totalDebt = 0;
    _orderCount = 0;
    for (final order in _orders) {
      if (order['status'] != 'cancelled') {
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final paid = (order['paid_amount'] as num?)?.toDouble() ?? 0;
        _totalRevenue += total;
        _totalDebt += (total - paid);
        _orderCount++;
      }
    }
  }

  Future<void> _loadVisits() async {
    // Load from BOTH tables: customer_visits (manual) + store_visits (journey plan)
    final results = await Future.wait([
      supabase
          .from('customer_visits')
          .select(
              'id, visit_date, check_in_time, check_out_time, purpose, result, employee:employee_id(full_name), order:order_id(order_number)')
          .eq('customer_id', _customer.id)
          .order('visit_date', ascending: false)
          .limit(50),
      supabase
          .from('store_visits')
          .select(
              'id, visit_date, start_time, end_time, visit_type, visit_purpose, status, observations, duration_minutes, sales_rep:sales_rep_id(full_name)')
          .eq('customer_id', _customer.id)
          .order('visit_date', ascending: false)
          .limit(50),
    ]);

    final manualVisits = List<Map<String, dynamic>>.from(results[0]);
    final storeVisits = List<Map<String, dynamic>>.from(results[1]);

    // Normalize store_visits to same format + add source tag
    for (final v in manualVisits) {
      v['_source'] = 'manual';
    }
    for (final sv in storeVisits) {
      sv['_source'] = 'journey';
      // Map store_visit fields to common format
      sv['check_in_time'] = sv['start_time'];
      sv['check_out_time'] = sv['end_time'];
      sv['employee'] = sv['sales_rep'];
      // Map visit_purpose array to purpose string
      final purposes = sv['visit_purpose'];
      if (purposes is List && purposes.isNotEmpty) {
        sv['purpose'] = purposes.first;
      } else {
        sv['purpose'] = sv['visit_type'];
      }
      // Map status to result
      if (sv['status'] == 'completed') {
        sv['result'] = 'ordered';
      }
    }

    // Merge and sort by date descending
    final merged = [...manualVisits, ...storeVisits];
    merged.sort((a, b) {
      final dateA = DateTime.tryParse(a['visit_date']?.toString() ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['visit_date']?.toString() ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    _visits = merged;
    _visitCount = _visits.length;
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa có số điện thoại'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _createOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormPage(preselectedCustomer: _customer),
      ),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã copy $label'),
            duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildOrdersTab(),
                        _buildDebtTab(),
                        _buildSamplesTab(),
                        _buildContactsTab(),
                        _buildVisitsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.teal,
      foregroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade700, Colors.teal.shade400],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      CustomerAvatar(
                        seed: _customer.name,
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customer.name,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.surface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _customer.code,
                              style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8)),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (_customer.category != null)
                                  _buildHeaderChip(_customer.category!,
                                      Theme.of(context).colorScheme.surface.withOpacity(0.2)),
                                const SizedBox(width: 8),
                                CustomerTierBadge(
                                    tier: CustomerTierExtension.fromString(
                                        _customer.tier)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Quick stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat('Đơn hàng', '$_orderCount'),
                      _buildQuickStat(
                          'Doanh thu', _formatCompact(_totalRevenue)),
                      _buildQuickStat('Công nợ', _formatCompact(_totalDebt)),
                      _buildQuickStat('Viếng thăm', '$_visitCount'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _makePhoneCall(_customer.phone),
          tooltip: 'Gọi điện',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditCustomerDialog();
                break;
              case 'archive':
                _toggleArchiveCustomer();
                break;
              case 'delete':
                _confirmDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa')
                ])),
            PopupMenuItem(
              value: 'archive',
              child: Row(children: [
                Icon(
                    _customer.status == 'archived'
                        ? Icons.unarchive
                        : Icons.archive,
                    size: 20,
                    color: Colors.orange),
                const SizedBox(width: 8),
                Text(_customer.status == 'archived' ? 'Khôi phục' : 'Lưu trữ',
                    style: const TextStyle(color: Colors.orange)),
              ]),
            ),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red))
                ])),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.surface)),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.surface)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.surface.withOpacity(0.8))),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.teal,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.teal,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Đơn hàng'),
          Tab(text: 'Công nợ'),
          Tab(text: 'Mẫu SP'),
          Tab(text: 'Cơ sở'),
          Tab(text: 'Viếng thăm'),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _createOrder,
      backgroundColor: Colors.teal,
      foregroundColor: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text('Tạo đơn'),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact info card
          _buildSectionCard(
            title: 'Thông tin liên hệ',
            icon: Icons.contact_phone,
            children: [
              if (_customer.phone != null)
                _buildInfoRow(Icons.phone, 'Điện thoại', _customer.phone!,
                    onTap: () => _makePhoneCall(_customer.phone),
                    onLongPress: () =>
                        _copyToClipboard(_customer.phone!, 'SĐT')),
              if (_customer.phone2 != null)
                _buildInfoRow(Icons.phone_android, 'SĐT 2', _customer.phone2!,
                    onTap: () => _makePhoneCall(_customer.phone2),
                    onLongPress: () =>
                        _copyToClipboard(_customer.phone2!, 'SĐT')),
              if (_customer.email != null)
                _buildInfoRow(Icons.email, 'Email', _customer.email!,
                    onLongPress: () =>
                        _copyToClipboard(_customer.email!, 'Email')),
              if (_customer.contactPerson != null)
                _buildInfoRow(
                    Icons.person, 'Người liên hệ', _customer.contactPerson!),
            ],
          ),

          const SizedBox(height: 16),

          // Lead Status card
          _buildSectionCard(
            title: 'Trạng thái khách hàng',
            icon: Icons.thermostat,
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: _showEditLeadStatus,
              tooltip: 'Cập nhật trạng thái',
            ),
            children: [
              Row(
                children: [
                  _buildLeadStatusBadge(_customer.leadStatus),
                  const SizedBox(width: 12),
                  Text(
                    _leadStatusDescription(_customer.leadStatus),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              if (_customer.lastInteractionNotes != null && _customer.lastInteractionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.notes, 'Ghi chú gần nhất', _customer.lastInteractionNotes!),
              ],
              if (_customer.lastInteractionDate != null) ...[
                _buildInfoRow(Icons.access_time, 'Tương tác lần cuối',
                    DateFormat('dd/MM/yyyy HH:mm').format(_customer.lastInteractionDate!)),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Address card
          _buildSectionCard(
            title: 'Địa chỉ',
            icon: Icons.location_on,
            trailing: _addresses.isNotEmpty
                ? Text('${_addresses.length} địa chỉ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                : null,
            children: [
              _buildInfoRow(
                  Icons.home, 'Địa chỉ chính', _customer.address ?? 'Chưa có'),
              if (_customer.ward != null ||
                  _customer.district != null ||
                  _customer.city != null)
                _buildInfoRow(
                    Icons.map,
                    'Khu vực',
                    [_customer.ward, _customer.district, _customer.city]
                        .where((e) => e != null)
                        .join(', ')),
              if (_addresses.isNotEmpty) ...[
                const Divider(height: 24),
                ...(_addresses.take(3).map((addr) => _buildAddressRow(addr))),
                if (_addresses.length > 3)
                  TextButton(
                    onPressed: () => _tabController.animateTo(4),
                    child: Text('Xem thêm ${_addresses.length - 3} địa chỉ'),
                  ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Business info card
          _buildSectionCard(
            title: 'Thông tin kinh doanh',
            icon: Icons.business,
            children: [
              if (_customer.type != null)
                _buildInfoRow(Icons.category, 'Loại KH', _customer.type!),
              if (_customer.channel != null)
                _buildInfoRow(Icons.storefront, 'Kênh', _customer.channel!),
              _buildInfoRow(Icons.schedule, 'Kỳ hạn TT',
                  '${_customer.paymentTerms} ngày'),
              _buildInfoRow(Icons.credit_card, 'Hạn mức',
                  _currencyFormat.format(_customer.creditLimit)),
              if (_customer.taxCode != null)
                _buildInfoRow(Icons.receipt, 'Mã số thuế', _customer.taxCode!),
              if (_customer.route != null)
                _buildInfoRow(Icons.route, 'Tuyến', _customer.route!),
            ],
          ),

          const SizedBox(height: 16),

          // Referrer info card (if exists)
          if (_referrer != null)
            _buildSectionCard(
              title: 'Người giới thiệu',
              icon: Icons.person_add_alt_1,
              children: [
                _buildInfoRow(Icons.person, 'Tên', _referrer!.name),
                if (_referrer!.phone != null)
                  _buildInfoRow(Icons.phone, 'SĐT', _referrer!.phone!,
                      onTap: () => _makePhoneCall(_referrer!.phone)),
                _buildInfoRow(Icons.percent, 'Hoa hồng',
                    '${_referrer!.commissionRate.toStringAsFixed(1)}%'),
                _buildInfoRow(
                    Icons.receipt, 'Áp dụng', _referrer!.commissionTypeText),
              ],
            ),

          if (_referrer != null) const SizedBox(height: 16),

          // Recent orders preview
          if (_orders.isNotEmpty)
            _buildSectionCard(
              title: 'Đơn hàng gần đây',
              icon: Icons.receipt_long,
              trailing: TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('Xem tất cả'),
              ),
              children: [
                ...(_orders.take(3).map((order) => _buildOrderRow(order))),
              ],
            ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'hot':
        color = Colors.red;
        label = 'Hot';
        icon = Icons.local_fire_department;
        break;
      case 'warm':
        color = Colors.orange;
        label = 'Warm';
        icon = Icons.whatshot;
        break;
      default:
        color = Colors.blue;
        label = 'Cold';
        icon = Icons.ac_unit;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _leadStatusDescription(String status) {
    switch (status) {
      case 'hot': return 'Khách hàng tiềm năng cao';
      case 'warm': return 'Đang quan tâm sản phẩm';
      default: return 'Chưa có nhu cầu rõ ràng';
    }
  }

  void _showEditLeadStatus() async {
    String selectedStatus = _customer.leadStatus;
    final notesController = TextEditingController(text: _customer.lastInteractionNotes ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.thermostat, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Cập nhật trạng thái KH', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mức độ quan tâm:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLeadStatusOption('cold', '❄️ Cold', Colors.blue, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                        const SizedBox(width: 8),
                        _buildLeadStatusOption('warm', '🔥 Warm', Colors.orange, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                        const SizedBox(width: 8),
                        _buildLeadStatusOption('hot', '🔴 Hot', Colors.red, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Ghi chú tương tác:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: KH quan tâm SP mới, hẹn gặp lại...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, {
                    'status': selectedStatus,
                    'notes': notesController.text.trim(),
                  }),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      await Supabase.instance.client.from('customers').update({
        'lead_status': result['status'],
        'last_interaction_notes': result['notes'],
        'last_interaction_date': DateTime.now().toIso8601String(),
        'last_interaction_by': currentUser?.id,
      }).eq('id', _customer.id);

      setState(() {
        _customer = _customer.copyWith(
          leadStatus: result['status'] as String,
          lastInteractionNotes: result['notes'] as String?,
          lastInteractionDate: DateTime.now(),
          lastInteractionBy: currentUser?.id,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái KH!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildLeadStatusOption(String value, String label, Color color, String selected, ValueChanged<String> onSelected) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey.shade700,
              fontSize: 13,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressRow(CustomerAddress addr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  addr.isDefault ? Colors.teal.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              size: 16,
              color: addr.isDefault ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(addr.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (addr.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Mặc định',
                            style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.surface)),
                      ),
                    ],
                  ],
                ),
                Text(
                  addr.fullAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final orderDate = DateTime.tryParse(order['order_date']?.toString() ?? '');
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final status = order['status'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.receipt, size: 16, color: _getStatusColor(status)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['order_number'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  orderDate != null
                      ? DateFormat('dd/MM/yyyy').format(orderDate)
                      : 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(_currencyFormat.format(total),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== ORDERS TAB ====================
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return _buildEmptyState(Icons.receipt_long, 'Chưa có đơn hàng',
          'Tạo đơn hàng đầu tiên cho khách hàng này');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderDate = DateTime.tryParse(order['order_date']?.toString() ?? '');
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0;
    final status = order['status'] as String?;
    final paymentStatus = order['payment_status'] as String?;
    final isCancelled = status == 'cancelled';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isCancelled ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt, color: _getStatusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order['order_number'] ?? 'N/A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                              _getStatusText(status), _getStatusColor(status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderDate != null
                            ? DateFormat('dd/MM/yyyy - HH:mm').format(orderDate)
                            : 'N/A',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isCancelled ? Colors.grey : Colors.teal,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (!isCancelled && paymentStatus != null)
                      _buildStatusChip(_getPaymentStatusText(paymentStatus),
                          _getPaymentStatusColor(paymentStatus)),
                  ],
                ),
              ],
            ),
            // Payment progress
            if (!isCancelled && paymentStatus == 'partial' && total > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: paidAmount / total,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade400),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currencyFormat.format(paidAmount)} / ${_currencyFormat.format(total)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  // ==================== DEBT TAB ====================
  Widget _buildDebtTab() {
    final unpaidOrders = _orders.where((o) {
      final status = o['status'] as String?;
      final total = (o['total'] as num?)?.toDouble() ?? 0;
      final paid = (o['paid_amount'] as num?)?.toDouble() ?? 0;
      return status != 'cancelled' && total > paid;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Tổng công nợ',
                    _currencyFormat.format(_totalDebt),
                    _totalDebt > 0 ? Colors.red : Colors.green,
                    Icons.account_balance_wallet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Đơn chưa TT', '${unpaidOrders.length}',
                    Colors.orange, Icons.receipt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Tổng mua',
                    _currencyFormat.format(_totalRevenue),
                    Colors.teal,
                    Icons.trending_up),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Đã thanh toán',
                    _currencyFormat.format(_totalRevenue - _totalDebt),
                    Colors.green,
                    Icons.check_circle),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Unpaid orders
          if (unpaidOrders.isEmpty)
            _buildEmptyState(Icons.check_circle, 'Không có công nợ',
                'Khách hàng đã thanh toán đầy đủ')
          else ...[
            Text('Đơn chưa thanh toán (${unpaidOrders.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...unpaidOrders.map((o) => _buildUnpaidOrderCard(o)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildUnpaidOrderCard(Map<String, dynamic> order) {
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final paid = (order['paid_amount'] as num?)?.toDouble() ?? 0;
    final debt = total - paid;
    final orderDate = DateTime.tryParse(order['order_date']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.receipt, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['order_number'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (orderDate != null)
                    Text(DateFormat('dd/MM/yyyy').format(orderDate),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Còn nợ',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(_currencyFormat.format(debt),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MẪU SP TAB ====================
  Widget _buildSamplesTab() {
    final samplesAsync = ref.watch(productSamplesProvider(
      ProductSampleFilters(customerId: _customer.id),
    ));

    return samplesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi tải dữ liệu: $e')),
      data: (samples) {
        if (samples.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Chưa có mẫu SP nào', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Gửi mẫu SP từ Kế hoạch viếng thăm', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        }

        // Group by status
        final statusOrder = ['pending', 'delivered', 'received', 'feedback_received', 'converted'];
        final statusCounts = <String, int>{};
        for (final s in samples) {
          statusCounts[s.status] = (statusCounts[s.status] ?? 0) + 1;
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productSamplesProvider(
              ProductSampleFilters(customerId: _customer.id),
            ));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSampleStatusChip('Tất cả', samples.length, Colors.grey),
                  for (final status in statusOrder)
                    if (statusCounts.containsKey(status))
                      _buildSampleStatusChip(
                        _sampleStatusLabel(status),
                        statusCounts[status]!,
                        _sampleStatusColor(status),
                      ),
                ],
              ),
              const SizedBox(height: 16),

              // Sample list
              ...samples.map((sample) => _buildSampleCard(sample)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSampleStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSampleCard(ProductSample sample) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: product name + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.card_giftcard, size: 20, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.productName ?? 'Sản phẩm',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sample.productSku != null)
                        Text(
                          'SKU: ${sample.productSku}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sampleStatusColor(sample.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sample.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _sampleStatusColor(sample.status),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Details
            Row(
              children: [
                _buildSampleDetail(Icons.inventory_2, 'SL: ${sample.quantity} ${sample.unit}'),
                const SizedBox(width: 16),
                _buildSampleDetail(Icons.calendar_today, DateFormat('dd/MM/yyyy').format(sample.sentDate)),
                if (sample.sentByName != null) ...[
                  const SizedBox(width: 16),
                  _buildSampleDetail(Icons.person, sample.sentByName!),
                ],
              ],
            ),

            // Notes
            if (sample.notes != null && sample.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notes, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sample.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Feedback
            if (sample.feedbackRating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < sample.feedbackRating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  )),
                  if (sample.feedbackNotes != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sample.feedbackNotes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Converted badge
            if (sample.convertedToOrder) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Đã chuyển đổi thành đơn hàng', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSampleDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  String _sampleStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ gửi';
      case 'delivered': return 'Đã gửi';
      case 'received': return 'Đã nhận';
      case 'feedback_received': return 'Phản hồi';
      case 'converted': return 'Đã mua';
      default: return status;
    }
  }

  Color _sampleStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'delivered': return Colors.blue;
      case 'received': return Colors.green;
      case 'feedback_received': return Colors.purple;
      case 'converted': return Colors.teal;
      default: return Colors.grey;
    }
  }

  // ==================== CƠ SỞ TAB ====================
  Widget _buildContactsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAddresses();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.store, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Cơ sở (${_addresses.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAddressDialog,
                icon: Icon(Icons.add, size: 18),
                label: Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_addresses.isEmpty)
            _buildEmptyCard(
                'Chưa có cơ sở nào', Icons.store_mall_directory_outlined)
          else
            ...(_addresses.map((a) => _buildBranchCard(a))),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBranchCard(CustomerAddress branch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: branch.isDefault
                ? Colors.purple.shade200
                : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon + Name + badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: branch.isDefault
                        ? Colors.purple.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store,
                      size: 20,
                      color: branch.isDefault
                          ? Colors.purple
                          : Colors.grey.shade600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(branch.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (branch.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('Chính',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: Colors.grey.shade600, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBranchDialog(branch);
                    } else if (value == 'delete') {
                      _deleteBranch(branch);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red))
                        ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Address
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.teal.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    branch.fullAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Contact person
            if (branch.contactPerson != null &&
                branch.contactPerson!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 6),
                  Text(branch.contactPerson!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ],
            // Phone
            if (branch.phone != null && branch.phone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.green.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(branch.phone!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ),
                  InkWell(
                    onTap: () => _makePhoneCall(branch.phone),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.phone,
                          color: Colors.green.shade600, size: 16),
                    ),
                  ),
                ],
              ),
            ],
            // Notes
            if (branch.notes != null && branch.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.note, size: 14, color: Colors.orange.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(branch.notes!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ==================== VISITS TAB ====================
  Widget _buildVisitsTab() {
    return Column(
      children: [
        // Header with add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử viếng thăm (${_visits.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: _showAddVisitDialog,
                icon: Icon(Icons.add, size: 18),
                label: Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _visits.isEmpty
              ? _buildEmptyVisitsState()
              : RefreshIndicator(
                  onRefresh: _loadVisits,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildVisitCard(_visits[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyVisitsState() {
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
            child:
                Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text('Chưa có lượt viếng thăm',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Nhấn "Thêm" để ghi nhận lượt viếng thăm',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
    final checkIn = DateTime.tryParse(visit['check_in_time']?.toString() ?? '');
    final checkOut = DateTime.tryParse(visit['check_out_time']?.toString() ?? '');
    final result = visit['result'] as String?;
    final purpose = visit['purpose'] as String?;
    final employee = visit['employee'] as Map<String, dynamic>?;
    final order = visit['order'] as Map<String, dynamic>?;
    final isJourney = visit['_source'] == 'journey';
    final durationMin = visit['duration_minutes'] as int?;
    final observations = visit['observations'] as String?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isJourney ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isJourney
                        ? Colors.blue.withOpacity(0.1)
                        : _getResultColor(result).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isJourney ? Icons.route : _getResultIcon(result),
                    color: isJourney ? Colors.blue : _getResultColor(result),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitDate != null
                            ? DateFormat('dd/MM/yyyy').format(visitDate)
                            : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (checkIn != null)
                        Text(
                          checkOut != null
                              ? '${DateFormat('HH:mm').format(checkIn)} → ${DateFormat('HH:mm').format(checkOut)}'
                              : 'Check-in: ${DateFormat('HH:mm').format(checkIn)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (durationMin != null)
                        Text(
                          'Thời gian: $durationMin phút',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (employee != null)
                        Text(
                          employee['full_name'] ?? '',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(
                      isJourney ? 'Hành trình' : 'Nhập tay',
                      isJourney ? Colors.blue : Colors.grey,
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 4),
                      _buildStatusChip(
                          _getResultText(result), _getResultColor(result)),
                    ],
                  ],
                ),
              ],
            ),
            if (purpose != null || order != null || observations != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (purpose != null)
                    _buildStatusChip(_getPurposeText(purpose), Colors.blue),
                  if (order != null)
                    _buildStatusChip(
                        'Đơn: ${order['order_number']}', Colors.green),
                ],
              ),
              if (observations != null && observations.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  observations,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ==================== ADD VISIT ====================
  Future<void> _showAddVisitDialog() async {
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? checkInTime;
    TimeOfDay? checkOutTime;
    String selectedPurpose = 'sales';
    String? selectedResult;
    bool isLoading = false;

    final purposeOptions = [
      {'value': 'sales', 'label': 'Bán hàng'},
      {'value': 'collection', 'label': 'Thu tiền'},
      {'value': 'support', 'label': 'Hỗ trợ'},
      {'value': 'survey', 'label': 'Khảo sát'},
      {'value': 'other', 'label': 'Khác'},
    ];

    final resultOptions = [
      {'value': null, 'label': 'Chưa có kết quả'},
      {'value': 'ordered', 'label': 'Đã đặt hàng'},
      {'value': 'no_order', 'label': 'Không đặt hàng'},
      {'value': 'not_available', 'label': 'Không gặp được'},
      {'value': 'rescheduled', 'label': 'Hẹn lại'},
    ];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_location_alt, color: Colors.teal),
              SizedBox(width: 8),
              Text('Thêm lượt viếng thăm'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.teal),
                    title: const Text('Ngày viếng thăm'),
                    subtitle:
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const Divider(),

                  // Check-in Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login, color: Colors.green),
                    title: const Text('Giờ check-in'),
                    subtitle: Text(checkInTime?.format(context) ?? 'Chưa chọn'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: checkInTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => checkInTime = picked);
                            }
                          },
                        ),
                        if (checkInTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () =>
                                setDialogState(() => checkInTime = null),
                          ),
                      ],
                    ),
                  ),

                  // Check-out Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Giờ check-out'),
                    subtitle:
                        Text(checkOutTime?.format(context) ?? 'Chưa chọn'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: checkOutTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => checkOutTime = picked);
                            }
                          },
                        ),
                        if (checkOutTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () =>
                                setDialogState(() => checkOutTime = null),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Purpose dropdown
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: const InputDecoration(
                      labelText: 'Mục đích viếng thăm',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
                    items: purposeOptions
                        .map((opt) => DropdownMenuItem(
                              value: opt['value'] as String,
                              child: Text(opt['label'] as String),
                            ))
                        .toList(),
                    onChanged: (value) => setDialogState(
                        () => selectedPurpose = value ?? 'sales'),
                  ),
                  const SizedBox(height: 12),

                  // Result dropdown
                  DropdownButtonFormField<String?>(
                    value: selectedResult,
                    decoration: const InputDecoration(
                      labelText: 'Kết quả',
                      prefixIcon: Icon(Icons.check_circle_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: resultOptions
                        .map((opt) => DropdownMenuItem(
                              value: opt['value'],
                              child: Text(opt['label'] as String),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedResult = value),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Lỗi: Không xác định được người dùng'),
                                backgroundColor: Colors.red),
                          );
                          setDialogState(() => isLoading = false);
                          return;
                        }

                        // Build check-in/out times
                        DateTime? checkInDateTime;
                        DateTime? checkOutDateTime;

                        if (checkInTime != null) {
                          checkInDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            checkInTime!.hour,
                            checkInTime!.minute,
                          );
                        }
                        if (checkOutTime != null) {
                          checkOutDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            checkOutTime!.hour,
                            checkOutTime!.minute,
                          );
                        }

                        await supabase.from('customer_visits').insert({
                          'company_id': user.companyId,
                          'customer_id': _customer.id,
                          'employee_id': user.id,
                          'visit_date':
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                          'check_in_time': checkInDateTime?.toIso8601String(),
                          'check_out_time': checkOutDateTime?.toIso8601String(),
                          'purpose': selectedPurpose,
                          'result': selectedResult,
                          'notes': notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Theme.of(context).colorScheme.surface),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadVisits();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã thêm lượt viếng thăm'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== EDIT CUSTOMER ====================
  Future<void> _showEditCustomerDialog() async {
    final nameController = TextEditingController(text: _customer.name);
    final phoneController = TextEditingController(text: _customer.phone ?? '');
    final phone2Controller =
        TextEditingController(text: _customer.phone2 ?? '');
    final emailController = TextEditingController(text: _customer.email ?? '');
    final contactPersonController =
        TextEditingController(text: _customer.contactPerson ?? '');
    final streetNumberController =
        TextEditingController(text: _customer.streetNumber ?? '');
    final streetController =
        TextEditingController(text: _customer.street ?? '');

    // Vietnamese Address Selection using dvhcvn
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];

    // Initialize - default to HCM
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;

      // Try to match existing district from customer data
      if (_customer.district != null && _customer.district!.isNotEmpty) {
        for (final d in districts) {
          if (d.name.contains(_customer.district!) ||
              _customer.district!.contains(d.name.replaceAll(
                  RegExp(r'^(Quận |Huyện |Thành phố |Thị xã )'), ''))) {
            selectedDistrict = d;
            wards = d.children;
            break;
          }
        }
      }
      // Try to match existing ward
      if (_customer.ward != null &&
          _customer.ward!.isNotEmpty &&
          selectedDistrict != null) {
        for (final w in wards) {
          if (w.name.contains(_customer.ward!) ||
              _customer.ward!.contains(
                  w.name.replaceAll(RegExp(r'^(Phường |Xã |Thị trấn )'), ''))) {
            selectedWard = w;
            break;
          }
        }
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.teal),
              SizedBox(width: 8),
              Text('Chỉnh sửa khách hàng'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên khách hàng *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone2Controller,
                    decoration: const InputDecoration(
                      labelText: 'SĐT 2',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Người liên hệ',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === Structured Address Section ===
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text('Địa chỉ',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: streetNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Số nhà',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: streetController,
                          decoration: const InputDecoration(
                            labelText: 'Tên đường',
                            border: OutlineInputBorder(),
                            hintText: 'VD: Dương Đình Hội',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<dvhcvn.Level2>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: districts
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child:
                                  Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDistrict = value;
                        selectedWard = null;
                        wards = value?.children ?? [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<dvhcvn.Level3>(
                    value: selectedWard,
                    decoration: const InputDecoration(
                      labelText: 'Phường/Xã *',
                      prefixIcon: Icon(Icons.house),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: wards
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child:
                                  Text(w.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedWard = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng nhập tên khách hàng'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  // Build full address from structured fields
                  final addressParts = <String>[];
                  if (streetNumberController.text.trim().isNotEmpty) {
                    addressParts.add(streetNumberController.text.trim());
                  }
                  if (streetController.text.trim().isNotEmpty) {
                    addressParts.add(streetController.text.trim());
                  }
                  if (selectedWard != null) {
                    addressParts.add(selectedWard!.name);
                  }
                  if (selectedDistrict != null) {
                    addressParts.add(selectedDistrict!.name);
                  }
                  if (selectedCity != null) {
                    addressParts.add(selectedCity.name);
                  }
                  final fullAddress = addressParts.join(', ');

                  // Auto-geocode if address changed and we have district info
                  double? latitude;
                  double? longitude;
                  if (selectedDistrict != null) {
                    final coords = await GeocodingService.geocodeFromFields(
                      streetNumber: streetNumberController.text.trim(),
                      street: streetController.text.trim(),
                      ward: selectedWard?.name,
                      district: selectedDistrict?.name,
                      city: selectedCity?.name,
                    );
                    if (coords != null) {
                      latitude = coords.lat;
                      longitude = coords.lng;
                    }
                  }

                  await supabase.from('customers').update({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'phone2': phone2Controller.text.trim().isEmpty
                        ? null
                        : phone2Controller.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    'contact_person':
                        contactPersonController.text.trim().isEmpty
                            ? null
                            : contactPersonController.text.trim(),
                    'street_number': streetNumberController.text.trim().isEmpty
                        ? null
                        : streetNumberController.text.trim(),
                    'street': streetController.text.trim().isEmpty
                        ? null
                        : streetController.text.trim(),
                    'ward': selectedWard?.name
                        .replaceAll(RegExp(r'^(Phường |Xã |Thị trấn )'), ''),
                    'district': selectedDistrict?.name.replaceAll(
                        RegExp(r'^(Quận |Huyện |Thành phố |Thị xã )'), ''),
                    'city': selectedCity?.name
                        .replaceAll(RegExp(r'^(Thành phố |Tỉnh )'), ''),
                    'address': fullAddress.isNotEmpty ? fullAddress : null,
                    'lat': latitude,
                    'lng': longitude,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', _customer.id);

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Theme.of(context).colorScheme.surface),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Reload customer data
      final response = await supabase
          .from('customers')
          .select()
          .eq('id', _customer.id)
          .single();
      setState(() {
        _customer = OdoriCustomer.fromJson(response);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã cập nhật khách hàng'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== CHỈNH SỬA CƠ SỞ ====================
  Future<void> _showEditBranchDialog(CustomerAddress branch) async {
    final nameController = TextEditingController(text: branch.name);
    final addressController = TextEditingController(text: branch.address);
    final contactPersonController =
        TextEditingController(text: branch.contactPerson ?? '');
    final phoneController = TextEditingController(text: branch.phone ?? '');
    final noteController = TextEditingController(text: branch.notes ?? '');
    bool isDefault = branch.isDefault;

    // Vietnamese Address Selection using dvhcvn
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];

    // Initialize with Ho Chi Minh City as default
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;

      // Try to match existing district
      if (branch.district != null) {
        for (final d in districts) {
          if (d.name == branch.district) {
            selectedDistrict = d;
            wards = d.children;
            break;
          }
        }
      }
      // Try to match existing ward
      if (branch.ward != null && selectedDistrict != null) {
        for (final w in wards) {
          if (w.name == branch.ward) {
            selectedWard = w;
            break;
          }
        }
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_location_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text('Chỉnh sửa cơ sở'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên cơ sở *',
                      hintText: 'VD: Cửa hàng chính, Kho, Chi nhánh Q7...',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ *',
                      hintText: 'Số nhà, đường...',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Quận/Huyện dropdown
                  DropdownButtonFormField<dvhcvn.Level2>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: districts
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child:
                                  Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDistrict = value;
                        selectedWard = null;
                        wards = value?.children ?? [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phường/Xã dropdown
                  DropdownButtonFormField<dvhcvn.Level3>(
                    value: selectedWard,
                    decoration: const InputDecoration(
                      labelText: 'Phường/Xã *',
                      prefixIcon: Icon(Icons.house),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: wards
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child:
                                  Text(w.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedWard = value),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Người liên hệ',
                      hintText: 'Tên người phụ trách tại cơ sở...',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (v) =>
                        setDialogState(() => isDefault = v ?? false),
                    title: const Text('Cơ sở chính'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng nhập tên và địa chỉ'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                if (selectedDistrict == null || selectedWard == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng chọn Quận/Huyện và Phường/Xã'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  // If this will be default, unset other defaults first
                  if (isDefault && !branch.isDefault) {
                    await supabase.from('customer_addresses').update(
                        {'is_default': false}).eq('customer_id', _customer.id);
                  }

                  await supabase.from('customer_addresses').update({
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'ward': selectedWard?.name,
                    'district': selectedDistrict?.name,
                    'city': selectedCity?.name ?? 'Thành phố Hồ Chí Minh',
                    'contact_person':
                        contactPersonController.text.trim().isEmpty
                            ? null
                            : contactPersonController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'notes': noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    'is_default': isDefault,
                  }).eq('id', branch.id);

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Theme.of(context).colorScheme.surface),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadAddresses();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã cập nhật cơ sở'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== XÓA CƠ SỞ ====================
  Future<void> _deleteBranch(CustomerAddress branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn xóa cơ sở '),
              TextSpan(
                  text: branch.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Theme.of(context).colorScheme.surface),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Soft delete
        await supabase
            .from('customer_addresses')
            .update({'is_active': false}).eq('id', branch.id);

        await _loadAddresses();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('✅ Đã xóa cơ sở "${branch.name}"'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ==================== THÊM CƠ SỞ ====================
  Future<void> _showAddAddressDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final contactPersonController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    bool isDefault = _addresses.isEmpty; // Default if no addresses exist

    // Vietnamese Address Selection using dvhcvn
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];

    // Initialize with Ho Chi Minh City as default
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_business, color: Colors.purple),
              SizedBox(width: 8),
              Text('Thêm cơ sở'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên cơ sở *',
                      hintText: 'VD: Cửa hàng chính, Kho, Chi nhánh Q7...',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ *',
                      hintText: 'Số nhà, đường...',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Quận/Huyện dropdown
                  DropdownButtonFormField<dvhcvn.Level2>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: districts
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child:
                                  Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDistrict = value;
                        selectedWard = null;
                        wards = value?.children ?? [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phường/Xã dropdown
                  DropdownButtonFormField<dvhcvn.Level3>(
                    value: selectedWard,
                    decoration: const InputDecoration(
                      labelText: 'Phường/Xã *',
                      prefixIcon: Icon(Icons.house),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: wards
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child:
                                  Text(w.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedWard = value),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Người liên hệ',
                      hintText: 'Tên người phụ trách tại cơ sở...',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (v) =>
                        setDialogState(() => isDefault = v ?? false),
                    title: const Text('Cơ sở chính'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng nhập tên và địa chỉ'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                if (selectedDistrict == null || selectedWard == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng chọn Quận/Huyện và Phường/Xã'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final user = ref.read(currentUserProvider);
                  if (user?.companyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Lỗi: Không xác định được công ty'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  // If this will be default, unset other defaults first
                  if (isDefault && _addresses.isNotEmpty) {
                    await supabase.from('customer_addresses').update(
                        {'is_default': false}).eq('customer_id', _customer.id);
                  }

                  await supabase.from('customer_addresses').insert({
                    'company_id': user!.companyId,
                    'customer_id': _customer.id,
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'ward': selectedWard?.name,
                    'district': selectedDistrict?.name,
                    'city': selectedCity?.name ?? 'Thành phố Hồ Chí Minh',
                    'contact_person':
                        contactPersonController.text.trim().isEmpty
                            ? null
                            : contactPersonController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'notes': noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    'is_default': isDefault,
                    'is_active': true,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Theme.of(context).colorScheme.surface),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadAddresses();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã thêm cơ sở'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== ARCHIVE/RESTORE ====================
  Future<void> _toggleArchiveCustomer() async {
    final isArchived = _customer.status == 'inactive';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isArchived ? Icons.unarchive : Icons.archive,
                color: Colors.orange),
            SizedBox(width: 12),
            Text(isArchived ? 'Khôi phục khách hàng?' : 'Lưu trữ khách hàng?'),
          ],
        ),
        content: Text(
          isArchived
              ? 'Khách hàng "${_customer.name}" sẽ được khôi phục về trạng thái hoạt động.'
              : 'Khách hàng "${_customer.name}" sẽ được chuyển vào mục lưu trữ. Bạn có thể khôi phục lại bất cứ lúc nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Theme.of(context).colorScheme.surface),
            child: Text(isArchived ? 'Khôi phục' : 'Lưu trữ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final newStatus = isArchived ? 'active' : 'inactive';
        await supabase
            .from('customers')
            .update({'status': newStatus}).eq('id', _customer.id);

        // Reload customer data
        final response = await supabase
            .from('customers')
            .select()
            .eq('id', _customer.id)
            .single();
        setState(() {
          _customer = OdoriCustomer.fromJson(response);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArchived
                  ? '✅ Đã khôi phục khách hàng'
                  : '✅ Đã lưu trữ khách hàng'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ==================== DELETE ====================
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa khách hàng "${_customer.name}"?'),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Hành động này không thể hoàn tác!',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Theme.of(context).colorScheme.surface),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Soft delete - sets status='inactive'
      await supabase.from('customers').update({'status': 'inactive', 'updated_at': DateTime.now().toIso8601String()}).eq('id', _customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Đã xóa khách hàng "${_customer.name}"'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== HELPERS ====================
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'confirmed':
      case 'sent_to_warehouse':
      case 'approved':
        return Colors.teal;
      case 'delivering':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'pending':
        return 'Chờ duyệt';
      case 'cancelled':
        return 'Đã hủy';
      case 'processing':
        return 'Đang xử lý';
      case 'confirmed':
      case 'sent_to_warehouse':
      case 'approved':
        return 'Đã duyệt';
      case 'delivering':
        return 'Đang giao';
      default:
        return status ?? 'N/A';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'Đã TT';
      case 'partial':
        return 'TT 1 phần';
      case 'unpaid':
        return 'Chưa TT';
      default:
        return status ?? '';
    }
  }

  String _getPurposeText(String? purpose) {
    switch (purpose) {
      case 'sales':
        return 'Bán hàng';
      case 'collect':
      case 'collection':
        return 'Thu tiền';
      case 'survey':
        return 'Khảo sát';
      case 'delivery':
        return 'Giao hàng';
      case 'support':
        return 'Hỗ trợ';
      case 'introduction':
        return 'Giới thiệu SP';
      case 'routine':
      case 'scheduled':
        return 'Ghé định kỳ';
      case 'merchandising':
        return 'Trưng bày';
      case 'complaint':
        return 'Khiếu nại';
      default:
        return purpose ?? 'Khác';
    }
  }

  String _getResultText(String? result) {
    switch (result) {
      case 'ordered':
        return 'Đặt hàng';
      case 'no_order':
        return 'Không đặt';
      case 'closed':
        return 'Đóng cửa';
      case 'not_available':
        return 'Không gặp';
      case 'collected':
        return 'Đã thu tiền';
      case 'pending':
        return 'Đang xử lý';
      default:
        return result ?? 'N/A';
    }
  }

  Color _getResultColor(String? result) {
    switch (result) {
      case 'ordered':
      case 'collected':
        return Colors.green;
      case 'no_order':
      case 'not_available':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getResultIcon(String? result) {
    switch (result) {
      case 'ordered':
        return Icons.shopping_cart;
      case 'collected':
        return Icons.payments;
      case 'no_order':
        return Icons.remove_shopping_cart;
      case 'closed':
        return Icons.store_outlined;
      case 'not_available':
        return Icons.person_off;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.place;
    }
  }
}
