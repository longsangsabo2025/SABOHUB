import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/employee_user.dart';
import '../../services/employee_auth_service.dart';

/// CEO Create Employee Page
/// CEO can create employee accounts (username/password based)
class CEOCreateEmployeePage extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const CEOCreateEmployeePage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  ConsumerState<CEOCreateEmployeePage> createState() =>
      _CEOCreateEmployeePageState();
}

class _CEOCreateEmployeePageState
    extends ConsumerState<CEOCreateEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeAuthService = EmployeeAuthService();

  // Form controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  EmployeeRole _selectedRole = EmployeeRole.staff;
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check username availability
      final isAvailable = await _employeeAuthService.isUsernameAvailable(
        companyId: widget.companyId,
        username: _usernameController.text.trim(),
      );

      if (!isAvailable) {
        if (mounted) {
          _showSnackBar('Tên đăng nhập đã tồn tại', Colors.red);
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create employee
      final result = await _employeeAuthService.createEmployee(
        companyId: widget.companyId,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (result.success && mounted) {
        _showSnackBar('Tạo tài khoản thành công!', Colors.green);
        Navigator.pop(context, result.employee);
      } else if (mounted) {
        _showSnackBar(result.error ?? 'Tạo tài khoản thất bại', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tạo tài khoản nhân viên'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Công ty',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            widget.companyName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role selection
              const Text(
                'Vai trò *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: EmployeeRole.values.map((role) {
                    return RadioListTile<EmployeeRole>(
                      value: role,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                      title: Text(role.displayName),
                      subtitle: Text(_getRoleDescription(role)),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Login credentials section
              const Text(
                'Thông tin đăng nhập',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập *',
                  hintText: 'Ví dụ: nguyen.van.a',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  if (value.length < 3) {
                    return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                    return 'Chỉ được dùng chữ, số, dấu chấm, gạch ngang';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu *',
                  hintText: 'Tối thiểu 6 ký tự',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

              const SizedBox(height: 24),

              // Personal info section
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Full name field
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên *',
                  hintText: 'Ví dụ: Nguyễn Văn A',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: Colors.white,
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
              ),

              const SizedBox(height: 16),

              // Email field (optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (tuỳ chọn)',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone field (optional)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại (tuỳ chọn)',
                  hintText: '0912345678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhân viên sẽ đăng nhập bằng:\n'
                        '• Tên công ty: ${widget.companyName}\n'
                        '• Tên đăng nhập: (vừa tạo)\n'
                        '• Mật khẩu: (vừa tạo)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
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

  String _getRoleDescription(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.manager:
        return 'Quản lý toàn bộ cửa hàng';
      case EmployeeRole.shiftLeader:
        return 'Trưởng ca, quản lý ca làm việc';
      case EmployeeRole.staff:
        return 'Nhân viên phục vụ';
    }
  }
}
