import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../widgets/bug_report_dialog.dart';
import '../../../../pages/staff/staff_profile_page.dart';

// ============================================================================
// PROFILE PAGE - Modern UI
// ============================================================================
class FinanceProfilePage extends ConsumerWidget {
  const FinanceProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade600]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Người dùng',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_getRoleLabel(user?.role.name),
                                style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats cards
              Row(
                children: [
                  _buildInfoCard(Icons.business, 'Công ty', user?.companyName ?? 'N/A', Colors.green),
                  const SizedBox(width: 12),
                  _buildInfoCard(Icons.phone, 'Điện thoại', user?.phone ?? 'N/A', Colors.orange),
                ],
              ),

              const SizedBox(height: 24),

              // Menu items
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      Icons.person_outline,
                      'Thông tin cá nhân',
                      'Xem và chỉnh sửa hồ sơ',
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StaffProfilePage()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      Icons.settings_outlined,
                      'Cài đặt',
                      'Tùy chỉnh ứng dụng',
                      Colors.grey,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển')),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      Icons.bug_report_outlined,
                      'Báo lỗi',
                      'Gửi phản hồi về ứng dụng',
                      Colors.orange,
                      () {
                        showDialog(
                          context: context,
                          builder: (context) => const BugReportDialog(),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      Icons.logout,
                      'Đăng xuất',
                      'Thoát khỏi tài khoản',
                      Colors.red,
                      () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: const Text('Xác nhận đăng xuất'),
                            content:
                                const Text('Bạn có chắc muốn đăng xuất không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Hủy',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Đăng xuất',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App version
              Text('Phiên bản 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'Quản trị viên';
      case 'distribution_manager':
        return 'Quản lý phân phối';
      case 'warehouse_staff':
        return 'Nhân viên kho';
      case 'driver':
        return 'Tài xế';
      case 'production_staff':
        return 'Nhân viên sản xuất';
      case 'finance':
        return 'Thu ngân';
      default:
        return 'Nhân viên';
    }
  }

  Widget _buildInfoCard(IconData icon, String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      String subtitle, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.shade600, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 68, color: Colors.grey.shade200);
  }
}
