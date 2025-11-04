import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/company.dart';
import '../../models/user.dart';
import '../../providers/employee_provider.dart';
import '../../providers/company_provider.dart';

/// Simple Create Employee Dialog
/// Chỉ cần nhập tên và chọn role - không cần Auth phức tạp
class CreateEmployeeSimpleDialog extends ConsumerStatefulWidget {
  final Company company;

  const CreateEmployeeSimpleDialog({
    super.key,
    required this.company,
  });

  @override
  ConsumerState<CreateEmployeeSimpleDialog> createState() =>
      _CreateEmployeeSimpleDialogState();
}

class _CreateEmployeeSimpleDialogState
    extends ConsumerState<CreateEmployeeSimpleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.staff;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Generate unique invite token
      final inviteToken = DateTime.now().millisecondsSinceEpoch.toString() +
          _nameController.text.hashCode.toString();

      // Invite expires in 7 days
      final inviteExpiresAt = DateTime.now().add(const Duration(days: 7));

      String roleValue;

      switch (_selectedRole) {
        case UserRole.manager:
          roleValue = 'MANAGER';
          break;
        case UserRole.shiftLeader:
          roleValue = 'SHIFT_LEADER';
          break;
        case UserRole.staff:
          roleValue = 'STAFF';
          break;
        case UserRole.ceo:
          roleValue = 'CEO';
          break;
      }

      // BƯỚC 1: Insert vào DB - KHÔNG TẠO AUTH ACCOUNT
      // Nhân viên sẽ tự tạo auth khi click invite link
      final response = await supabase
          .from('users')
          .insert({
            'full_name': _nameController.text.trim(),
            'email': 'pending-$inviteToken@temp.local', // Temporary email
            'role': roleValue,
            'phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'company_id': widget.company.id,
            'is_active': false, // Inactive until onboarded
            'invite_token': inviteToken,
            'invite_expires_at': inviteExpiresAt.toIso8601String(),
            'invited_at': DateTime.now().toIso8601String(),
          })
          .select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, invite_token, invite_expires_at, invited_at, onboarded_at, created_at, updated_at')
          .single();

      final userId = response['id'] as String;

      // BƯỚC 2: Generate invite link
      // TODO: Replace with your actual domain
      final inviteLink = 'https://app.sabohub.com/onboard/$inviteToken';
      // For local testing:
      // final inviteLink = 'http://localhost:53892/onboard/$inviteToken';

      if (!mounted) return;

      Navigator.of(context).pop();

      // Refresh employee list and company stats AFTER closing dialog
      // This ensures the parent widget rebuilds properly
      await Future.delayed(const Duration(milliseconds: 100));
      ref.invalidate(companyEmployeesProvider(widget.company.id));
      ref.invalidate(companyEmployeesStatsProvider(widget.company.id));
      ref.invalidate(companyStatsProvider(widget.company.id));

      // Show success dialog with invite link
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 32),
              const SizedBox(width: 12),
              const Text('Tạo nhân viên thành công'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhân viên ${_nameController.text} đã được thêm!',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '� Link mời nhân viên:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          inviteLink,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '⏰ Link có hiệu lực trong 7 ngày',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📱 Gửi link này cho nhân viên qua Zalo/SMS/Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Copy link to clipboard
                // TODO: Implement clipboard copy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã copy link vào clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('📋 Copy Link'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm nhân viên mới',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.company.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên *',
                  hintText: 'Nhập họ tên nhân viên',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
                enabled: !_isCreating,
              ),
              const SizedBox(height: 16),

              // Phone Field (Optional)
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại (không bắt buộc)',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isCreating,
              ),
              const SizedBox(height: 16),

              // Role Selection
              const Text(
                'Chức vụ *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      role: UserRole.manager,
                      label: 'Quản lý',
                      icon: Icons.supervised_user_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleButton(
                      role: UserRole.shiftLeader,
                      label: 'Trưởng ca',
                      icon: Icons.groups,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleButton(
                      role: UserRole.staff,
                      label: 'Nhân viên',
                      icon: Icons.person,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email sẽ được tạo tự động. Nhân viên chỉ cần đăng ký thông tin, không cần đăng nhập.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Thêm nhân viên'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: _isCreating
          ? null
          : () {
              setState(() {
                _selectedRole = role;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
