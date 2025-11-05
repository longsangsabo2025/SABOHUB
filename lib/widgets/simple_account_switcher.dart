import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Simple Account Switcher - Chỉ để chuyển đổi giữa 2 tài khoản đã xác thực
/// Hiển thị trong actions của AppBar
class SimpleAccountSwitcher extends ConsumerWidget {
  const SimpleAccountSwitcher({super.key});

  // 2 tài khoản có sẵn
  static const ceoAccount = {
    'email': 'ceo@demo.com',
    'password': 'demo',
    'name': 'CEO',
    'icon': Icons.business_center,
    'color': Color(0xFF3B82F6), // Blue
  };

  static const managerAccount = {
    'email': 'manager@demo.com',
    'password': 'demo',
    'name': 'Manager',
    'icon': Icons.manage_accounts,
    'color': Color(0xFF10B981), // Green
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ hiển thị trong debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final authState = ref.watch(authProvider);
    /*final currentEmail = */authState.user?.email;

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 18,
              color: Colors.purple.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Switch',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
      ),
      tooltip: 'Chuyển tài khoản (Dev)',
      offset: const Offset(0, 45),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ceo',
          child: _buildAccountItem(
            icon: ceoAccount['icon'] as IconData,
            name: ceoAccount['name'] as String,
            email: 'CEO Account',
            color: ceoAccount['color'] as Color,
            isActive: false,
          ),
        ),
        PopupMenuItem(
          value: 'manager',
          child: _buildAccountItem(
            icon: managerAccount['icon'] as IconData,
            name: managerAccount['name'] as String,
            email: 'Manager Account',
            color: managerAccount['color'] as Color,
            isActive: false,
          ),
        ),
      ],
      onSelected: (accountType) => _showLoginDialog(context, ref, accountType),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String name,
    required String email,
    required Color color,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : Colors.black87,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle, size: 16, color: color),
                  ],
                ],
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLoginDialog(
    BuildContext context,
    WidgetRef ref,
    String accountType,
  ) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final account = accountType == 'ceo' ? ceoAccount : managerAccount;
    final color = account['color'] as Color;
    final icon = account['icon'] as IconData;
    final name = account['name'] as String;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text('Đăng nhập $name'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onSubmitted: (_) {
                      // Enter để submit
                      if (emailController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        Navigator.of(dialogContext).pop();
                        _performLogin(
                          context,
                          ref,
                          name,
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Vui lòng nhập đầy đủ thông tin'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    _performLogin(context, ref, name, email, password);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performLogin(
    BuildContext context,
    WidgetRef ref,
    String accountName,
    String email,
    String password,
  ) async {
    final authNotifier = ref.read(authProvider.notifier);

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Đang chuyển tài khoản...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final success = await authNotifier.login(email, password);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã chuyển sang $accountName thành công!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final authState = ref.read(authProvider);
          final errorMessage = authState.error ?? 'Đăng nhập thất bại';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
