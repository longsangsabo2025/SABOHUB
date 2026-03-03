import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';

/// Driver History Page - Lịch sử giao hàng
class DriverHistoryPage extends ConsumerStatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  ConsumerState<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends ConsumerState<DriverHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  String _dateFilter = 'today';
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) return;

      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      DateTime startDate;
      switch (_dateFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Query deliveries của driver này, join với sales_orders
      final data = await supabase
          .from('deliveries')
          .select('*, sales_orders:order_id(*, customers(name, phone, address))')
          .eq('driver_id', userId)
          .eq('status', 'completed')
          .gte('completed_at', startDate.toIso8601String())
          .order('completed_at', ascending: false)
          .limit(100);

      // Transform data to match expected format
      final historyList = (data as List).map((delivery) {
        final order = delivery['sales_orders'] as Map<String, dynamic>?;
        if (order == null) return null;
        
        return {
          ...order,
          'delivery_id': delivery['id'],
          'completed_at': delivery['completed_at'],
        };
      }).whereType<Map<String, dynamic>>().toList();

      setState(() {
        _history = historyList;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load delivery history', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _history.fold<num>(
      0,
      (sum, order) => sum + ((order['total'] as num?) ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadHistory();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date filter chips
                  Row(
                    children: [
                      _buildFilterChip('Hôm nay', 'today'),
                      const SizedBox(width: 8),
                      _buildFilterChip('7 ngày', 'week'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tháng này', 'month'),
                    ],
                  ),
                ],
              ),
            ),

            // Summary card
            if (!_isLoading && _history.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_history.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Đơn đã giao',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payments, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tổng thu hộ',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // History list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
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
                                child: Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có lịch sử giao hàng',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final order = _history[index];
                              return _buildHistoryCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _dateFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateFilter = value;
          _isLoading = true;
        });
        _loadHistory();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final completedAt = order['completed_at'] != null
        ? DateTime.tryParse(order['completed_at'])
        : null;
    final customerName = order['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = order['delivery_address'] ?? customer?['address'] ?? '';
    final paymentStatus = order['payment_status']?.toString().toLowerCase() ?? 'unpaid';
    final paymentMethod = order['payment_method']?.toString().toLowerCase() ?? '';
    
    // Determine payment status display
    final isPaid = paymentStatus == 'paid';
    final paymentLabel = isPaid 
        ? (paymentMethod == 'transfer' ? 'Chuyển khoản' : paymentMethod == 'cash' ? 'Tiền mặt' : 'Đã thu')
        : 'Chưa thu';

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
          // Header row: Order number + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$orderNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade800,
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
              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerAddress,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 10),
          
          // Footer: Status + Time
          Row(
            children: [
              // Delivery status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Đã giao',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Payment status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.payments : Icons.pending,
                      size: 14,
                      color: isPaid ? Colors.blue.shade600 : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isPaid ? Colors.blue.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Time
              if (completedAt != null)
                Text(
                  DateFormat('HH:mm - dd/M').format(completedAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
