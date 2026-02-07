import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../widgets/customer_avatar.dart';
import 'customer_debt_detail_sheet.dart';

// ============================================================================
// ACCOUNTS RECEIVABLE PAGE - Modern UI
// ============================================================================
class AccountsReceivablePage extends ConsumerStatefulWidget {
  const AccountsReceivablePage({super.key});

  @override
  ConsumerState<AccountsReceivablePage> createState() =>
      _AccountsReceivablePageState();
}

class _AccountsReceivablePageState
    extends ConsumerState<AccountsReceivablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _customersWithDebt = [];
  List<Map<String, dynamic>> _agingData = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _sortBy = 'debt_desc'; // debt_desc, debt_asc, name_asc
  double? _minDebtFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('customers')
          .select('id, name, code, phone, address, total_debt, credit_limit, payment_terms')
          .eq('company_id', companyId)
          .gt('total_debt', 0)
          .order('total_debt', ascending: false);

      // Load aging data from receivables view
      List<Map<String, dynamic>> aging = [];
      try {
        aging = List<Map<String, dynamic>>.from(await supabase
            .from('v_receivables_aging')
            .select('customer_id, customer_name, balance, aging_bucket, days_overdue')
            .eq('company_id', companyId));
      } catch (_) {}

      setState(() {
        _customersWithDebt = List<Map<String, dynamic>>.from(data);
        _agingData = aging;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers with debt', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchController.text.toLowerCase();
    var list = _customersWithDebt;

    if (query.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toLowerCase();
        final phone = (c['phone'] ?? '').toLowerCase();
        final code = (c['code'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || code.contains(query);
      }).toList();
    }

    // Debt range filter
    if (_minDebtFilter != null) {
      list = list.where((c) {
        final debt = (c['total_debt'] ?? 0).toDouble();
        return debt >= _minDebtFilter!;
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'debt_asc':
        list.sort((a, b) => ((a['total_debt'] ?? 0) as num).compareTo((b['total_debt'] ?? 0) as num));
        break;
      case 'name_asc':
        list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      case 'debt_desc':
      default:
        list.sort((a, b) => ((b['total_debt'] ?? 0) as num).compareTo((a['total_debt'] ?? 0) as num));
        break;
    }

    return list;
  }

  List<Map<String, dynamic>> get _overdueCustomers {
    // Use real aging data - find customers with overdue receivables
    final overdueCustomerIds = _agingData
        .where((a) => (a['days_overdue'] ?? 0) > 0)
        .map((a) => a['customer_id'])
        .toSet();
    return _filteredCustomers.where((c) => overdueCustomerIds.contains(c['id'])).toList();
  }

  // Aging summary for the header
  Map<String, double> get _agingSummary {
    final summary = <String, double>{
      'current': 0, '1-30': 0, '31-60': 0, '61-90': 0, '90+': 0,
    };
    for (final a in _agingData) {
      final bucket = a['aging_bucket']?.toString() ?? 'current';
      final balance = (a['balance'] ?? 0).toDouble();
      summary[bucket] = (summary[bucket] ?? 0) + balance;
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text('Công nợ phải thu',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Nhập công nợ đầu kỳ
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _showAddManualReceivableDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Nhập nợ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        tooltip: 'Xuất báo cáo công nợ',
                        onPressed: _exportDebtReport,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadCustomers();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sort & filter row
                  Row(
                    children: [
                      // Sort dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isDense: true,
                              isExpanded: true,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              icon: Icon(Icons.sort, size: 18, color: Colors.grey.shade600),
                              items: const [
                                DropdownMenuItem(value: 'debt_desc', child: Text('Nợ cao nhất')),
                                DropdownMenuItem(value: 'debt_asc', child: Text('Nợ thấp nhất')),
                                DropdownMenuItem(value: 'name_asc', child: Text('Tên A-Z')),
                              ],
                              onChanged: (v) => setState(() => _sortBy = v ?? 'debt_desc'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Min debt filter  
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _minDebtFilter != null ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: _minDebtFilter != null ? Border.all(color: Colors.orange.shade300) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double?>(
                            value: _minDebtFilter,
                            isDense: true,
                            hint: Text('Mức nợ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                            items: const [
                              DropdownMenuItem<double?>(value: null, child: Text('Tất cả')),
                              DropdownMenuItem<double?>(value: 1000000, child: Text('> 1 triệu')),
                              DropdownMenuItem<double?>(value: 5000000, child: Text('> 5 triệu')),
                              DropdownMenuItem<double?>(value: 10000000, child: Text('> 10 triệu')),
                              DropdownMenuItem<double?>(value: 50000000, child: Text('> 50 triệu')),
                            ],
                            onChanged: (v) => setState(() => _minDebtFilter = v),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Summary card
                  if (_filteredCustomers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tổng công nợ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(
                                  _filteredCustomers.fold<double>(0, (sum, c) => sum + (c['total_debt'] ?? 0).toDouble()),
                                ),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${_filteredCustomers.length} KH',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    // Aging summary bar
                    if (_agingData.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildAgingBar(),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tất cả'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_filteredCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700)),
                            ),
                          ],
                        )),
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Quá hạn'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_overdueCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red.shade700)),
                            ),
                          ],
                        )),
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
                      controller: _tabController,
                      children: [
                        _buildCustomerList(_filteredCustomers),
                        _buildCustomerList(_overdueCustomers),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<Map<String, dynamic>> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_circle, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Không có khách hàng nào',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) => _buildDebtCard(customers[index]),
      ),
    );
  }

  // ==========================================================
  // NHẬP CÔNG NỢ ĐẦU KỲ - Manual Receivable Entry
  // ==========================================================
  void _showAddManualReceivableDialog() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;

    final supabase = Supabase.instance.client;

    // Load ALL customers (not just those with debt)
    List<Map<String, dynamic>> allCustomers = [];
    try {
      final data = await supabase
          .from('customers')
          .select('id, name, code, phone, total_debt')
          .eq('company_id', companyId)
          .order('name');
      allCustomers = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách khách hàng: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (allCustomers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có khách hàng nào trong hệ thống'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final amountController = TextEditingController();
    final refController = TextEditingController();
    final noteController = TextEditingController(text: 'Công nợ đầu kỳ');
    final customerSearchController = TextEditingController();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    Map<String, dynamic>? selectedCustomer;
    DateTime invoiceDate = DateTime.now();
    DateTime? dueDate;
    bool isSubmitting = false;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = customerSearchController.text.isEmpty
              ? allCustomers
              : allCustomers.where((c) {
                  final q = customerSearchController.text.toLowerCase();
                  return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
                      (c['code'] ?? '').toString().toLowerCase().contains(q) ||
                      (c['phone'] ?? '').toString().toLowerCase().contains(q);
                }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.history_edu, color: Colors.blue.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nhập công nợ đầu kỳ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Ghi nhận công nợ từ trước khi sử dụng hệ thống',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Customer Selection ----
                        const Text('Chọn khách hàng *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        
                        if (selectedCustomer != null) ...[
                          // Selected customer card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                CustomerAvatar(
                                  seed: selectedCustomer!['name'] ?? 'K',
                                  radius: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedCustomer!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        '${selectedCustomer!['code'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      if ((selectedCustomer!['total_debt'] ?? 0).toDouble() > 0)
                                        Text(
                                          'Nợ hiện tại: ${currencyFormat.format((selectedCustomer!['total_debt'] ?? 0).toDouble())}',
                                          style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz, size: 20),
                                  tooltip: 'Đổi khách hàng',
                                  onPressed: () => setDialogState(() => selectedCustomer = null),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Customer search
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: customerSearchController,
                              onChanged: (_) => setDialogState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Tìm theo tên, mã, SĐT...',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Customer list
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length.clamp(0, 50),
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                return ListTile(
                                  dense: true,
                                  leading: CustomerAvatar(
                                    seed: c['name'] ?? 'K',
                                    radius: 16,
                                  ),
                                  title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  subtitle: Text('${c['code'] ?? ''} • ${c['phone'] ?? ''}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  trailing: (c['total_debt'] ?? 0).toDouble() > 0
                                      ? Text(currencyFormat.format((c['total_debt'] ?? 0).toDouble()),
                                          style: TextStyle(fontSize: 11, color: Colors.orange.shade600))
                                      : null,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedCustomer = c;
                                      customerSearchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ---- Amount ----
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số tiền công nợ *',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixText: '₫',
                            helperText: 'Tổng số tiền khách hàng còn nợ',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---- Dates row ----
                        Row(
                          children: [
                            // Invoice date
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: invoiceDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    locale: const Locale('vi'),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => invoiceDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Ngày phát sinh', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            Text(DateFormat('dd/MM/yyyy').format(invoiceDate),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Due date
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    locale: const Locale('vi'),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => dueDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                        ? Colors.red.shade300
                                        : Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(12),
                                    color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                        ? Colors.red.shade50 : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event, size: 18,
                                          color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                              ? Colors.red.shade600 : Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Hạn thanh toán', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            Text(
                                              dueDate != null
                                                  ? DateFormat('dd/MM/yyyy').format(dueDate!)
                                                  : 'Chưa chọn',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                                    ? Colors.red.shade700 : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (dueDate != null && dueDate!.isBefore(DateTime.now())) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text('Hạn thanh toán đã qua → sẽ ghi nhận là "quá hạn"',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ---- Reference number ----
                        TextField(
                          controller: refController,
                          decoration: InputDecoration(
                            labelText: 'Số hóa đơn / mã tham chiếu',
                            prefixIcon: const Icon(Icons.receipt_long),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'VD: HD-001, INV-2024-001... (để trống sẽ tự tạo)',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---- Notes ----
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Ghi chú',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---- Info box ----
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Công nợ đầu kỳ là khoản nợ phát sinh trước khi sử dụng hệ thống. '
                                  'Sau khi nhập, khoản nợ sẽ xuất hiện trong danh sách công nợ và '
                                  'có thể thu tiền bình thường.',
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // space for button
                      ],
                    ),
                  ),
                ),

                // ---- Submit button ----
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : () async {
                        // Validate
                        if (selectedCustomer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn khách hàng'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final result = await supabase.rpc('create_manual_receivable', params: {
                            'p_company_id': companyId,
                            'p_customer_id': selectedCustomer!['id'],
                            'p_amount': amount,
                            'p_invoice_date': DateFormat('yyyy-MM-dd').format(invoiceDate),
                            'p_due_date': dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : null,
                            'p_reference_number': refController.text.isNotEmpty ? refController.text : null,
                            'p_notes': noteController.text.isNotEmpty ? noteController.text : null,
                          });

                          final res = result as Map<String, dynamic>;
                          if (res['success'] == true) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ Đã ghi nhận công nợ ${currencyFormat.format(amount)} cho ${res['customer_name']}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            // Refresh the list
                            setState(() => _isLoading = true);
                            _loadCustomers();
                          } else {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: ${res['error']}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(isSubmitting ? 'Đang lưu...' : 'Ghi nhận công nợ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // PDF Debt Report Export
  // ==========================================================
  Future<void> _exportDebtReport() async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final cf = NumberFormat('#,###', 'vi_VN');
      final now = DateTime.now();
      final customers = _filteredCustomers;
      final totalDebt = customers.fold<double>(0, (s, c) => s + (c['total_debt'] ?? 0).toDouble());
      final aging = _agingSummary;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BAO CAO CONG NO PHAI THU', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  pw.Text('Ngay: ${DateFormat('dd/MM/yyyy').format(now)}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text('Tong cong no: ${cf.format(totalDebt)} VND', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.SizedBox(width: 30),
                  pw.Text('So khach hang: ${customers.length}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Text('Chua den han: ${cf.format(aging['current'] ?? 0)}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.SizedBox(width: 12),
                  pw.Text('1-30 ngay: ${cf.format(aging['1-30'] ?? 0)}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.SizedBox(width: 12),
                  pw.Text('31-60: ${cf.format(aging['31-60'] ?? 0)}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.SizedBox(width: 12),
                  pw.Text('61-90: ${cf.format(aging['61-90'] ?? 0)}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.SizedBox(width: 12),
                  pw.Text('>90: ${cf.format(aging['90+'] ?? 0)}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.red)),
                ],
              ),
              pw.Divider(),
            ],
          ),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(70),
                5: const pw.FixedColumnWidth(70),
                6: const pw.FixedColumnWidth(70),
                7: const pw.FixedColumnWidth(70),
                8: const pw.FixedColumnWidth(70),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('STT', fontBold),
                    _pdfCell('Khach hang', fontBold, align: pw.TextAlign.left),
                    _pdfCell('SĐT', fontBold),
                    _pdfCell('Tong no', fontBold),
                    _pdfCell('Chua han', fontBold),
                    _pdfCell('1-30', fontBold),
                    _pdfCell('31-60', fontBold),
                    _pdfCell('61-90', fontBold),
                    _pdfCell('>90', fontBold),
                  ],
                ),
                // Data rows
                ...customers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final customerId = c['id'];
                  final debt = (c['total_debt'] ?? 0).toDouble();
                  
                  // Get aging for this customer
                  final customerAging = _agingData.where((a) => a['customer_id'] == customerId).toList();
                  double current = 0, d130 = 0, d3160 = 0, d6190 = 0, d90 = 0;
                  for (final a in customerAging) {
                    final bal = (a['balance'] ?? 0).toDouble();
                    switch (a['aging_bucket']?.toString()) {
                      case 'current': current += bal; break;
                      case '1-30': d130 += bal; break;
                      case '31-60': d3160 += bal; break;
                      case '61-90': d6190 += bal; break;
                      case '90+': d90 += bal; break;
                    }
                  }

                  return pw.TableRow(
                    children: [
                      _pdfCell('${idx + 1}', font),
                      _pdfCell(c['name'] ?? '', font, align: pw.TextAlign.left),
                      _pdfCell(c['phone'] ?? '', font),
                      _pdfCell(cf.format(debt), font, align: pw.TextAlign.right),
                      _pdfCell(current > 0 ? cf.format(current) : '-', font, align: pw.TextAlign.right),
                      _pdfCell(d130 > 0 ? cf.format(d130) : '-', font, align: pw.TextAlign.right),
                      _pdfCell(d3160 > 0 ? cf.format(d3160) : '-', font, align: pw.TextAlign.right),
                      _pdfCell(d6190 > 0 ? cf.format(d6190) : '-', font, align: pw.TextAlign.right),
                      _pdfCell(d90 > 0 ? cf.format(d90) : '-', font, align: pw.TextAlign.right,
                          color: d90 > 0 ? PdfColors.red : null),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                  children: [
                    _pdfCell('', fontBold),
                    _pdfCell('TONG CONG', fontBold, align: pw.TextAlign.left),
                    _pdfCell('', fontBold),
                    _pdfCell(cf.format(totalDebt), fontBold, align: pw.TextAlign.right),
                    _pdfCell(cf.format(aging['current'] ?? 0), fontBold, align: pw.TextAlign.right),
                    _pdfCell(cf.format(aging['1-30'] ?? 0), fontBold, align: pw.TextAlign.right),
                    _pdfCell(cf.format(aging['31-60'] ?? 0), fontBold, align: pw.TextAlign.right),
                    _pdfCell(cf.format(aging['61-90'] ?? 0), fontBold, align: pw.TextAlign.right),
                    _pdfCell(cf.format(aging['90+'] ?? 0), fontBold, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BaoCaoCongNo_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất báo cáo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.center, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: color), textAlign: align),
    );
  }

  Widget _buildAgingBar() {
    final aging = _agingSummary;
    final total = aging.values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return const SizedBox.shrink();

    final cf = NumberFormat.compact(locale: 'vi_VN');
    final buckets = [
      {'key': 'current', 'label': 'Chưa đến hạn', 'color': Colors.green},
      {'key': '1-30', 'label': '1-30 ngày', 'color': Colors.orange},
      {'key': '31-60', 'label': '31-60', 'color': Colors.deepOrange},
      {'key': '61-90', 'label': '61-90', 'color': Colors.red.shade600},
      {'key': '90+', 'label': '>90', 'color': Colors.red.shade900},
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tuổi nợ (Aging)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: buckets.map((b) {
                final val = aging[b['key'] as String] ?? 0;
                final fraction = val / total;
                if (fraction <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (fraction * 100).round().clamp(1, 100),
                  child: Container(
                    height: 6,
                    color: b['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Labels
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: buckets.where((b) => (aging[b['key'] as String] ?? 0) > 0).map((b) {
              final val = aging[b['key'] as String] ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: b['color'] as Color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text('${b['label']}: ${cf.format(val)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> customer) {
    final debt = (customer['total_debt'] ?? 0).toDouble();
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    // Use real aging data for overdue detection
    final customerAgingRecords = _agingData.where((a) =>
        a['customer_id'] == customer['id'] && (a['days_overdue'] ?? 0) > 0).toList();
    final isOverdue = customerAgingRecords.isNotEmpty;
    final maxOverdueDays = isOverdue
        ? customerAgingRecords.map((a) => (a['days_overdue'] as num?) ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GestureDetector(
      onTap: () => _showCustomerDebtDetail(customer),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue ? Border.all(color: Colors.red.shade200, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomerAvatar(
                  seed: customer['name'] ?? 'K',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${customer['phone'] ?? ''} • ${customer['code'] ?? ''}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: maxOverdueDays > 60 ? Colors.red.shade100 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text('Quá hạn ${maxOverdueDays}d',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Công nợ',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text(currencyFormat.format(debt),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Colors.red.shade700
                                : Colors.orange.shade700)),
                  ],
                ),
                if (creditLimit > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Hạn mức',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(currencyFormat.format(creditLimit),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(customer),
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Thu tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ======================================================================
  // CUSTOMER DEBT DETAIL - Chi tiết công nợ từng khách hàng
  // ======================================================================
  void _showCustomerDebtDetail(Map<String, dynamic> customer) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final debt = (customer['total_debt'] ?? 0).toDouble();
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDebtDetailSheet(
        customer: customer,
        debt: debt,
        creditLimit: creditLimit,
        currencyFormat: currencyFormat,
        onPayment: () {
          Navigator.pop(context);
          _showPaymentDialog(customer);
        },
        onRefresh: _loadCustomers,
      ),
    );
  }

  // ======================================================================
  // PAYMENT DIALOG - Ghi nhận thanh toán (cải tiến)
  // ======================================================================
  void _showPaymentDialog(Map<String, dynamic> customer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final referenceController = TextEditingController();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final debt = (customer['total_debt'] ?? 0).toDouble();
    String selectedMethod = 'cash';
    XFile? proofImage;
    Uint8List? proofImageBytes;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text('Ghi nhận thanh toán',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Customer info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CustomerAvatar(
                      seed: customer['name'] ?? 'K',
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer['name'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Công nợ: ${currencyFormat.format(debt)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment method selection
              const Text('Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodChip('Tiền mặt', 'cash', selectedMethod, Icons.money, Colors.green,
                      (v) => setDialogState(() => selectedMethod = v)),
                  const SizedBox(width: 8),
                  _buildMethodChip('Chuyển khoản', 'transfer', selectedMethod, Icons.account_balance, Colors.blue,
                      (v) => setDialogState(() => selectedMethod = v)),
                  const SizedBox(width: 8),
                  _buildMethodChip('Khác', 'other', selectedMethod, Icons.more_horiz, Colors.grey,
                      (v) => setDialogState(() => selectedMethod = v)),
                ],
              ),

              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền thanh toán *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: '₫',
                  helperText: 'Công nợ hiện tại: ${currencyFormat.format(debt)}',
                ),
              ),

              const SizedBox(height: 16),

              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [
                  if (debt > 0) _buildQuickAmountChip('Trả hết', debt, amountController, () => setDialogState(() {})),
                  if (debt >= 1000000) _buildQuickAmountChip('1 triệu', 1000000, amountController, () => setDialogState(() {})),
                  if (debt >= 500000) _buildQuickAmountChip('500K', 500000, amountController, () => setDialogState(() {})),
                ],
              ),

              const SizedBox(height: 16),

              // Reference (for transfers)
              if (selectedMethod == 'transfer') ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'Mã giao dịch / Số tham chiếu',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: 'Nhập mã GD ngân hàng để đối soát',
                    ),
                  ),
                ),

                // Proof image picker for bank transfers
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text('Ảnh chứng minh chuyển khoản',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue.shade700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (proofImageBytes != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(proofImageBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setDialogState(() {
                                  proofImage = null;
                                  proofImageBytes = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImageUploadService();
                                  final file = await picker.pickFromGallery();
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() {
                                      proofImage = file;
                                      proofImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Thư viện', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImageUploadService();
                                  final file = await picker.pickFromCamera();
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() {
                                      proofImage = file;
                                      proofImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade300),
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

              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: const Icon(Icons.note),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ')));
                      return;
                    }

                    try {
                      setDialogState(() => isUploading = true);
                      final authState = ref.read(authProvider);
                      final companyId = authState.user?.companyId;
                      final userId = authState.user?.id;
                      if (companyId == null) return;

                      // Upload proof image if provided
                      String? proofImageUrl;
                      if (proofImage != null && selectedMethod == 'transfer') {
                        final uploadService = ImageUploadService();
                        proofImageUrl = await uploadService.uploadPaymentProof(
                          imageFile: proofImage!,
                          companyId: companyId,
                        );
                      }

                      final supabase = Supabase.instance.client;
                      await supabase.from('customer_payments').insert({
                        'company_id': companyId,
                        'customer_id': customer['id'],
                        'amount': amount,
                        'payment_date': DateTime.now().toIso8601String(),
                        'payment_method': selectedMethod,
                        'reference': referenceController.text.isNotEmpty ? referenceController.text : null,
                        'notes': noteController.text,
                        'created_by': userId,
                        if (proofImageUrl != null) 'proof_image_url': proofImageUrl,
                      });

                      // Update customer debt
                      final newDebt = (debt - amount).clamp(0, double.infinity);
                      await supabase.from('customers').update({
                        'total_debt': newDebt,
                      }).eq('id', customer['id']);

                      // Auto-allocate payment to oldest unpaid orders
                      var remaining = amount;
                      final unpaidOrders = await supabase
                          .from('sales_orders')
                          .select('id, total, paid_amount, payment_status')
                          .eq('customer_id', customer['id'])
                          .eq('company_id', companyId)
                          .neq('payment_status', 'paid')
                          .order('created_at', ascending: true);

                      for (final order in unpaidOrders) {
                        if (remaining <= 0) break;
                        final orderTotal = (order['total'] ?? 0).toDouble();
                        final orderPaid = (order['paid_amount'] ?? 0).toDouble();
                        final orderRemaining = orderTotal - orderPaid;

                        if (orderRemaining <= 0) continue;

                        final applyAmount = remaining >= orderRemaining ? orderRemaining : remaining;
                        final newPaid = orderPaid + applyAmount;
                        final newStatus = newPaid >= orderTotal ? 'paid' : 'partial';

                        await supabase.from('sales_orders').update({
                          'paid_amount': newPaid,
                          'payment_status': newStatus,
                        }).eq('id', order['id']);

                        remaining -= applyAmount;
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('Đã ghi nhận ${currencyFormat.format(amount)}'),
                          ]),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(isUploading ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN THANH TOÁN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildMethodChip(String label, String value, String selected, IconData icon, Color color, Function(String) onTap) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : Colors.grey.shade500),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? color : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount, TextEditingController controller, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        controller.text = amount.toStringAsFixed(0);
        onTap();
      },
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }
}
