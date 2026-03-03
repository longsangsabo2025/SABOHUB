import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';

/// User Profile Page
/// Display and edit user information, settings, and preferences
class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingAvatar = false;
  Map<String, dynamic>? _userData;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get user from auth provider (works for both CEO and Employee)
      final authState = ref.read(authProvider);
      final appUser = authState.user;
      
      if (appUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // All users (CEO + Employee) use employees table
      final response = await _supabase
          .from('employees')
          .select(
              'id, full_name, email, phone, avatar_url, role, branch_id, company_id, companies!company_id(name), branches!branch_id(name)')
          .eq('id', appUser.id)
          .maybeSingle();

      if (response != null) {
        final data = response;
        setState(() {
          _userData = data;
          _fullNameController.text = data['full_name'] ?? appUser.name ?? '';
          _emailController.text = data['email'] ?? appUser.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _avatarUrl = data['avatar_url'];
        });
      } else {
        // Fallback to auth provider data
        setState(() {
          _userData = {'id': appUser.id, 'role': appUser.role.toString()};
          _fullNameController.text = appUser.name ?? '';
          _emailController.text = appUser.email ?? '';
          _phoneController.text = '';
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get user from auth provider (works for both CEO and Employee)
      final authState = ref.read(authProvider);
      final appUser = authState.user;
      
      if (appUser == null) throw Exception('Chưa đăng nhập');
      
      // All users (CEO + Employee) use employees table
      await _supabase
          .from('employees')
          .update({
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appUser.id);

      // Reload user data to update UI
      await _loadUserData();

      // Refresh auth provider to update global state - FORCE RELOAD FROM DATABASE
      await ref.read(authProvider.notifier).reloadUserFromDatabase();

      if (mounted) {
        setState(() => _isEditing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật thông tin!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu không khớp!')),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                // All users use employee_login, so change password via RPC
                final appUser = ref.read(authProvider).user;
                if (appUser == null) throw Exception('Chưa đăng nhập');
                
                final result = await _supabase.rpc('change_employee_password', params: {
                  'p_employee_id': appUser.id,
                  'p_new_password': passwordController.text,
                });
                
                if (result['success'] != true) {
                  throw Exception(result['error'] ?? 'Không thể đổi mật khẩu');
                }

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã đổi mật khẩu!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear auth state (works for both CEO and Employee)
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
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
      // Get user from auth provider
      final appUser = ref.read(authProvider).user;
      final userId = appUser?.id;
      
      if (userId == null) throw Exception('Chưa đăng nhập');

      final bytes = await image.readAsBytes();
      
      // Determine file extension and content type
      // On web, image.path may be a blob URL, so we need to handle it properly
      String fileExt = 'jpg'; // Default extension
      String contentType = 'image/jpeg'; // Default content type
      
      // Try to get extension from mimeType first (more reliable on web)
      final mimeType = image.mimeType;
      if (mimeType != null && mimeType.startsWith('image/')) {
        final mimeExt = mimeType.split('/').last;
        if (mimeExt == 'jpeg' || mimeExt == 'jpg') {
          fileExt = 'jpg';
          contentType = 'image/jpeg';
        } else if (mimeExt == 'png') {
          fileExt = 'png';
          contentType = 'image/png';
        } else if (mimeExt == 'gif') {
          fileExt = 'gif';
          contentType = 'image/gif';
        } else if (mimeExt == 'webp') {
          fileExt = 'webp';
          contentType = 'image/webp';
        }
      } else if (!image.path.startsWith('blob:')) {
        // Fallback to path extension if not a blob URL
        final pathExt = image.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(pathExt)) {
          fileExt = pathExt == 'jpeg' ? 'jpg' : pathExt;
          contentType = pathExt == 'jpeg' || pathExt == 'jpg' ? 'image/jpeg' : 'image/$pathExt';
        }
      }
      
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Debug: Log Supabase URL
      debugPrint('🔍 Supabase URL: ${_supabase.rest.url}');
      debugPrint('🔍 Uploading to bucket: avatars, path: $filePath');

      // Upload to Supabase Storage (bucket: avatars - dedicated for profile images)
      await _supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      debugPrint('✅ Upload success! URL: $publicUrl');

      // All users in employees table
      await _supabase.from('employees').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

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
      // Get user from auth provider
      final appUser = ref.read(authProvider).user;
      final userId = appUser?.id;
      
      if (userId == null) throw Exception('Chưa đăng nhập');

      // All users in employees table
      await _supabase.from('employees').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Chỉnh sửa',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData(); // Reset form
              },
              tooltip: 'Hủy',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildCompanyInfoCard(),
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildAvatarSection() {
    final role = _userData?['role'] ?? 'STAFF';
    final fullName = _userData?['full_name'] ?? 'User';
    final initials = fullName.split(' ').take(2).map((e) => e[0]).join();

    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Stack(
            children: [
              _isUploadingAvatar
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getRoleColor(role).withValues(alpha: 0.2),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: _getRoleColor(role),
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getRoleColor(role)),
          ),
          child: Text(
            _getRoleLabel(role),
            style: TextStyle(
              color: _getRoleColor(role),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              enabled: false, // Email không thể đổi
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    // Get company name from foreign key relation
    final companyData = _userData?['companies'];
    final companyName =
        companyData is Map ? (companyData['name'] ?? 'Chưa có') : 'Chưa có';

    // Get branch name from foreign key relation
    final branchData = _userData?['branches'];
    final branchName =
        branchData is Map ? (branchData['name'] ?? 'Chưa có') : 'Chưa có';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin công ty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Công ty', companyName),
            const Divider(),
            _buildInfoRow(Icons.store, 'Chi nhánh', branchName),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Thông báo'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tiếng Việt'),
                SizedBox(width: 8),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('Trợ giúp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement help
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('Về ứng dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sabo Hub',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.restaurant_menu, size: 48),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'CEO':
        return Colors.purple;
      case 'BRANCH_MANAGER':
        return Colors.blue;
      case 'SHIFT_LEADER':
        return Colors.orange;
      case 'STAFF':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'CEO':
        return 'Giám đốc điều hành';
      case 'BRANCH_MANAGER':
        return 'Quản lý chi nhánh';
      case 'SHIFT_LEADER':
        return 'Trưởng ca';
      case 'STAFF':
        return 'Nhân viên';
      default:
        return role;
    }
  }
}
