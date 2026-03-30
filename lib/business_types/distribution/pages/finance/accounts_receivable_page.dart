import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/debt_calculation_service.dart';
import '../../../../providers/auth_provider.dart';
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
  List<Map<String, dynamic>> _salesOrderAgingData = [];
  Set<String> _overdueCustomerIds = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _sortBy = 'debt_desc'; // debt_desc, debt_asc, name_asc
  double? _minDebtFilter;

  double _parseCurrencyInput(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return double.tryParse(digitsOnly) ?? 0;
  }

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
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Use shared DebtCalculationService as single source of truth
      final debtSummary = await DebtCalculationService.computeDebtSummary(companyId);
      final debtByCustomer = debtSummary.debtByCustomer;

      final customerMap = <String, Map<String, dynamic>>{};

      final customerIds = debtByCustomer.keys.where((id) => id.isNotEmpty).toList();
      if (customerIds.isNotEmpty) {
        final data = await supabase
            .from('customers')
            .select('id, name, code, phone, address, total_debt, credit_limit, payment_terms')
            .eq('company_id', companyId)
            .inFilter('id', customerIds);

        for (final c in data) {
          final cId = c['id']?.toString() ?? '';
          if (cId.isEmpty) continue;
          final row = Map<String, dynamic>.from(c);
          row['total_debt'] = debtByCustomer[cId] ?? 0;
          customerMap[cId] = row;
        }
      }

      // Build final sorted list
      final customerList = customerMap.values.toList()
        ..removeWhere((c) => ((c['total_debt'] ?? 0) as num) <= 0)
        ..sort((a, b) => ((b['total_debt'] ?? 0) as num).compareTo((a['total_debt'] ?? 0) as num));

      // Load aging data from receivables view
      List<Map<String, dynamic>> aging = [];
      try {
        aging = List<Map<String, dynamic>>.from(await supabase
            .from('v_receivables_aging')
            .select('customer_id, customer_name, balance, aging_bucket, days_overdue')
            .eq('company_id', companyId));
      } catch (e) {
        AppLogger.warn('Aging view not available: $e');
      }

      setState(() {
        _customersWithDebt = customerList;
        _agingData = aging;
        _salesOrderAgingData = List<Map<String, dynamic>>.from(debtSummary.agingItems);
        _overdueCustomerIds = debtSummary.overdueCustomerIds;
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
    // Use overdue customer IDs from shared DebtCalculationService
    return _filteredCustomers.where((c) => _overdueCustomerIds.contains(c['id']?.toString())).toList();
  }

  // Aging summary for the header (combines receivables + sales orders)
  Map<String, double> get _agingSummary {
    final summary = <String, double>{
      'current': 0, '1-30': 0, '31-60': 0, '61-90': 0, '90+': 0,
    };
    // From receivables aging view
    for (final a in _agingData) {
      final bucket = a['aging_bucket']?.toString() ?? 'current';
      final balance = (a['balance'] ?? 0).toDouble();
      summary[bucket] = (summary[bucket] ?? 0) + balance;
    }
    // From sales orders aging
    for (final a in _salesOrderAgingData) {
      final bucket = a['aging_bucket']?.toString() ?? 'current';
      final balance = (a['balance'] ?? 0).toDouble();
      summary[bucket] = (summary[bucket] ?? 0) + balance;
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: AppSpacing.paddingXL,
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
                          gradient: LinearGradient(colors: [AppColors.info, AppColors.infoDark]),
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
                                  AppSpacing.hGapXXS,
                                  Text('Nhập nợ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.hGapXXS,
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
                  AppSpacing.gapLG,

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm khách hàng...',
                        hintStyle: TextStyle(color: AppColors.grey500),
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.grey600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: AppColors.grey600),
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

                  AppSpacing.gapLG,

                  // Sort & filter row
                  Row(
                    children: [
                      // Sort dropdown
                      Expanded(
                        child: Container(
                          padding: AppSpacing.paddingHMD,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isDense: true,
                              isExpanded: true,
                              style: TextStyle(fontSize: 13, color: AppColors.grey700),
                              icon: Icon(Icons.sort, size: 18, color: AppColors.grey600),
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
                      AppSpacing.hGapSM,
                      // Min debt filter  
                      Container(
                        padding: AppSpacing.paddingHMD,
                        decoration: BoxDecoration(
                          color: _minDebtFilter != null ? AppColors.warningLight : AppColors.grey100,
                          borderRadius: BorderRadius.circular(10),
                          border: _minDebtFilter != null ? Border.all(color: AppColors.warning) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double?>(
                            value: _minDebtFilter,
                            isDense: true,
                            hint: Text('Mức nợ', style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                            style: TextStyle(fontSize: 13, color: AppColors.warningDark),
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
                    AppSpacing.gapMD,
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.warning, AppColors.warningDark]),
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
                    if (_agingData.isNotEmpty || _salesOrderAgingData.isNotEmpty) ...[
                      AppSpacing.gapSM,
                      _buildAgingBar(),
                    ],
                  ],

                  AppSpacing.gapLG,

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
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
                      labelColor: AppColors.warningDark,
                      unselectedLabelColor: AppColors.grey600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tất cả'),
                            AppSpacing.hGapXS,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_filteredCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warningDark)),
                            ),
                          ],
                        )),
                        Tab(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Quá hạn'),
                            AppSpacing.hGapXS,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_overdueCustomers.length}',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.errorDark)),
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
              padding: AppSpacing.paddingXXL,
              decoration: BoxDecoration(
                  color: AppColors.grey100, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_circle, size: 48, color: AppColors.grey400),
            ),
            AppSpacing.gapLG,
            Text('Không có khách hàng nào',
                style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: AppSpacing.paddingLG,
        itemCount: customers.length,
        itemBuilder: (context, index) => _buildDebtCard(customers[index]),
      ),
    );
  }

  // ==========================================================
  // NHẬP CÔNG NỢ ĐẦU KỲ - Manual Receivable Entry
  // ==========================================================
  void _showAddManualReceivableDialog() async {
    final user = ref.read(currentUserProvider);
    final companyId = user?.companyId;
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
          SnackBar(content: Text('Lỗi tải danh sách khách hàng: $e'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (allCustomers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có khách hàng nào trong hệ thống'), backgroundColor: AppColors.warning),
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
                      decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
                
                // Header
                Padding(
                  padding: AppSpacing.paddingXL,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.history_edu, color: AppColors.infoDark, size: 24),
                      ),
                      AppSpacing.hGapMD,
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nhập công nợ đầu kỳ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Ghi nhận công nợ từ trước khi sử dụng hệ thống',
                                style: TextStyle(fontSize: 12, color: AppColors.grey500)),
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
                    padding: AppSpacing.paddingXL,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Customer Selection ----
                        const Text('Chọn khách hàng *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        AppSpacing.gapSM,
                        
                        if (selectedCustomer != null) ...[
                          // Selected customer card
                          Container(
                            padding: AppSpacing.paddingMD,
                            decoration: BoxDecoration(
                              color: AppColors.infoLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.infoLight),
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
                                        style: TextStyle(fontSize: 12, color: AppColors.grey600),
                                      ),
                                      if ((selectedCustomer!['total_debt'] ?? 0).toDouble() > 0)
                                        Text(
                                          'Nợ hiện tại: ${currencyFormat.format((selectedCustomer!['total_debt'] ?? 0).toDouble())}',
                                          style: TextStyle(fontSize: 11, color: AppColors.warningDark),
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
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: customerSearchController,
                              onChanged: (_) => setDialogState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Tìm theo tên, mã, SĐT...',
                                hintStyle: TextStyle(color: AppColors.grey500),
                                prefixIcon: Icon(Icons.search, color: AppColors.grey600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          AppSpacing.gapSM,
                          // Customer list
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length.clamp(0, 50),
                              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.grey200),
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
                                      style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                  trailing: (c['total_debt'] ?? 0).toDouble() > 0
                                      ? Text(currencyFormat.format((c['total_debt'] ?? 0).toDouble()),
                                          style: TextStyle(fontSize: 11, color: AppColors.warningDark))
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

                        AppSpacing.gapXL,

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

                        AppSpacing.gapLG,

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
                                    builder: (context, child) {
                                      return Localizations.override(
                                        context: context,
                                        locale: const Locale('vi'),
                                        delegates: const [
                                          GlobalMaterialLocalizations.delegate,
                                          GlobalWidgetsLocalizations.delegate,
                                          GlobalCupertinoLocalizations.delegate,
                                        ],
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() => invoiceDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.grey400),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 18, color: AppColors.grey600),
                                      AppSpacing.hGapSM,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Ngày phát sinh', style: TextStyle(fontSize: 11, color: AppColors.grey600)),
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
                                    builder: (context, child) {
                                      return Localizations.override(
                                        context: context,
                                        locale: const Locale('vi'),
                                        delegates: const [
                                          GlobalMaterialLocalizations.delegate,
                                          GlobalWidgetsLocalizations.delegate,
                                          GlobalCupertinoLocalizations.delegate,
                                        ],
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() => dueDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                        ? AppColors.error
                                        : AppColors.grey400),
                                    borderRadius: BorderRadius.circular(12),
                                    color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                        ? AppColors.errorLight : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event, size: 18,
                                          color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                              ? AppColors.errorDark : AppColors.grey600),
                                      AppSpacing.hGapSM,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Hạn thanh toán', style: TextStyle(fontSize: 11, color: AppColors.grey600)),
                                            Text(
                                              dueDate != null
                                                  ? DateFormat('dd/MM/yyyy').format(dueDate!)
                                                  : 'Chưa chọn',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                                    ? AppColors.errorDark : null,
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
                              Icon(Icons.info_outline, size: 14, color: AppColors.error),
                              AppSpacing.hGapXXS,
                              Text('Hạn thanh toán đã qua → sẽ ghi nhận là "quá hạn"',
                                  style: TextStyle(fontSize: 11, color: AppColors.error)),
                            ],
                          ),
                        ],

                        AppSpacing.gapLG,

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

                        AppSpacing.gapLG,

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

                        AppSpacing.gapXXL,

                        // ---- Info box ----
                        Container(
                          padding: AppSpacing.paddingMD,
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warningLight),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.warningDark),
                              AppSpacing.hGapSM,
                              const Expanded(
                                child: Text(
                                  'Công nợ đầu kỳ là khoản nợ phát sinh trước khi sử dụng hệ thống. '
                                  'Sau khi nhập, khoản nợ sẽ xuất hiện trong danh sách công nợ và '
                                  'có thể thu tiền bình thường.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
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
                  padding: AppSpacing.paddingXL,
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
                            const SnackBar(content: Text('Vui lòng chọn khách hàng'), backgroundColor: AppColors.warning),
                          );
                          return;
                        }
                        final amount = _parseCurrencyInput(amountController.text);
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ'), backgroundColor: AppColors.warning),
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
                                  backgroundColor: AppColors.success,
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
                                SnackBar(content: Text('Lỗi: ${res['error']}'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      icon: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(isSubmitting ? 'Đang lưu...' : 'Ghi nhận công nợ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.infoDark,
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
          SnackBar(content: Text('Lỗi xuất báo cáo: $e'), backgroundColor: AppColors.error),
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
      {'key': 'current', 'label': 'Chưa đến hạn', 'color': AppColors.success},
      {'key': '1-30', 'label': '1-30 ngày', 'color': AppColors.warning},
      {'key': '31-60', 'label': '31-60', 'color': Colors.deepOrange},
      {'key': '61-90', 'label': '61-90', 'color': AppColors.errorDark},
      {'key': '90+', 'label': '>90', 'color': AppColors.errorDark},
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
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
                  AppSpacing.hGapXXS,
                  Text('${b['label']}: ${cf.format(val)}', style: TextStyle(fontSize: 10, color: AppColors.grey700)),
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
    // Use real aging data for overdue detection (from receivables AND sales orders)
    final customerAgingRecords = _agingData.where((a) =>
        a['customer_id'] == customer['id'] && (a['days_overdue'] ?? 0) > 0).toList();
    final customerSORecords = _salesOrderAgingData.where((a) =>
        a['customer_id'] == customer['id'] && (a['days_overdue'] ?? 0) > 30).toList();
    final isOverdue = customerAgingRecords.isNotEmpty || customerSORecords.isNotEmpty;
    final allOverdueDays = [
      ...customerAgingRecords.map((a) => (a['days_overdue'] as num?) ?? 0),
      ...customerSORecords.map((a) => (a['days_overdue'] as num?) ?? 0),
    ];
    final maxOverdueDays = allOverdueDays.isNotEmpty
        ? allOverdueDays.reduce((a, b) => a > b ? a : b)
        : 0;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GestureDetector(
      onTap: () => _showCustomerDebtDetail(customer),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue ? Border.all(color: AppColors.errorLight, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomerAvatar(
                  seed: customer['name'] ?? 'K',
                  radius: 22,
                ),
                AppSpacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${customer['phone'] ?? ''} • ${customer['code'] ?? ''}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.grey600)),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: maxOverdueDays > 60 ? AppColors.errorLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: AppColors.errorDark),
                        AppSpacing.hGapXXS,
                        Text('Quá hạn ${maxOverdueDays}d',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.errorDark,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ),
            AppSpacing.gapLG,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Công nợ',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.grey600)),
                    Text(currencyFormat.format(debt),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? AppColors.errorDark
                                : AppColors.warningDark)),
                  ],
                ),
                if (creditLimit > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Hạn mức',
                          style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                      Text(currencyFormat.format(creditLimit),
                          style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                    ],
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(customer),
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Thu tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
          padding: AppSpacing.paddingXL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapXL,
              const Text('Ghi nhận thanh toán',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              AppSpacing.gapXL,

              // Customer info
              Container(
                padding: AppSpacing.paddingLG,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CustomerAvatar(
                      seed: customer['name'] ?? 'K',
                      radius: 20,
                    ),
                    AppSpacing.hGapMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer['name'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Công nợ: ${currencyFormat.format(debt)}',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.errorDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapXL,

              // Payment method selection
              const Text('Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              AppSpacing.gapSM,
              Row(
                children: [
                  _buildMethodChip('Tiền mặt', 'cash', selectedMethod, Icons.money, AppColors.success,
                      (v) => setDialogState(() => selectedMethod = v)),
                  AppSpacing.hGapSM,
                  _buildMethodChip('Chuyển khoản', 'transfer', selectedMethod, Icons.account_balance, AppColors.info,
                      (v) => setDialogState(() => selectedMethod = v)),
                  AppSpacing.hGapSM,
                  _buildMethodChip('Khác', 'other', selectedMethod, Icons.more_horiz, AppColors.grey500,
                      (v) => setDialogState(() => selectedMethod = v)),
                ],
              ),

              AppSpacing.gapXL,
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

              AppSpacing.gapLG,

              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [
                  if (debt > 0) _buildQuickAmountChip('Trả hết', debt, amountController, () => setDialogState(() {})),
                  if (debt >= 1000000) _buildQuickAmountChip('1 triệu', 1000000, amountController, () => setDialogState(() {})),
                  if (debt >= 500000) _buildQuickAmountChip('500K', 500000, amountController, () => setDialogState(() {})),
                ],
              ),

              AppSpacing.gapLG,

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
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.infoLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt, color: AppColors.infoDark, size: 18),
                          AppSpacing.hGapSM,
                          Text('Ảnh chứng minh chuyển khoản',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.infoDark)),
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
                                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
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
                                  foregroundColor: AppColors.infoDark,
                                  side: BorderSide(color: AppColors.info),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            AppSpacing.hGapSM,
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
                                  foregroundColor: AppColors.infoDark,
                                  side: BorderSide(color: AppColors.info),
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
              AppSpacing.gapXXL,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount = _parseCurrencyInput(amountController.text);
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ')));
                      return;
                    }

                    try {
                      setDialogState(() => isUploading = true);
                      final user = ref.read(currentUserProvider);
                      final companyId = user?.companyId;
                      final userId = user?.id;
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

                      // Auto-allocate remaining payment to manual receivables
                      if (remaining > 0) {
                        final unpaidReceivables = await supabase
                            .from('receivables')
                            .select('id, original_amount, paid_amount, write_off_amount, status')
                            .eq('customer_id', customer['id'])
                            .eq('company_id', companyId)
                            .neq('status', 'paid')
                            .order('invoice_date', ascending: true);

                        for (final rec in unpaidReceivables) {
                          if (remaining <= 0) break;
                          final origAmt = (rec['original_amount'] ?? 0).toDouble();
                          final paidAmt = (rec['paid_amount'] ?? 0).toDouble();
                          final writeOff = (rec['write_off_amount'] ?? 0).toDouble();
                          final recRemaining = origAmt - paidAmt - writeOff;

                          if (recRemaining <= 0) continue;

                          final applyAmt = remaining >= recRemaining ? recRemaining : remaining;
                          final newRecPaid = paidAmt + applyAmt;
                          final newRecStatus = (newRecPaid + writeOff) >= origAmt ? 'paid' : 'open';

                          await supabase.from('receivables').update({
                            'paid_amount': newRecPaid,
                            'status': newRecStatus,
                            'last_payment_date': DateTime.now().toIso8601String().split('T')[0],
                          }).eq('id', rec['id']);

                          remaining -= applyAmt;
                        }
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            AppSpacing.hGapMD,
                            Text('Đã ghi nhận ${currencyFormat.format(amount)}'),
                          ]),
                          backgroundColor: AppColors.success,
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
                            backgroundColor: AppColors.error));
                      }
                    }
                  },
                  icon: isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(isUploading ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN THANH TOÁN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: AppSpacing.paddingVLG,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              AppSpacing.gapLG,
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
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.grey100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.grey300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : AppColors.grey500),
              AppSpacing.gapXXS,
              Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? color : AppColors.grey600)),
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
      backgroundColor: AppColors.infoLight,
      side: BorderSide(color: AppColors.infoLight),
    );
  }
}
