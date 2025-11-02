import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/branch.dart';
import '../../services/branch_service.dart';

/// Branch Details Provider
final branchDetailsProvider =
    FutureProvider.family<Branch?, String>((ref, id) async {
  final service = BranchService();
  return await service.getBranchById(id);
});

/// Branch Stats Provider
final branchStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, branchId) async {
  final service = BranchService();
  return await service.getBranchStats(branchId);
});

/// Branch Details Page
/// Displays comprehensive information about a single branch
class BranchDetailsPage extends ConsumerStatefulWidget {
  final String branchId;
  final String companyId;

  const BranchDetailsPage({
    super.key,
    required this.branchId,
    required this.companyId,
  });

  @override
  ConsumerState<BranchDetailsPage> createState() => _BranchDetailsPageState();
}

class _BranchDetailsPageState extends ConsumerState<BranchDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchAsync = ref.watch(branchDetailsProvider(widget.branchId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: branchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải thông tin chi nhánh',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.refresh(branchDetailsProvider(widget.branchId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (branch) {
          if (branch == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy chi nhánh',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }
          return _buildContent(branch);
        },
      ),
    );
  }

  Widget _buildContent(Branch branch) {
    return Column(
      children: [
        _buildHeader(branch),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(branch),
              _buildSettingsTab(branch),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Branch branch) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            branch.isActive ? Colors.blue[700]! : Colors.grey[700]!,
            branch.isActive
                ? Colors.blue[500]!.withOpacity(0.7)
                : Colors.grey[500]!.withOpacity(0.7),
          ],
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
                    onPressed: () => _showEditDialog(branch),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showMoreOptions(branch),
                  ),
                ],
              ),
            ),
            // Branch Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Icon
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
                      Icons.store,
                      size: 40,
                      color: branch.isActive ? Colors.blue[700] : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Branch Name
                  Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: branch.isActive
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: branch.isActive ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      branch.isActive ? 'Đang hoạt động' : 'Tạm dừng',
                      style: TextStyle(
                        color: branch.isActive ? Colors.green : Colors.red,
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
          Tab(text: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Branch branch) {
    final statsAsync = ref.watch(branchStatsProvider(widget.branchId));

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
          // Branch Information
          const Text(
            'Thông tin chi nhánh',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(branch),
          const SizedBox(height: 32),
          // Contact Information
          if (branch.phone != null || branch.email != null) ...[
            const Text(
              'Thông tin liên hệ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactCard(branch),
            const SizedBox(height: 32),
          ],
          // Timeline
          const Text(
            'Thời gian',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimelineCard(branch),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Row(
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

  Widget _buildInfoCard(Branch branch) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.store,
              label: 'Tên chi nhánh',
              value: branch.name,
            ),
            if (branch.address != null && branch.address!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Địa chỉ',
                value: branch.address!,
              ),
            ],
            if (branch.phone != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: branch.phone!,
              ),
            ],
            if (branch.email != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: branch.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Branch branch) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (branch.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.phone, color: Colors.green[700]),
                ),
                title: const Text('Gọi điện'),
                subtitle: Text(branch.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _launchPhone(branch.phone!),
                ),
              ),
            if (branch.phone != null && branch.email != null)
              const Divider(height: 24),
            if (branch.email != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.email, color: Colors.blue[700]),
                ),
                title: const Text('Gửi email'),
                subtitle: Text(branch.email!),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _launchEmail(branch.email!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Branch branch) {
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
              value: branch.createdAt != null
                  ? dateFormat.format(branch.createdAt!)
                  : 'N/A',
            ),
            if (branch.updatedAt != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Cập nhật cuối',
                value: dateFormat.format(branch.updatedAt!),
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

  Widget _buildSettingsTab(Branch branch) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt chi nhánh',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: 'Thông tin chung',
            items: [
              _SettingItem(
                icon: Icons.edit,
                title: 'Chỉnh sửa thông tin',
                subtitle: 'Cập nhật tên, địa chỉ, liên hệ',
                onTap: () => _showEditDialog(branch),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Trạng thái',
            items: [
              _SettingItem(
                icon: branch.isActive ? Icons.pause_circle : Icons.play_circle,
                title: branch.isActive ? 'Tạm dừng hoạt động' : 'Kích hoạt lại',
                subtitle: branch.isActive
                    ? 'Tạm dừng hoạt động chi nhánh'
                    : 'Tiếp tục hoạt động',
                onTap: () => _toggleBranchStatus(branch),
                color: branch.isActive ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Nguy hiểm',
            items: [
              _SettingItem(
                icon: Icons.delete_forever,
                title: 'Xóa chi nhánh',
                subtitle: 'Xóa vĩnh viễn chi nhánh và toàn bộ dữ liệu',
                onTap: () => _showDeleteDialog(branch),
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
          ? Text(item.subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: item.onTap,
    );
  }

  // Dialog Methods
  void _showEditDialog(Branch branch) {
    final nameController = TextEditingController(text: branch.name);
    final addressController = TextEditingController(text: branch.address ?? '');
    final phoneController = TextEditingController(text: branch.phone ?? '');
    final emailController = TextEditingController(text: branch.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa chi nhánh'),
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
                  await branchService.updateBranch(branch.id, {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  });

                  ref.invalidate(branchDetailsProvider(widget.branchId));
                  ref.invalidate(branchStatsProvider(widget.branchId));
                  Navigator.pop(context);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật chi nhánh thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
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

  void _showMoreOptions(Branch branch) {
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
                  const SnackBar(content: Text('Chia sẻ chi nhánh')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Làm mới'),
              onTap: () {
                Navigator.pop(context);
                ref.invalidate(branchDetailsProvider(widget.branchId));
                ref.invalidate(branchStatsProvider(widget.branchId));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Branch branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa chi nhánh "${branch.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBranch(branch);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _toggleBranchStatus(Branch branch) async {
    final newStatus = !branch.isActive;
    try {
      final branchService = BranchService();
      await branchService.updateBranch(branch.id, {
        'is_active': newStatus,
      });
      ref.invalidate(branchDetailsProvider(widget.branchId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newStatus ? 'Đã kích hoạt chi nhánh' : 'Đã tạm dừng chi nhánh'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteBranch(Branch branch) async {
    try {
      final branchService = BranchService();
      await branchService.deleteBranch(branch.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // Return to company details
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa chi nhánh')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
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
