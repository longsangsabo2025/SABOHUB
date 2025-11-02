import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/branch.dart';
import '../../models/business_type.dart';
import '../../models/company.dart';
import '../../services/branch_service.dart';
import '../../services/company_service.dart';
import 'ai_assistant_tab.dart';
import 'branch_details_page.dart';
import 'create_employee_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
              _buildOverviewTab(company),
              _buildBranchesTab(company),
              AIAssistantTab(
                companyId: company.id,
                companyName: company.name,
              ),
              _buildSettingsTab(company),
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
          Tab(text: 'Chi nhánh'),
          Tab(icon: Icon(Icons.smart_toy), text: 'AI Assistant'),
          Tab(text: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Company company) {
    final statsAsync = ref.watch(companyStatsProvider(widget.companyId));

    return SingleChildScrollView(
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateEmployeeDialog(
        companyId: company.id,
        companyName: company.name,
      ),
    );

    if (result == true && mounted) {
      // Refresh company data to update employee count
      ref.invalidate(companyDetailsProvider(widget.companyId));
      ref.invalidate(companyStatsProvider(widget.companyId));
    }
  }

  Future<void> _showEmployeeListDialog(Company company) async {
    // TODO: Implement employee list dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đang được phát triển'),
      ),
    );
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
