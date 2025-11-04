import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/app_router.dart';
import '../../models/user.dart';
import '../../services/employee_service.dart';

/// Create Employee Account Page
/// Tạo tài khoản nhân viên mới
class CreateEmployeePage extends ConsumerStatefulWidget {
  const CreateEmployeePage({super.key});

  @override
  ConsumerState<CreateEmployeePage> createState() => _CreateEmployeePageState();
}

class _CreateEmployeePageState extends ConsumerState<CreateEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tạo tài khoản nhân viên',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildAccountInfoSection(),
              const SizedBox(height: 24),
              _buildRoleSection(),
              const SizedBox(height: 24),
              _buildAccountPreview(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Điền thông tin để tạo tài khoản nhân viên',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: '👤 Thông tin cá nhân',
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Họ và tên',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập họ và tên';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
              return 'Số điện thoại không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return _buildSection(
      title: '🔐 Thông tin đăng nhập',
      children: [
        // Email field with generate suggestion
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email đăng nhập',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _generateSuggestedEmail,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Tự động'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    backgroundColor: Colors.blue.shade50,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            if (_emailController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Nhân viên sẽ dùng email này để đăng nhập',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Password field with generate suggestion
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPasswordField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    isVisible: _passwordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
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
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _generateStrongPassword,
                  icon: const Icon(Icons.vpn_key, size: 18),
                  label: const Text('Tạo mạnh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade600,
                    backgroundColor: Colors.orange.shade50,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            if (_passwordController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    Icon(
                      _isPasswordStrong(_passwordController.text)
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 14,
                      color: _isPasswordStrong(_passwordController.text)
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPasswordStrengthText(_passwordController.text),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isPasswordStrong(_passwordController.text)
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Xác nhận mật khẩu',
          isVisible: _confirmPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
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
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Xác nhận mật khẩu',
          isVisible: _confirmPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != _passwordController.text) {
              return 'Mật khẩu không khớp';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSection() {
    return _buildSection(
      title: '👔 Chức vụ',
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: UserRole.values.map((role) {
              return _buildRoleOption(role);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role) {
    final isSelected = _selectedRole == role;
    final roleInfo = _getRoleInfo(role);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: RadioListTile<UserRole>(
        title: Row(
          children: [
            Icon(
              roleInfo['icon'] as IconData,
              color: roleInfo['color'] as Color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              roleInfo['title'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            roleInfo['description'] as String,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        value: role,
        groupValue: _selectedRole,
        activeColor: Colors.blue.shade600,
        onChanged: (UserRole? value) {
          if (value != null) {
            setState(() {
              _selectedRole = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildAccountPreview() {
    final hasData = _emailController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _nameController.text.isNotEmpty;

    if (!hasData) return const SizedBox.shrink();

    return _buildSection(
      title: '👀 Xem trước tài khoản',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin sẽ được tạo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_nameController.text.isNotEmpty) ...[
                _buildPreviewItem('Tên', _nameController.text, Icons.person),
                const SizedBox(height: 8),
              ],
              if (_emailController.text.isNotEmpty) ...[
                _buildPreviewItem('Email', _emailController.text, Icons.email),
                const SizedBox(height: 8),
              ],
              if (_passwordController.text.isNotEmpty) ...[
                _buildPreviewItem(
                  'Mật khẩu',
                  _passwordVisible ? _passwordController.text : '••••••••',
                  Icons.lock,
                  trailing: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildPreviewItem(
                'Vai trò',
                _getRoleInfo(_selectedRole)['title'],
                _getRoleInfo(_selectedRole)['icon'],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhân viên có thể đăng nhập ngay sau khi tài khoản được tạo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value, IconData icon,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return {
          'title': 'CEO',
          'description': 'Quyền quản lý toàn bộ hệ thống',
          'icon': Icons.business_center,
          'color': Colors.purple,
        };
      case UserRole.manager:
        return {
          'title': 'Quản lý',
          'description': 'Quản lý nhân viên và hoạt động cửa hàng',
          'icon': Icons.supervisor_account,
          'color': Colors.orange,
        };
      case UserRole.shiftLeader:
        return {
          'title': 'Trưởng ca',
          'description': 'Điều phối và giám sát ca làm việc',
          'icon': Icons.people_outline,
          'color': Colors.green,
        };
      case UserRole.staff:
        return {
          'title': 'Nhân viên',
          'description': 'Thực hiện các nhiệm vụ hàng ngày',
          'icon': Icons.person,
          'color': Colors.blue,
        };
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final employeeService = ref.read(employeeServiceProvider);

      // Check if email already exists
      final existingUser =
          await employeeService.getUserByEmail(_emailController.text.trim());

      if (existingUser != null) {
        if (mounted) {
          _showEmailExistsDialog(existingUser);
        }
        return;
      }

      // Create new employee
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Không thể tạo tài khoản xác thực');
      }

      final userId = authResponse.user!.id;

      // Insert user data
      await Supabase.instance.client.from('users').insert({
        'id': userId,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole.name,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Tạo tài khoản cho ${_nameController.text} thành công!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to employee list to show the created account
        context.pushReplacement(AppRoutes.employeeList);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        String errorMessage = 'Có lỗi database xảy ra';

        if (e.code == '23505') {
          if (e.message.contains('users_email_key')) {
            errorMessage = 'Email này đã được sử dụng bởi tài khoản khác';
          } else if (e.message.contains('users_pkey')) {
            errorMessage = 'ID đã tồn tại, vui lòng thử lại';
          } else {
            errorMessage = 'Thông tin đã tồn tại trong hệ thống';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi xác thực';

        if (e.message.contains('email')) {
          errorMessage = 'Email không hợp lệ hoặc đã được sử dụng';
        } else if (e.message.contains('password')) {
          errorMessage = 'Mật khẩu không đủ mạnh';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Có lỗi xảy ra: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods for auto-generation
  void _generateSuggestedEmail() {
    final name = _nameController.text.trim();
    final role = _selectedRole;

    if (name.isNotEmpty) {
      // Normalize name for email
      final normalizedName = name
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      String rolePrefix;
      switch (role) {
        case UserRole.manager:
          rolePrefix = 'manager';
          break;
        case UserRole.shiftLeader:
          rolePrefix = 'shiftleader';
          break;
        case UserRole.staff:
          rolePrefix = 'staff';
          break;
        case UserRole.ceo:
          rolePrefix = 'ceo';
          break;
      }

      final suggestedEmail = '$rolePrefix$normalizedName@sabohub.com';
      setState(() {
        _emailController.text = suggestedEmail;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Đã tạo email: $suggestedEmail'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập tên trước khi tạo email'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _generateStrongPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';

    // Ensure at least one of each type
    password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[(random % 26)];
    password += 'abcdefghijklmnopqrstuvwxyz'[(random % 26)];
    password += '0123456789'[(random % 10)];
    password += '!@#\$%^&*'[(random % 8)];

    // Fill the rest randomly
    for (int i = 4; i < 12; i++) {
      password += chars[(random + i) % chars.length];
    }

    // Shuffle the password
    final shuffled = password.split('')..shuffle();
    final finalPassword = shuffled.join();

    setState(() {
      _passwordController.text = finalPassword;
      _confirmPasswordController.text = finalPassword;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔐 Đã tạo mật khẩu mạnh: $finalPassword'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Sao chép',
          textColor: Colors.white,
          onPressed: () {
            // Copy to clipboard functionality would go here
          },
        ),
      ),
    );
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  String _getPasswordStrengthText(String password) {
    if (password.isEmpty) return '';

    if (_isPasswordStrong(password)) {
      return 'Mật khẩu mạnh ✨';
    } else if (password.length >= 6) {
      return 'Mật khẩu trung bình - nên thêm ký tự đặc biệt';
    } else {
      return 'Mật khẩu yếu - cần ít nhất 6 ký tự';
    }
  }

  void _showEmailExistsDialog(Map<String, dynamic> existingUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Email đã tồn tại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email "${_emailController.text}" đã được sử dụng bởi:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        existingUser['name'] ?? 'Không rõ tên',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _getRoleDisplayName(existingUser['role']),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        existingUser['is_active'] == true
                            ? Icons.check_circle
                            : Icons.block,
                        color: existingUser['is_active'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        existingUser['is_active'] == true
                            ? 'Đang hoạt động'
                            : 'Đã tạm khóa',
                        style: TextStyle(
                          color: existingUser['is_active'] == true
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.employeeList);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem danh sách nhân viên'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'ceo':
        return 'CEO';
      case 'manager':
        return 'Quản lý';
      case 'shiftLeader':
        return 'Trưởng ca';
      case 'staff':
        return 'Nhân viên';
      default:
        return 'Không rõ';
    }
  }
}
