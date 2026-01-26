import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../constants/roles.dart';
import '../../models/user.dart' as app_user;

/// Staff Profile Page
/// Personal settings and profile management for staff
class StaffProfilePage extends ConsumerStatefulWidget {
  const StaffProfilePage({super.key});

  @override
  ConsumerState<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends ConsumerState<StaffProfilePage> {
  bool _notificationsEnabled = true;
  bool _locationSharing = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildWorkInfoSection(user),
            const SizedBox(height: 24),
            _buildSettingsSection(user),
            const SizedBox(height: 24),
            _buildSupportSection(),
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
        'Hồ sơ cá nhân',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✏️ Chỉnh sửa hồ sơ'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.settings, color: Color(0xFF8B5CF6)),
                      title: const Text('Cài đặt tài khoản'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚙️ Cài đặt tài khoản')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Color(0xFF3B82F6)),
                      title: const Text('Đổi mật khẩu'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔐 Đổi mật khẩu')),
                        );
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      title: const Text('Đăng xuất'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('👋 Đăng xuất')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_vert, color: Colors.black54),
        ),
      ],
    );
  }

  String _getRoleLabel(SaboRole role) {
    switch (role) {
      case SaboRole.superAdmin:
        return 'Super Admin';
      case SaboRole.ceo:
        return 'Giám đốc điều hành';
      case SaboRole.manager:
        return 'Quản lý';
      case SaboRole.shiftLeader:
        return 'Trưởng ca';
      case SaboRole.staff:
        return 'Nhân viên';
      case SaboRole.driver:
        return 'Tài xế giao hàng';
      case SaboRole.warehouse:
        return 'Nhân viên kho';
    }
  }

  Color _getRoleColor(SaboRole role) {
    switch (role) {
      case SaboRole.superAdmin:
        return const Color(0xFFEF4444);
      case SaboRole.ceo:
        return const Color(0xFF8B5CF6);
      case SaboRole.manager:
        return const Color(0xFF3B82F6);
      case SaboRole.shiftLeader:
        return const Color(0xFFF59E0B);
      case SaboRole.staff:
        return const Color(0xFF10B981);
      case SaboRole.driver:
        return const Color(0xFF0EA5E9);
      case SaboRole.warehouse:
        return const Color(0xFFF97316);
    }
  }

  Widget _buildProfileHeader(app_user.User? user) {
    final roleColor = user != null ? _getRoleColor(user.role) : const Color(0xFF10B981);
    final userName = user?.name ?? 'Người dùng';
    final roleLabel = user != null ? _getRoleLabel(user.role) : 'Nhân viên';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor,
            roleColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: user != null && user.avatarUrl != null 
                    ? NetworkImage(user.avatarUrl!) 
                    : null,
                child: user == null || user.avatarUrl == null 
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat('Ca làm', '156'),
              ),
              Expanded(
                child: _buildHeaderStat('Đánh giá', '4.8★'),
              ),
              Expanded(
                child: _buildHeaderStat('Tháng', '11'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê tháng này',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Giờ làm', '184h', 'Mục tiêu: 180h',
                    const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Nhiệm vụ', '87/92', 'Hoàn thành 95%',
                    const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Khách hàng', '245', 'Phục vụ tháng này',
                    const Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Tip', '1.2M', 'Thu nhập thêm', const Color(0xFFF59E0B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
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
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkInfoSection(app_user.User? user) {
    final employeeId = user?.id?.substring(0, 8).toUpperCase() ?? 'N/A';
    final email = user?.email ?? 'Chưa cập nhật';
    final phone = user?.phone ?? 'Chưa cập nhật';
    final createdAt = user?.createdAt;
    final joinDate = createdAt != null 
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
        : 'Chưa xác định';
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin công việc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Mã nhân viên', employeeId, Icons.badge),
          _buildInfoItem('Ngày vào làm', joinDate, Icons.calendar_today),
          _buildInfoItem('Email', email, Icons.email),
          _buildInfoItem('Điện thoại', phone, Icons.phone),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              size: 18,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(app_user.User? user) {
    final isDriver = user?.role == SaboRole.driver;
    final isWarehouse = user?.role == SaboRole.warehouse;
    
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
              'Cài đặt ứng dụng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSwitchItem(
            'Thông báo push',
            'Nhận thông báo về ca làm và nhiệm vụ',
            Icons.notifications,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          if (isDriver) _buildSwitchItem(
            'Chia sẻ vị trí GPS',
            'Cho phép theo dõi vị trí khi giao hàng',
            Icons.gps_fixed,
            _locationSharing,
            (value) => setState(() => _locationSharing = value),
          ),
          if (isWarehouse) _buildSwitchItem(
            'Quét mã QR tự động',
            'Tự động quét khi mở ứng dụng',
            Icons.qr_code_scanner,
            _locationSharing,
            (value) => setState(() => _locationSharing = value),
          ),
          if (!isDriver && !isWarehouse) _buildSwitchItem(
            'Chia sẻ vị trí',
            'Cho phép quản lý biết vị trí khi làm việc',
            Icons.location_on,
            _locationSharing,
            (value) => setState(() => _locationSharing = value),
          ),
          _buildSwitchItem(
            'Chế độ tối',
            'Giao diện tối cho môi trường làm việc',
            Icons.dark_mode,
            _darkMode,
            (value) => setState(() => _darkMode = value),
            isLast: true,
          ),
        ],
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

  Widget _buildSupportSection() {
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
              'Hỗ trợ & Khác',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildActionItem(
            'Xem lương & thưởng',
            'Chi tiết bảng lương và các khoản thưởng',
            Icons.account_balance_wallet,
            () {},
          ),
          _buildActionItem(
            'Đăng ký nghỉ phép',
            'Gửi đơn xin nghỉ phép đến quản lý',
            Icons.event_busy,
            () {},
          ),
          _buildActionItem(
            'Góp ý & đánh giá',
            'Chia sẻ ý kiến về môi trường làm việc',
            Icons.feedback,
            () {},
          ),
          _buildActionItem(
            'Hướng dẫn sử dụng',
            'Cách sử dụng ứng dụng hiệu quả',
            Icons.help,
            () {},
          ),
          _buildActionItem(
            'Chính sách công ty',
            'Nội quy và quy định làm việc',
            Icons.policy,
            () {},
          ),
          _buildActionItem(
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

  Widget _buildActionItem(
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
            onPressed: () async {
              Navigator.pop(context);
              // Perform actual logout
              await ref.read(authProvider.notifier).logout();
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
