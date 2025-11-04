import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _quickLogins = [
    {'email': 'ceo1@sabohub.com', 'password': 'demo', 'label': 'CEO - Nhà hàng Sabo', 'role': 'CEO'},
    {'email': 'manager1@sabohub.com', 'password': 'demo', 'label': 'Manager - Chi nhánh 1', 'role': 'MANAGER'},
    {'email': 'shift@sabohub.com', 'password': 'demo', 'label': 'Shift Leader - Trưởng ca', 'role': 'SHIFT_LEADER'},
    {'email': 'staff1@sabohub.com', 'password': 'demo', 'label': 'Staff - Nhân viên', 'role': 'STAFF'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _quickLogin(String email, String password) async {
    _emailController.text = email;
    _passwordController.text = password;
    await _login();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đăng nhập thất bại: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎨 POLISHED LOGO với gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.business_center, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text('SABOHUB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Quản lý nhân viên chuyên nghiệp', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ✨ POLISHED EMAIL FIELD
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'nhap@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.blue.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Email không đúng định dạng';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔒 POLISHED PASSWORD FIELD với show/hide
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: Icon(Icons.lock_outlined, color: Colors.blue.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (value.length < 3) return 'Mật khẩu quá ngắn';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 🚀 POLISHED LOGIN BUTTON với loading animation
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.go('/forgot-password'),
                    child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 32),

                // 🎯 POLISHED QUICK LOGIN DEMO
                const Divider(),
                const SizedBox(height: 16),
                Text('Đăng nhập nhanh (Demo)', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),

                ...List.generate(_quickLogins.length, (index) {
                  final login = _quickLogins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _quickLogin(login['email']!, login['password']!),
                      icon: Icon(_getIconForRole(login['role']!)),
                      label: Text(login['label']!),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(12)),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey.shade600)),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: const Text('Đăng ký ngay', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'CEO': return Icons.business_center;
      case 'MANAGER': return Icons.person_outline;
      case 'SHIFT_LEADER': return Icons.access_time;
      case 'STAFF': return Icons.people;
      default: return Icons.person;
    }
  }
}