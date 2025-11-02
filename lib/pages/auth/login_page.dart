import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Quick login buttons for testing
  final List<Map<String, String>> _quickLogins = [
    {
      'email': 'ceo1@sabohub.com',
      'password': 'password123',
      'label': 'CEO - Nhà hàng Sabo',
      'role': 'CEO'
    },
    {
      'email': 'ceo2@sabohub.com',
      'password': 'password123',
      'label': 'CEO - Cafe Sabo',
      'role': 'CEO'
    },
    {
      'email': 'manager1@sabohub.com',
      'password': 'password123',
      'label': 'Manager - Chi nhánh 1',
      'role': 'MANAGER'
    },
    {
      'email': 'staff1@sabohub.com',
      'password': 'password123',
      'label': 'Staff - Chi nhánh 1',
      'role': 'STAFF'
    },
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
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SABOHUB',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 32),

              // Quick login section
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Đăng nhập nhanh (Demo)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Quick login buttons
              ...List.generate(_quickLogins.length, (index) {
                final login = _quickLogins[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () =>
                            _quickLogin(login['email']!, login['password']!),
                    icon: Icon(_getIconForRole(login['role']!)),
                    label: Text(login['label']!),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'CEO':
        return Icons.business_center;
      case 'MANAGER':
        return Icons.person_outline;
      case 'STAFF':
        return Icons.people;
      default:
        return Icons.person;
    }
  }
}
