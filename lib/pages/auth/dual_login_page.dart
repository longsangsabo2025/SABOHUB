import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import '../../providers/auth_provider.dart';
import '../../services/gemini_service.dart';
import '../../providers/company_list_provider.dart';
import '../../services/employee_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/app_logger.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Login Page với thiết kế mới:
/// - Giao diện chính: Đăng nhập Nhân viên (Company/Username/Password)
/// - Nút nhỏ ở góc: Chuyển sang CEO login
class DualLoginPage extends ConsumerStatefulWidget {
  const DualLoginPage({super.key});

  @override
  ConsumerState<DualLoginPage> createState() => _DualLoginPageState();
}

class _DualLoginPageState extends ConsumerState<DualLoginPage> {
  bool _showCEOLogin = false;

  void _toggleLoginMode() {
    setState(() {
      _showCEOLogin = !_showCEOLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Logo and title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'SABOHUB',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.surface,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _showCEOLogin
                              ? 'Đăng nhập CEO'
                              : 'Hệ thống quản lý giao hàng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.surface70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login form container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _showCEOLogin
                            ? CEOLoginForm(
                                key: const ValueKey('ceo'),
                                onBack: _toggleLoginMode,
                              )
                            : EmployeeLoginForm(
                                key: const ValueKey('employee')),
                      ),
                    ),
                  ),
                ],
              ),

              // CEO button ở góc trên bên phải
              if (!_showCEOLogin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('ceo_toggle_button'),
                      onTap: _toggleLoginMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 16,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'CEO',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Employee Login Form - Giao diện đăng nhập chính
class EmployeeLoginForm extends ConsumerStatefulWidget {
  const EmployeeLoginForm({super.key});

  @override
  ConsumerState<EmployeeLoginForm> createState() => _EmployeeLoginFormState();
}

class _EmployeeLoginFormState extends ConsumerState<EmployeeLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeAuthService = EmployeeAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  // Keys for SharedPreferences
  static const String _rememberKey = '@employee_remember_me';
  static const String _savedCredentialsKey = '@employee_saved_credentials';
  static const String _savedAccountsKey = '@employee_saved_accounts'; // NEW: Multi-account storage
  
  // List of saved accounts
  List<Map<String, String>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load all saved accounts from SharedPreferences
  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_savedAccountsKey);
      if (savedJson != null) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        setState(() {
          _savedAccounts = decoded.map((e) => Map<String, String>.from(e)).toList();
        });
        AppLogger.auth('📥 Loaded ${_savedAccounts.length} saved accounts');
      }
    } catch (e) {
      AppLogger.error('Failed to load saved accounts', e);
    }
  }

  /// Save account to the list of saved accounts
  Future<void> _saveAccountToList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final newAccount = {
        'company': _companyController.text.trim(),
        'username': _usernameController.text.trim(),
      };
      
      // Remove existing account with same username@company to avoid duplicates
      _savedAccounts.removeWhere((acc) => 
        acc['username'] == newAccount['username'] && 
        acc['company'] == newAccount['company']
      );
      
      // Add new account at the beginning
      _savedAccounts.insert(0, newAccount);
      
      // Keep only last 10 accounts
      if (_savedAccounts.length > 10) {
        _savedAccounts = _savedAccounts.sublist(0, 10);
      }
      
      await prefs.setString(_savedAccountsKey, jsonEncode(_savedAccounts));
      AppLogger.auth('💾 Saved account ${newAccount['username']}@${newAccount['company']}');
    } catch (e) {
      AppLogger.error('Failed to save account to list', e);
    }
  }

  /// Delete a saved account
  Future<void> _deleteAccount(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removed = _savedAccounts.removeAt(index);
      await prefs.setString(_savedAccountsKey, jsonEncode(_savedAccounts));
      setState(() {});
      AppLogger.auth('🗑️ Deleted account ${removed['username']}@${removed['company']}');
    } catch (e) {
      AppLogger.error('Failed to delete account', e);
    }
  }

  /// Select a saved account
  void _selectAccount(Map<String, String> account) {
    setState(() {
      _companyController.text = account['company'] ?? '';
      _usernameController.text = account['username'] ?? '';
      _passwordController.text = '';
      _rememberMe = true;
    });
  }

  /// Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberKey) ?? false;
      
      if (remember) {
        final savedJson = prefs.getString(_savedCredentialsKey);
        if (savedJson != null) {
          final saved = jsonDecode(savedJson);
          setState(() {
            _rememberMe = true;
            _companyController.text = saved['company'] ?? '';
            _usernameController.text = saved['username'] ?? '';
            _passwordController.text = saved['password'] ?? '';
          });
          AppLogger.auth('📥 Loaded saved credentials for ${saved['username']}');
          
          // Auto-login if password is saved (remember me)
          final password = saved['password'] as String?;
          if (password != null && password.isNotEmpty) {
            AppLogger.auth('🔄 Auto-login with saved credentials...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _login();
            });
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load saved credentials', e);
    }
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setBool(_rememberKey, true);
        // Save company + username + password for auto-login
        await prefs.setString(_savedCredentialsKey, jsonEncode({
          'company': _companyController.text.trim(),
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }));
        // Also save to multi-account list
        await _saveAccountToList();
        AppLogger.auth('💾 Saved credentials for ${_usernameController.text}');
      } else {
        await prefs.setBool(_rememberKey, false);
        await prefs.remove(_savedCredentialsKey);
        AppLogger.auth('🗑️ Cleared saved credentials');
      }
    } catch (e) {
      AppLogger.error('Failed to save credentials', e);
    }
  }

  Future<void> _login() async {
    AppLogger.box('🔐 EMPLOYEE LOGIN ATTEMPT', {
      'company': _companyController.text.trim(),
      'username': _usernameController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (!_formKey.currentState!.validate()) {
      AppLogger.warn('Form validation failed');
      return;
    }

    AppLogger.auth('Form validated, starting login...');
    setState(() => _isLoading = true);

    try {
      AppLogger.auth('📡 Calling EmployeeAuthService.login()...');
      final result = await _employeeAuthService.login(
        companyName: _companyController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      AppLogger.auth('📥 Login result received', {
        'success': result.success,
        'hasEmployee': result.employee != null,
        'error': result.error,
      });

      if (result.success && result.employee != null) {
        AppLogger.success('✅ Login successful!');
        AppLogger.data('👤 Employee data', {
          'id': result.employee!.id,
          'fullName': result.employee!.fullName,
          'role': result.employee!.role.value,
          'companyId': result.employee!.companyId,
        });
        // Save credentials if remember me is checked
        await _saveCredentials();
        AppLogger.auth('🔄 Converting employee to User...');
        final user = result.employee!.toUser();
        AppLogger.data('👤 User object', {
          'id': user.id,
          'name': user.name,
          'role': user.role.toString(),
          'businessType': user.businessType?.toString(),
          'companyName': user.companyName,
        });

        AppLogger.auth('📝 Calling authNotifier.loginWithUser()...');
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.loginWithUser(user);
        AppLogger.success('✅ Auth state updated!');

        // Load company AI API key for Gemini
        try {
          final companyData = await Supabase.instance.client
              .from('companies')
              .select('ai_api_key')
              .eq('id', result.employee!.companyId)
              .maybeSingle();
          if (companyData != null && companyData['ai_api_key'] != null) {
            GeminiService.setApiKey(companyData['ai_api_key'] as String);
            AppLogger.info('🤖 AI API key loaded for company');
          }
        } catch (e) {
          AppLogger.warn('Failed to load AI API key: $e');
        }

        if (mounted) {
          AppLogger.nav('🧭 Navigating to home...');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đăng nhập thành công! Xin chào ${result.employee!.fullName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          context.go('/');
          AppLogger.success('✅ Navigation complete!');
        }
      } else {
        AppLogger.error('❌ Login failed', result.error);
        if (mounted) {
          _showError(result.error ?? 'Đăng nhập thất bại');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('💥 Exception in _login()', e, stackTrace);
      if (mounted) {
        _showError('Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        AppLogger.auth('🏁 Login process finished, setting isLoading = false');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Build saved accounts section with horizontal scroll
  Widget _buildSavedAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Tài khoản đã lưu',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedAccounts.length,
            itemBuilder: (context, index) {
              final account = _savedAccounts[index];
              return Padding(
                padding: EdgeInsets.only(right: index < _savedAccounts.length - 1 ? 10 : 0),
                child: _buildAccountCard(account, index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build individual account card
  Widget _buildAccountCard(Map<String, String> account, int index) {
    final username = account['username'] ?? '';
    final company = account['company'] ?? '';
    
    return GestureDetector(
      onTap: () => _selectAccount(account),
      onLongPress: () => _showDeleteAccountDialog(index, username, company),
      child: Container(
        width: 140,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              company,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to confirm account deletion
  void _showDeleteAccountDialog(int index, String username, String company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa tài khoản?'),
          ],
        ),
        content: Text('Bạn có muốn xóa tài khoản "$username" khỏi danh sách đã lưu không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng nhập Nhân viên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sử dụng thông tin tài khoản được cấp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Saved accounts section
            if (_savedAccounts.isNotEmpty) ...[
              _buildSavedAccountsSection(),
              const SizedBox(height: 20),
            ],

            // Company autocomplete field
            Consumer(
              builder: (context, ref, child) {
                final companiesAsync = ref.watch(allCompaniesProvider);
                final companyNames = companiesAsync.when(
                  data: (companies) => companies.map((c) => c.name).toList(),
                  loading: () => <String>[],
                  error: (_, __) => <String>[],
                );

                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return companyNames.where((name) =>
                        name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _companyController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync with our controller
                    controller.text = _companyController.text;
                    controller.addListener(() {
                      _companyController.text = controller.text;
                    });
                    
                    return TextFormField(
                      key: const Key('employee_company_field'),
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Tên công ty',
                        hintText: 'Nhập tên công ty của bạn',
                        prefixIcon: Icon(Icons.business_outlined,
                            color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên công ty';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          width: MediaQuery.of(context).size.width - 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: Icon(Icons.business,
                                    color: AppColors.primary, size: 20),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Username field
            _buildTextField(
              fieldKey: const Key('employee_username_field'),
              controller: _usernameController,
              label: 'Tên đăng nhập',
              hint: 'Ví dụ: kho, driver1, asm.nam',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              key: const Key('employee_password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon:
                    Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Remember me checkbox
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _rememberMe = !_rememberMe);
                  },
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface87,
                    ),
                  ),
                ),
                const Spacer(),
                if (_rememberMe)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Sẽ lưu',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: Key('employee_login_button'),
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Theme.of(context).colorScheme.surface),
                          SizedBox(width: 8),
                          Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thông tin đăng nhập được cấp bởi quản lý.\n'
                      'Nếu chưa có tài khoản, vui lòng liên hệ CEO.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    Key? fieldKey,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey.shade50,
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
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

/// CEO Login Form - Hiển thị khi click nút CEO ở góc
class CEOLoginForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const CEOLoginForm({super.key, required this.onBack});

  @override
  ConsumerState<CEOLoginForm> createState() => _CEOLoginFormState();
}

class _CEOLoginFormState extends ConsumerState<CEOLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Keys for SharedPreferences
  static const String _ceoRememberKey = '@ceo_remember_me';
  static const String _ceoSavedCredentialsKey = '@ceo_saved_credentials';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load saved CEO credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_ceoRememberKey) ?? false;

      if (remember) {
        final savedJson = prefs.getString(_ceoSavedCredentialsKey);
        if (savedJson != null) {
          final saved = jsonDecode(savedJson);
          setState(() {
            _rememberMe = true;
            _emailController.text = saved['email'] ?? '';
            _passwordController.text = saved['password'] ?? '';
          });
          AppLogger.auth('📥 Loaded saved CEO credentials for ${saved['email']}');

          // Auto-login if password is saved
          final password = saved['password'] as String?;
          if (password != null && password.isNotEmpty) {
            AppLogger.auth('🔄 Auto-login CEO with saved credentials...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _login();
            });
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load CEO saved credentials', e);
    }
  }

  /// Save CEO credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setBool(_ceoRememberKey, true);
        await prefs.setString(_ceoSavedCredentialsKey, jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }));
        AppLogger.auth('💾 Saved CEO credentials for ${_emailController.text}');
      } else {
        await prefs.setBool(_ceoRememberKey, false);
        await prefs.remove(_ceoSavedCredentialsKey);
        AppLogger.auth('🗑️ Cleared CEO saved credentials');
      }
    } catch (e) {
      AppLogger.error('Failed to save CEO credentials', e);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      if (success) {
        // Save credentials on successful login
        await _saveCredentials();
      } else if (mounted) {
        final authState = ref.read(authProvider);
        _showError(authState.error ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Row(
              children: [
                InkWell(
                  key: const Key('employee_back_button'),
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 18, color: Theme.of(context).colorScheme.onSurface54),
                        SizedBox(width: 4),
                        Text(
                          'Nhân viên',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.amber.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng nhập CEO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sử dụng email và mật khẩu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Email field
            TextFormField(
              key: const Key('ceo_email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'ceo@company.com',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Colors.amber.shade700),
                filled: true,
                fillColor: Colors.grey.shade50,
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
                  borderSide:
                      BorderSide(color: Colors.amber.shade700, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!value.contains('@')) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              key: const Key('ceo_password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon:
                    Icon(Icons.lock_outline, color: Colors.amber.shade700),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
                  borderSide:
                      BorderSide(color: Colors.amber.shade700, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Remember me checkbox
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    activeColor: Colors.amber.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _rememberMe = !_rememberMe);
                  },
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface87,
                    ),
                  ),
                ),
                const Spacer(),
                if (_rememberMe)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Sẽ lưu',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: Key('ceo_login_button'),
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Theme.of(context).colorScheme.surface),
                          SizedBox(width: 8),
                          Text(
                            'Đăng nhập CEO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Warning note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trang này chỉ dành cho CEO/Admin.\n'
                      'Nhân viên vui lòng sử dụng giao diện đăng nhập nhân viên.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
