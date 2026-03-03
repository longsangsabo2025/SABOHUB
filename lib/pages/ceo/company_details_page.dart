import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/branch.dart';
import '../../models/company.dart';
import '../../business_types/service/providers/monthly_pnl_provider.dart';
import '../../business_types/service/models/monthly_pnl.dart';
import '../../business_types/service/pages/cashflow/daily_cashflow_import_page.dart';
import '../../services/branch_service.dart';
import '../../services/company_service.dart';
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

  const CompanyDetailsPage({
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

  String get _currentTabName {
    if (_currentIndex < 5) return _mainTabs[_currentIndex]['label'] as String;
    final secondary = _secondaryTabs.firstWhere(
      (t) => t['index'] == _currentIndex,
      orElse: () => {'label': 'Thêm'},
    );
    return secondary['label'] as String;
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
          return _buildContent(company);
        },
      ),
    );
  }

  Widget _buildContent(Company company) {
    // For main tabs (0-3), use TabBar index; for secondary tabs, show menu indicator
    final isMainTab = _currentIndex < 4;
    
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
            color: Colors.black.withValues(alpha: 0.1),
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Quay lại',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              // Company logo/icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            company.type.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                        const SizedBox(width: 4),
                        Text(
                          company.status == 'active' ? 'Hoạt động' : 'Tạm dừng',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
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
                icon: const Icon(Icons.more_vert, color: Colors.white),
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
                  const PopupMenuItem<int>(
                    enabled: false,
                    child: Text(
                      'Thêm tùy chọn',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
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
                              : Colors.black87,
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
      color: Colors.white,
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
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import / Nhập thủ công'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final records = summary['records'] as List<MonthlyPnl>;
          final latestRevenue = summary['latestNetRevenue'] as double;
          final latestProfit = summary['latestNetProfit'] as double;
          final latestMargin = summary['latestNetMargin'] as double;
          final growthPct = summary['revenueGrowthPct'] as double;
          final totalRevenue12m = summary['totalRevenue12m'] as double;
          final totalProfit12m = summary['totalProfit12m'] as double;
          final latestMonth = summary['latestMonth'] as String;
          final isProfitable = summary['isProfitable'] as bool;
          final isCorporation = summary['isCorporation'] as bool? ?? false;
          final subsidiaryBreakdown = summary['subsidiaryBreakdown'] as List<Map<String, dynamic>>? ?? [];

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
                    // Import button - chỉ hiển thị cho non-corporation (công ty con có thể import)
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
                          label: const Text('Import/Nhập thủ công'),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: growthPct > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
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

                // Revenue trend chart
                if (records.length >= 3) ...[                  Text('Xu hướng doanh thu',
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
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
              ],
            ),
          );
        },
      );
    });
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
}
