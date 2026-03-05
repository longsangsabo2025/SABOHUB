import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/account_storage_service.dart';
import '../core/theme/app_spacing.dart';

/// Multi-Account Manager
/// Lưu và chuyển đổi giữa nhiều tài khoản đã đăng nhập
/// Tương tự như Google/Facebook account switcher
class MultiAccountSwitcher extends ConsumerStatefulWidget {
  const MultiAccountSwitcher({super.key});

  @override
  ConsumerState<MultiAccountSwitcher> createState() =>
      _MultiAccountSwitcherState();
}

class _MultiAccountSwitcherState extends ConsumerState<MultiAccountSwitcher> {
  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  /// Load danh sách tài khoản đã lưu
  Future<void> _loadSavedAccounts() async {
    final accounts = await AccountStorageService.getSavedAccounts();
    setState(() {
      _savedAccounts = accounts;
      _isLoading = false;
    });
  }

  /// Lưu tài khoản hiện tại vào danh sách
  Future<void> _saveCurrentAccount() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    await AccountStorageService.saveAccount(authState.user!);
    await _loadSavedAccounts(); // Reload list
  }

  /// Xóa tài khoản khỏi danh sách
  Future<void> _removeAccount(String email) async {
    await AccountStorageService.removeAccount(email);
    await _loadSavedAccounts(); // Reload list
  }

  /// Chuyển sang tài khoản khác
  Future<void> _switchToAccount(SavedAccount account) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Đăng xuất tài khoản hiện tại
      await ref.read(authProvider.notifier).logout();

      // Đăng nhập bằng tài khoản đã lưu
      // Lưu ý: Cần password, nên sẽ yêu cầu nhập lại password
      navigator.pop(); // Close loading

      _showPasswordDialog(account);
    } catch (e) {
      navigator.pop(); // Close loading
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi chuyển tài khoản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dialog nhập password để chuyển tài khoản
  void _showPasswordDialog(SavedAccount account) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(account.role),
              child: Text(
                account.name[0].toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.surface),
              ),
            ),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    account.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) =>
                  _performSwitch(account, passwordController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _performSwitch(account, passwordController.text),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  /// Thực hiện đăng nhập
  Future<void> _performSwitch(SavedAccount account, String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
      );
      return;
    }

    Navigator.of(context).pop(); // Close password dialog

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success =
          await ref.read(authProvider.notifier).login(account.email, password);

      navigator.pop(); // Close loading

      if (success) {
        // Update last used
        account.lastUsed = DateTime.now();
        await _saveCurrentAccount();

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('✅ Đã chuyển sang ${account.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content:
                  Text('❌ Đăng nhập thất bại. Vui lòng kiểm tra mật khẩu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      navigator.pop(); // Close loading
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'ceo':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'shift_leader':
        return Colors.orange;
      case 'staff':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUser != null) ...[
              CircleAvatar(
                radius: 12,
                backgroundColor: _getRoleColor(currentUser.role.name),
                child: Text(
                  (currentUser.name ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.hGapXS,
            ],
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.blue.shade700),
          ],
        ),
      ),
      tooltip: 'Chuyển tài khoản',
      offset: const Offset(0, 45),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        // Current account header
        if (currentUser != null) {
          items.add(
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đang đăng nhập',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  AppSpacing.gapXXS,
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getRoleColor(currentUser.role.name),
                        child: Text(
                          (currentUser.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppSpacing.hGapMD,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentUser.email ?? 'ID: ${currentUser.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
          );

          // Save current account button
          items.add(
            PopupMenuItem(
              value: 'save',
              child: const Row(
                children: [
                  Icon(Icons.save, size: 20, color: Colors.blue),
                  AppSpacing.hGapMD,
                  Text('💾 Lưu tài khoản này'),
                ],
              ),
            ),
          );

          items.add(const PopupMenuDivider());
        }

        // Saved accounts
        if (_savedAccounts.isNotEmpty) {
          items.add(
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Tài khoản đã lưu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          );

          for (final account in _savedAccounts) {
            // Skip current account
            if (currentUser != null && account.email == currentUser.email) {
              continue;
            }

            items.add(
              PopupMenuItem(
                value: 'switch_${account.email}',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getRoleColor(account.role),
                      child: Text(
                        account.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AppSpacing.hGapMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            account.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeAccount(account.email);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          items.add(const PopupMenuDivider());
        }

        // Add account button
        items.add(
          const PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.person_add, size: 20, color: Colors.green),
                AppSpacing.hGapMD,
                Text('➕ Thêm tài khoản khác'),
              ],
            ),
          ),
        );

        return items;
      },
      onSelected: (value) {
        if (value == 'save') {
          _saveCurrentAccount();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã lưu tài khoản'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (value == 'add') {
          // Navigate to login page
          ref.read(authProvider.notifier).logout();
        } else if (value.startsWith('switch_')) {
          final email = value.substring(7);
          final account =
              _savedAccounts.firstWhere((acc) => acc.email == email);
          _switchToAccount(account);
        }
      },
    );
  }
}
