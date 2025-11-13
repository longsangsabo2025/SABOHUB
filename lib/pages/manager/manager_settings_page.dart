import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/multi_account_switcher.dart';

/// Manager Settings Page
/// Settings and preferences for managers
class ManagerSettingsPage extends ConsumerStatefulWidget {
  const ManagerSettingsPage({super.key});

  @override
  ConsumerState<ManagerSettingsPage> createState() =>
      _ManagerSettingsPageState();
}

class _ManagerSettingsPageState extends ConsumerState<ManagerSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoScheduling = false;
  bool _overtimeAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildOperationsSection(),
            const SizedBox(height: 24),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildSystemSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Cài đặt',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        // Multi-Account Switcher
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❓ Trợ giúp đang được phát triển'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
          },
          icon: const Icon(Icons.help_outline, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    final authState = ref.watch(authProvider);
    // TODO: Replace with proper provider after Riverpod 3.x migration
    // final teamAsync = ref.watch(cachedManagerTeamMembersProvider(null));

    if (authState.isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Chưa đăng nhập')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF10B981),
                child: Text(
                  (user.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quản lý',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.id.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã đăng xuất'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // TODO: Restore team stats after Riverpod 3.x migration
          Row(
            children: [
              Expanded(
                child: _buildProfileStat('Nhân viên', '0'),
              ),
              Expanded(
                child: _buildProfileStat(
                    'Email', (user.email ?? 'unknown').split('@')[0]),
              ),
              Expanded(
                child: _buildProfileStat('Vai trò', 'Manager'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsSection() {
    // TODO: Replace with proper provider after Riverpod 3.x migration
    // final staffAsync = ref.watch(cachedStaffStatsProvider(null));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Vận hành',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // TODO: Restore staff stats after Riverpod 3.x migration
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '0 NV',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSettingItem(
            'Quản lý ca làm việc',
            'Lập lịch và điều phối ca',
            Icons.schedule,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📅 Quản lý ca đang phát triển'),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
          ),
          _buildSettingItem(
            'Quản lý nhân viên',
            'Thêm, sửa thông tin nhân viên',
            Icons.people,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('👥 Vào tab Staff để quản lý'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
          _buildSettingItem(
            'Báo cáo hiệu suất',
            'Xem và xuất báo cáo',
            Icons.analytics,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📊 Vào tab Analytics để xem'),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
          ),
          _buildSettingItem(
            'Quản lý kho',
            'Kiểm tra và cập nhật kho',
            Icons.inventory,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📦 Quản lý kho đang phát triển'),
                  backgroundColor: Color(0xFFFBBF24),
                ),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Thông báo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSwitchItem(
            'Thông báo chung',
            'Nhận thông báo về hoạt động chung',
            Icons.notifications,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSwitchItem(
            'Cảnh báo làm thêm giờ',
            'Thông báo khi nhân viên làm quá giờ',
            Icons.access_time,
            _overtimeAlerts,
            (value) => setState(() => _overtimeAlerts = value),
          ),
          _buildSwitchItem(
            'Tự động lập lịch',
            'Tự động sắp xếp ca làm việc',
            Icons.auto_awesome,
            _autoScheduling,
            (value) => setState(() => _autoScheduling = value),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Hệ thống',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingItem(
            'Sao lưu dữ liệu',
            'Sao lưu dữ liệu ca làm và nhân viên',
            Icons.backup,
            () {},
          ),
          _buildSettingItem(
            'Cài đặt bảo mật',
            'Quản lý mật khẩu và bảo mật',
            Icons.security,
            () {},
          ),
          _buildSettingItem(
            'Hỗ trợ',
            'Liên hệ hỗ trợ kỹ thuật',
            Icons.help_center,
            () {},
          ),
          _buildSettingItem(
            'Về ứng dụng',
            'Thông tin phiên bản và điều khoản',
            Icons.info,
            () {},
          ),
          _buildSettingItem(
            'Đăng xuất',
            'Thoát khỏi tài khoản hiện tại',
            Icons.logout,
            () {
              _showLogoutDialog();
            },
            isLast: true,
            textColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isLast = false,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (textColor ?? const Color(0xFF10B981))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: textColor ?? const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
