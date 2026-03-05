import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:excel/excel.dart' as excel_lib;

import '../../models/branch.dart';
import '../../models/company.dart';
import '../../business_types/service/providers/monthly_pnl_provider.dart';
import '../../business_types/service/providers/shareholder_provider.dart';
import '../../business_types/service/models/monthly_pnl.dart';
import '../../business_types/service/models/daily_cashflow.dart';
import '../../business_types/service/models/shareholder.dart';
import '../../business_types/service/services/daily_cashflow_service.dart';
import '../../business_types/service/pages/cashflow/daily_cashflow_import_page.dart';
import '../../business_types/service/pages/cashflow/monthly_pnl_entry_page.dart';
import '../../business_types/service/pages/cashflow/invoice_scan_page.dart';
import '../../utils/quick_date_range_picker.dart';
import '../../services/branch_service.dart';
import '../../services/company_service.dart';
import '../../services/gemini_service.dart';
import '../../widgets/shimmer_loading.dart';
import 'ai_assistant_tab.dart';
import 'company/accounting_tab.dart';
import 'company/attendance_tab.dart';
import 'company/business_law_tab.dart';
import 'company/documents_tab.dart';
import 'company/employee_documents_tab.dart';
import 'company/employees_tab.dart';
import 'company/overview_tab.dart';
import 'company/permissions_management_tab.dart';
import 'company/settings_tab.dart';
import 'company/tasks_tab.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Company Details Page Provider
/// Caches data to prevent unnecessary refetches when switching tabs
final companyDetailsProvider =
    FutureProvider.autoDispose.family<Company?, String>((ref, id) async {
  // Keep provider alive to cache company data across tab switches
  ref.keepAlive();

  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Branches Provider
final companyBranchesProvider =
    FutureProvider.autoDispose.family<List<Branch>, String>((ref, companyId) async {
  final service = BranchService();
  return await service.getAllBranches(companyId: companyId);
});

/// Company Stats Provider
final companyStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, companyId) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyStats(companyId);
});

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// Company Details Page
/// Displays comprehensive information about a single company
class CompanyDetailsPage extends ConsumerStatefulWidget {
  final String companyId;

  CompanyDetailsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends ConsumerState<CompanyDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  // Tab definitions - 5 main tabs shown in TabBar
  static const _mainTabs = [
    {'icon': Icons.dashboard, 'label': 'Tổng quan'},
    {'icon': Icons.analytics, 'label': 'Tài chính'},
    {'icon': Icons.people, 'label': 'Nhân viên'},
    {'icon': Icons.assignment, 'label': 'Công việc'},
    {'icon': Icons.description, 'label': 'Tài liệu'},
  ];
  
  // Secondary tabs accessed via menu
  static const _secondaryTabs = [
    {'icon': Icons.smart_toy, 'label': 'AI Assistant', 'index': 5},
    {'icon': Icons.access_time, 'label': 'Chấm công', 'index': 6},
    {'icon': Icons.account_balance_wallet, 'label': 'Kế toán', 'index': 7},
    {'icon': Icons.folder_shared, 'label': 'Hồ sơ NV', 'index': 8},
    {'icon': Icons.gavel, 'label': 'Luật DN', 'index': 9},
    {'icon': Icons.admin_panel_settings, 'label': 'Phân quyền', 'index': 10},
    {'icon': Icons.settings, 'label': 'Cài đặt', 'index': 11},
  ];

  // ═══════════════════════════════════════════════════════════════
  // FINANCIAL TAB STATE — Lịch sử nhập liệu, Filter, Export
  // ═══════════════════════════════════════════════════════════════
  final _cashflowService = DailyCashflowService();
  List<DailyCashflow>? _cashflowHistory;
  bool _loadingHistory = false;
  DateTimeRange? _historyDateFilter;
  bool _historyExpanded = false;
  
  // P&L Month Filter - để lọc báo cáo tài chính theo tháng
  String? _selectedPnlMonth; // Format: 'MM/yyyy' hoặc null = tháng mới nhất
  int? _selectedPnlYear; // Năm đang xem, null = năm mới nhất
  
  // Shareholder Year Filter - để xem lịch sử cổ phần theo năm
  int? _selectedShareholderYear; // null = năm mới nhất

  Future<void> _loadCashflowHistory(String companyId) async {
    if (_loadingHistory) return;
    setState(() => _loadingHistory = true);
    try {
      final history = await _cashflowService.getCashflowHistory(
        companyId: companyId,
        limit: 100,
      );
      
      // Apply date filter if set
      if (_historyDateFilter != null && history.isNotEmpty) {
        final filtered = history.where((cf) {
          return cf.reportDate.isAfter(_historyDateFilter!.start.subtract(const Duration(days: 1))) &&
                 cf.reportDate.isBefore(_historyDateFilter!.end.add(const Duration(days: 1)));
        }).toList();
        if (mounted) setState(() { _cashflowHistory = filtered; _loadingHistory = false; });
      } else {
        if (mounted) setState(() { _cashflowHistory = history; _loadingHistory = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _cashflowHistory = []; _loadingHistory = false; });
    }
  }

  Future<void> _deleteCashflowRecord(String id, String companyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bản ghi này? Thao tác không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _cashflowService.deleteCashflow(id);
      _loadCashflowHistory(companyId);
      // Refresh P&L summary
      ref.invalidate(financialSummaryProvider(companyId));
    }
  }

  void _exportCashflowToCSV(List<DailyCashflow> history, String companyName) {
    if (history.isEmpty) return;
    
    final csvLines = <String>[];
    csvLines.add('Ngày,Chi nhánh,Doanh thu,Tiền mặt,Chuyển khoản,Thẻ,Ví ĐT,Điểm,Số HĐ,Nguồn');
    
    for (final cf in history) {
      csvLines.add([
        DateFormat('dd/MM/yyyy').format(cf.reportDate),
        cf.branchName ?? '',
        cf.totalRevenue.toStringAsFixed(0),
        cf.cashAmount.toStringAsFixed(0),
        cf.transferAmount.toStringAsFixed(0),
        cf.cardAmount.toStringAsFixed(0),
        cf.ewalletAmount.toStringAsFixed(0),
        cf.pointsAmount.toStringAsFixed(0),
        cf.totalOrders.toString(),
        cf.sourceFile == 'manual_entry' ? 'Nhập thủ công' : 'Import Excel',
      ].join(','));
    }
    
    final csvContent = csvLines.join('\n');
    final bytes = utf8.encode('\uFEFF$csvContent'); // BOM for Excel UTF-8
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final date = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    html.AnchorElement(href: url)
      ..setAttribute('download', 'BaoCaoDoanhThu_${companyName}_$date.csv')
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider(widget.companyId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: companyAsync.when(
        loading: () => Column(
          children: [
            // Shimmer for header/overview section
            const ShimmerCompanyHeader(),
            const SizedBox(height: 16),
            // Bottom navigation bar shown even while loading
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải thông tin công ty',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.refresh(companyDetailsProvider(widget.companyId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (company) {
          if (company == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy công ty',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }
          // Set company-specific AI API key
          GeminiService.setApiKey(company.aiApiKey);
          return _buildContent(company);
        },
      ),
    );
  }

  Widget _buildContent(Company company) {
    return Scaffold(
      body: Column(
        children: [
          // Header with back button and company info
          _buildTopAppBar(company),
          // Top TabBar - always visible
          _buildTopTabBar(company),
          // Content area
          Expanded(
            // ✅ PERFORMANCE FIX: Lazy loading - only build current tab
            // Previous: IndexedStack kept all 10 tabs in memory (~100MB overhead)
            // Now: Only builds active tab, reducing memory usage by ~80%
            child: _buildCurrentTab(company),
          ),
        ],
      ),
    );
  }

  /// Build Top AppBar with company info
  Widget _buildTopAppBar(Company company) {
    return Container(
      decoration: BoxDecoration(
        color: company.type.color,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface),
                tooltip: 'Quay lại',
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 8),
              // Company logo/icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  company.type.icon,
                  size: 20,
                  color: company.type.color,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      company.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            company.type.label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: company.status == 'active' 
                                ? Colors.green[300] 
                                : Colors.red[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          company.status == 'active' ? 'Hoạt động' : 'Tạm dừng',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More options menu (includes secondary tabs)
              PopupMenuButton<int>(
                icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.surface),
                tooltip: 'Tùy chọn khác',
                onSelected: (index) {
                  if (index < 0) {
                    // Negative indices for actions
                    if (index == -1) _showEditDialog(company);
                    if (index == -2) _showMoreOptions(company);
                  } else {
                    // Tab indices
                    setState(() {
                      _currentIndex = index;
                      if (index < 4) {
                        _tabController.animateTo(index);
                      }
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int>(
                    value: -1,
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Chỉnh sửa công ty'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<int>(
                    enabled: false,
                    child: Text(
                      'Thêm tùy chọn',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface87),
                    ),
                  ),
                  ..._secondaryTabs.map((tab) => PopupMenuItem<int>(
                    value: tab['index'] as int,
                    child: ListTile(
                      leading: Icon(
                        tab['icon'] as IconData,
                        color: _currentIndex == tab['index'] 
                            ? Colors.blue[700] 
                            : Colors.grey[700],
                      ),
                      title: Text(
                        tab['label'] as String,
                        style: TextStyle(
                          color: _currentIndex == tab['index'] 
                              ? Colors.blue[700] 
                              : Theme.of(context).colorScheme.onSurface87,
                          fontWeight: _currentIndex == tab['index'] 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Top TabBar
  Widget _buildTopTabBar(Company company) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: company.type.color,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: company.type.color,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: _mainTabs.map((tab) => Tab(
          icon: Icon(tab['icon'] as IconData, size: 20),
          text: tab['label'] as String,
          iconMargin: const EdgeInsets.only(bottom: 4),
        )).toList(),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Build only the currently active tab (lazy loading)
  /// This significantly reduces memory usage compared to IndexedStack
  Widget _buildCurrentTab(Company company) {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(company: company, companyId: widget.companyId);
      case 1:
        return _buildFinancialTab(company);
      case 2:
        return EmployeesTab(company: company, companyId: widget.companyId);
      case 3:
        return TasksTab(company: company, companyId: widget.companyId);
      case 4:
        return DocumentsTab(company: company);
      case 5:
        return AIAssistantTab(
          companyId: company.id,
          companyName: company.name,
        );
      case 6:
        return AttendanceTab(company: company, companyId: widget.companyId);
      case 7:
        return AccountingTab(company: company, companyId: widget.companyId);
      case 8:
        return EmployeeDocumentsTab(
            company: company, companyId: widget.companyId);
      case 9:
        return BusinessLawTab(company: company, companyId: widget.companyId);
      case 10:
        return PermissionsManagementTab(
            company: company, companyId: widget.companyId);
      case 11:
        return SettingsTab(company: company, companyId: widget.companyId);
      default:
        return OverviewTab(company: company, companyId: widget.companyId);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FINANCIAL TAB - Báo cáo tài chính Live
  // ══════════════════════════════════════════════════════════════
  Widget _buildFinancialTab(Company company) {
    return Consumer(builder: (context, ref, _) {
      final summaryAsync = ref.watch(financialSummaryProvider(company.id));

      return summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        data: (summary) {
          if (summary['hasData'] != true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Chưa có dữ liệu tài chính',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Import báo cáo cuối ngày để xem thống kê',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 24),
                  // Nút Import cho trường hợp chưa có data
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DailyCashflowImportPage(
                            companyId: company.id,
                            companyName: company.name,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Import / Nhập thủ công'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final records = summary['records'] as List<MonthlyPnl>;
          final totalRevenue12m = summary['totalRevenue12m'] as double;
          final totalProfit12m = summary['totalProfit12m'] as double;
          final isCorporation = summary['isCorporation'] as bool? ?? false;
          final subsidiaryBreakdown = summary['subsidiaryBreakdown'] as List<Map<String, dynamic>>? ?? [];

          // ═══════════════════════════════════════════════════════════════
          // P&L MONTH FILTER - Tính toán dữ liệu theo tháng đã chọn
          // ═══════════════════════════════════════════════════════════════
          // Build list of available months from records, grouped by year
          final availableMonths = records.map((r) {
            return '${r.reportMonth.month.toString().padLeft(2, '0')}/${r.reportMonth.year}';
          }).toList();
          
          // Extract unique years for year filter tabs
          final availableYears = records.map((r) => r.reportMonth.year).toSet().toList()..sort((a, b) => b.compareTo(a));
          
          // Initialize year filter to most recent year
          if (_selectedPnlYear == null && availableYears.isNotEmpty) {
            _selectedPnlYear = availableYears.first;
          }
          
          // Filter months by selected year
          final filteredMonths = availableMonths.where((m) {
            final year = int.tryParse(m.split('/').last) ?? 0;
            return year == _selectedPnlYear;
          }).toList();
          
          // Determine which month to display
          final displayMonth = _selectedPnlMonth ?? (filteredMonths.isNotEmpty ? filteredMonths.first : (availableMonths.isNotEmpty ? availableMonths.first : null));
          
          // Find the selected record
          MonthlyPnl? selectedRecord;
          int selectedIndex = 0;
          if (displayMonth != null && records.isNotEmpty) {
            selectedIndex = availableMonths.indexOf(displayMonth);
            if (selectedIndex >= 0 && selectedIndex < records.length) {
              selectedRecord = records[selectedIndex];
            } else {
              selectedRecord = records.first;
              selectedIndex = 0;
            }
          } else if (records.isNotEmpty) {
            selectedRecord = records.first;
          }
          
          // Calculate display values based on selected month
          final latestRevenue = selectedRecord?.netRevenue ?? 0.0;
          final latestProfit = selectedRecord?.netProfit ?? 0.0;
          final latestMargin = latestRevenue > 0 ? (latestProfit / latestRevenue) * 100 : 0.0;
          final latestMonth = displayMonth ?? 'N/A';
          final isProfitable = latestProfit >= 0;
          
          // Calculate growth compared to previous month
          double growthPct = 0.0;
          if (selectedIndex + 1 < records.length) {
            final prevRecord = records[selectedIndex + 1];
            if (prevRecord.netRevenue > 0) {
              growthPct = ((latestRevenue - prevRecord.netRevenue) / prevRecord.netRevenue) * 100;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.analytics, size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text('Báo cáo tài chính',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                    const Spacer(),
                    // Scan AI button
                    if (!isCorporation)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoiceScanPage(
                                  companyId: company.id,
                                  companyName: company.name,
                                ),
                              ),
                            ).then((_) {
                              ref.invalidate(financialSummaryProvider(company.id));
                            });
                          },
                          icon: const Icon(Icons.document_scanner, size: 16),
                          label: const Text('📸 Scan AI'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple.shade700,
                            side: BorderSide(color: Colors.deepPurple.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    // Manual entry button
                    if (!isCorporation)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MonthlyPnlEntryPage(
                                  companyId: company.id,
                                  companyName: company.name,
                                ),
                              ),
                            ).then((saved) {
                              if (saved == true) {
                                ref.invalidate(financialSummaryProvider(company.id));
                              }
                            });
                          },
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('Nhập chi phí'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    if (!isCorporation)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyCashflowImportPage(
                                  companyId: company.id,
                                  companyName: company.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Import'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Live',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // ═══════════════════════════════════════════════════════════════
                // MONTH FILTER - Smart Year + Month Dropdown
                // ═══════════════════════════════════════════════════════════════
                if (availableMonths.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 18, color: Colors.indigo.shade600),
                        SizedBox(width: 8),
                        // YEAR DROPDOWN
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedPnlYear ?? (availableYears.isNotEmpty ? availableYears.first : DateTime.now().year),
                              isDense: true,
                              icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.indigo.shade600),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                              items: availableYears.map((year) {
                                final monthCount = records.where((r) => r.reportMonth.year == year).length;
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text('$year ($monthCount tháng)'),
                                );
                              }).toList(),
                              onChanged: (year) {
                                if (year != null) {
                                  setState(() {
                                    _selectedPnlYear = year;
                                    // Auto-select most recent month in new year
                                    final monthsInYear = availableMonths.where((m) {
                                      return int.tryParse(m.split('/').last) == year;
                                    }).toList();
                                    _selectedPnlMonth = monthsInYear.isNotEmpty ? monthsInYear.first : null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // MONTH DROPDOWN
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: filteredMonths.contains(displayMonth) ? displayMonth : (filteredMonths.isNotEmpty ? filteredMonths.first : null),
                                isDense: true,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.indigo.shade600),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                                hint: Text('Chọn tháng', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                items: filteredMonths.map((month) {
                                  final mNum = month.split('/').first;
                                  // Find the record to show revenue hint
                                  final idx = availableMonths.indexOf(month);
                                  final rec = (idx >= 0 && idx < records.length) ? records[idx] : null;
                                  final revHint = rec != null ? ' — ${_formatCurrency(rec.netRevenue)}' : '';
                                  return DropdownMenuItem<String>(
                                    value: month,
                                    child: Text('Tháng $mNum$revHint', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (month) {
                                  if (month != null) {
                                    setState(() => _selectedPnlMonth = month);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        // Navigate prev/next month
                        const SizedBox(width: 4),
                        _buildMonthNavButton(
                          icon: Icons.chevron_left,
                          tooltip: 'Tháng trước',
                          onTap: () {
                            final currentIdx = availableMonths.indexOf(displayMonth ?? '');
                            if (currentIdx >= 0 && currentIdx + 1 < availableMonths.length) {
                              final prevMonth = availableMonths[currentIdx + 1];
                              final prevYear = int.tryParse(prevMonth.split('/').last) ?? 0;
                              setState(() {
                                _selectedPnlMonth = prevMonth;
                                if (prevYear != _selectedPnlYear) _selectedPnlYear = prevYear;
                              });
                            }
                          },
                        ),
                        _buildMonthNavButton(
                          icon: Icons.chevron_right,
                          tooltip: 'Tháng sau',
                          onTap: () {
                            final currentIdx = availableMonths.indexOf(displayMonth ?? '');
                            if (currentIdx > 0) {
                              final nextMonth = availableMonths[currentIdx - 1];
                              final nextYear = int.tryParse(nextMonth.split('/').last) ?? 0;
                              setState(() {
                                _selectedPnlMonth = nextMonth;
                                if (nextYear != _selectedPnlYear) _selectedPnlYear = nextYear;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Latest month card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProfitable
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.red.shade50, Colors.red.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isProfitable ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Tháng $latestMonth',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                          const Spacer(),
                          if (growthPct != 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: growthPct > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.surface),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _financialMetric(
                              'Doanh thu',
                              _formatCurrency(latestRevenue),
                              Icons.trending_up,
                              Colors.blue.shade700,
                            ),
                          ),
                          Container(width: 1, height: 50, color: Colors.grey.shade300),
                          Expanded(
                            child: _financialMetric(
                              'Lợi nhuận',
                              _formatCurrency(latestProfit),
                              isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                              isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          Container(width: 1, height: 50, color: Colors.grey.shade300),
                          Expanded(
                            child: _financialMetric(
                              'Biên LN',
                              '${latestMargin.toStringAsFixed(1)}%',
                              Icons.percent,
                              Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (selectedRecord != null) ...[
                        Text('Chi tiết chi phí tháng',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(2),
                          },
                          border: TableBorder.all(color: Colors.grey, width: 0.3),
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                child: Text('Loại chi phí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                child: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ]),
                            _expenseRow('Lương nhân viên', selectedRecord.salaryExpenses),
                            _expenseRow('Mặt bằng', selectedRecord.rentExpense),
                            _expenseRow('Điện', selectedRecord.electricityExpense),
                            _expenseRow('Quảng cáo', selectedRecord.advertisingExpense),
                            _expenseRow('Nhập hàng có hóa đơn', selectedRecord.invoicedPurchases),
                            _expenseRow('Mua vật dụng/khác', selectedRecord.otherPurchases),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Edit expenses button
                        if (!isCorporation)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MonthlyPnlEntryPage(
                                      companyId: company.id,
                                      companyName: company.name,
                                      existingRecord: selectedRecord,
                                    ),
                                  ),
                                ).then((saved) {
                                  if (saved == true) {
                                    ref.invalidate(financialSummaryProvider(company.id));
                                  }
                                });
                              },
                              icon: Icon(Icons.edit, size: 14, color: Colors.green.shade700),
                              label: Text('Sửa chi phí / Đính kèm hóa đơn',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 12-month totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng 12 tháng gần nhất',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Doanh thu',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(totalRevenue12m),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lợi nhuận',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(totalProfit12m),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: totalProfit12m >= 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════════════════════════════════
                // SHAREHOLDERS SECTION - Cổ phần / Equity
                // ═══════════════════════════════════════════════════════════════
                _buildShareholdersSection(company.id),
                const SizedBox(height: 16),

                // Revenue trend chart
                if (records.length >= 3) ...[
                  Text('Xu hướng doanh thu',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  _buildRevenueChart(records.reversed.toList()),
                ],

                // Subsidiary breakdown for corporations
                if (isCorporation && subsidiaryBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.business, size: 18, color: Colors.indigo.shade700),
                      const SizedBox(width: 8),
                      Text('Chi tiết theo công ty con',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${subsidiaryBreakdown.length} công ty',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo.shade700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Subsidiary list
                  ...subsidiaryBreakdown.map((sub) {
                    final subRevenue = sub['totalRevenue'] as double;
                    final subProfit = sub['totalProfit'] as double;
                    final subMargin = sub['profitMargin'] as double;
                    final subName = sub['companyName'] as String;
                    final subType = sub['businessType'] as String;
                    final monthCount = sub['monthCount'] as int;
                    final subIsProfitable = subProfit >= 0;
                    
                    // Calculate percentage of total
                    final revenuePct = totalRevenue12m > 0 ? (subRevenue / totalRevenue12m) * 100 : 0.0;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company name & type
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subName,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_getBusinessTypeLabel(subType),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${revenuePct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Progress bar showing contribution
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: revenuePct / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  subIsProfitable ? Colors.green.shade400 : Colors.red.shade400),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Revenue & Profit
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Doanh thu',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text(_formatCurrency(subRevenue),
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lợi nhuận',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text(_formatCurrency(subProfit),
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: subIsProfitable
                                                ? Colors.green.shade700
                                                : Colors.red.shade700)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Biên LN',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text('${subMargin.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Metadata
                          Text('Dữ liệu từ $monthCount tháng',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }),
                ],

                // ═══════════════════════════════════════════════════════════════
                // DAILY CASHFLOW HISTORY - Lịch sử nhập liệu hàng ngày
                // ═══════════════════════════════════════════════════════════════
                if (!isCorporation) ...[
                  const SizedBox(height: 24),
                  _buildCashflowHistorySection(company),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  /// Build cashflow history section với filter, export, edit/delete
  Widget _buildCashflowHistorySection(Company company) {
    // Load history on first build
    if (_cashflowHistory == null && !_loadingHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCashflowHistory(company.id);
      });
    }

    final fmt = NumberFormat('#,###', 'vi');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với action buttons
        Row(
          children: [
            Icon(Icons.history, size: 18, color: Colors.indigo.shade700),
            const SizedBox(width: 8),
            Text('Lịch sử nhập liệu',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700)),
            const Spacer(),
            
            // Filter button
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showQuickDateRangePicker(context, current: _historyDateFilter);
                if (picked != null) {
                  setState(() {
                    _historyDateFilter = picked.start.year == 1970 ? null : picked;
                    _cashflowHistory = null;
                  });
                  _loadCashflowHistory(company.id);
                }
              },
              icon: Icon(Icons.filter_list, size: 16, 
                  color: _historyDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
              label: Text(
                _historyDateFilter != null 
                    ? getDateRangeLabel(_historyDateFilter!)
                    : 'Lọc ngày',
                style: TextStyle(fontSize: 11, 
                    color: _historyDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                side: BorderSide(
                    color: _historyDateFilter != null ? Colors.indigo.shade400 : Colors.grey.shade300),
                backgroundColor: _historyDateFilter != null ? Colors.indigo.shade50 : null,
              ),
            ),
            const SizedBox(width: 8),
            
            // Export button
            OutlinedButton.icon(
              onPressed: _cashflowHistory != null && _cashflowHistory!.isNotEmpty
                  ? () => _exportCashflowToCSV(_cashflowHistory!, company.name)
                  : null,
              icon: Icon(Icons.download, size: 16, color: Colors.green.shade700),
              label: Text('Xuất CSV', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                side: BorderSide(color: Colors.green.shade300),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Record count
        if (_cashflowHistory != null)
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text('${_cashflowHistory!.length} bản ghi',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
        const SizedBox(height: 12),
        
        // Content
        if (_loadingHistory)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_cashflowHistory == null || _cashflowHistory!.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có dữ liệu nhập liệu',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Sử dụng nút Import để thêm báo cáo cuối ngày',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          // Expandable history list
          Column(
            children: [
              // Show first 5 or all if expanded
              ...(_historyExpanded 
                  ? _cashflowHistory! 
                  : _cashflowHistory!.take(5)
              ).map((cf) => _buildCashflowHistoryCard(cf, fmt, company)),
              
              // Show more/less button
              if (_cashflowHistory!.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _historyExpanded = !_historyExpanded),
                    icon: Icon(
                      _historyExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      _historyExpanded 
                          ? 'Thu gọn' 
                          : 'Xem thêm (${_cashflowHistory!.length - 5} bản ghi)',
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.indigo.shade600),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Build individual history card with edit/delete
  Widget _buildCashflowHistoryCard(DailyCashflow cf, NumberFormat fmt, Company company) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(DateFormat('dd').format(cf.reportDate),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700)),
                Text(DateFormat('MM/yy').format(cf.reportDate),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Revenue & Order details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fmt.format(cf.totalRevenue)} ₫',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _miniHistoryTag('${cf.totalOrders} HĐ', Colors.blue),
                    _miniHistoryTag('TM: ${fmt.format(cf.cashAmount)}', Colors.green),
                    if (cf.transferAmount > 0)
                      _miniHistoryTag('CK: ${fmt.format(cf.transferAmount)}', Colors.indigo),
                    if (cf.cardAmount > 0)
                      _miniHistoryTag('Thẻ: ${fmt.format(cf.cardAmount)}', Colors.purple),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cf.sourceFile == 'manual_entry' ? '✏️ Nhập thủ công' : '📄 Import: ${cf.sourceFile ?? 'Excel'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          
          // Action menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (action) {
              if (action == 'edit') {
                // Navigate to DailyCashflowImportPage with prefilled data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyCashflowImportPage(
                      companyId: company.id,
                      companyName: company.name,
                    ),
                  ),
                ).then((_) {
                  // Refresh history after returning
                  _loadCashflowHistory(company.id);
                  ref.invalidate(financialSummaryProvider(company.id));
                });
              } else if (action == 'delete') {
                _deleteCashflowRecord(cf.id, company.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _miniHistoryTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 18, color: Colors.indigo.shade600),
        ),
      ),
    );
  }

  Widget _financialMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return NumberFormat('#,###').format(amount);
  }

  String _getBusinessTypeLabel(String type) {
    switch (type) {
      case 'billiards':
        return '🎱 Bida';
      case 'restaurant':
        return '🍽️ Nhà hàng';
      case 'hotel':
        return '🏨 Khách sạn';
      case 'cafe':
        return '☕ Quán cà phê';
      case 'retail':
        return '🛒 Bán lẻ';
      case 'distribution':
        return '🚚 Phân phối';
      case 'manufacturing':
        return '🏭 Sản xuất';
      case 'corporation':
        return '🏢 Tổng công ty';
      default:
        return type;
    }
  }

  Widget _buildRevenueChart(List<MonthlyPnl> records) {
    final data = records.length > 12 ? records.sublist(records.length - 12) : records;
    final maxRevenue = data.fold<double>(0, (max, r) => r.netRevenue > max ? r.netRevenue : max);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((r) {
          final heightPct = maxRevenue > 0 ? r.netRevenue / maxRevenue : 0.0;
          final isProfitable = r.netProfit > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isProfitable ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      height: (heightPct * 100).clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        color: isProfitable
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'T${r.reportMonth.month}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper methods for header actions
  void _showEditDialog(Company company) {
    final nameController = TextEditingController(text: company.name);
    final addressController = TextEditingController(text: company.address);
    final phoneController = TextEditingController(text: company.phone ?? '');
    final emailController = TextEditingController(text: company.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa công ty'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên công ty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final service = ref.read(companyServiceProvider);
                  await service.updateCompany(company.id, {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  });

                  ref.invalidate(companyDetailsProvider(widget.companyId));
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật công ty thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(Company company) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chia sẻ công ty')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Làm mới'),
              onTap: () {
                Navigator.pop(context);
                ref.invalidate(companyDetailsProvider(widget.companyId));
                ref.invalidate(companyStatsProvider(widget.companyId));
                ref.invalidate(companyBranchesProvider(widget.companyId));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build shareholders section - Cổ phần với lịch sử theo năm
  Widget _buildShareholdersSection(String companyId) {
    return Consumer(builder: (context, ref, _) {
      final historyAsync = ref.watch(shareholdersHistoryProvider(companyId));

      return historyAsync.when(
        loading: () => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => const SizedBox.shrink(),
        data: (history) {
          if (history.isEmpty) {
            return const SizedBox.shrink();
          }

          // Get available years sorted descending
          final availableYears = history.keys.toList()..sort((a, b) => b.compareTo(a));
          final latestYear = availableYears.first;
          
          // Determine which year to display
          final displayYear = _selectedShareholderYear ?? latestYear;
          final shareholders = history[displayYear] ?? [];
          
          if (shareholders.isEmpty) {
            return SizedBox.shrink();
          }
          
          // Get previous year data for comparison
          final yearIndex = availableYears.indexOf(displayYear);
          final previousYear = yearIndex < availableYears.length - 1 
              ? availableYears[yearIndex + 1] 
              : null;
          final prevShareholders = previousYear != null ? (history[previousYear] ?? []) : <Shareholder>[];
          
          // Calculate totals
          double totalInvestment = 0;
          double totalDepreciation = 0;
          for (final sh in shareholders) {
            totalInvestment += sh.cashInvested;
            totalDepreciation += sh.depreciation;
          }

          // Define colors for shareholders
          final shareholderColors = [
            Colors.blue.shade600,
            Colors.green.shade600,
            Colors.orange.shade600,
            Colors.purple.shade600,
            Colors.red.shade600,
          ];

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade50,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.pie_chart, size: 20, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text('Cơ cấu cổ phần',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700)),
                    const Spacer(),
                    // Export button
                    IconButton(
                      onPressed: () => _exportShareholdersToExcel(context, 
                        history: history,
                        displayYear: displayYear,
                        companyName: widget.companyId, // Will be replaced with actual name
                      ),
                      icon: Icon(Icons.download_outlined, size: 20, color: Colors.purple.shade600),
                      tooltip: 'Xuất Excel',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Year indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${availableYears.length} năm dữ liệu',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // ═══════════════════════════════════════════════════════════════
                // YEAR SELECTOR - Chọn năm để xem lịch sử
                // ═══════════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.purple.shade600),
                      const SizedBox(width: 8),
                      Text('Năm:',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableYears.map((year) {
                              final isSelected = year == displayYear;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedShareholderYear = year),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.purple.shade600 : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? Colors.purple.shade600 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      year.toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Reset button
                      if (_selectedShareholderYear != null)
                        IconButton(
                          onPressed: () => setState(() => _selectedShareholderYear = null),
                          icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
                          tooltip: 'Về năm mới nhất',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════════════════════════════════
                // PIE CHART - Biểu đồ tròn trực quan
                // ═══════════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Pie Chart
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: _ShareholderPieChartPainter(
                            shareholders: shareholders,
                            colors: shareholderColors,
                            surfaceColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: shareholders.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final sh = entry.value;
                            final color = shareholderColors[idx % shareholderColors.length];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sh.shareholderName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${sh.ownershipPercentage.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════════════════════════════════
                // BẢNG TỔNG HỢP CHI TIẾT
                // ═══════════════════════════════════════════════════════════════
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),      // Cổ đông
                        1: FlexColumnWidth(2.5),    // Vốn góp
                        2: FlexColumnWidth(1.8),    // Khấu hao
                        3: FlexColumnWidth(2.2),    // Vốn ròng
                        4: FlexColumnWidth(1.5),    // Tỷ lệ
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey.shade200),
                      ),
                      children: [
                        // Header row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.purple.shade100),
                          children: [
                            _tableCell('Cổ đông', isHeader: true),
                            _tableCell('Vốn góp', isHeader: true),
                            _tableCell('KH 30%', isHeader: true),
                            _tableCell('Vốn ròng', isHeader: true),
                            _tableCell('Tỷ lệ', isHeader: true),
                          ],
                        ),
                        // Data rows
                        ...shareholders.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sh = entry.value;
                          final netValue = sh.cashInvested - sh.depreciation;
                          final color = shareholderColors[idx % shareholderColors.length];
                          return TableRow(
                            decoration: BoxDecoration(
                              color: idx % 2 == 0 ? Theme.of(context).colorScheme.surface : Colors.grey.shade50,
                            ),
                            children: [
                              _tableCell(sh.shareholderName, color: color),
                              _tableCell(_formatCurrencyShort(sh.cashInvested)),
                              _tableCell(_formatCurrencyShort(sh.depreciation), color: Colors.orange.shade700),
                              _tableCell(_formatCurrencyShort(netValue), bold: true),
                              _tableCell('${sh.ownershipPercentage.toStringAsFixed(2)}%', bold: true, color: color),
                            ],
                          );
                        }),
                        // Total row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.yellow.shade100),
                          children: [
                            _tableCell('TỔNG', isHeader: true),
                            _tableCell(_formatCurrencyShort(totalInvestment), bold: true),
                            _tableCell(_formatCurrencyShort(totalDepreciation), bold: true, color: Colors.orange.shade700),
                            _tableCell(_formatCurrencyShort(totalInvestment - totalDepreciation), bold: true),
                            _tableCell('100%', bold: true, color: Colors.purple.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════════════════════════════════
                // GIẢI THÍCH QUY TẮC
                // ═══════════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate_outlined, size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Công thức tính',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ruleItem('Khấu hao = 30% × Vốn góp', Icons.remove_circle_outline, Colors.orange.shade700),
                      _ruleItem('Vốn ròng = Vốn góp − Khấu hao', Icons.calculate_outlined, Colors.green.shade700),
                      _ruleItem('Tỷ lệ SH = Vốn ròng ÷ Tổng vốn ròng × 100%', Icons.pie_chart_outline, Colors.purple.shade700),
                      const Divider(height: 16),
                      Text(
                        '📌 Lưu ý: Khấu hao 30%/năm áp dụng để tính giá trị hiện tại của vốn góp.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Shareholder list
                ...shareholders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sh = entry.value;
                  final color = shareholderColors[index % shareholderColors.length];
                  final pct = sh.ownershipPercentage;
                  
                  // Calculate change from previous year
                  double change = 0;
                  if (prevShareholders.isNotEmpty) {
                    final prevSh = prevShareholders.where((p) => p.shareholderName == sh.shareholderName).firstOrNull;
                    if (prevSh != null) {
                      change = pct - prevSh.ownershipPercentage;
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sh.shareholderName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            if (change != 0 && previousYear != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: change > 0 
                                      ? Colors.green.shade100 
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: change > 0 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showShareholderDetailSheet(
                                context,
                                sh: sh,
                                color: color,
                                displayYear: displayYear,
                                totalInvestment: totalInvestment,
                                totalDepreciation: totalDepreciation,
                                shareholders: shareholders,
                                prevShareholders: prevShareholders,
                                previousYear: previousYear,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: color.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatCurrency(sh.cashInvested),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (sh.depreciation > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                'KH: ${_formatCurrency(sh.depreciation)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (sh.notes != null && sh.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              sh.notes!,
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // Total investment summary
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng vốn góp năm $displayYear',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(_formatCurrency(totalInvestment),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700)),
                        ],
                      ),
                    ),
                    if (totalDepreciation > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đã khấu hao',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text(_formatCurrency(totalDepreciation),
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700)),
                          ],
                        ),
                      ),
                  ],
                ),

                // Note about changes
                if (previousYear != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Thay đổi % so với năm $previousYear',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  void _showShareholderDetailSheet(
    BuildContext context, {
    required Shareholder sh,
    required Color color,
    required int displayYear,
    required double totalInvestment,
    required double totalDepreciation,
    required List<Shareholder> shareholders,
    required List<Shareholder> prevShareholders,
    required int? previousYear,
  }) {
    final netValue = sh.cashInvested - sh.depreciation;
    final totalNetInvestment = totalInvestment - totalDepreciation;
    final computedPct = totalNetInvestment > 0 ? (netValue / totalNetInvestment * 100) : 0.0;

    final prevSh = prevShareholders
        .where((p) => p.shareholderName == sh.shareholderName)
        .firstOrNull;
    final change = prevSh != null ? sh.ownershipPercentage - prevSh.ownershipPercentage : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${sh.shareholderName} — Chi tiết $displayYear',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ─── Section 1: Vốn góp ───
                    _detailSectionTitle(Icons.account_balance_wallet_outlined, 'Vốn góp', color),
                    const SizedBox(height: 8),
                    _detailRow2('Vốn đã đầu tư', _formatCurrency(sh.cashInvested), bold: true),
                    if (sh.depreciation > 0) ...[
                      _detailRow2('Khấu hao đã trừ', '− ${_formatCurrency(sh.depreciation)}',
                          valueColor: Colors.orange.shade700),
                      const Divider(height: 16, indent: 0, endIndent: 0),
                      _detailRow2(
                        'Vốn ròng sau KH',
                        _formatCurrency(netValue),
                        bold: true,
                        valueColor: color,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ─── Section 2: Tổng công ty ───
                    _detailSectionTitle(Icons.business, 'Tổng công ty ($displayYear)', Colors.purple.shade600),
                    const SizedBox(height: 8),
                    _detailRow2('Tổng vốn góp', _formatCurrency(totalInvestment)),
                    if (totalDepreciation > 0) ...[
                      _detailRow2('Tổng khấu hao', '− ${_formatCurrency(totalDepreciation)}',
                          valueColor: Colors.orange.shade700),
                      _detailRow2('Tổng vốn ròng', _formatCurrency(totalNetInvestment),
                          bold: true, valueColor: Colors.purple.shade700),
                    ],
                    const SizedBox(height: 20),

                    // ─── Section 3: Công thức ───
                    _detailSectionTitle(Icons.calculate_outlined, 'Công thức tỷ lệ sở hữu', Colors.indigo.shade600),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vốn ròng ÷ Tổng vốn ròng × 100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sh.depreciation > 0
                                ? '= ${_formatCurrency(netValue)} ÷ ${_formatCurrency(totalNetInvestment)} × 100'
                                : '= ${_formatCurrency(sh.cashInvested)} ÷ ${_formatCurrency(totalInvestment)} × 100',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '= ${computedPct.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lưu trong DB: ${sh.ownershipPercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Section 4: So sánh năm trước ───
                    if (prevSh != null && previousYear != null) ...[
                      _detailSectionTitle(Icons.compare_arrows, 'So với năm $previousYear', Colors.teal.shade600),
                      const SizedBox(height: 8),
                      _detailRow2('Vốn góp năm $previousYear', _formatCurrency(prevSh.cashInvested)),
                      if (prevSh.depreciation > 0)
                        _detailRow2('Khấu hao năm $previousYear', _formatCurrency(prevSh.depreciation),
                            valueColor: Colors.orange.shade700),
                      _detailRow2('Tỷ lệ năm $previousYear', '${prevSh.ownershipPercentage.toStringAsFixed(2)}%'),
                      _detailRow2(
                        'Chênh lệch tỷ lệ',
                        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                        bold: true,
                        valueColor: change >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ─── Section 5: Ghi chú ───
                    if (sh.notes != null && sh.notes!.isNotEmpty) ...[
                      _detailSectionTitle(Icons.sticky_note_2_outlined, 'Ghi chú', Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          sh.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _detailRow2(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for table cells
  Widget _tableCell(String text, {bool isHeader = false, bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader || bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? Colors.purple.shade900 : Colors.grey.shade800),
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  /// Helper widget for rule explanation items
  Widget _ruleItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Format currency to short form (e.g., 622.9tr)
  String _formatCurrencyShort(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} tr';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} K';
    }
    return value.toStringAsFixed(0);
  }

  /// Export shareholders data to Excel file
  void _exportShareholdersToExcel(BuildContext context, {
    required Map<int, List<Shareholder>> history,
    required int displayYear,
    required String companyName,
  }) {
    try {
      final excelFile = excel_lib.Excel.createExcel();
      
      // Remove default sheet
      excelFile.delete('Sheet1');
      
      // Get all years sorted descending
      final years = history.keys.toList()..sort((a, b) => b.compareTo(a));
      
      for (final year in years) {
        final shareholders = history[year] ?? [];
        if (shareholders.isEmpty) continue;
        
        // Create sheet for this year
        final sheetName = 'Năm $year';
        final sheet = excelFile[sheetName];
        
        // Header style
        final headerStyle = excel_lib.CellStyle(
          bold: true,
          backgroundColorHex: excel_lib.ExcelColor.fromHexString('#E8D5FF'),
          horizontalAlign: excel_lib.HorizontalAlign.Center,
        );
        
        // Title row
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 
            excel_lib.TextCellValue('CƠ CẤU CỔ PHẦN NĂM $year');
        sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                    excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));
        
        // Header row
        final headers = ['STT', 'Cổ đông', 'Vốn đã góp (VND)', 'Khấu hao (VND)', 'Vốn ròng (VND)', 'Tỷ lệ sở hữu (%)'];
        for (var i = 0; i < headers.length; i++) {
          final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
          cell.value = excel_lib.TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }
        
        // Calculate totals
        double totalInvested = 0;
        double totalDepreciation = 0;
        for (final sh in shareholders) {
          totalInvested += sh.cashInvested;
          totalDepreciation += sh.depreciation;
        }
        final totalNet = totalInvested - totalDepreciation;
        
        // Data rows
        for (var i = 0; i < shareholders.length; i++) {
          final sh = shareholders[i];
          final netValue = sh.cashInvested - sh.depreciation;
          final rowIndex = i + 3;
          
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
              excel_lib.IntCellValue(i + 1);
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
              excel_lib.TextCellValue(sh.shareholderName);
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = 
              excel_lib.DoubleCellValue(sh.cashInvested);
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = 
              excel_lib.DoubleCellValue(sh.depreciation);
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = 
              excel_lib.DoubleCellValue(netValue);
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = 
              excel_lib.DoubleCellValue(sh.ownershipPercentage);
        }
        
        // Total row
        final totalRowIndex = shareholders.length + 3;
        final totalStyle = excel_lib.CellStyle(
          bold: true,
          backgroundColorHex: excel_lib.ExcelColor.fromHexString('#FFF3CD'),
        );
        
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIndex))
          ..value = excel_lib.TextCellValue('TỔNG CỘNG')
          ..cellStyle = totalStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIndex))
          ..value = excel_lib.DoubleCellValue(totalInvested)
          ..cellStyle = totalStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex))
          ..value = excel_lib.DoubleCellValue(totalDepreciation)
          ..cellStyle = totalStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex))
          ..value = excel_lib.DoubleCellValue(totalNet)
          ..cellStyle = totalStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex))
          ..value = excel_lib.DoubleCellValue(100.0)
          ..cellStyle = totalStyle;
        
        // Formula explanation row
        final formulaRowIndex = totalRowIndex + 2;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: formulaRowIndex)).value = 
            excel_lib.TextCellValue('📌 Công thức: Tỷ lệ sở hữu = Vốn ròng ÷ Tổng vốn ròng × 100');
        sheet.merge(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: formulaRowIndex),
          excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: formulaRowIndex),
        );
        
        // Notes row
        final notesRowIndex = formulaRowIndex + 1;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: notesRowIndex)).value = 
            excel_lib.TextCellValue('📌 Vốn ròng = Vốn đã góp − Khấu hao');
        sheet.merge(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: notesRowIndex),
          excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: notesRowIndex),
        );
        
        // Set column widths
        sheet.setColumnWidth(0, 8);  // STT
        sheet.setColumnWidth(1, 20); // Cổ đông
        sheet.setColumnWidth(2, 20); // Vốn góp
        sheet.setColumnWidth(3, 18); // Khấu hao
        sheet.setColumnWidth(4, 18); // Vốn ròng
        sheet.setColumnWidth(5, 18); // Tỷ lệ
      }
      
      // Generate file
      final bytes = excelFile.encode();
      if (bytes == null) return;
      
      // Download file
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'co_cau_co_phan_$displayYear.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surface, size: 18),
                SizedBox(width: 8),
                Text('Đã tải file Excel thành công'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

}

TableRow _expenseRow(String label, double value) {
  return TableRow(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(
        value == 0 ? '-' : NumberFormat.currency(locale: 'vi', symbol: '', decimalDigits: 0).format(value),
        style: const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]),
      ),
    ),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHAREHOLDER PIE CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _ShareholderPieChartPainter extends CustomPainter {
  final List<Shareholder> shareholders;
  final List<Color> colors;
  final Color surfaceColor;

  _ShareholderPieChartPainter({
    required this.shareholders,
    required this.colors,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    double startAngle = -1.5708; // -90 degrees in radians (start from top)

    for (int i = 0; i < shareholders.length; i++) {
      final sh = shareholders[i];
      final sweepAngle = (sh.ownershipPercentage / 100) * 2 * 3.14159;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = surfaceColor
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut hole)
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = surfaceColor;
    canvas.drawCircle(center, radius * 0.45, centerPaint);

    // Draw year in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${DateTime.now().year}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
