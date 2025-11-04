import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEV ONLY - Role Switcher for quick testing
/// Remove this in production!
class DevRoleSwitcher extends ConsumerWidget {
  const DevRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      return Positioned(
        bottom: 80,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'dev_role_switcher',
          mini: true,
          backgroundColor: Colors.purple.shade700,
          onPressed: () => _showRoleSelector(context),
          child: const Icon(Icons.switch_account, size: 20),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showRoleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.engineering, color: Colors.purple.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'DEV MODE - Switch Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEBUG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Role buttons
              _buildRoleButton(
                context,
                icon: Icons.business_center,
                title: 'CEO',
                subtitle: 'ceo@demo.com / password123',
                color: Colors.blue,
                email: 'ceo@demo.com',
                password: 'password123',
              ),
              _buildRoleButton(
                context,
                icon: Icons.manage_accounts,
                title: 'Manager',
                subtitle: 'manager@demo.com / password123',
                color: Colors.green,
                email: 'manager@demo.com',
                password: 'password123',
              ),
              _buildRoleButton(
                context,
                icon: Icons.supervisor_account,
                title: 'Shift Leader',
                subtitle: 'shiftleader@demo.com / password123',
                color: Colors.orange,
                email: 'shiftleader@demo.com',
                password: 'password123',
              ),
              _buildRoleButton(
                context,
                icon: Icons.person,
                title: 'Staff',
                subtitle: 'staff@demo.com / password123',
                color: Colors.purple,
                email: 'staff@demo.com',
                password: 'password123',
              ),
              const Divider(height: 32),
              // Custom login button
              _buildCustomLoginButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String email,
    required String password,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _switchRole(context, email, password, title);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLoginButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showCustomLoginDialog(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Text(
              'Đăng nhập bằng tài khoản khác',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.login, color: Colors.blue),
              SizedBox(width: 12),
              Text('Đăng nhập tùy chỉnh'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Nhập email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Tài khoản demo:\n'
                '• ceo@demo.com\n'
                '• manager@demo.com\n'
                '• shiftleader@demo.com\n'
                '• staff@demo.com\n'
                'Mật khẩu: password123',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập đầy đủ thông tin'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      Navigator.pop(context);
                      await _switchRole(context, email, password, 'Custom');
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchRole(
    BuildContext context,
    String email,
    String password,
    String roleName,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang chuyển tài khoản...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final supabase = Supabase.instance.client;

      // Sign out current user
      await supabase.auth.signOut();

      // Sign in with new credentials
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (response.user != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Đã chuyển sang tài khoản: $email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home
        context.go('/');
      } else {
        throw Exception('Đăng nhập thất bại');
      }
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
