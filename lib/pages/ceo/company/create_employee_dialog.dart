import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/company.dart';
import '../../../services/employee_auth_service.dart';
import '../../../models/employee_user.dart';

/// Simple dialog to create employee for a specific company
class CreateEmployeeDialog extends ConsumerStatefulWidget {
  final Company company;

  const CreateEmployeeDialog({
    super.key,
    required this.company,
  });

  @override
  ConsumerState<CreateEmployeeDialog> createState() =>
      _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends ConsumerState<CreateEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  EmployeeRole _selectedRole = EmployeeRole.staff;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = EmployeeAuthService();
      final result = await service.createEmployee(
        companyId: widget.company.id,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;

      if (result.success && result.employee != null) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Tạo nhân viên thành công!\nUsername: ${result.employee!.username}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.error ?? "Lỗi không xác định"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.person_add, size: 28, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tạo nhân viên mới',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Công ty: ${widget.company.name}',
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
                const Divider(height: 32),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    hintText: 'Nhập tên đăng nhập',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    if (value.trim().length < 3) {
                      return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên đầy đủ',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                DropdownButtonFormField<EmployeeRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: EmployeeRole.staff, child: Text('Nhân viên')),
                    DropdownMenuItem(
                        value: EmployeeRole.shiftLeader,
                        child: Text('Quản lý ca')),
                    DropdownMenuItem(
                        value: EmployeeRole.manager, child: Text('Quản lý')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createEmployee,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isLoading ? 'Đang tạo...' : 'Tạo nhân viên'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
