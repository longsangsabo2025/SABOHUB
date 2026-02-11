import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/customer_avatar.dart';

// ============================================================================
// CUSTOMER DEBT DETAIL SHEET - Chi tiết công nợ theo khách hàng
// ============================================================================
class CustomerDebtDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;
  final double debt;
  final double creditLimit;
  final NumberFormat currencyFormat;
  final VoidCallback onPayment;
  final Future<void> Function() onRefresh;

  const CustomerDebtDetailSheet({
    super.key,
    required this.customer,
    required this.debt,
    required this.creditLimit,
    required this.currencyFormat,
    required this.onPayment,
    required this.onRefresh,
  });

  @override
  ConsumerState<CustomerDebtDetailSheet> createState() => _CustomerDebtDetailSheetState();
}

class _CustomerDebtDetailSheetState extends ConsumerState<CustomerDebtDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _detailTabController;
  List<Map<String, dynamic>> _unpaidOrders = [];
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _detailTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final customerId = widget.customer['id'];

      // Load unpaid orders (include delivery_address for branch info)
      final orders = await supabase
          .from('sales_orders')
          .select('id, order_number, total, paid_amount, payment_status, payment_method, delivery_status, created_at, delivery_date, order_date, delivery_address, delivery_address_id, sales_order_items(id, product_name, quantity)')
          .eq('customer_id', customerId)
          .eq('company_id', companyId)
          .neq('payment_status', 'paid')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      // Load payment history
      final payments = await supabase
          .from('customer_payments')
          .select('*')
          .eq('customer_id', customerId)
          .eq('company_id', companyId)
          .order('payment_date', ascending: false)
          .limit(50);

      setState(() {
        _unpaidOrders = List<Map<String, dynamic>>.from(orders);
        _paymentHistory = List<Map<String, dynamic>>.from(payments);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading customer debt detail', e);
      setState(() => _isLoading = false);
    }
  }

  String _calcDebtAge(Map<String, dynamic> order) {
    final deliveredAt = order['delivery_date'] ?? order['order_date'] ?? order['created_at'];
    if (deliveredAt == null) return '';
    final date = DateTime.tryParse(deliveredAt.toString());
    if (date == null) return '';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return '1 ngày';
    return '$days ngày';
  }

  Color _ageColor(Map<String, dynamic> order) {
    final deliveredAt = order['delivery_date'] ?? order['order_date'] ?? order['created_at'];
    if (deliveredAt == null) return Colors.grey;
    final date = DateTime.tryParse(deliveredAt.toString());
    if (date == null) return Colors.grey;
    final days = DateTime.now().difference(date).inDays;
    if (days <= 7) return Colors.green;
    if (days <= 30) return Colors.orange;
    if (days <= 60) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cf = widget.currencyFormat;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CustomerAvatar(
                        seed: widget.customer['name'] ?? 'K',
                        radius: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.customer['name'] ?? 'N/A',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${widget.customer['phone'] ?? ''} • ${widget.customer['code'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Debt summary strip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.red.shade400]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tổng công nợ', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                              Text(cf.format(widget.debt), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Đơn nợ', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                            Text('${_unpaidOrders.length}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: widget.onPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Thu tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _detailTabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: [
                        Tab(text: 'Đơn nợ (${_unpaidOrders.length})'),
                        Tab(text: 'Lịch sử TT (${_paymentHistory.length})'),
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
                      controller: _detailTabController,
                      children: [
                        _buildUnpaidOrdersTab(cf),
                        _buildPaymentHistoryTab(cf),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidOrdersTab(NumberFormat cf) {
    if (_unpaidOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 12),
            Text('Không có đơn nợ', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _unpaidOrders.length,
      itemBuilder: (context, index) {
        final order = _unpaidOrders[index];
        final total = (order['total'] ?? 0).toDouble();
        final paid = (order['paid_amount'] ?? 0).toDouble();
        final remaining = total - paid;
        final items = order['sales_order_items'] as List? ?? [];
        final orderNum = order['order_number'] ?? '';
        final age = _calcDebtAge(order);
        final ageCol = _ageColor(order);
        final createdAt = order['order_date'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['order_date']))
            : order['created_at'] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['created_at']).toLocal())
                : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: order number + age badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('#$orderNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo.shade700)),
                  ),
                  const SizedBox(width: 8),
                  Text(createdAt, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  if (age.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ageCol.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ageCol.withValues(alpha: 0.3)),
                      ),
                      child: Text(age, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ageCol)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Branch/delivery address
              if (order['delivery_address'] != null && (order['delivery_address'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.teal.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order['delivery_address'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Items summary
              Text('${items.length} sản phẩm', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

              const SizedBox(height: 8),

              // Amount row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng đơn', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(cf.format(total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (paid > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Đã trả', style: TextStyle(fontSize: 11, color: Colors.green.shade500)),
                          Text(cf.format(paid), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Còn nợ', style: TextStyle(fontSize: 11, color: Colors.red.shade500)),
                        Text(cf.format(remaining), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      ],
                    ),
                  ),
                ],
              ),

              // Progress bar
              if (total > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (paid / total).clamp(0.0, 1.0),
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistoryTab(NumberFormat cf) {
    if (_paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Chưa có lịch sử thanh toán', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, index) {
        final p = _paymentHistory[index];
        final amount = (p['amount'] ?? 0).toDouble();
        final date = DateTime.tryParse(p['payment_date']?.toString() ?? '');
        final method = p['payment_method']?.toString() ?? '';
        final reference = p['reference']?.toString() ?? '';
        final note = p['notes']?.toString() ?? '';
        final proofUrl = p['proof_image_url']?.toString();

        String methodLabel = 'Không rõ';
        IconData methodIcon = Icons.help_outline;
        Color methodColor = Colors.grey;
        switch (method) {
          case 'cash':
            methodLabel = 'Tiền mặt';
            methodIcon = Icons.money;
            methodColor = Colors.green;
            break;
          case 'transfer':
            methodLabel = 'Chuyển khoản';
            methodIcon = Icons.account_balance;
            methodColor = Colors.blue;
            break;
          case 'other':
            methodLabel = 'Khác';
            methodIcon = Icons.more_horiz;
            methodColor = Colors.grey;
            break;
        }

        return GestureDetector(
          onTap: proofUrl != null && proofUrl.isNotEmpty ? () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Ảnh chứng minh thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                      child: Image.network(proofUrl, fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) => progress == null ? child
                          : const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                        errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Không tải được ảnh')])),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } : null,
          child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(methodIcon, color: methodColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(methodLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (proofUrl != null && proofUrl.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.image, size: 14, color: Colors.blue.shade400),
                        ],
                      ],
                    ),
                    if (date != null)
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    if (reference.isNotEmpty)
                      Text('Ref: $reference', style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
                    if (note.isNotEmpty)
                      Text(note, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('+${cf.format(amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade700)),
            ],
          ),
          ),
        );
      },
    );
  }
}
