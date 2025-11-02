import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../services/employee_service.dart';

/// Create Employee Dialog
/// Dialog for CEO to create new employee accounts
class CreateEmployeeDialog extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const CreateEmployeeDialog({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  ConsumerState<CreateEmployeeDialog> createState() =>
      _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends ConsumerState<CreateEmployeeDialog> {
  UserRole _selectedRole = UserRole.staff;
  bool _isCreating = false;
  String? _generatedEmail;
  String? _generatedPassword;
  bool _showCredentials = false;

  @override
  void initState() {
    super.initState();
    _updateGeneratedEmail();
  }

  void _updateGeneratedEmail() {
    final service = ref.read(employeeServiceProvider);
    setState(() {
      _generatedEmail = service.generateEmployeeEmail(
        companyName: widget.companyName,
        role: _selectedRole,
      );
    });
  }

  Future<void> _createEmployee() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final service = ref.read(employeeServiceProvider);
      final result = await service.createEmployeeAccount(
        companyId: widget.companyId,
        companyName: widget.companyName,
        role: _selectedRole,
      );

      setState(() {
        _generatedEmail = result['email'];
        _generatedPassword = result['tempPassword'];
        _showCredentials = true;
        _isCreating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tạo tài khoản thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Đã copy $label'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: Colors.blue[700],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạo tài khoản nhân viên',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.companyName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (!_showCredentials) ...[
              // Role Selection
              _buildRoleSelection(),
              const SizedBox(height: 16),

              // Generated Email Preview
              _buildEmailPreview(),
              const SizedBox(height: 24),

              // Info Box
              _buildInfoBox(),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // Credentials Display
              _buildCredentialsDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn chức vụ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRoleChip(
                UserRole.manager, 'Quản lý', Icons.supervised_user_circle),
            _buildRoleChip(UserRole.shiftLeader, 'Trưởng ca', Icons.groups),
            _buildRoleChip(UserRole.staff, 'Nhân viên', Icons.person),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedRole = role;
          _updateGeneratedEmail();
        });
      },
      selectedColor: Colors.blue[700],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmailPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Email sẽ được tạo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _generatedEmail ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
              const SizedBox(width: 8),
              Text(
                'Lưu ý quan trọng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Mật khẩu tạm thời sẽ được tạo tự động\n'
            '• Nhân viên sẽ được yêu cầu đổi mật khẩu lần đầu đăng nhập\n'
            '• Email xác thực sẽ được gửi tự động\n'
            '• Nhân viên cần hoàn thiện thông tin cá nhân và verify email',
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green[600],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          '✅ Tài khoản đã được tạo thành công!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Email
        _buildCredentialField(
          'Email đăng nhập',
          _generatedEmail ?? '',
          Icons.email,
        ),
        const SizedBox(height: 16),

        // Password
        _buildCredentialField(
          'Mật khẩu tạm thời',
          _generatedPassword ?? '',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),

        // Warning Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lưu thông tin đăng nhập này và gửi cho nhân viên. '
                  'Bạn sẽ không thể xem lại mật khẩu sau khi đóng cửa sổ này.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[900],
                    height: 1.5,
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
                onPressed: () {
                  _copyToClipboard(
                    'Email: $_generatedEmail\nMật khẩu: $_generatedPassword',
                    'thông tin đăng nhập',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, size: 18),
                    SizedBox(width: 8),
                    Text('Copy tất cả'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCredentialField(
    String label,
    String value,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    fontFamily: isPassword ? 'monospace' : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyToClipboard(value, label),
                color: Colors.blue[700],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
