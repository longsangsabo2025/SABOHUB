import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../widgets/customer_avatar.dart';

// ============================================================================
// ORDERS SUMMARY PAGE - Tổng hợp đơn hàng cho Kế toán
// ============================================================================
class OrdersSummaryPage extends ConsumerStatefulWidget {
  const OrdersSummaryPage({super.key});

  @override
  ConsumerState<OrdersSummaryPage> createState() => _OrdersSummaryPageState();
}

class _OrdersSummaryPageState extends ConsumerState<OrdersSummaryPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final _orderSearchController = TextEditingController();
  DateTimeRange? _orderDateFilter;
  String _deliveryStatusFilter = 'all'; // all, pending, delivering, delivered, cancelled
  String _paymentStatusFilter = 'all'; // all, paid, unpaid, pending_transfer, partial
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  @override
  void dispose() {
    _orderSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      var query = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId);

      if (_orderDateFilter != null) {
        query = query
            .gte('created_at', _orderDateFilter!.start.toIso8601String())
            .lte('created_at', _orderDateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(200);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading orders summary', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var result = _orders;
    final query = _orderSearchController.text.toLowerCase();

    // Search
    if (query.isNotEmpty) {
      result = result.where((o) {
        final customer = o['customers'] as Map<String, dynamic>?;
        final name = (customer?['name'] ?? '').toLowerCase();
        final phone = (customer?['phone'] ?? '').toLowerCase();
        final orderNum = (o['order_number'] ?? '').toLowerCase();
        final customerName = (o['customer_name'] ?? '').toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            orderNum.contains(query) ||
            customerName.contains(query);
      }).toList();
    }

    // Delivery status filter
    if (_deliveryStatusFilter != 'all') {
      result = result.where((o) {
        return (o['delivery_status'] ?? '').toString() == _deliveryStatusFilter;
      }).toList();
    }

    // Payment status filter
    if (_paymentStatusFilter != 'all') {
      result = result.where((o) {
        final ps = (o['payment_status'] ?? '').toString();
        switch (_paymentStatusFilter) {
          case 'paid':
            return ps == 'paid';
          case 'unpaid':
            return ps == 'unpaid' || ps.isEmpty;
          case 'pending_transfer':
            return ps == 'pending_transfer';
          case 'partial':
            return ps == 'partial';
          case 'debt':
            return ps == 'debt';
          default:
            return true;
        }
      }).toList();
    }

    return result;
  }

  Map<String, List<Map<String, dynamic>>> get _ordersByDate {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final o in _filteredOrders) {
      final date = DateTime.tryParse(o['created_at'] ?? '');
      final key = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Không rõ';
      grouped.putIfAbsent(key, () => []).add(o);
    }
    return grouped;
  }

  // Stats
  int get _totalOrders => _filteredOrders.length;
  double get _totalRevenue => _filteredOrders.fold(0.0, (sum, o) => sum + (o['total'] ?? 0).toDouble());
  int get _deliveredCount => _filteredOrders.where((o) => o['delivery_status'] == 'delivered').length;
  int get _pendingCount => _filteredOrders.where((o) => o['delivery_status'] == 'pending' || o['delivery_status'] == 'delivering').length;
  int get _paidCount => _filteredOrders.where((o) => o['payment_status'] == 'paid').length;
  int get _unpaidCount => _filteredOrders.where((o) => o['payment_status'] != 'paid').length;

  String _deliveryStatusLabel(String? status) {
    switch (status) {
      case 'pending': return 'Chờ giao';
      case 'delivering': return 'Đang giao';
      case 'delivered': return 'Đã giao';
      case 'cancelled': return 'Đã hủy';
      default: return 'Mới';
    }
  }

  Color _deliveryStatusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'delivering': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'paid': return 'Đã TT';
      case 'partial': return 'TT 1 phần';
      case 'pending_transfer': return 'Chờ CK';
      case 'debt': return 'Công nợ';
      case 'unpaid': return 'Chưa TT';
      default: return 'Chưa TT';
    }
  }

  Color _paymentStatusColor(String? status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.amber;
      case 'pending_transfer': return Colors.purple;
      case 'debt': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final grouped = _ordersByDate;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Tổng hợp đơn hàng',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _loadAllOrders(),
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
                      controller: _orderSearchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm KH, mã đơn, SĐT...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _orderSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _orderSearchController.clear();
                                  setState(() {});
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter row
                  Row(
                    children: [
                      // Date filter
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showQuickDateRangePicker(context, current: _orderDateFilter);
                            if (picked != null) {
                              if (picked.start.year == 1970) {
                                setState(() => _orderDateFilter = null);
                              } else {
                                setState(() => _orderDateFilter = picked);
                              }
                              _loadAllOrders();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: _orderDateFilter != null ? Colors.indigo.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: _orderDateFilter != null ? Border.all(color: Colors.indigo.shade300) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16,
                                    color: _orderDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _orderDateFilter != null
                                        ? getDateRangeLabel(_orderDateFilter!)
                                        : 'Ngày',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _orderDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_orderDateFilter != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _orderDateFilter = null);
                                      _loadAllOrders();
                                    },
                                    child: Icon(Icons.close, size: 16, color: Colors.indigo.shade700),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Delivery status filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _deliveryStatusFilter != 'all' ? Colors.blue.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: _deliveryStatusFilter != 'all' ? Border.all(color: Colors.blue.shade300) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _deliveryStatusFilter,
                            isDense: true,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Giao hàng')),
                              DropdownMenuItem(value: 'pending', child: Text('Chờ giao')),
                              DropdownMenuItem(value: 'delivering', child: Text('Đang giao')),
                              DropdownMenuItem(value: 'delivered', child: Text('Đã giao')),
                            ],
                            onChanged: (v) => setState(() => _deliveryStatusFilter = v ?? 'all'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Payment status filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _paymentStatusFilter != 'all' ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: _paymentStatusFilter != 'all' ? Border.all(color: Colors.orange.shade300) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _paymentStatusFilter,
                            isDense: true,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Thanh toán')),
                              DropdownMenuItem(value: 'paid', child: Text('Đã TT')),
                              DropdownMenuItem(value: 'unpaid', child: Text('Chưa TT')),
                              DropdownMenuItem(value: 'pending_transfer', child: Text('Chờ CK')),
                              DropdownMenuItem(value: 'partial', child: Text('TT 1 phần')),
                              DropdownMenuItem(value: 'debt', child: Text('Công nợ')),
                            ],
                            onChanged: (v) => setState(() => _paymentStatusFilter = v ?? 'all'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats cards row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatChip('$_totalOrders đơn', Icons.shopping_bag, Colors.indigo),
                        const SizedBox(width: 8),
                        _buildStatChip(currencyFormat.format(_totalRevenue), Icons.attach_money, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatChip('$_deliveredCount giao', Icons.check_circle, Colors.teal),
                        const SizedBox(width: 8),
                        _buildStatChip('$_pendingCount chờ', Icons.local_shipping, Colors.orange),
                        const SizedBox(width: 8),
                        _buildStatChip('$_paidCount TT', Icons.paid, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatChip('$_unpaidCount nợ', Icons.money_off, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orders list grouped by date
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.shopping_bag_outlined,
                                    size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                  _orderSearchController.text.isNotEmpty ||
                                          _deliveryStatusFilter != 'all' ||
                                          _paymentStatusFilter != 'all'
                                      ? 'Không tìm thấy đơn hàng phù hợp'
                                      : 'Chưa có đơn hàng nào',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAllOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              final dateKey = grouped.keys.elementAt(index);
                              final dateOrders = grouped[dateKey]!;
                              final dayTotal = dateOrders.fold<double>(
                                  0, (sum, o) => sum + (o['total'] ?? 0).toDouble());

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date header
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(dateKey,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Colors.indigo.shade700)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${dateOrders.length} đơn',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        const Spacer(),
                                        Text(currencyFormat.format(dayTotal),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Colors.green.shade700)),
                                      ],
                                    ),
                                  ),
                                  // Orders for this date
                                  ...dateOrders.map((o) => _buildOrderSummaryCard(o)),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final orderNumber = order['order_number'] ?? order['id']?.toString().substring(0, 8) ?? '';
    final deliveryStatus = order['delivery_status']?.toString();
    final paymentStatus = order['payment_status']?.toString();
    final createdAt = order['created_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(order['created_at']))
        : '';
    final invoiceImageUrl = order['invoice_image_url']?.toString();
    final hasInvoiceImage = invoiceImageUrl != null && invoiceImageUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetailSheet(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Order number + time + status chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$orderNumber',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.indigo.shade700)),
                    ),
                    const SizedBox(width: 8),
                    Text(createdAt, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const Spacer(),
                    // Delivery status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _deliveryStatusColor(deliveryStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_deliveryStatusLabel(deliveryStatus),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _deliveryStatusColor(deliveryStatus))),
                    ),
                    const SizedBox(width: 4),
                    // Payment status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _paymentStatusColor(paymentStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_paymentStatusLabel(paymentStatus),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _paymentStatusColor(paymentStatus))),
                    ),
                    const SizedBox(width: 4),
                    // Invoice image indicator
                    GestureDetector(
                      onTap: hasInvoiceImage ? () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: InteractiveViewer(
                                    child: Image.network(invoiceImageUrl!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, progress) => progress == null
                                        ? child
                                        : const SizedBox(height: 200, width: 200, child: Center(child: CircularProgressIndicator())),
                                      errorBuilder: (_, __, ___) => Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                        child: const Column(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Không tải được ảnh'),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: hasInvoiceImage ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hasInvoiceImage ? Colors.green.shade300 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          hasInvoiceImage ? Icons.receipt_long : Icons.receipt_long_outlined,
                          size: 16,
                          color: hasInvoiceImage ? Colors.green.shade700 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Customer info
                Row(
                  children: [
                    CustomerAvatar(
                      seed: (customer?['name'] ?? 'K'),
                      radius: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer?['name'] ?? order['customer_name'] ?? 'Khách lẻ',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (customer?['phone'] != null)
                            Text(customer!['phone'],
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(total),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade700)),
                        Text('${items.length} SP',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailSheet(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = order['sales_order_items'] as List? ?? [];
    String? invoiceImageUrl = order['invoice_image_url']?.toString();
    bool isUploadingInvoice = false;
    final invoiceNumber = (order['invoice_number'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
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
                        if ((order['delivery_address'] ?? customer?['address']) != null)
                          Text('Địa chỉ: ${order['delivery_address'] ?? customer!['address']}'),
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

                  // Invoice image section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.amber.shade800, size: 18),
                            const SizedBox(width: 8),
                            Text('Ảnh hóa đơn',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.amber.shade800)),
                            const Spacer(),
                            if (invoiceImageUrl != null && invoiceImageUrl!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Đã lưu', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (invoiceImageUrl != null && invoiceImageUrl!.isNotEmpty)
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Stack(
                                        children: [
                                          InteractiveViewer(
                                            child: Image.network(invoiceImageUrl!, fit: BoxFit.contain,
                                              loadingBuilder: (_, child, progress) => progress == null ? child
                                                : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                                              errorBuilder: (_, __, ___) => Container(
                                                padding: const EdgeInsets.all(24),
                                                child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Không tải được ảnh')]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(invoiceImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) => progress == null ? child
                                      : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                                    errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: isUploadingInvoice ? null : () async {
                                    final uploadService = ImageUploadService();
                                    final file = await uploadService.pickFromGallery();
                                    if (file == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Chưa chọn ảnh'), backgroundColor: Colors.orange),
                                        );
                                      }
                                      return;
                                    }
                                    setSheetState(() => isUploadingInvoice = true);
                                    try {
                                      final authState = ref.read(authProvider);
                                      final companyId = authState.user?.companyId ?? '';
                                      final url = await uploadService.uploadInvoiceImage(
                                        imageFile: file, companyId: companyId, orderId: order['id']);
                                      if (url != null) {
                                        await Supabase.instance.client.from('sales_orders')
                                            .update({'invoice_image_url': url}).eq('id', order['id']);
                                        setSheetState(() { invoiceImageUrl = url; isUploadingInvoice = false; });
                                        _loadAllOrders();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: const Text('✅ Đã cập nhật ảnh hóa đơn'), backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                                        }
                                      }
                                    } catch (e) {
                                      setSheetState(() => isUploadingInvoice = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Thay đổi ảnh', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.amber.shade800,
                                    side: BorderSide(color: Colors.amber.shade300),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          isUploadingInvoice
                            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isUploadingInvoice ? null : () async {
                                        final uploadService = ImageUploadService();
                                        final file = await uploadService.pickFromGallery();
                                        if (file == null) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Chưa chọn ảnh'), backgroundColor: Colors.orange),
                                            );
                                          }
                                          return;
                                        }
                                        setSheetState(() => isUploadingInvoice = true);
                                        try {
                                          final authState = ref.read(authProvider);
                                          final companyId = authState.user?.companyId ?? '';
                                          final url = await uploadService.uploadInvoiceImage(
                                            imageFile: file, companyId: companyId, orderId: order['id']);
                                          if (url != null) {
                                            await Supabase.instance.client.from('sales_orders')
                                                .update({'invoice_image_url': url}).eq('id', order['id']);
                                            setSheetState(() { invoiceImageUrl = url; isUploadingInvoice = false; });
                                            _loadAllOrders();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: const Text('✅ Đã lưu ảnh hóa đơn'), backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                                            }
                                          }
                                        } catch (e) {
                                          setSheetState(() => isUploadingInvoice = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.photo_library, size: 16),
                                      label: const Text('Thư viện', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber.shade800,
                                        side: BorderSide(color: Colors.amber.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isUploadingInvoice ? null : () async {
                                        final uploadService = ImageUploadService();
                                        final file = await uploadService.pickFromCamera();
                                        if (file == null) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Chưa chọn ảnh'), backgroundColor: Colors.orange),
                                            );
                                          }
                                          return;
                                        }
                                        setSheetState(() => isUploadingInvoice = true);
                                        try {
                                          final authState = ref.read(authProvider);
                                          final companyId = authState.user?.companyId ?? '';
                                          final url = await uploadService.uploadInvoiceImage(
                                            imageFile: file, companyId: companyId, orderId: order['id']);
                                          if (url != null) {
                                            await Supabase.instance.client.from('sales_orders')
                                                .update({'invoice_image_url': url}).eq('id', order['id']);
                                            setSheetState(() { invoiceImageUrl = url; isUploadingInvoice = false; });
                                            _loadAllOrders();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: const Text('✅ Đã lưu ảnh hóa đơn'), backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                                            }
                                          }
                                        } catch (e) {
                                          setSheetState(() => isUploadingInvoice = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.camera_alt, size: 16),
                                      label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber.shade800,
                                        side: BorderSide(color: Colors.amber.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
