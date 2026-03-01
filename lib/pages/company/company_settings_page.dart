import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cached_data_providers.dart';
import '../ceo/company/settings_tab.dart';

/// Company Settings Page
/// Cài đặt công ty với các tính năng quản lý nhân viên
class CompanySettingsPage extends ConsumerWidget {
  const CompanySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.read(authProvider).user;
    final companyId = authUser?.companyId;
    final companyAsync = companyId != null 
        ? ref.watch(cachedCompanyProvider(companyId)) 
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Cài đặt công ty',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Account Settings (from SettingsTab)
            if (companyId != null && companyAsync != null)
              companyAsync.when(
                data: (company) => company != null
                    ? SettingsTab(company: company, companyId: companyId)
                    : const SizedBox.shrink(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            const SizedBox(height: 32),
            _buildSectionTitle('Quản lý nhân viên'),
            const SizedBox(height: 16),
            _buildEmployeeManagementCard(context),
            const SizedBox(height: 32),
            _buildSectionTitle('Cài đặt chung'),
            const SizedBox(height: 16),
            _buildGeneralSettingsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEmployeeManagementCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildEmployeeOption(
            context,
            icon: Icons.person_add,
            iconColor: Colors.blue,
            title: 'Tạo tài khoản nhân viên',
            subtitle: 'Tạo tài khoản trực tiếp cho nhân viên',
            onTap: () => _navigateToCreateEmployee(context),
          ),
          const Divider(height: 1),
          _buildEmployeeOption(
            context,
            icon: Icons.link,
            iconColor: Colors.green,
            title: 'Tạo link mời nhân viên',
            subtitle: 'Gửi link để nhân viên tự đăng ký',
            onTap: () => _navigateToCreateInvitation(context),
          ),
          const Divider(height: 1),
          _buildEmployeeOption(
            context,
            icon: Icons.people,
            iconColor: Colors.orange,
            title: 'Danh sách nhân viên',
            subtitle: 'Xem và quản lý tài khoản nhân viên',
            onTap: () => _navigateToEmployeeList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildEmployeeOption(
            context,
            icon: Icons.business,
            iconColor: Colors.green,
            title: 'Thông tin công ty',
            subtitle: 'Cập nhật thông tin công ty',
            onTap: () => _navigateToCompanyInfo(context),
          ),
          const Divider(height: 1),
          _buildEmployeeOption(
            context,
            icon: Icons.settings,
            iconColor: Colors.purple,
            title: 'Cài đặt hệ thống',
            subtitle: 'Cấu hình hệ thống và bảo mật',
            onTap: () => _navigateToSystemSettings(context),
          ),
          const Divider(height: 1),
          _buildEmployeeOption(
            context,
            icon: Icons.help_outline,
            iconColor: Colors.teal,
            title: 'Hỗ trợ',
            subtitle: 'Liên hệ hỗ trợ kỹ thuật',
            onTap: () => _navigateToSupport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _navigateToCreateEmployee(BuildContext context) {
    context.push(AppRoutes.createEmployee);
  }

  void _navigateToCreateInvitation(BuildContext context) {
    context.push(AppRoutes.createInvitation);
  }

  void _navigateToEmployeeList(BuildContext context) {
    context.push(AppRoutes.employeeList);
  }

  void _navigateToCompanyInfo(BuildContext context) {
    // Navigate to employee list as company info overview
    context.push(AppRoutes.employeeList);
  }

  void _navigateToSystemSettings(BuildContext context) {
    // Show a dialog with available settings
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cài đặt hệ thống'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Quản lý nhân viên'),
              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.employeeList); },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Tạo nhân viên mới'),
              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.createEmployee); },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _navigateToSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hỗ trợ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: support@sabohub.com'),
            SizedBox(height: 8),
            Text('📞 Hotline: 0123 456 789'),
            SizedBox(height: 8),
            Text('🕒 Giờ hỗ trợ: 8:00 - 17:00 (T2-T6)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
