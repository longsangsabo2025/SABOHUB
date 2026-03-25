import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/theme/app_colors.dart';
import '../../../../models/company.dart';
import '../../../../models/project.dart';
import '../../../../pages/ceo/company_details_page.dart' hide companyStatsProvider;
import '../../../../providers/auth_provider.dart';
import '../../../../providers/company_alerts_provider.dart';
import '../../../../providers/company_provider.dart';
import '../../../../providers/project_provider.dart';
import '../../pages/cashflow/daily_cashflow_import_page.dart';
import '../../providers/monthly_pnl_provider.dart';
import '../../services/service_number_formatters.dart';
import 'widgets/project_detail_sheet.dart';

class ManagerProjectsTab extends ConsumerStatefulWidget {
  const ManagerProjectsTab({super.key});

  @override
  ConsumerState<ManagerProjectsTab> createState() => ManagerProjectsTabState();
}

class ManagerProjectsTabState extends ConsumerState<ManagerProjectsTab> {
  List<String> _assignedCompanyIds = [];
  String? _primaryCompanyId;
  bool _isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedCompanies();
  }

  Future<void> _loadAssignedCompanies() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoadingAssignments = false);
      return;
    }
    
    try {
      final response = await Supabase.instance.client
          .from('manager_companies')
          .select()
          .eq('manager_id', user.id);
      
      final List<String> ids = [];
      String? primary;
      for (final row in response as List) {
        ids.add(row['company_id'] as String);
        if (row['is_primary'] == true) {
          primary = row['company_id'] as String;
        }
      }
      
      if (mounted) {
        setState(() {
          _assignedCompanyIds = ids;
          _primaryCompanyId = primary;
          _isLoadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssignments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use allCompaniesAdminProvider instead of companiesProvider
    // companiesProvider filters by ownership (CEO), but manager needs assigned companies
    final companiesAsync = ref.watch(allCompaniesAdminProvider);

    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (allCompanies) {
        // Filter to only show manager's assigned companies
        final myCompanies = allCompanies
            .where((c) => _assignedCompanyIds.contains(c.id))
            .toList();
        final alertsMapAsync = ref.watch(
          multiCompanyAlertsProvider(myCompanies.map((c) => c.id).toList()),
        );
        
        if (myCompanies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Chưa được gán công ty',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Liên hệ CEO để được phân quyền',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        // Single company view
        if (myCompanies.length == 1) {
          final company = myCompanies.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text('Công ty của tôi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompanyCard(
                  context,
                  company,
                  alerts: alertsMapAsync.asData?.value[company.id],
                ),
                const SizedBox(height: 20),
                _buildQuickStats(company.id),
                const SizedBox(height: 20),
                _buildProjectsSection(company.id),
                const SizedBox(height: 20),
                _buildFinancialDashboard(company.id),
              ],
            ),
          );
        }

        // Multiple companies view
        return Column(
          children: [
            // Stats bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.business, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text('Công ty quản lý: ${myCompanies.length}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Company list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: myCompanies.length,
                itemBuilder: (context, index) {
                  final c = myCompanies[index];
                  final isPrimary = c.id == _primaryCompanyId;
                  return Stack(
                    children: [
                      _buildCompanyCard(
                        context,
                        c,
                        alerts: alertsMapAsync.asData?.value[c.id],
                      ),
                      if (isPrimary)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text('Chính', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(String companyId) {
    return Consumer(builder: (context, ref, _) {
      final statsAsync = ref.watch(companyStatsProvider(companyId));
      return statsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (stats) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Thống kê nhanh',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statItem('Nhân viên', '${stats['employees'] ?? 0}', Icons.people_outline, AppColors.info),
                  _statItem('Chi nhánh', '${stats['branches'] ?? 0}', Icons.store_outlined, AppColors.warning),
                  _statItem('Bàn', '${stats['tables'] ?? 0}', Icons.table_bar, AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  /// Projects section showing projects and sub-projects
  Widget _buildProjectsSection(String companyId) {
    return Consumer(builder: (context, ref, _) {
      final projectsAsync = ref.watch(companyProjectsProvider(companyId));
      
      return projectsAsync.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Lỗi: $e', style: TextStyle(color: Colors.red.shade400)),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có dự án',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text('Tạo dự án mới để quản lý công việc',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.folder_special, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Dự án',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${projects.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Project list
                ...projects.map((project) => _buildProjectTile(project)),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildProjectTile(Project project) {
    return InkWell(
      onTap: () => _showProjectDetail(project),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: project.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(project.status.icon, size: 12, color: project.status.color),
                      const SizedBox(width: 4),
                      Text(
                        project.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: project.status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        project.progress >= 100 
                            ? AppColors.success 
                            : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${project.progress}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: project.progress >= 100 
                        ? AppColors.success 
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            // Priority badge
            if (project.priority != ProjectPriority.medium) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: project.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.priority.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: project.priority.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProjectDetail(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectDetailSheet(project: project),
    );
  }

  Widget _buildCompanyCard(BuildContext context, Company c, {CompanyAlerts? alerts}) {
    final typeColor = c.type.color;
    final typeIcon = c.type.icon;
    final isActive = c.status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCompanyDetail(context, c),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: typeColor, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Icon + Name + Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(c.type.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Tạm ngưng',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              // Row 2: Alerts badges
              if (alerts != null && alerts.hasAlerts)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (alerts.overdueTasksCount > 0)
                        _alertBadge(
                          icon: Icons.warning_amber_rounded,
                          count: alerts.overdueTasksCount,
                          label: 'Quá hạn',
                          color: Colors.red,
                        ),
                      if (alerts.pendingApprovalCount > 0)
                        _alertBadge(
                          icon: Icons.pending_actions,
                          count: alerts.pendingApprovalCount,
                          label: 'Chờ duyệt',
                          color: Colors.orange,
                        ),
                      if (alerts.newReportsCount > 0)
                        _alertBadge(
                          icon: Icons.analytics_outlined,
                          count: alerts.newReportsCount,
                          label: 'Báo cáo',
                          color: Colors.blue,
                        ),
                      if (alerts.unreadMessagesCount > 0)
                        _alertBadge(
                          icon: Icons.message_outlined,
                          count: alerts.unreadMessagesCount,
                          label: 'Tin nhắn',
                          color: Colors.purple,
                        ),
                    ],
                  ),
                ),
              // Row 3: Address
              if (c.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(c.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ],
              // Row 3: Contact info
              const SizedBox(height: 6),
              Row(
                children: [
                  if (c.phone != null && c.phone!.isNotEmpty) ...[
                    Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(c.phone!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                  ],
                  if (c.email != null && c.email!.isNotEmpty) ...[
                    Icon(Icons.email_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(c.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ),
                  ],
                  if (c.createdAt != null) ...[
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(c.createdAt!),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Alert badge widget for company notifications
  Widget _alertBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigate to full Company Details Page ──
  void _showCompanyDetail(BuildContext context, Company c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: c.id),
      ),
    );
  }

  // ── Company Detail Bottom Sheet (legacy, kept for reference) ──
  // ignore: unused_element
  void _showCompanyDetailBottomSheet(BuildContext context, Company c) {
    final typeColor = c.type.color;
    final isActive = c.status == 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(builder: (context, ref, _) {
        final statsAsync = ref.watch(companyStatsProvider(c.id));
        return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c.type.icon, size: 24, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(c.type.label,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Tạm ngưng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats from provider
                    statsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _statItem('Nhân viên', '${stats['employees'] ?? 0}', Icons.people_outline, AppColors.info),
                            _statItem('Chi nhánh', '${stats['branches'] ?? 0}', Icons.store_outlined, AppColors.warning),
                            _statItem('Bàn', '${stats['tables'] ?? 0}', Icons.table_bar, AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Info grid
                    if (c.address.isNotEmpty)
                      _infoRow(Icons.location_on_outlined, 'Địa chỉ', c.address),
                    if (c.phone != null && c.phone!.isNotEmpty)
                      _infoRow(Icons.phone_outlined, 'Điện thoại', c.phone!),
                    if (c.email != null && c.email!.isNotEmpty)
                      _infoRow(Icons.email_outlined, 'Email', c.email!),
                    if (c.createdAt != null)
                      _infoRow(Icons.calendar_today_outlined, 'Ngày tạo',
                          DateFormat('dd/MM/yyyy').format(c.createdAt!)),
                    // Bank info
                    if (c.activeBankNameValue != null && c.activeBankNameValue!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text('Tài khoản ngân hàng',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${c.activeBankNameValue}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            if (c.activeBankAccountNumberValue != null)
                              Text(c.activeBankAccountNumberValue!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            if (c.activeBankAccountNameValue != null)
                              Text(c.activeBankAccountNameValue!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                    // ── Import Báo Cáo button ──
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyCashflowImportPage(
                                companyId: c.id,
                                companyName: c.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import Báo Cáo Cuối Ngày'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // ── Financial Dashboard ──
                    const SizedBox(height: 20),
                    _buildFinancialDashboard(c.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Financial Dashboard Widget ──
  Widget _buildFinancialDashboard(String companyId) {
    return Consumer(builder: (context, ref, _) {
    final summaryAsync = ref.watch(financialSummaryProvider(companyId));

    return summaryAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        if (summary['hasData'] != true) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, size: 24, color: Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Chưa có dữ liệu tài chính',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ),
              ],
            ),
          );
        }

        final latestRevenue = summary['latestNetRevenue'] as double;
        final latestProfit = summary['latestNetProfit'] as double;
        final latestMargin = summary['latestNetMargin'] as double;
        final growthPct = summary['revenueGrowthPct'] as double;
        final totalRevenue12m = summary['totalRevenue12m'] as double;
        final totalProfit12m = summary['totalProfit12m'] as double;
        final latestMonth = summary['latestMonth'] as String;
        final isProfitable = summary['isProfitable'] as bool;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(Icons.analytics, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text('Báo cáo tài chính',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Live',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Latest month summary card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfitable
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700)),
                      const Spacer(),
                      if (growthPct != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: growthPct > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _financialMetric(
                          'Doanh thu',
                          formatServiceCurrencyCompact(latestRevenue),
                          Icons.trending_up,
                          Colors.blue.shade700,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Expanded(
                        child: _financialMetric(
                          'Lợi nhuận',
                          formatServiceCurrencyCompact(latestProfit),
                          isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                          isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
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
            const SizedBox(height: 12),

            // 12-month totals
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng 12 tháng gần nhất',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Doanh thu',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text(formatServiceCurrencyCompact(totalRevenue12m),
                                style: TextStyle(
                                    fontSize: 14,
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
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text(formatServiceCurrencyCompact(totalProfit12m),
                                style: TextStyle(
                                    fontSize: 14,
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
          ],
        );
      },
    );
    });
  }

  Widget _financialMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }

}
