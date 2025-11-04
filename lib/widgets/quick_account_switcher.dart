import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../providers/auth_provider.dart';

/// Quick Account Switcher - Chuyển đổi nhanh giữa 2 tài khoản đã lưu
/// Phù hợp cho testing và development
class QuickAccountSwitcher extends ConsumerStatefulWidget {
  const QuickAccountSwitcher({super.key});

  @override
  ConsumerState<QuickAccountSwitcher> createState() =>
      _QuickAccountSwitcherState();
}

class _QuickAccountSwitcherState extends ConsumerState<QuickAccountSwitcher> {
  static const String _savedAccountsKey = '@saved_accounts';

  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_savedAccountsKey);

      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        setState(() {
          _savedAccounts =
              accountsList.map((json) => SavedAccount.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('🔴 Error loading saved accounts: $e');
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = jsonEncode(
        _savedAccounts.map((acc) => acc.toJson()).toList(),
      );
      await prefs.setString(_savedAccountsKey, accountsJson);
    } catch (e) {
      print('🔴 Error saving accounts: $e');
    }
  }

  Future<void> _switchAccount(SavedAccount account) async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.login(account.email, account.password);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã chuyển sang ${account.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể chuyển tài khoản'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddAccountDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'CEO';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tài khoản nhanh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  hintText: 'VD: CEO Chính',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'VD: ceo@sabohub.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: ['CEO', 'Manager', 'Staff', 'Shift Leader']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final account = SavedAccount(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  name: nameController.text.trim(),
                  role: selectedRole,
                );

                setState(() {
                  _savedAccounts.add(account);
                });
                _saveAccounts();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã lưu tài khoản'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(SavedAccount account) {
    setState(() {
      _savedAccounts.remove(account);
    });
    _saveAccounts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Đã xóa tài khoản'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentEmail = authState.user?.email;

    // Only show in debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 140,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Account quick switch buttons
          ..._savedAccounts.map((account) {
            final isCurrentAccount = account.email == currentEmail;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa tài khoản'),
                      content: Text(
                        'Bạn có chắc muốn xóa "${account.name}" khỏi danh sách?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAccount(account);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
                child: FloatingActionButton.extended(
                  heroTag: 'quick_switch_${account.email}',
                  onPressed: _isLoading || isCurrentAccount
                      ? null
                      : () => _switchAccount(account),
                  backgroundColor: isCurrentAccount
                      ? Colors.green.shade700
                      : _getRoleColor(account.role),
                  icon: _isLoading && !isCurrentAccount
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _getRoleIcon(account.role),
                          size: 18,
                        ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentAccount) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, size: 14),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // Add account button
          FloatingActionButton(
            heroTag: 'add_quick_account',
            mini: true,
            backgroundColor: Colors.blue.shade700,
            onPressed: _showAddAccountDialog,
            child: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return Colors.blue.shade700;
      case 'MANAGER':
        return Colors.green.shade700;
      case 'SHIFT LEADER':
        return Colors.orange.shade700;
      case 'STAFF':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return Icons.business_center;
      case 'MANAGER':
        return Icons.manage_accounts;
      case 'SHIFT LEADER':
        return Icons.supervisor_account;
      case 'STAFF':
        return Icons.person;
      default:
        return Icons.account_circle;
    }
  }
}

class SavedAccount {
  final String email;
  final String password;
  final String name;
  final String role;

  SavedAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        email: json['email'],
        password: json['password'],
        name: json['name'],
        role: json['role'],
      );
}

/// Quick Account Switcher for AppBar/Header
/// Hiển thị dạng horizontal trong header
class QuickAccountSwitcherHeader extends ConsumerStatefulWidget {
  const QuickAccountSwitcherHeader({super.key});

  @override
  ConsumerState<QuickAccountSwitcherHeader> createState() =>
      _QuickAccountSwitcherHeaderState();
}

class _QuickAccountSwitcherHeaderState
    extends ConsumerState<QuickAccountSwitcherHeader> {
  static const String _savedAccountsKey = '@saved_accounts';

  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_savedAccountsKey);

      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        setState(() {
          _savedAccounts =
              accountsList.map((json) => SavedAccount.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('🔴 Error loading saved accounts: $e');
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = jsonEncode(
        _savedAccounts.map((acc) => acc.toJson()).toList(),
      );
      await prefs.setString(_savedAccountsKey, accountsJson);
    } catch (e) {
      print('🔴 Error saving accounts: $e');
    }
  }

  Future<void> _switchAccount(SavedAccount account) async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.login(account.email, account.password);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã chuyển sang ${account.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể chuyển tài khoản'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddAccountDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'CEO';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tài khoản nhanh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  hintText: 'VD: CEO Chính',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'VD: ceo@sabohub.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: ['CEO', 'Manager', 'Staff', 'Shift Leader']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final account = SavedAccount(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  name: nameController.text.trim(),
                  role: selectedRole,
                );

                setState(() {
                  _savedAccounts.add(account);
                });
                _saveAccounts();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã lưu tài khoản'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(SavedAccount account) {
    setState(() {
      _savedAccounts.remove(account);
    });
    _saveAccounts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Đã xóa tài khoản'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentEmail = authState.user?.email;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Account chips
        ..._savedAccounts.map((account) {
          final isCurrentAccount = account.email == currentEmail;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _isLoading || isCurrentAccount
                  ? null
                  : () => _switchAccount(account),
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa tài khoản'),
                    content: Text(
                      'Bạn có chắc muốn xóa "${account.name}" khỏi danh sách?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAccount(account);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCurrentAccount
                      ? Colors.green.shade50
                      : _getRoleColor(account.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentAccount
                        ? Colors.green.shade700
                        : _getRoleColor(account.role),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(account.role),
                      size: 16,
                      color: isCurrentAccount
                          ? Colors.green.shade700
                          : _getRoleColor(account.role),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrentAccount
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrentAccount
                            ? Colors.green.shade700
                            : _getRoleColor(account.role),
                      ),
                    ),
                    if (isCurrentAccount) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),

        // Add button
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 24,
          color: Colors.blue.shade700,
          tooltip: 'Thêm tài khoản',
          onPressed: _showAddAccountDialog,
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return Colors.blue.shade700;
      case 'MANAGER':
        return Colors.green.shade700;
      case 'SHIFT LEADER':
        return Colors.orange.shade700;
      case 'STAFF':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return Icons.business_center;
      case 'MANAGER':
        return Icons.manage_accounts;
      case 'SHIFT LEADER':
        return Icons.supervisor_account;
      case 'STAFF':
        return Icons.person;
      default:
        return Icons.account_circle;
    }
  }
}
