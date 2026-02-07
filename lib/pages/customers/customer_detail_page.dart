import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;
import '../../business_types/distribution/models/odori_customer.dart';
import '../../models/customer_contact.dart';
import '../../models/customer_address.dart';
import '../../models/customer_tier.dart';
import '../../models/referrer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/customer_tier_widgets.dart';
import '../../widgets/customer_avatar.dart';
import '../orders/order_form_page.dart';

final supabase = Supabase.instance.client;
final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

class CustomerDetailPage extends ConsumerStatefulWidget {
  final OdoriCustomer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OdoriCustomer _customer;
  bool _isLoading = true;

  // Data
  List<CustomerAddress> _addresses = [];
  List<CustomerContact> _contacts = [];
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
    _tabController = TabController(length: 5, vsync: this);
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
      debugPrint('Error loading customer data: $e');
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
      debugPrint('Error loading referrer: $e');
    }
  }

  Future<void> _loadAddresses() async {
    final response = await supabase
        .from('customer_addresses')
        .select()
        .eq('customer_id', _customer.id)
        .eq('is_active', true)
        .order('is_default', ascending: false);
    
    _addresses = (response as List).map((e) => CustomerAddress.fromJson(e)).toList();
  }

  Future<void> _loadContacts() async {
    final response = await supabase
        .from('customer_contacts')
        .select('*, customer_addresses(name)')
        .eq('customer_id', _customer.id)
        .eq('is_active', true)
        .order('is_primary', ascending: false);
    
    _contacts = (response as List).map((e) => CustomerContact.fromJson(e)).toList();
  }

  Future<void> _loadOrders() async {
    final response = await supabase
        .from('sales_orders')
        .select('id, order_number, order_date, total, paid_amount, status, payment_status, delivery_status')
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
    final response = await supabase
        .from('customer_visits')
        .select('id, visit_date, check_in_time, check_out_time, purpose, result, employee:employee_id(full_name), order:order_id(order_number)')
        .eq('customer_id', _customer.id)
        .order('visit_date', ascending: false)
        .limit(50);
    
    _visits = List<Map<String, dynamic>>.from(response);
    _visitCount = _visits.length;
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại'), backgroundColor: Colors.orange),
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
        SnackBar(content: Text('Đã copy $label'), duration: const Duration(seconds: 1)),
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
      foregroundColor: Colors.white,
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
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customer.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_customer.code != null)
                              Text(
                                _customer.code!,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (_customer.category != null)
                                  _buildHeaderChip(_customer.category!, Colors.white.withOpacity(0.2)),
                                if (_customer.tier != null) ...[
                                  const SizedBox(width: 8),
                                  CustomerTierBadge(tier: CustomerTierExtension.fromString(_customer.tier)),
                                ],
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
                      _buildQuickStat('Doanh thu', _formatCompact(_totalRevenue)),
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
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Chỉnh sửa')])),
            PopupMenuItem(
              value: 'archive', 
              child: Row(children: [
                Icon(_customer.status == 'archived' ? Icons.unarchive : Icons.archive, size: 20, color: Colors.orange), 
                const SizedBox(width: 8), 
                Text(_customer.status == 'archived' ? 'Khôi phục' : 'Lưu trữ', style: const TextStyle(color: Colors.orange)),
              ]),
            ),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
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
      foregroundColor: Colors.white,
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
                _buildInfoRow(Icons.phone, 'Điện thoại', _customer.phone!, onTap: () => _makePhoneCall(_customer.phone), onLongPress: () => _copyToClipboard(_customer.phone!, 'SĐT')),
              if (_customer.phone2 != null)
                _buildInfoRow(Icons.phone_android, 'SĐT 2', _customer.phone2!, onTap: () => _makePhoneCall(_customer.phone2), onLongPress: () => _copyToClipboard(_customer.phone2!, 'SĐT')),
              if (_customer.email != null)
                _buildInfoRow(Icons.email, 'Email', _customer.email!, onLongPress: () => _copyToClipboard(_customer.email!, 'Email')),
              if (_customer.contactPerson != null)
                _buildInfoRow(Icons.person, 'Người liên hệ', _customer.contactPerson!),
            ],
          ),

          const SizedBox(height: 16),

          // Address card
          _buildSectionCard(
            title: 'Địa chỉ',
            icon: Icons.location_on,
            trailing: _addresses.isNotEmpty 
                ? Text('${_addresses.length} địa chỉ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                : null,
            children: [
              _buildInfoRow(Icons.home, 'Địa chỉ chính', _customer.address ?? 'Chưa có'),
              if (_customer.ward != null || _customer.district != null || _customer.city != null)
                _buildInfoRow(Icons.map, 'Khu vực', [_customer.ward, _customer.district, _customer.city].where((e) => e != null).join(', ')),
              if (_addresses.isNotEmpty) ...[
                const Divider(height: 24),
                ...(_addresses.take(3).map((addr) => _buildAddressRow(addr))),
                if (_addresses.length > 3)
                  TextButton(
                    onPressed: () => _tabController.animateTo(3),
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
              if (_customer.paymentTerms != null)
                _buildInfoRow(Icons.schedule, 'Kỳ hạn TT', '${_customer.paymentTerms} ngày'),
              if (_customer.creditLimit != null)
                _buildInfoRow(Icons.credit_card, 'Hạn mức', _currencyFormat.format(_customer.creditLimit)),
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
                  _buildInfoRow(Icons.phone, 'SĐT', _referrer!.phone!, onTap: () => _makePhoneCall(_referrer!.phone)),
                _buildInfoRow(Icons.percent, 'Hoa hồng', '${_referrer!.commissionRate.toStringAsFixed(1)}%'),
                _buildInfoRow(Icons.receipt, 'Áp dụng', _referrer!.commissionTypeText),
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
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap, VoidCallback? onLongPress}) {
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
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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

  Widget _buildAddressRow(CustomerAddress addr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: addr.isDefault ? Colors.teal.shade50 : Colors.grey.shade100,
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
                    Text(addr.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (addr.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Mặc định', style: TextStyle(fontSize: 9, color: Colors.white)),
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
            child: Icon(Icons.receipt, size: 16, color: _getStatusColor(status)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['order_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  orderDate != null ? DateFormat('dd/MM/yyyy').format(orderDate) : 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(_currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== ORDERS TAB ====================
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return _buildEmptyState(Icons.receipt_long, 'Chưa có đơn hàng', 'Tạo đơn hàng đầu tiên cho khách hàng này');
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
        side: BorderSide(color: isCancelled ? Colors.red.shade200 : Colors.grey.shade200),
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
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(_getStatusText(status), _getStatusColor(status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderDate != null ? DateFormat('dd/MM/yyyy - HH:mm').format(orderDate) : 'N/A',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (!isCancelled && paymentStatus != null)
                      _buildStatusChip(_getPaymentStatusText(paymentStatus), _getPaymentStatusColor(paymentStatus)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
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
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
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
                child: _buildStatCard('Tổng công nợ', _currencyFormat.format(_totalDebt), 
                    _totalDebt > 0 ? Colors.red : Colors.green, Icons.account_balance_wallet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Đơn chưa TT', '${unpaidOrders.length}', Colors.orange, Icons.receipt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Tổng mua', _currencyFormat.format(_totalRevenue), Colors.teal, Icons.trending_up),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Đã thanh toán', _currencyFormat.format(_totalRevenue - _totalDebt), Colors.green, Icons.check_circle),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Unpaid orders
          if (unpaidOrders.isEmpty)
            _buildEmptyState(Icons.check_circle, 'Không có công nợ', 'Khách hàng đã thanh toán đầy đủ')
          else ...[
            Text('Đơn chưa thanh toán (${unpaidOrders.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...unpaidOrders.map((o) => _buildUnpaidOrderCard(o)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
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
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                  Text(order['order_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (orderDate != null)
                    Text(DateFormat('dd/MM/yyyy').format(orderDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Còn nợ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(_currencyFormat.format(debt), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
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
                child: Text('Cơ sở (${_addresses.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAddressDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_addresses.isEmpty)
            _buildEmptyCard('Chưa có cơ sở nào', Icons.store_mall_directory_outlined)
          else
            ...(_addresses.map((a) => _buildBranchCard(a))),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildContactCard(CustomerContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: contact.isPrimary ? Colors.purple.shade200 : Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CustomerAvatar(
          seed: contact.name,
          radius: 20,
        ),
        title: Row(
          children: [
            Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                child: const Text('Chính', style: TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.position != null)
              Text(contact.position!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (contact.phone != null)
              Text(contact.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: contact.phone != null
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(contact.phone),
              )
            : null,
        isThreeLine: contact.position != null && contact.phone != null,
      ),
    );
  }

  Widget _buildBranchCard(CustomerAddress branch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: branch.isDefault ? Colors.purple.shade200 : Colors.grey.shade200),
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
                    color: branch.isDefault ? Colors.purple.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, size: 20, color: branch.isDefault ? Colors.purple : Colors.grey.shade600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                      ),
                      if (branch.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Chính', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
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
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Chỉnh sửa')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
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
            if (branch.contactPerson != null && branch.contactPerson!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 6),
                  Text(branch.contactPerson!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
                    child: Text(branch.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
                      child: Icon(Icons.phone, color: Colors.green.shade600, size: 16),
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
                    child: Text(branch.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: _showAddVisitDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    itemBuilder: (context, index) => _buildVisitCard(_visits[index]),
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
            child: Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text('Chưa có lượt viếng thăm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Nhấn "Thêm" để ghi nhận lượt viếng thăm', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
    final checkIn = DateTime.tryParse(visit['check_in_time']?.toString() ?? '');
    final result = visit['result'] as String?;
    final purpose = visit['purpose'] as String?;
    final employee = visit['employee'] as Map<String, dynamic>?;
    final order = visit['order'] as Map<String, dynamic>?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
                    color: _getResultColor(result).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getResultIcon(result), color: _getResultColor(result)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitDate != null ? DateFormat('dd/MM/yyyy').format(visitDate) : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (checkIn != null)
                        Text(
                          'Check-in: ${DateFormat('HH:mm').format(checkIn)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (employee != null)
                        Text(
                          employee['full_name'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                if (result != null)
                  _buildStatusChip(_getResultText(result), _getResultColor(result)),
              ],
            ),
            if (purpose != null || order != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (purpose != null)
                    _buildStatusChip(_getPurposeText(purpose), Colors.blue),
                  if (order != null)
                    _buildStatusChip('Đơn: ${order['order_number']}', Colors.green),
                ],
              ),
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
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500), textAlign: TextAlign.center),
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
          title: const Row(
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
                    leading: const Icon(Icons.calendar_today, color: Colors.teal),
                    title: const Text('Ngày viếng thăm'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                            onPressed: () => setDialogState(() => checkInTime = null),
                          ),
                      ],
                    ),
                  ),
                  
                  // Check-out Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Giờ check-out'),
                    subtitle: Text(checkOutTime?.format(context) ?? 'Chưa chọn'),
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
                            onPressed: () => setDialogState(() => checkOutTime = null),
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
                    items: purposeOptions.map((opt) => DropdownMenuItem(
                      value: opt['value'] as String,
                      child: Text(opt['label'] as String),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedPurpose = value ?? 'sales'),
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
                    items: resultOptions.map((opt) => DropdownMenuItem(
                      value: opt['value'] as String?,
                      child: Text(opt['label'] as String),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedResult = value),
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                try {
                  final user = ref.read(authProvider).user;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi: Không xác định được người dùng'), backgroundColor: Colors.red),
                    );
                    setDialogState(() => isLoading = false);
                    return;
                  }
                  
                  // Build check-in/out times
                  DateTime? checkInDateTime;
                  DateTime? checkOutDateTime;
                  
                  if (checkInTime != null) {
                    checkInDateTime = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      checkInTime!.hour, checkInTime!.minute,
                    );
                  }
                  if (checkOutTime != null) {
                    checkOutDateTime = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      checkOutTime!.hour, checkOutTime!.minute,
                    );
                  }
                  
                  await supabase.from('customer_visits').insert({
                    'company_id': user.companyId,
                    'customer_id': _customer.id,
                    'employee_id': user.id,
                    'visit_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    'check_in_time': checkInDateTime?.toIso8601String(),
                    'check_out_time': checkOutDateTime?.toIso8601String(),
                    'purpose': selectedPurpose,
                    'result': selectedResult,
                    'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  });
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
          const SnackBar(content: Text('✅ Đã thêm lượt viếng thăm'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== EDIT CUSTOMER ====================
  Future<void> _showEditCustomerDialog() async {
    final nameController = TextEditingController(text: _customer.name);
    final phoneController = TextEditingController(text: _customer.phone ?? '');
    final phone2Controller = TextEditingController(text: _customer.phone2 ?? '');
    final emailController = TextEditingController(text: _customer.email ?? '');
    final contactPersonController = TextEditingController(text: _customer.contactPerson ?? '');
    final addressController = TextEditingController(text: _customer.address ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.teal),
            SizedBox(width: 8),
            Text('Chỉnh sửa khách hàng'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách hàng *',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'SĐT 2',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Người liên hệ',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên khách hàng'), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                await supabase.from('customers').update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  'phone_2': phone2Controller.text.trim().isEmpty ? null : phone2Controller.text.trim(),
                  'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  'contact_person': contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                  'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', _customer.id);
                
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // Reload customer data
      final response = await supabase.from('customers').select().eq('id', _customer.id).single();
      setState(() {
        _customer = OdoriCustomer.fromJson(response);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã cập nhật khách hàng'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== ADD CONTACT ====================
  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final positionController = TextEditingController();
    bool isPrimary = _contacts.isEmpty; // Default to primary if no contacts exist
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Colors.purple),
              SizedBox(width: 8),
              Text('Thêm cơ sở / chi nhánh'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên cơ sở / chi nhánh *',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (v) => setDialogState(() => isPrimary = v ?? false),
                  title: const Text('Cơ sở chính'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên và số điện thoại'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                try {
                  // If this will be primary, unset other primaries first
                  if (isPrimary && _contacts.isNotEmpty) {
                    await supabase.from('customer_contacts')
                        .update({'is_primary': false})
                        .eq('customer_id', _customer.id);
                  }
                  
                  final user = ref.read(authProvider).user;
                  if (user?.companyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi: Không xác định được công ty'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  await supabase.from('customer_contacts').insert({
                    'customer_id': _customer.id,
                    'company_id': user!.companyId,
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    'position': positionController.text.trim().isEmpty ? null : positionController.text.trim(),
                    'is_primary': isPrimary,
                    'is_active': true,
                  });
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      await _loadContacts();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm cơ sở'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== CHỈNH SỬA CƠ SỞ ====================
  Future<void> _showEditBranchDialog(CustomerAddress branch) async {
    final nameController = TextEditingController(text: branch.name);
    final addressController = TextEditingController(text: branch.address);
    final contactPersonController = TextEditingController(text: branch.contactPerson ?? '');
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
          title: const Row(
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
                    items: districts.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
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
                    items: wards.map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedWard = value),
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
                    onChanged: (v) => setDialogState(() => isDefault = v ?? false),
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên và địa chỉ'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                if (selectedDistrict == null || selectedWard == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn Quận/Huyện và Phường/Xã'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                try {
                  // If this will be default, unset other defaults first
                  if (isDefault && !branch.isDefault) {
                    await supabase.from('customer_addresses')
                        .update({'is_default': false})
                        .eq('customer_id', _customer.id);
                  }
                  
                  await supabase.from('customer_addresses').update({
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'ward': selectedWard?.name,
                    'district': selectedDistrict?.name,
                    'city': selectedCity?.name ?? 'Thành phố Hồ Chí Minh',
                    'contact_person': contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    'notes': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    'is_default': isDefault,
                  }).eq('id', branch.id);
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
          const SnackBar(content: Text('✅ Đã cập nhật cơ sở'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== XÓA CƠ SỞ ====================
  Future<void> _deleteBranch(CustomerAddress branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
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
              TextSpan(text: branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // Soft delete
        await supabase.from('customer_addresses')
            .update({'is_active': false})
            .eq('id', branch.id);
        
        await _loadAddresses();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Đã xóa cơ sở "${branch.name}"'), backgroundColor: Colors.green),
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
          title: const Row(
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
                    items: districts.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
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
                    items: wards.map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedWard = value),
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
                    onChanged: (v) => setDialogState(() => isDefault = v ?? false),
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên và địa chỉ'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                if (selectedDistrict == null || selectedWard == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn Quận/Huyện và Phường/Xã'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                try {
                  final user = ref.read(authProvider).user;
                  if (user?.companyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi: Không xác định được công ty'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  // If this will be default, unset other defaults first
                  if (isDefault && _addresses.isNotEmpty) {
                    await supabase.from('customer_addresses')
                        .update({'is_default': false})
                        .eq('customer_id', _customer.id);
                  }
                  
                  await supabase.from('customer_addresses').insert({
                    'company_id': user!.companyId,
                    'customer_id': _customer.id,
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'ward': selectedWard?.name,
                    'district': selectedDistrict?.name,
                    'city': selectedCity?.name ?? 'Thành phố Hồ Chí Minh',
                    'contact_person': contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    'notes': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    'is_default': isDefault,
                    'is_active': true,
                  });
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
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
          const SnackBar(content: Text('✅ Đã thêm cơ sở'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ==================== ARCHIVE/RESTORE ====================
  Future<void> _toggleArchiveCustomer() async {
    final isArchived = _customer.status == 'archived';
    final action = isArchived ? 'khôi phục' : 'lưu trữ';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isArchived ? Icons.unarchive : Icons.archive, color: Colors.orange),
            const SizedBox(width: 12),
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: Text(isArchived ? 'Khôi phục' : 'Lưu trữ'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final newStatus = isArchived ? 'active' : 'archived';
        await supabase.from('customers')
            .update({'status': newStatus})
            .eq('id', _customer.id);
        
        // Reload customer data
        final response = await supabase.from('customers').select().eq('id', _customer.id).single();
        setState(() {
          _customer = OdoriCustomer.fromJson(response);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArchived ? '✅ Đã khôi phục khách hàng' : '✅ Đã lưu trữ khách hàng'),
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
            const SizedBox(height: 12),
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
                  Expanded(child: Text('Hành động này không thể hoàn tác!', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('customers').delete().eq('id', _customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đã xóa khách hàng "${_customer.name}"'), backgroundColor: Colors.green),
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
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      case 'approved': return Colors.teal;
      case 'delivering': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'pending': return 'Chờ duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'processing': return 'Đang xử lý';
      case 'approved': return 'Đã duyệt';
      case 'delivering': return 'Đang giao';
      default: return status ?? 'N/A';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'unpaid': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid': return 'Đã TT';
      case 'partial': return 'TT 1 phần';
      case 'unpaid': return 'Chưa TT';
      default: return status ?? '';
    }
  }

  String _getPurposeText(String? purpose) {
    switch (purpose) {
      case 'sales': return 'Bán hàng';
      case 'collect': return 'Thu tiền';
      case 'survey': return 'Khảo sát';
      case 'delivery': return 'Giao hàng';
      case 'support': return 'Hỗ trợ';
      case 'introduction': return 'Giới thiệu SP';
      default: return purpose ?? 'Khác';
    }
  }

  String _getResultText(String? result) {
    switch (result) {
      case 'ordered': return 'Đặt hàng';
      case 'no_order': return 'Không đặt';
      case 'closed': return 'Đóng cửa';
      case 'not_available': return 'Không gặp';
      case 'collected': return 'Đã thu tiền';
      case 'pending': return 'Đang xử lý';
      default: return result ?? 'N/A';
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
      case 'ordered': return Icons.shopping_cart;
      case 'collected': return Icons.payments;
      case 'no_order': return Icons.remove_shopping_cart;
      case 'closed': return Icons.store_outlined;
      case 'not_available': return Icons.person_off;
      case 'pending': return Icons.hourglass_empty;
      default: return Icons.place;
    }
  }
}
