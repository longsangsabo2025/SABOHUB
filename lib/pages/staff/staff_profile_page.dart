import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../constants/roles.dart';
import '../../models/user.dart' as app_user;
import '../../widgets/bug_report_dialog.dart';

/// Staff Profile Page - Full Featured
/// Personal settings and profile management for staff
class StaffProfilePage extends ConsumerStatefulWidget {
  const StaffProfilePage({super.key});

  @override
  ConsumerState<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends ConsumerState<StaffProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  // TODO: Bật lại khi phát triển tính năng cài đặt ứng dụng
  // bool _notificationsEnabled = true;
  // bool _locationSharing = false;
  // bool _darkMode = false;
  Map<String, dynamic>? _employeeData;
  
  // Real stats
  int _monthsWorked = 0;
  String _joinDate = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      final supabase = Supabase.instance.client;
      // Employee xác thực qua CEO, cần query theo auth_user_id
      final data = await supabase
          .from('employees')
          .select('*, companies(name)')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        // Calculate months worked
        final createdAt = data['created_at'] != null 
            ? DateTime.parse(data['created_at']) 
            : null;
        int months = 0;
        String joinDateStr = 'Chưa xác định';
        
        if (createdAt != null) {
          final now = DateTime.now();
          months = (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
          if (months < 1) months = 1;
          joinDateStr = '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
        }
        
        setState(() {
          _employeeData = data;
          _fullNameController.text = data['full_name'] ?? user.name ?? '';
          _phoneController.text = data['phone'] ?? user.phone ?? '';
          _monthsWorked = months;
          _joinDate = joinDateStr;
          _avatarUrl = data['avatar_url'];
        });
      } else {
        _fullNameController.text = user.name ?? '';
        _phoneController.text = user.phone ?? '';
        
        // Calculate from user createdAt
        if (user.createdAt != null) {
          final now = DateTime.now();
          final months = (now.year - user.createdAt!.year) * 12 + (now.month - user.createdAt!.month);
          setState(() {
            _monthsWorked = months < 1 ? 1 : months;
            _joinDate = '${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading employee data: $e');
      final user = ref.read(authProvider).user;
      _fullNameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      setState(() => _isLoading = true);
      
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) throw Exception('Chưa đăng nhập');
      
      final supabase = Supabase.instance.client;
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';
      
      // Upload to Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );
      
      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      // Update employee record - sử dụng auth_user_id vì employee xác thực qua CEO
      await supabase.from('employees').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('auth_user_id', user.id);
      
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
      if (mounted) setState(() => _isLoading = false);
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

      // Employee xác thực qua CEO, cần query theo auth_user_id
      await supabase.from('employees').update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('auth_user_id', user.id);

      await ref.read(authProvider.notifier).reloadUserFromDatabase();
      await _loadEmployeeData();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật thông tin thành công!'),
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
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNewPw = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final roleColor = _getRoleColor(ref.read(authProvider).user?.role ?? SaboRole.staff);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: roleColor),
                const SizedBox(width: 8),
                const Text('Đổi mật khẩu'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                onPressed: () {
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
                style: ElevatedButton.styleFrom(backgroundColor: roleColor),
                child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final supabase = Supabase.instance.client;
        final authState = ref.read(authProvider);
        final user = authState.user;

        if (user != null) {
          // Use change_employee_password RPC
          try {
            await supabase.rpc('change_employee_password', params: {
              'p_employee_id': user.id,
              'p_new_password': newPasswordController.text,
            });
          } catch (rpcError) {
            throw Exception('Lỗi đổi mật khẩu: $rpcError');
          }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(user),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildEditableInfoSection(user),
            const SizedBox(height: 24),
            // TODO: Bật lại khi phát triển tính năng cài đặt
            // _buildSettingsSection(user),
            // const SizedBox(height: 24),
            _buildSupportSection(user),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(app_user.User? user) {
    final roleColor = user != null ? _getRoleColor(user.role) : const Color(0xFF10B981);
    return AppBar(
      elevation: 0,
      backgroundColor: roleColor,
      foregroundColor: Colors.white,
      title: const Text(
        'Hồ sơ cá nhân',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_isEditing)
          IconButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadEmployeeData();
            },
            icon: const Icon(Icons.close),
            tooltip: 'Hủy',
          ),
        IconButton(
          onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          icon: Icon(_isEditing ? Icons.check : Icons.edit),
          tooltip: _isEditing ? 'Lưu' : 'Chỉnh sửa',
        ),
      ],
    );
  }

  Widget _buildEditableInfoSection(app_user.User? user) {
    final roleColor = user != null ? _getRoleColor(user.role) : const Color(0xFF10B981);
    final email = user?.email ?? _employeeData?['email'] ?? 'Chưa cập nhật';
    
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: roleColor),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Đang chỉnh sửa',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email (không thể thay đổi)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ),
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
    final userName = user?.name ?? _fullNameController.text;
    final roleLabel = user != null ? _getRoleLabel(user.role) : 'Nhân viên';
    final companyName = _employeeData?['companies']?['name'] ?? user?.companyName ?? '';
    
    // Use avatar from state or user
    final avatarUrl = _avatarUrl ?? user?.avatarUrl;
    
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
          // Avatar with tap to change
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl) 
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
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
          ),
          const SizedBox(height: 16),
          Text(
            userName.isNotEmpty ? userName : 'Người dùng',
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
          if (companyName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Real stats from database
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat('Ngày vào', _joinDate.isNotEmpty ? _joinDate : '--'),
              ),
              Expanded(
                child: _buildHeaderStat('Thâm niên', '$_monthsWorked tháng'),
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

  // TODO: Bật lại khi phát triển tính năng cài đặt ứng dụng
  /*
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
  */

  Widget _buildSupportSection(app_user.User? user) {
    final isManager = user?.role == SaboRole.manager || 
                      user?.role == SaboRole.ceo;
    
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
            'Đổi mật khẩu',
            'Thay đổi mật khẩu đăng nhập',
            Icons.lock_outline,
            _changePassword,
            iconColor: const Color(0xFF3B82F6),
          ),
          // TODO: Bật lại khi phát triển tính năng lương thưởng
          // _buildActionItem(
          //   'Xem lương & thưởng',
          //   'Chi tiết bảng lương và các khoản thưởng',
          //   Icons.account_balance_wallet,
          //   () => ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Chức năng đang phát triển')),
          //   ),
          // ),
          // TODO: Bật lại khi phát triển tính năng nghỉ phép
          // _buildActionItem(
          //   'Đăng ký nghỉ phép',
          //   'Gửi đơn xin nghỉ phép đến quản lý',
          //   Icons.event_busy,
          //   () => ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Chức năng đang phát triển')),
          //   ),
          // ),
          if (isManager) _buildActionItem(
            'Báo cáo lỗi',
            'Gửi phản hồi về lỗi ứng dụng',
            Icons.bug_report,
            () => BugReportDialog.show(context),
            iconColor: Colors.orange,
          ),
          // TODO: Bật lại khi phát triển tính năng hướng dẫn
          // _buildActionItem(
          //   'Hướng dẫn sử dụng',
          //   'Cách sử dụng ứng dụng hiệu quả',
          //   Icons.help,
          //   () => ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Liên hệ: support@sabohub.vn')),
          //   ),
          // ),
          // TODO: Bật lại khi phát triển tính năng về ứng dụng
          // _buildActionItem(
          //   'Về ứng dụng',
          //   'Thông tin phiên bản và nhà phát triển',
          //   Icons.info_outline,
          //   () {
          //     final roleColor = _getRoleColor(ref.read(authProvider).user?.role ?? SaboRole.staff);
          //     showAboutDialog(
          //       context: context,
          //       applicationName: 'SABOHUB',
          //       applicationVersion: '1.0.0',
          //       applicationIcon: Icon(Icons.hub, size: 48, color: roleColor),
          //       children: [
          //         const Text('Hệ thống quản lý phân phối đa ngành'),
          //         const SizedBox(height: 8),
          //         const Text('© 2026 SABO Ecosystem'),
          //       ],
          //     );
          //   },
          //   iconColor: const Color(0xFF8B5CF6),
          // ),
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
    Color? iconColor,
  }) {
    final defaultIconColor = iconColor ?? textColor ?? const Color(0xFF10B981);
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
                color: defaultIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: defaultIconColor,
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
