import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';

/// CEO Profile Page
/// Displays CEO profile information, settings, and account management
class CEOProfilePage extends ConsumerStatefulWidget {
  const CEOProfilePage({super.key});

  @override
  ConsumerState<CEOProfilePage> createState() => _CEOProfilePageState();
}

class _CEOProfilePageState extends ConsumerState<CEOProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isEditingProfile = false;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user data from users table
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userData = response;
          _nameController.text = response['full_name'] ?? '';
          _emailController.text = response['email'] ?? user.email ?? '';
          _phoneController.text = response['phone'] ?? '';
          _positionController.text = _getRoleLabel(response['role'] ?? 'CEO');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return 'Giám đốc điều hành';
      case 'MANAGER':
        return 'Quản lý chi nhánh';
      case 'STAFF':
        return 'Nhân viên';
      default:
        return role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ cá nhân'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _userData ?? {};

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
        ),
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (!_isEditingProfile)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditingProfile = true;
                });
              },
              icon: const Icon(Icons.edit, color: Colors.blue),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingProfile = false;
                      // Reset form to original data
                      _loadUserData();
                    });
                  },
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    // Save profile changes
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      final user = _supabase.auth.currentUser;
                      if (user == null) throw Exception('Chưa đăng nhập');

                      await _supabase.from('users').update({
                        'full_name': _nameController.text.trim(),
                        'phone': _phoneController.text.trim(),
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', user.id);

                      await _loadUserData();

                      setState(() {
                        _isEditingProfile = false;
                      });

                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã lưu thông tin cá nhân'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: profile['avatar'] != null
                            ? null
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue.shade600,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name and position
                  if (!_isEditingProfile) ...[
                    Text(
                      profile['full_name'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleLabel(profile['role'] ?? 'STAFF'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Status badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Đang hoạt động',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CEO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Personal Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isEditingProfile) ...[
                    _buildEditField('Họ và tên', _nameController),
                    const SizedBox(height: 16),
                    _buildEditField('Email', _emailController),
                    const SizedBox(height: 16),
                    _buildEditField('Số điện thoại', _phoneController),
                    const SizedBox(height: 16),
                    _buildEditField('Chức vụ', _positionController),
                  ] else ...[
                    _buildInfoRow('Họ và tên', profile['full_name'] ?? 'N/A',
                        Icons.person),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                        'Email', profile['email'] ?? 'N/A', Icons.email),
                    const SizedBox(height: 16),
                    _buildInfoRow('Số điện thoại', profile['phone'] ?? 'N/A',
                        Icons.phone),
                    const SizedBox(height: 16),
                    _buildInfoRow('Chức vụ',
                        _getRoleLabel(profile['role'] ?? 'STAFF'), Icons.work),
                    const SizedBox(height: 16),
                    _buildInfoRow('Phòng ban', 'Ban lãnh đạo', Icons.business),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                        'Địa điểm', 'Hà Nội, Việt Nam', Icons.location_on),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Activity Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    'Ngày gia nhập',
                    profile['created_at'] != null
                        ? DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(profile['created_at']))
                        : '15/01/2020',
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Đăng nhập lần cuối',
                    profile['updated_at'] != null
                        ? _getTimeAgo(DateTime.parse(profile['updated_at']))
                        : 'N/A',
                    Icons.access_time,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cài đặt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingOption(
                    'Đổi mật khẩu',
                    Icons.lock,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Tính năng đổi mật khẩu sẽ được triển khai'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingOption(
                    'Cài đặt thông báo',
                    Icons.notifications,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Tính năng cài đặt thông báo sẽ được triển khai'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingOption(
                    'Bảo mật tài khoản',
                    Icons.security,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Tính năng bảo mật tài khoản sẽ được triển khai'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingOption(
                    'Đăng xuất',
                    Icons.logout,
                    () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final goRouter = GoRouter.of(context);
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận đăng xuất'),
                          content:
                              const Text('Bạn có chắc chắn muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Đăng xuất',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        // Perform logout
                        await ref.read(authProvider.notifier).logout();

                        if (mounted) {
                          // Show success message
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('✅ Đã đăng xuất thành công'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to login page
                          goRouter.go('/login');
                        }
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingOption(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
