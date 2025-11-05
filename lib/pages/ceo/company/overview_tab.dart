import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/company.dart';
import '../../../providers/cached_data_providers.dart';
import 'widgets/stat_card.dart';

/// Overview Tab - Hiển thị thông tin tổng quan về công ty
class OverviewTab extends ConsumerWidget {
  final Company company;
  final String companyId;

  const OverviewTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedCompanyStatsProvider(companyId));

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
          _buildContactCard(context, company),
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
              child: StatCard(
                icon: Icons.people,
                label: 'Nhân viên',
                value: '${stats['employeeCount'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
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
              child: StatCard(
                icon: Icons.table_restaurant,
                label: 'Bàn chơi',
                value: '${stats['tableCount'] ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
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

  Widget _buildContactCard(BuildContext context, Company company) {
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
                  onPressed: () => _launchPhone(context, company.phone!),
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
                  onPressed: () => _launchEmail(context, company.email!),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gọi $phoneNumber')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi email tới $email')),
      );
    }
  }
}
