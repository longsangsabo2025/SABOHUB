import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isUploadingAvatar = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  Map<String, dynamic>? _userData;
  String? _avatarUrl;

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
      var response = await _supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      // Fallback to employees table if not found in users
      if (response == null) {
        response = await _supabase
            .from('employees')
            .select('*')
            .eq('auth_user_id', user.id)
            .maybeSingle();
      }

      if (response != null) {
        final data = response;
        setState(() {
          _userData = data;
          _nameController.text = data['full_name'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _positionController.text = _getRoleLabel(data['role'] ?? 'CEO');
          _avatarUrl = data['avatar_url'];
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

  // === Avatar Methods ===
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAvatarOptionButton(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_avatarUrl != null)
                  _buildAvatarOptionButton(
                    icon: Icons.delete,
                    label: 'Xóa ảnh',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removeAvatar();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      await _uploadAvatar(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar(XFile image) async {
    setState(() => _isUploadingAvatar = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update users table (CEO uses users table)
      await _supabase.from('users').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() => _avatarUrl = publicUrl);

      // Reload user
      await ref.read(authProvider.notifier).reloadUserFromDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật ảnh đại diện!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh đại diện?'),
        content: const Text('Bạn có chắc muốn xóa ảnh đại diện không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      // Update users table
      await _supabase.from('users').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() => _avatarUrl = null);

      await ref.read(authProvider.notifier).reloadUserFromDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa ảnh đại diện!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
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
                  // Avatar with upload
                  GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Stack(
                      children: [
                        _isUploadingAvatar
                            ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade100,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.blue.shade600,
                                      )
                                    : null,
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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
