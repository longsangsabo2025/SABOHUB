import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/ai_uploaded_file.dart';
import '../../models/branch.dart';
import '../../models/business_type.dart';
import '../../models/company.dart';
import '../../models/task.dart';
import '../../models/task_template.dart';
import '../../models/user.dart' as app_user;
import '../../providers/document_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/task_template_provider.dart';
import '../../services/branch_service.dart';
import '../../services/company_service.dart';
import '../../services/employee_service.dart';
import 'ai_assistant_tab.dart';
import 'branch_details_page.dart';
import 'company/documents_tab.dart';
import 'company/employees_tab.dart';
import 'company/overview_tab.dart';
import 'company/settings_tab.dart';
import 'company/tasks_tab.dart';
import 'create_employee_simple_dialog.dart';
import 'create_task_dialog.dart';
import 'edit_employee_dialog.dart';
import 'edit_task_dialog.dart';
import 'task_details_dialog.dart';

/// Company Details Page Provider
final companyDetailsProvider =
    FutureProvider.family<Company?, String>((ref, id) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Branches Provider
final companyBranchesProvider =
    FutureProvider.family<List<Branch>, String>((ref, companyId) async {
  final service = BranchService();
  return await service.getAllBranches(companyId: companyId);
});

/// Company Stats Provider
final companyStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
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

  // Employee search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  app_user.UserRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider(widget.companyId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
    return Column(
      children: [
        _buildHeader(company),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(company: company, companyId: widget.companyId),
              EmployeesTab(company: company, companyId: widget.companyId),
              TasksTab(company: company, companyId: widget.companyId),
              DocumentsTab(company: company),
              AIAssistantTab(
                companyId: company.id,
                companyName: company.name,
              ),
              SettingsTab(company: company, companyId: widget.companyId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Company company) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [company.type.color, company.type.color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditDialog(company),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showMoreOptions(company),
                  ),
                ],
              ),
            ),
            // Company Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Logo or Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      company.type.icon,
                      size: 40,
                      color: company.type.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Name
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Business Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      company.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: company.status == 'active'
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: company.status == 'active'
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      company.status == 'active'
                          ? 'Đang hoạt động'
                          : 'Tạm dừng',
                      style: TextStyle(
                        color: company.status == 'active'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(icon: Icon(Icons.people), text: 'Nhân viên'),
          Tab(icon: Icon(Icons.assignment), text: 'Công việc'),
          Tab(icon: Icon(Icons.description), text: 'Tài liệu'),
          Tab(icon: Icon(Icons.smart_toy), text: 'AI Assistant'),
          Tab(text: 'Cài đặt'),
        ],
      ),
    );
  }
}

      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'Thống kê',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _buildStatsCards(stats),
          ),
          const SizedBox(height: 32),
          // Company Information
          const Text(
            'Thông tin công ty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(company),
          const SizedBox(height: 32),
          // Contact Information
          const Text(
            'Thông tin liên hệ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContactCard(company),
          const SizedBox(height: 32),
          // Timeline
          const Text(
            'Thời gian',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimelineCard(company),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                label: 'Nhân viên',
                value: '${stats['employeeCount'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.store,
                label: 'Chi nhánh',
                value: '${stats['branchCount'] ?? 0}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.table_restaurant,
                label: 'Bàn chơi',
                value: '${stats['tableCount'] ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                label: 'Doanh thu/tháng',
                value: _formatCurrency(stats['monthlyRevenue'] ?? 0.0),
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Company company) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.business,
              label: 'Tên công ty',
              value: company.name,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Loại hình',
              value: company.type.label,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Địa chỉ',
              value: company.address.isNotEmpty
                  ? company.address
                  : 'Chưa cập nhật',
            ),
            if (company.phone != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: company.phone!,
              ),
            ],
            if (company.email != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: company.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Company company) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (company.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.phone, color: Colors.green[700]),
                ),
                title: const Text('Gọi điện'),
                subtitle: Text(company.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _launchPhone(company.phone!),
                ),
              ),
            if (company.phone != null && company.email != null)
              const Divider(height: 24),
            if (company.email != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.email, color: Colors.blue[700]),
                ),
                title: const Text('Gửi email'),
                subtitle: Text(company.email!),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _launchEmail(company.email!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Company company) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo',
              value: company.createdAt != null
                  ? dateFormat.format(company.createdAt!)
                  : 'N/A',
            ),
            if (company.updatedAt != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Cập nhật cuối',
                value: dateFormat.format(company.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchesTab(Company company) {
    final branchesAsync = ref.watch(companyBranchesProvider(widget.companyId));

    return branchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Lỗi: $error', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      data: (branches) {
        if (branches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có chi nhánh',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddBranchDialog(company),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm chi nhánh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${branches.length} chi nhánh',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBranchDialog(company),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Branches List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: branches.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return _buildBranchCard(branch);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BranchDetailsPage(
                branchId: branch.id,
                companyId: widget.companyId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Branch Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 16),
              // Branch Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: branch.isActive
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            branch.isActive ? 'Hoạt động' : 'Tạm dừng',
                            style: TextStyle(
                              fontSize: 11,
                              color: branch.isActive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (branch.address != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              branch.address!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (branch.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            branch.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Action Button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BranchDetailsPage(
                        branchId: branch.id,
                        companyId: widget.companyId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeesTab(Company company) {
    // Fetch real employee data from Supabase
    final employeesAsync = ref.watch(companyEmployeesProvider(company.id));
    final statsAsync = ref.watch(companyEmployeesStatsProvider(company.id));

    return Column(
      children: [
        // Header with Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
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
              Row(
                children: [
                  const Text(
                    'Danh sách nhân viên',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateEmployeeDialog(company),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Thêm nhân viên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats Row - using real data
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.people,
                        count: '${stats['total']}',
                        label: 'Tổng NV',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.supervised_user_circle,
                        count: '${stats['manager']}',
                        label: 'Quản lý',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.groups,
                        count: '${stats['shift_leader']}',
                        label: 'Trưởng ca',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.person,
                        count: '${stats['staff']}',
                        label: 'Nhân viên',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Row(
                  children: [
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.people,
                        count: '0',
                        label: 'Tổng NV',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.supervised_user_circle,
                        count: '0',
                        label: 'Quản lý',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.groups,
                        count: '0',
                        label: 'Trưởng ca',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.person,
                        count: '0',
                        label: 'Nhân viên',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên, email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedRoleFilter == null,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter = null);
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.supervised_user_circle,
                              size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Quản lý'),
                        ],
                      ),
                      selected:
                          _selectedRoleFilter == app_user.UserRole.manager,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.manager : null);
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Trưởng ca'),
                        ],
                      ),
                      selected:
                          _selectedRoleFilter == app_user.UserRole.shiftLeader,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.shiftLeader : null);
                      },
                      selectedColor: Colors.orange[100],
                      checkmarkColor: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.purple),
                          SizedBox(width: 4),
                          Text('Nhân viên'),
                        ],
                      ),
                      selected: _selectedRoleFilter == app_user.UserRole.staff,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.staff : null);
                      },
                      selectedColor: Colors.purple[100],
                      checkmarkColor: Colors.purple[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Employee List - using real data
        Expanded(
          child: employeesAsync.when(
            data: (employees) {
              // Apply search and filter
              var filteredEmployees = employees.where((employee) {
                // Search filter
                final matchesSearch = _searchQuery.isEmpty ||
                    employee.name?.toLowerCase().contains(_searchQuery) ==
                        true ||
                    employee.email.toLowerCase().contains(_searchQuery);

                // Role filter
                final matchesRole = _selectedRoleFilter == null ||
                    employee.role == _selectedRoleFilter;

                return matchesSearch && matchesRole;
              }).toList();

              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showCreateEmployeeDialog(company),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nhân viên đầu tiên'),
                      ),
                    ],
                  ),
                );
              }

              if (filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_searchQuery.isNotEmpty ||
                          _selectedRoleFilter != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedRoleFilter = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEmployees.length,
                itemBuilder: (context, index) {
                  return _buildEmployeeCard(filteredEmployees[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu nhân viên',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(companyEmployeesProvider(company.id));
                      ref.invalidate(companyEmployeesStatsProvider(company.id));
                      ref.invalidate(companyStatsProvider(widget.companyId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(app_user.User employee) {
    // Determine color based on role
    Color roleColor;
    String roleLabel;

    switch (employee.role) {
      case app_user.UserRole.manager:
        roleColor = Colors.green;
        roleLabel = 'Quản lý';
        break;
      case app_user.UserRole.shiftLeader:
        roleColor = Colors.orange;
        roleLabel = 'Trưởng ca';
        break;
      case app_user.UserRole.staff:
        roleColor = Colors.purple;
        roleLabel = 'Nhân viên';
        break;
      case app_user.UserRole.ceo:
        roleColor = Colors.blue;
        roleLabel = 'CEO';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.2),
              child: Text(
                (employee.name != null && employee.name!.isNotEmpty)
                    ? employee.name![0].toUpperCase()
                    : employee.email[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name ?? employee.email.split('@').first,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          employee.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          employee.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Action Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    // Edit employee
                    await _showEditEmployeeDialog(employee);
                    break;
                  case 'deactivate':
                    // Deactivate/Activate employee
                    await _toggleEmployeeStatus(employee);
                    break;
                  case 'delete':
                    // Delete employee
                    await _deleteEmployee(employee);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(
                        (employee.isActive ?? true)
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                        color: (employee.isActive ?? true)
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text((employee.isActive ?? true)
                          ? 'Vô hiệu hóa'
                          : 'Kích hoạt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tasks Tab
  Widget _buildTasksTab(Company company) {
    final tasksAsync = ref.watch(companyTasksProvider(widget.companyId));
    final statsAsync = ref.watch(companyTaskStatsProvider(widget.companyId));
    final insightsAsync = ref.watch(documentInsightsProvider(company.id));

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header with stats and AI suggestions
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quản lý công việc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Button to view AI suggestions
                        insightsAsync.when(
                          data: (insights) {
                            final suggestedTasks = insights['tasks'] as List<dynamic>? ?? [];
                            if (suggestedTasks.isEmpty) return const SizedBox.shrink();
                            
                            return Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showAISuggestedTasks(context, company, suggestedTasks),
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: Text('${suggestedTasks.length} đề xuất từ AI'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[700],
                                    side: BorderSide(color: Colors.orange[300]!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _createTemplatesFromAI(context, company, suggestedTasks),
                                  icon: const Icon(Icons.repeat),
                                  label: Text('Tạo Templates (${suggestedTasks.length})'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateTaskDialog(context, company),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo công việc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats cards
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _buildTaskStatCard(
                          icon: Icons.assignment,
                          label: 'Tổng số',
                          value: stats['total']?.toString() ?? '0',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTaskStatCard(
                          icon: Icons.pending_actions,
                          label: 'Cần làm',
                          value: stats['todo']?.toString() ?? '0',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTaskStatCard(
                          icon: Icons.autorenew,
                          label: 'Đang làm',
                          value: stats['inProgress']?.toString() ?? '0',
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTaskStatCard(
                          icon: Icons.check_circle,
                          label: 'Hoàn thành',
                          value: stats['completed']?.toString() ?? '0',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyTasksState(context, company);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải danh sách công việc',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(companyTasksProvider(widget.companyId));
                        ref.invalidate(companyTaskStatsProvider(widget.companyId));
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasksState(BuildContext context, Company company) {
    final insightsAsync = ref.watch(documentInsightsProvider(company.id));
    
    return insightsAsync.when(
      data: (insights) {
        final suggestedTasks = insights['tasks'] as List<dynamic>? ?? [];
        
        if (suggestedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có công việc nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTaskDialog(context, company),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo công việc đầu tiên'),
                ),
              ],
            ),
          );
        }

        // Show AI suggestions when no tasks exist
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    size: 64,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AI đã phân tích tài liệu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chúng tôi tìm thấy ${suggestedTasks.length} công việc được đề xuất từ tài liệu vận hành của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showCreateTaskDialog(context, company),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo thủ công'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAISuggestedTasks(context, company, suggestedTasks),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Xem đề xuất từ AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có công việc nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // Open task details dialog
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => TaskDetailsDialog(
              task: task,
            ),
          );
          
          // Refresh if data changed
          if (result == true && mounted) {
            ref.invalidate(companyTasksProvider(widget.companyId));
            ref.invalidate(companyTaskStatsProvider(widget.companyId));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.priority.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: task.priority.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.priority.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: task.priority.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: task.status.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: task.status.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Menu button
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // Edit task
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => EditTaskDialog(
                            task: task,
                          ),
                        );
                        
                        // Refresh if edited
                        if (result == true && mounted) {
                          ref.invalidate(companyTasksProvider(widget.companyId));
                          ref.invalidate(companyTaskStatsProvider(widget.companyId));
                        }
                      } else if (value == 'delete') {
                        // Delete task with confirmation
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true && mounted) {
                          try {
                            await ref.read(taskServiceProvider).deleteTask(task.id);
                            
                            if (mounted) {
                              ref.invalidate(companyTasksProvider(widget.companyId));
                              ref.invalidate(companyTaskStatsProvider(widget.companyId));
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa công việc thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi khi xóa công việc: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Task title
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Task metadata
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hạn: ${dateFormat.format(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (task.assignedToName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedToName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildDocumentsTab(Company company) {
    final documentsAsync = ref.watch(companyDocumentsProvider(company.id));
    final insightsAsync = ref.watch(documentInsightsProvider(company.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài liệu vận hành',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hệ thống tài liệu và phân tích tự động từ AI',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // AI Insights Section
          insightsAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (insights) => _buildInsightsSection(insights),
          ),
          
          const SizedBox(height: 32),

          // Documents List
          const Text(
            'Danh sách tài liệu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          documentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $error'),
              ),
            ),
            data: (documents) {
              if (documents.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có tài liệu nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: documents.map((doc) => _buildDocumentCard(doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Phân tích tự động từ AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Org Chart
            if (insights['org_chart'] != null) ...[
              _buildOrgChartSummary(insights['org_chart']),
              const Divider(height: 32),
            ],
            
            // Tasks Summary
            if (insights['suggested_tasks'] != null) ...[
              _buildTasksSummary(insights['suggested_tasks']),
              const Divider(height: 32),
            ],
            
            // KPIs Summary
            if (insights['kpis'] != null) ...[
              _buildKPIsSummary(insights['kpis']),
              const Divider(height: 32),
            ],
            
            // Programs Summary
            if (insights['programs'] != null) ...[
              _buildProgramsSummary(insights['programs']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrgChartSummary(Map<String, dynamic> orgChart) {
    final positions = orgChart['positions'] as List? ?? [];
    final totalNeeded = orgChart['total_needed'] ?? 0;
    final totalCurrent = orgChart['total_current'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_tree, size: 20),
            const SizedBox(width: 8),
            const Text('Sơ đồ tổ chức', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('$totalCurrent/$totalNeeded vị trí'),
              backgroundColor: Colors.blue[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...positions.take(5).map((pos) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                pos['status'] == 'filled' ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: pos['status'] == 'filled' ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(pos['title'] ?? '')),
              if (pos['count'] != null) Text('x${pos['count']}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTasksSummary(List<dynamic> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_box, size: 20),
            const SizedBox(width: 8),
            const Text('Công việc gợi ý', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${tasks.length} tasks'),
              backgroundColor: Colors.green[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tasks.take(5).map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: _getPriorityColor(task['priority'])),
              const SizedBox(width: 12),
              Expanded(child: Text(task['title'] ?? '')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['category'] ?? '',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildKPIsSummary(List<dynamic> kpis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, size: 20),
            const SizedBox(width: 8),
            const Text('KPI đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${kpis.length} chỉ tiêu'),
              backgroundColor: Colors.purple[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...kpis.take(5).map((kpi) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(kpi['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text('${kpi['weight']}%', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (kpi['weight'] ?? 0) / 100,
                backgroundColor: Colors.grey[200],
                color: Colors.purple,
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildProgramsSummary(List<dynamic> programs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 20),
            const SizedBox(width: 8),
            const Text('Chương trình & Sự kiện', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${programs.length} chương trình'),
              backgroundColor: Colors.orange[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...programs.map((program) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getProgramColor(program['type']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  program['code'] ?? '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (program['description'] != null)
                      Text(
                        program['description'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(program['status']),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildDocumentCard(AIUploadedFile doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(Icons.description, color: Colors.blue[700]),
        ),
        title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${(doc.fileSize / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 4),
            Text(
              'Tạo: ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _buildDocStatusBadge(doc.status),
        onTap: () {
          // Show document detail dialog
          _showDocumentDetail(doc);
        },
      ),
    );
  }

  Widget _buildDocStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'analyzed':
        color = Colors.green;
        label = 'Đã phân tích';
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Đang xử lý';
        break;
      case 'error':
        color = Colors.red;
        label = 'Lỗi';
        break;
      default:
        color = Colors.blue;
        label = 'Đã tải lên';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Đang áp dụng';
        break;
      case 'planned':
        color = Colors.blue;
        label = 'Kế hoạch';
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Hoàn thành';
        break;
      default:
        color = Colors.orange;
        label = 'Chưa rõ';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getProgramColor(String? type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'membership':
        return Colors.purple;
      case 'event':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showDocumentDetail(AIUploadedFile doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc.fileName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    doc.extractedText ?? 'Không có nội dung',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show AI Suggested Tasks Dialog
  void _showAISuggestedTasks(BuildContext context, Company company, List<dynamic> suggestedTasks) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_awesome, color: Colors.orange[700]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đề xuất công việc từ AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${suggestedTasks.length} công việc được phân tích từ tài liệu vận hành',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suggestedTasks.length,
                  itemBuilder: (context, index) {
                    final task = suggestedTasks[index] as Map<String, dynamic>;
                    return _buildSuggestedTaskCard(context, company, task);
                  },
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _createAllSuggestedTasks(context, company, suggestedTasks);
                      },
                      icon: const Icon(Icons.add_task),
                      label: Text('Tạo tất cả (${suggestedTasks.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedTaskCard(BuildContext context, Company company, Map<String, dynamic> task) {
    final priority = task['priority'] as String? ?? 'medium';
    final category = task['category'] as String? ?? 'Khác';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: _getPriorityColor(priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildCategoryBadge(category),
                      const SizedBox(width: 8),
                      _buildPriorityBadge(priority),
                    ],
                  ),
                  if (task['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      task['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task['assignee'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Đề xuất: ${task['assignee']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Action button
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await _createTaskFromSuggestion(context, company, task);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tạo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    IconData icon;
    
    switch (category.toLowerCase()) {
      case 'checklist':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'sop':
        color = Colors.blue;
        icon = Icons.description_outlined;
        break;
      case 'kpi':
        color = Colors.purple;
        icon = Icons.analytics_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.category_outlined;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = _getPriorityColor(priority);
    String label;
    
    switch (priority.toLowerCase()) {
      case 'high':
        label = 'Cao';
        break;
      case 'medium':
        label = 'Trung bình';
        break;
      case 'low':
        label = 'Thấp';
        break;
      default:
        label = priority;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Create single task from AI suggestion
  Future<void> _createTaskFromSuggestion(
    BuildContext context,
    Company company,
    Map<String, dynamic> suggestion,
  ) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập');
      }
      
      // Get first branch or use company ID as branch
      final branchService = BranchService();
      final branches = await branchService.getAllBranches(companyId: company.id);
      final branchId = branches.isNotEmpty ? branches.first.id : company.id;
      
      final task = Task(
        id: '', // Will be generated by database
        branchId: branchId,
        title: suggestion['title'] as String,
        description: suggestion['description'] as String? ?? '',
        category: TaskCategory.operations, // Default category
        priority: _parsePriority(suggestion['priority'] as String? ?? 'medium'),
        status: TaskStatus.todo,
        dueDate: DateTime.now().add(const Duration(days: 7)), // Due in 1 week
        createdBy: currentUser.id,
        createdByName: currentUser.email ?? '',
        createdAt: DateTime.now(),
      );
      
      await taskService.createTask(task);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo công việc: ${suggestion['title']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh tasks
      ref.invalidate(companyTasksProvider(widget.companyId));
      ref.invalidate(companyTaskStatsProvider(widget.companyId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo công việc: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create task templates from AI suggestions (recurring tasks)
  Future<void> _createTemplatesFromAI(
    BuildContext context,
    Company company,
    List<dynamic> suggestions,
  ) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      // Get first branch
      final branchService = BranchService();
      final branches = await branchService.getAllBranches(companyId: company.id);
      final branchId = branches.isNotEmpty ? branches.first.id : company.id;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.repeat, color: Colors.green),
              SizedBox(width: 12),
              Text('Tạo Task Templates?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo templates cho công việc lặp lại định kỳ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...suggestions.take(5).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s['title'] as String)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔄 Templates sẽ tự động tạo tasks:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Hằng ngày/tuần/tháng', style: TextStyle(fontSize: 13)),
                    Text('• Phân công đúng nhân viên', style: TextStyle(fontSize: 13)),
                    Text('• Không bỏ sót công việc', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: Text('Tạo ${suggestions.length} Templates'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Đang tạo templates...'),
            ],
          ),
          duration: Duration(seconds: 60),
        ),
      );

      final templateService = ref.read(taskTemplateServiceProvider);
      int successCount = 0;

      for (final suggestion in suggestions) {
        try {
          await templateService.createFromAISuggestion(
            companyId: company.id,
            branchId: branchId,
            suggestion: suggestion as Map<String, dynamic>,
            createdBy: currentUser.id,
          );
          successCount++;
        } catch (e) {
          print('Failed to create template: $e');
          continue;
        }
      }

      // Refresh providers
      ref.invalidate(companyTaskTemplatesProvider(company.id));
      ref.invalidate(activeTaskTemplatesProvider(company.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo $successCount/${suggestions.length} templates thành công!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Xem',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to templates page
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo templates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  TaskPriority _parsePriority(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  // Create all suggested tasks at once
  Future<void> _createAllSuggestedTasks(
    BuildContext context,
    Company company,
    List<dynamic> suggestions,
  ) async {
    final taskService = ref.read(taskServiceProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }
    
    // Get first branch
    final branchService = BranchService();
    final branches = await branchService.getAllBranches(companyId: company.id);
    final branchId = branches.isNotEmpty ? branches.first.id : company.id;
    
    int successCount = 0;
    
    for (final suggestion in suggestions) {
      try {
        final taskData = suggestion as Map<String, dynamic>;
        final task = Task(
          id: '',
          branchId: branchId,
          title: taskData['title'] as String,
          description: taskData['description'] as String? ?? '',
          category: TaskCategory.operations,
          priority: _parsePriority(taskData['priority'] as String? ?? 'medium'),
          status: TaskStatus.todo,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          createdBy: currentUser.id,
          createdByName: currentUser.email ?? '',
          createdAt: DateTime.now(),
        );
        
        await taskService.createTask(task);
        successCount++;
      } catch (e) {
        // Continue with other tasks even if one fails
        continue;
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo $successCount/${suggestions.length} công việc từ AI'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Refresh tasks
    ref.invalidate(companyTasksProvider(widget.companyId));
    ref.invalidate(companyTaskStatsProvider(widget.companyId));
  }

  // Show create task dialog (manual)
  Future<void> _showCreateTaskDialog(BuildContext context, Company company) async {
    // Get primary branch for this company
    final branchService = BranchService();
    final branches = await branchService.getAllBranches(companyId: company.id);
    
    // Show create task dialog with companyId and optional branchId
    if (context.mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CreateTaskDialog(
          companyId: company.id,
          branchId: branches.isNotEmpty ? branches.first.id : null,
        ),
      );
      
      // Refresh if task created
      if (result == true) {
        ref.invalidate(companyTasksProvider(widget.companyId));
        ref.invalidate(companyTaskStatsProvider(widget.companyId));
      }
    }
  }

  Widget _buildSettingsTab(Company company) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt công ty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Employee Management Section
          _buildSettingSection(
            title: 'Quản lý nhân viên',
            items: [
              _SettingItem(
                icon: Icons.person_add,
                title: 'Tạo tài khoản nhân viên',
                subtitle: 'Tạo tài khoản cho quản lý, trưởng ca, nhân viên',
                onTap: () => _showCreateEmployeeDialog(company),
                color: Colors.blue,
              ),
              _SettingItem(
                icon: Icons.people,
                title: 'Danh sách nhân viên',
                subtitle: 'Xem và quản lý tài khoản nhân viên',
                onTap: () => _showEmployeeListDialog(company),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingSection(
            title: 'Thông tin chung',
            items: [
              _SettingItem(
                icon: Icons.edit,
                title: 'Chỉnh sửa thông tin',
                subtitle: 'Cập nhật tên, địa chỉ, liên hệ',
                onTap: () => _showEditDialog(company),
              ),
              _SettingItem(
                icon: Icons.category,
                title: 'Thay đổi loại hình',
                subtitle: 'Chọn loại hình kinh doanh',
                onTap: () => _showChangeBusinessTypeDialog(company),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Trạng thái',
            items: [
              _SettingItem(
                icon: company.status == 'active'
                    ? Icons.pause_circle
                    : Icons.play_circle,
                title: company.status == 'active'
                    ? 'Tạm dừng hoạt động'
                    : 'Kích hoạt lại',
                subtitle: company.status == 'active'
                    ? 'Tạm dừng hoạt động công ty'
                    : 'Tiếp tục hoạt động',
                onTap: () => _toggleCompanyStatus(company),
                color:
                    company.status == 'active' ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Nguy hiểm',
            items: [
              _SettingItem(
                icon: Icons.delete_forever,
                title: 'Xóa công ty',
                subtitle: 'Xóa vĩnh viễn công ty và toàn bộ dữ liệu',
                onTap: () => _showDeleteDialog(company),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey[200]),
                _buildSettingItem(items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(_SettingItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (item.color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: item.color ?? Colors.blue[700],
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: item.color,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: TextStyle(fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: item.onTap,
    );
  }

  // Dialog Methods
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
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật công ty thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showChangeBusinessTypeDialog(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi loại hình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BusinessType.values.map((type) {
            return RadioListTile<BusinessType>(
              value: type,
              groupValue: company.type,
              title: Text(type.label),
              onChanged: (value) async {
                if (value != null) {
                  await _updateBusinessType(company, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog(Company company) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm chi nhánh mới'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên chi nhánh *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên chi nhánh';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                  ),
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
                  final branchService = BranchService();
                  await branchService.createBranch(
                    companyId: company.id,
                    name: nameController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  );

                  ref.invalidate(companyBranchesProvider(widget.companyId));
                  ref.invalidate(companyStatsProvider(widget.companyId));
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm chi nhánh thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Thêm'),
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

  void _showDeleteDialog(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa công ty "${company.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCompany(company);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _updateBusinessType(
      Company company, BusinessType newType) async {
    try {
      final service = ref.read(companyServiceProvider);
      await service.updateCompany(company.id, {
        'business_type': newType.toString().split('.').last,
      });
      ref.invalidate(companyDetailsProvider(widget.companyId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật loại hình')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _toggleCompanyStatus(Company company) async {
    final newStatus = company.status == 'active' ? 'inactive' : 'active';
    try {
      final service = ref.read(companyServiceProvider);
      await service.updateCompany(company.id, {
        'is_active': newStatus == 'active',
      });
      ref.invalidate(companyDetailsProvider(widget.companyId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'active'
              ? 'Đã kích hoạt công ty'
              : 'Đã tạm dừng công ty'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteCompany(Company company) async {
    try {
      final service = ref.read(companyServiceProvider);
      await service.deleteCompany(company.id);
      Navigator.of(context).pop(); // Return to companies list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa công ty')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  // Employee Management Methods
  Future<void> _showCreateEmployeeDialog(Company company) async {
    await showDialog(
      context: context,
      builder: (context) => CreateEmployeeSimpleDialog(
        company: company,
      ),
    );

    // Refresh already handled in dialog
  }

  Future<void> _showEmployeeListDialog(Company company) async {
    // TODO: Implement employee list dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đang được phát triển'),
      ),
    );
  }

  // Employee Management Actions
  Future<void> _showEditEmployeeDialog(app_user.User employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditEmployeeDialog(
        employee: employee,
        companyId: widget.companyId,
      ),
    );

    if (result == true && mounted) {
      // Refresh employee list and company stats
      ref.invalidate(companyEmployeesProvider(widget.companyId));
      ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
      ref.invalidate(companyStatsProvider(widget.companyId));
    }
  }

  Future<void> _toggleEmployeeStatus(app_user.User employee) async {
    final newStatus = !(employee.isActive ?? true);
    final action = newStatus ? 'kích hoạt' : 'vô hiệu hóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text(
          'Bạn có chắc muốn $action tài khoản của ${employee.name ?? employee.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(newStatus ? 'Kích hoạt' : 'Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = EmployeeService();
        await service.toggleEmployeeStatus(employee.id, newStatus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã $action tài khoản ${employee.name ?? employee.email}',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh employee list and company stats
          ref.invalidate(companyEmployeesProvider(widget.companyId));
          ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
          ref.invalidate(companyStatsProvider(widget.companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteEmployee(app_user.User employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xóa tài khoản của ${employee.name ?? employee.email}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = EmployeeService();
        await service.deleteEmployee(employee.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã xóa tài khoản ${employee.name ?? employee.email}',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh employee list and company stats
          ref.invalidate(companyEmployeesProvider(widget.companyId));
          ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
          ref.invalidate(companyStatsProvider(widget.companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper methods for contact actions
  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gọi $phoneNumber')),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi email tới $email')),
      );
    }
  }
}

// Helper class for setting items
class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });
}
