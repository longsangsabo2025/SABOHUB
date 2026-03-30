import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';

/// Finance Delivery History Page - Lịch sử giao hàng cho kế toán
/// Xem tất cả đơn đã giao của công ty, phân loại theo payment method
class FinanceDeliveryHistoryPage extends ConsumerStatefulWidget {
  const FinanceDeliveryHistoryPage({super.key});

  @override
  ConsumerState<FinanceDeliveryHistoryPage> createState() =>
      _FinanceDeliveryHistoryPageState();
}

class _FinanceDeliveryHistoryPageState
    extends ConsumerState<FinanceDeliveryHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveries = [];
  String _dateFilter = 'today';
  String _paymentFilter = 'all'; // all, cash, transfer, debt, unpaid
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _loadDeliveries() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              delivery_address, customer_address,
              customers(name, phone, address)
            ),
            driver:driver_id(name)
          ''')
          .eq('company_id', companyId)
          .eq('status', 'completed')
          .gte('completed_at', _startDate.toIso8601String())
          .order('completed_at', ascending: false)
          .limit(500);

      setState(() {
        _deliveries = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load finance delivery history', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    var list = _deliveries;

    // Filter by payment method
    if (_paymentFilter != 'all') {
      list = list.where((d) {
        final order = d['sales_orders'] as Map<String, dynamic>?;
        final paymentStatus =
            order?['payment_status']?.toString().toLowerCase() ?? 'unpaid';
        final paymentMethod =
            order?['payment_method']?.toString().toLowerCase() ?? '';

        switch (_paymentFilter) {
          case 'cash':
            return paymentStatus == 'paid' && paymentMethod == 'cash';
          case 'transfer':
            return paymentMethod == 'transfer';
          case 'debt':
            return paymentMethod == 'debt' ||
                (paymentStatus == 'unpaid' && paymentMethod == 'debt');
          case 'unpaid':
            return paymentStatus == 'unpaid' || paymentStatus == 'partial';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final order = d['sales_orders'] as Map<String, dynamic>?;
        final customer = order?['customers'] as Map<String, dynamic>?;
        final customerName = (order?['customer_name'] ??
                customer?['name'] ??
                '')
            .toString()
            .toLowerCase();
        final orderNumber =
            (order?['order_number'] ?? '').toString().toLowerCase();
        final driverName =
            (d['driver']?['name'] ?? '').toString().toLowerCase();
        return customerName.contains(q) ||
            orderNumber.contains(q) ||
            driverName.contains(q);
      }).toList();
    }

    return list;
  }

  // Summary stats
  int get _totalOrders => _filteredDeliveries.length;

  double get _totalAmount => _filteredDeliveries.fold(0.0, (sum, d) {
        final order = d['sales_orders'] as Map<String, dynamic>?;
        return sum + ((order?['total'] as num?)?.toDouble() ?? 0);
      });

  int _countByPayment(String method) {
    return _deliveries.where((d) {
      final order = d['sales_orders'] as Map<String, dynamic>?;
      final ps = order?['payment_status']?.toString().toLowerCase() ?? '';
      final pm = order?['payment_method']?.toString().toLowerCase() ?? '';
      switch (method) {
        case 'cash':
          return ps == 'paid' && pm == 'cash';
        case 'transfer':
          return pm == 'transfer';
        case 'debt':
          return pm == 'debt';
        case 'unpaid':
          return ps == 'unpaid' || ps == 'partial';
        default:
          return false;
      }
    }).length;
  }

  double _sumByPayment(String method) {
    return _deliveries.where((d) {
      final order = d['sales_orders'] as Map<String, dynamic>?;
      final ps = order?['payment_status']?.toString().toLowerCase() ?? '';
      final pm = order?['payment_method']?.toString().toLowerCase() ?? '';
      switch (method) {
        case 'cash':
          return ps == 'paid' && pm == 'cash';
        case 'transfer':
          return pm == 'transfer';
        case 'debt':
          return pm == 'debt';
        case 'unpaid':
          return ps == 'unpaid' || ps == 'partial';
        default:
          return false;
      }
    }).fold(0.0, (sum, d) {
      final order = d['sales_orders'] as Map<String, dynamic>?;
      return sum + ((order?['total'] as num?)?.toDouble() ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDeliveries;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lịch sử giao hàng',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadDeliveries();
                        },
                      ),
                    ],
                  ),
                  AppSpacing.gapMD,

                  // Date filter chips
                  Row(
                    children: [
                      _buildDateChip('Hôm nay', 'today'),
                      const SizedBox(width: 8),
                      _buildDateChip('7 ngày', 'week'),
                      const SizedBox(width: 8),
                      _buildDateChip('Tháng này', 'month'),
                    ],
                  ),
                ],
              ),
            ),

            // Summary card
            if (!_isLoading && _deliveries.isNotEmpty) _buildSummaryCard(),

            // Payment breakdown chips
            if (!_isLoading && _deliveries.isNotEmpty) _buildPaymentFilters(),

            // Search
            if (!_isLoading && _deliveries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo khách, mã đơn, tài xế...',
                      hintStyle: TextStyle(color: AppColors.grey500),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.grey600),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon:
                                  Icon(Icons.clear, color: AppColors.grey600),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDeliveries,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildDeliveryCard(filtered[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = _dateFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateFilter = value;
          _isLoading = true;
        });
        _loadDeliveries();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat(
                icon: Icons.check_circle,
                value: '$_totalOrders',
                label: 'Đơn đã giao',
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryStat(
                icon: Icons.payments,
                value: currencyFormat.format(_totalAmount),
                label: 'Tổng giá trị',
                valueSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Tiền mặt', _sumByPayment('cash'), Icons.payments),
                _buildMiniStat('CK', _sumByPayment('transfer'), Icons.qr_code),
                _buildMiniStat('Công nợ', _sumByPayment('debt'), Icons.receipt_long),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String value,
    required String label,
    double valueSize = 28,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildPaymentFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPaymentChip('Tất cả', 'all', Icons.list, AppColors.grey600,
                _deliveries.length),
            const SizedBox(width: 8),
            _buildPaymentChip('Tiền mặt', 'cash', Icons.payments,
                Colors.green.shade700, _countByPayment('cash')),
            const SizedBox(width: 8),
            _buildPaymentChip('Chuyển khoản', 'transfer', Icons.qr_code,
                Colors.blue.shade700, _countByPayment('transfer')),
            const SizedBox(width: 8),
            _buildPaymentChip('Công nợ', 'debt', Icons.receipt_long,
                Colors.orange.shade700, _countByPayment('debt')),
            const SizedBox(width: 8),
            _buildPaymentChip('Chưa thu', 'unpaid', Icons.pending,
                Colors.red.shade700, _countByPayment('unpaid')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(
      String label, String value, IconData icon, Color color, int count) {
    final isSelected = _paymentFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppColors.grey600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.grey700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.grey400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.grey400),
          ),
          AppSpacing.gapLG,
          Text(
            _paymentFilter != 'all'
                ? 'Không có đơn với loại thanh toán này'
                : 'Chưa có đơn đã giao',
            style: TextStyle(
                color: AppColors.grey600,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          AppSpacing.gapSM,
          Text(
            'Kéo xuống để làm mới',
            style: TextStyle(color: AppColors.grey500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final order = delivery['sales_orders'] as Map<String, dynamic>?;
    final customer = order?['customers'] as Map<String, dynamic>?;
    final driverData = delivery['driver'] as Map<String, dynamic>?;

    final orderNumber =
        order?['order_number']?.toString() ?? delivery['delivery_number'] ?? 'N/A';
    final total = (order?['total'] as num?)?.toDouble() ?? 0;
    final customerName =
        order?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = order?['delivery_address'] ??
        order?['customer_address'] ??
        customer?['address'] ??
        '';
    final driverName = driverData?['name'] ?? 'Tài xế';
    final completedAt = delivery['completed_at'] != null
        ? DateTime.tryParse(delivery['completed_at'])?.toLocal()
        : null;
    final paymentStatus =
        order?['payment_status']?.toString().toLowerCase() ?? 'unpaid';
    final paymentMethod =
        order?['payment_method']?.toString().toLowerCase() ?? '';

    // Payment display
    String paymentLabel;
    Color paymentColor;
    IconData paymentIcon;

    if (paymentStatus == 'paid' && paymentMethod == 'cash') {
      paymentLabel = 'Tiền mặt';
      paymentColor = Colors.green.shade700;
      paymentIcon = Icons.payments;
    } else if (paymentMethod == 'transfer') {
      paymentLabel = paymentStatus == 'pending_transfer'
          ? 'Chờ xác nhận CK'
          : 'Chuyển khoản';
      paymentColor = Colors.blue.shade700;
      paymentIcon = Icons.qr_code;
    } else if (paymentMethod == 'debt') {
      paymentLabel = 'Công nợ';
      paymentColor = Colors.orange.shade700;
      paymentIcon = Icons.receipt_long;
    } else if (paymentStatus == 'paid') {
      paymentLabel = 'Đã thu';
      paymentColor = Colors.green.shade700;
      paymentIcon = Icons.check_circle;
    } else {
      paymentLabel = 'Chưa thu';
      paymentColor = Colors.red.shade600;
      paymentIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: order number + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$orderNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.grey800,
                  ),
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer name
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppColors.grey500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Address
          if (customerAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.grey500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerAddress,
                    style: TextStyle(color: AppColors.grey600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Footer: status chips + driver + time
          Row(
            children: [
              // Delivery status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Đã giao',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Payment status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(paymentIcon, size: 14, color: paymentColor),
                    const SizedBox(width: 4),
                    Text(
                      paymentLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: paymentColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Time + driver
              if (completedAt != null)
                Text(
                  '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')} - ${completedAt.day}/${completedAt.month}',
                  style: TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
            ],
          ),

          // Driver name row
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Text(
                driverName,
                style: TextStyle(fontSize: 11, color: AppColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
