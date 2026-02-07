import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'bug_report_dialog.dart';

/// Reusable Account/Profile Tab for all roles
/// Features: View/Edit profile, Change password, Settings, Logout
class AccountProfileTab extends ConsumerStatefulWidget {
  final Color themeColor;
  final String roleLabel;

  const AccountProfileTab({
    super.key,
    this.themeColor = Colors.teal,
    this.roleLabel = 'Nhân viên',
  });

  @override
  ConsumerState<AccountProfileTab> createState() => _AccountProfileTabState();
}

class _AccountProfileTabState extends ConsumerState<AccountProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  Map<String, dynamic>? _employeeData;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      final supabase = Supabase.instance.client;

      // Get employee data
      final data = await supabase
          .from('employees')
          .select('*, companies(name)')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _employeeData = data;
          _fullNameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading employee data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) throw Exception('Chưa đăng nhập');

      final supabase = Supabase.instance.client;

      await supabase.from('employees').update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Reload user data
      await ref.read(authProvider.notifier).reloadUserFromDatabase();
      await _loadEmployeeData();

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
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPw = true;
    bool obscureNewPw = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: widget.themeColor),
              const SizedBox(width: 8),
              const Text('Đổi mật khẩu'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrentPw ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureCurrentPw = !obscureCurrentPw),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  obscureText: obscureCurrentPw,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPw ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureNewPw = !obscureNewPw),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Tối thiểu 6 ký tự',
                  ),
                  obscureText: obscureNewPw,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mật khẩu không khớp!')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // Update password in employees table (hash with pgcrypto)
        final supabase = Supabase.instance.client;
        final authState = ref.read(authProvider);
        final user = authState.user;

        if (user != null) {
          // Call RPC to update password
          await supabase.rpc('update_employee_password', params: {
            'emp_id': user.id,
            'new_password': newPasswordController.text,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã đổi mật khẩu thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // Fallback: update directly if RPC doesn't exist
          try {
            final supabase = Supabase.instance.client;
            final authState = ref.read(authProvider);
            final user = authState.user;
            
            await supabase.from('employees').update({
              'password_hash': newPasswordController.text, // Will be hashed by trigger
            }).eq('id', user!.id);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã đổi mật khẩu!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e2'), backgroundColor: Colors.red),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(user),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Edit Profile Card
                          _buildEditableInfoCard(),

                          const SizedBox(height: 16),

                          // Settings Card
                          _buildSettingsCard(),

                          const SizedBox(height: 16),

                          // Actions Card
                          _buildActionsCard(),

                          const SizedBox(height: 24),

                          // App Version
                          Text(
                            'SABOHUB v1.0.0',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    final name = user?.name ?? _fullNameController.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final companyName = _employeeData?['companies']?['name'] ?? user?.companyName ?? 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.themeColor, widget.themeColor.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đổi ảnh đại diện đang phát triển')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, size: 18, color: widget.themeColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.roleLabel,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          // Company
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                companyName,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: widget.themeColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Thông tin cá nhân',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(Icons.edit, color: widget.themeColor),
                      tooltip: 'Chỉnh sửa',
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _loadEmployeeData(); // Reset
                          },
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                        IconButton(
                          onPressed: _saveProfile,
                          icon: Icon(Icons.check, color: widget.themeColor),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Full Name
              TextFormField(
                controller: _fullNameController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: !_isEditing,
                  fillColor: Colors.grey.shade100,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: !_isEditing,
                  fillColor: Colors.grey.shade100,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              // Email (read-only)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.lock_outline,
            label: 'Đổi mật khẩu',
            color: Colors.orange,
            onTap: _changePassword,
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingToggle(
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
            color: Colors.blue,
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Đã bật thông báo' : 'Đã tắt thông báo'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingItem(
            icon: Icons.help_outline,
            label: 'Trợ giúp & Hỗ trợ',
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liên hệ: support@sabohub.vn')),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingItem(
            icon: Icons.info_outline,
            label: 'Về ứng dụng',
            color: Colors.purple,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SABOHUB',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.hub, size: 48, color: widget.themeColor),
                children: [
                  const Text('Hệ thống quản lý phân phối đa ngành'),
                  const SizedBox(height: 8),
                  const Text('© 2026 SABO Ecosystem'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.bug_report_outlined,
            label: 'Báo cáo lỗi',
            color: Colors.red.shade400,
            onTap: () => BugReportDialog.show(context),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingItem(
            icon: Icons.logout,
            label: 'Đăng xuất',
            color: Colors.red,
            showArrow: false,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: TextStyle(color: color == Colors.red ? Colors.red : null)),
      trailing: showArrow ? Icon(Icons.chevron_right, color: Colors.grey.shade400) : null,
      onTap: onTap,
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: widget.themeColor,
      ),
    );
  }
}
