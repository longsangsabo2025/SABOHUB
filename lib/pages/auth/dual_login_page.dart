import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/company_list_provider.dart';
import '../../services/employee_auth_service.dart';

/// Dual Login Page
/// Tab 1: CEO Login (Email/Password - Supabase Auth)
/// Tab 2: Employee Login (Company/Username/Password - Custom Auth)
class DualLoginPage extends ConsumerStatefulWidget {
  const DualLoginPage({super.key});

  @override
  ConsumerState<DualLoginPage> createState() => _DualLoginPageState();
}

class _DualLoginPageState extends ConsumerState<DualLoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 40,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SABOHUB',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Hệ thống quản lý quán bida',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Login form container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black54,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.admin_panel_settings),
                              text: 'CEO',
                            ),
                            Tab(
                              icon: Icon(Icons.people),
                              text: 'Nhân viên',
                            ),
                          ],
                        ),
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            CEOLoginTab(),
                            EmployeeLoginTab(),
                          ],
                        ),
                      ),
                    ],
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

/// CEO Login Tab (Email/Password - Supabase Auth)
class CEOLoginTab extends ConsumerStatefulWidget {
  const CEOLoginTab({super.key});

  @override
  ConsumerState<CEOLoginTab> createState() => _CEOLoginTabState();
}

class _CEOLoginTabState extends ConsumerState<CEOLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _quickLogin(String email, String password) async {
    setState(() => _isLoading = true);
    _emailController.text = email;
    _passwordController.text = password;
    
    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(email, password);

      if (!success && mounted) {
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

  Future<void> _login() async {
    print('🔵 [LOGIN] _login() called');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [LOGIN] Form validation failed');
      return;
    }

    print('✅ [LOGIN] Form validated, starting login...');
    print('📧 [LOGIN] Email: ${_emailController.text.trim()}');
    
    setState(() => _isLoading = true);

    try {
      print('🔄 [LOGIN] Calling authProvider.login...');
      
      final success = await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      print('📊 [LOGIN] Login result: $success');

      if (!success && mounted) {
        final authState = ref.read(authProvider);
        print('❌ [LOGIN] Login failed: ${authState.error}');
        _showError(authState.error ?? 'Đăng nhập thất bại');
      } else {
        print('✅ [LOGIN] Login successful!');
      }
    } catch (e) {
      print('💥 [LOGIN] Exception: $e');
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
            const Text(
              'Đăng nhập CEO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sử dụng email và mật khẩu đã đăng ký',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
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
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Login Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on,
                          color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Đăng nhập nhanh',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _quickLogin('longsangsabo1@gmail.com',
                              'Acookingoil123@'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.business, size: 20),
                      label: const Text(
                        'CEO - longsangsabo1@gmail.com',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
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

/// Employee Login Tab (Company/Username/Password - Custom Auth)
class EmployeeLoginTab extends ConsumerStatefulWidget {
  const EmployeeLoginTab({super.key});

  @override
  ConsumerState<EmployeeLoginTab> createState() => _EmployeeLoginTabState();
}

class _EmployeeLoginTabState extends ConsumerState<EmployeeLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeAuthService = EmployeeAuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _employeeAuthService.login(
        companyName: _companyController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success && result.employee != null) {
        // Convert employee to User and login
        final user = result.employee!.toUser();
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.loginWithUser(user);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập thành công! Xin chào ${result.employee!.fullName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // Navigate to main app - RoleBasedDashboard will handle routing
          context.go('/');
        }
      } else {
        if (mounted) {
          _showError(result.error ?? 'Đăng nhập thất bại');
        }
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
            const Text(
              'Đăng nhập Nhân viên',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sử dụng thông tin CEO đã tạo cho bạn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),

            // Company dropdown
            Consumer(
              builder: (context, ref, child) {
                final companiesAsync = ref.watch(allCompaniesProvider);
                
                return companiesAsync.when(
                  data: (companies) {
                    if (companies.isEmpty) {
                      return TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Tên công ty',
                          hintText: 'Ví dụ: SABO Billiards',
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên công ty';
                          }
                          return null;
                        },
                      );
                    }
                    
                    return DropdownButtonFormField<String>(
                      value: _companyController.text.isEmpty ? null : _companyController.text,
                      decoration: InputDecoration(
                        labelText: 'Tên công ty',
                        hintText: 'Chọn công ty',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: companies.map((company) {
                        return DropdownMenuItem<String>(
                          value: company.name,
                          child: Text(company.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _companyController.text = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng chọn công ty';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      labelText: 'Tên công ty',
                      hintText: 'Đang tải danh sách công ty...',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: false,
                  ),
                  error: (error, stack) => TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      labelText: 'Tên công ty',
                      hintText: 'Ví dụ: SABO Billiards',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên công ty';
                      }
                      return null;
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập',
                hintText: 'Ví dụ: nguyen.van.a',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
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
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Thông tin đăng nhập được CEO cung cấp.\n'
                      'Nếu chưa có tài khoản, vui lòng liên hệ CEO.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
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
