import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

// ============================================================================
// PAYMENTS PAGE - Modern UI
// ============================================================================
class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  DateTimeRange? _dateFilter;
  final _paymentSearchController = TextEditingController();
  String _paymentMethodFilter = 'all'; // all, cash, transfer, other

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _paymentSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var queryBuilder = supabase
          .from('customer_payments')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId);

      if (_dateFilter != null) {
        // End date needs +1 day because payment_date is timestamp (has time component)
        // e.g. "Hôm qua" = Feb 10 → need payments from Feb 10 00:00 to Feb 11 00:00
        final endOfDay = DateTime(_dateFilter!.end.year, _dateFilter!.end.month, _dateFilter!.end.day)
            .add(const Duration(days: 1));
        queryBuilder = queryBuilder
            .gte('payment_date', _dateFilter!.start.toIso8601String())
            .lt('payment_date', endOfDay.toIso8601String());
      }

      final data = await queryBuilder
          .order('payment_date', ascending: false)
          .limit(100);

      setState(() {
        _payments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load payments', e);
      setState(() => _isLoading = false);
    }
  }

  double get _totalAmount {
    return _filteredPayments.fold(
        0.0, (sum, p) => sum + (p['amount'] ?? 0).toDouble());
  }

  List<Map<String, dynamic>> get _filteredPayments {
    var result = _payments;
    final query = _paymentSearchController.text.toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((p) {
        final customer = p['customers'] as Map<String, dynamic>?;
        final name = (customer?['name'] ?? '').toLowerCase();
        final phone = (customer?['phone'] ?? '').toLowerCase();
        final note = (p['notes'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || note.contains(query);
      }).toList();
    }

    if (_paymentMethodFilter != 'all') {
      result = result.where((p) {
        final method = (p['payment_method'] ?? '').toString().toLowerCase();
        switch (_paymentMethodFilter) {
          case 'cash': return method == 'cash' || method == 'tiền mặt';
          case 'transfer': return method == 'transfer' || method == 'chuyển khoản';
          default: return method != 'cash' && method != 'transfer' && method != 'tiền mặt' && method != 'chuyển khoản';
        }
      }).toList();
    }

    return result;
  }

  Map<String, List<Map<String, dynamic>>> get _paymentsByDate {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final p in _filteredPayments) {
      final date = DateTime.tryParse(p['payment_date'] ?? '');
      final key = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Không rõ';
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

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
                children: [
                  Row(
                    children: [
                      const Text('Lịch sử thanh toán',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadPayments();
                        },
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
                      controller: _paymentSearchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm khách hàng, ghi chú...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _paymentSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _paymentSearchController.clear();
                                  setState(() {});
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date filter
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showQuickDateRangePicker(context, current: _dateFilter);
                            if (picked != null) {
                              if (picked.start.year == 1970) {
                                setState(() => _dateFilter = null);
                              } else {
                                setState(() => _dateFilter = picked);
                              }
                              _loadPayments();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _dateFilter != null ? Colors.blue.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: _dateFilter != null ? Border.all(color: Colors.blue.shade300) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    color: _dateFilter != null ? Colors.blue.shade700 : Colors.grey.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dateFilter != null
                                        ? getDateRangeLabel(_dateFilter!)
                                        : 'Chọn khoảng thời gian',
                                    style: TextStyle(color: _dateFilter != null ? Colors.blue.shade700 : Colors.grey.shade700),
                                  ),
                                ),
                                if (_dateFilter != null)
                                  IconButton(
                                    icon: Icon(Icons.clear, color: Colors.blue.shade700),
                                    onPressed: () {
                                      setState(() => _dateFilter = null);
                                      _loadPayments();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Payment method filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _paymentMethodFilter != 'all' ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: _paymentMethodFilter != 'all' ? Border.all(color: Colors.green.shade300) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _paymentMethodFilter,
                            isDense: true,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                              DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                              DropdownMenuItem(value: 'transfer', child: Text('CK')),
                            ],
                            onChanged: (v) => setState(() => _paymentMethodFilter = v ?? 'all'),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tổng đã thu',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(_totalAmount),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_filteredPayments.length} giao dịch',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payments list - grouped by date
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPayments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.receipt_long,
                                    size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                  _paymentSearchController.text.isNotEmpty
                                      ? 'Không tìm thấy thanh toán phù hợp'
                                      : 'Chưa có thanh toán nào',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPayments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _paymentsByDate.length,
                            itemBuilder: (context, index) {
                              final dateKey = _paymentsByDate.keys.elementAt(index);
                              final datePayments = _paymentsByDate[dateKey]!;
                              final dayTotal = datePayments.fold<double>(
                                  0, (sum, p) => sum + (p['amount'] ?? 0).toDouble());

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
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(dateKey,
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${datePayments.length} GD',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        const Spacer(),
                                        Text('+${currencyFormat.format(dayTotal)}',
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green.shade700)),
                                      ],
                                    ),
                                  ),
                                  // Payments for this date
                                  ...datePayments.map((p) => _buildPaymentCard(p)),
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

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final customer = payment['customers'] as Map<String, dynamic>?;
    final amount = (payment['amount'] ?? 0).toDouble();
    final paymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final proofUrl = payment['proof_image_url']?.toString();
    final method = payment['payment_method']?.toString() ?? '';

    return GestureDetector(
      onTap: proofUrl != null && proofUrl.isNotEmpty ? () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
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
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments, color: Colors.green.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(customer?['name'] ?? 'Khách hàng',
                        style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    if (proofUrl != null && proofUrl.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.image, size: 14, color: Colors.blue.shade400),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (paymentDate != null)
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(paymentDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    if (method == 'transfer') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('CK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                      ),
                    ],
                    if (method == 'cash') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('TM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${currencyFormat.format(amount)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 15)),
              if (payment['notes'] != null && payment['notes'].toString().isNotEmpty)
                Text(payment['notes'].toString(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
