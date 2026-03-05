import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/app_logger.dart';
import '../../widgets/realtime_notification_widgets.dart';
import '../admin/bug_reports_management_page.dart';

/// Super Admin Main Layout
/// Platform-level administration for managing all companies, users, and system settings
class SuperAdminMainLayout extends ConsumerStatefulWidget {
  const SuperAdminMainLayout({super.key});

  @override
  ConsumerState<SuperAdminMainLayout> createState() => _SuperAdminMainLayoutState();
}

class _SuperAdminMainLayoutState extends ConsumerState<SuperAdminMainLayout> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    _SuperAdminDashboardPage(),
    _CompaniesManagementPage(),
    _UsersManagementPage(),
    BugReportsManagementPage(),
    _SystemSettingsPage(),
    _AuditLogsPage(),
    _SuperAdminProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E2E),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppColors.error, size: 20),
            ),
            AppSpacing.hGapMD,
            const Text(
              'SABOHUB Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // System Health Indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 14),
                AppSpacing.hGapXXS,
                Text('System OK', style: TextStyle(color: AppColors.success, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () => _showSystemNotifications(context),
          ),
          const RealtimeNotificationBell(iconColor: Colors.white70),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.error,
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?.name ?? 'Admin'),
                  subtitle: const Text('Super Admin'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1E1E2E),
        selectedItemColor: AppColors.error,
        unselectedItemColor: AppColors.grey600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report_outlined),
            activeIcon: Icon(Icons.bug_report),
            label: 'Bug Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Audit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showSystemNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            AppSpacing.gapLG,
            _buildNotificationItem(
              icon: Icons.business,
              color: AppColors.info,
              title: 'New company registered',
              subtitle: '2 hours ago',
            ),
            _buildNotificationItem(
              icon: Icons.warning,
              color: AppColors.warning,
              title: 'High CPU usage detected',
              subtitle: '5 hours ago',
            ),
            _buildNotificationItem(
              icon: Icons.check_circle,
              color: AppColors.success,
              title: 'System backup completed',
              subtitle: 'Yesterday',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.grey400)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ============================================================================
// DASHBOARD PAGE
// ============================================================================
class _SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const _SuperAdminDashboardPage();

  @override
  ConsumerState<_SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends ConsumerState<_SuperAdminDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final supabase = SupabaseService().client;
      
      // Get total companies
      final companiesResult = await supabase.from('companies').select('id').count();
      final totalCompanies = companiesResult.count;
      
      // Get total employees
      final employeesResult = await supabase.from('employees').select('id').count();
      final totalEmployees = employeesResult.count;
      
      // Get active sessions (approximation)
      final activeCompanies = await supabase
          .from('companies')
          .select('id')
          .eq('is_active', true)
          .count();
      
      // Get recent activity from analytics_events
      final activityResult = await supabase
          .from('analytics_events')
          .select('event_name, category, created_at')
          .order('created_at', ascending: false)
          .limit(5);
      
      setState(() {
        _stats = {
          'totalCompanies': totalCompanies,
          'totalUsers': totalEmployees,
          'activeCompanies': activeCompanies.count,
          'systemHealth': 98.5,
        };
        _recentActivity = List<Map<String, dynamic>>.from(activityResult);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            AppSpacing.gapXL,
            _buildStatsGrid(),
            AppSpacing.gapXL,
            _buildSystemHealthCard(),
            AppSpacing.gapXL,
            _buildRecentActivityCard(),
            AppSpacing.gapXL,
            _buildQuickActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXL,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.error, AppColors.errorDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              AppSpacing.hGapMD,
              const Text(
                'Platform Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          AppSpacing.gapSM,
          Text(
            'Quản lý toàn bộ hệ thống SABOHUB',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          AppSpacing.gapLG,
          Row(
            children: [
              _buildMiniStat('Companies', '${_stats['totalCompanies'] ?? 0}'),
              const SizedBox(width: 24),
              _buildMiniStat('Users', '${_stats['totalUsers'] ?? 0}'),
              const SizedBox(width: 24),
              _buildMiniStat('Health', '${(_stats['systemHealth'] ?? 0).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.business,
          label: 'Total Companies',
          value: '${_stats['totalCompanies'] ?? 0}',
          color: AppColors.info,
          trend: '+2 this month',
        ),
        _buildStatCard(
          icon: Icons.people,
          label: 'Total Users',
          value: '${_stats['totalUsers'] ?? 0}',
          color: AppColors.success,
          trend: '+15 this week',
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          label: 'Active Companies',
          value: '${_stats['activeCompanies'] ?? 0}',
          color: AppColors.primary,
          trend: '100% active',
        ),
        _buildStatCard(
          icon: Icons.speed,
          label: 'System Health',
          value: '${(_stats['systemHealth'] ?? 0).toStringAsFixed(1)}%',
          color: AppColors.warning,
          trend: 'Excellent',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              Text(trend, style: TextStyle(fontSize: 10, color: AppColors.grey400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.success),
              AppSpacing.hGapSM,
              Text('System Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          AppSpacing.gapLG,
          _buildHealthItem('Database', 99.9, AppColors.success),
          _buildHealthItem('API Server', 98.5, AppColors.success),
          _buildHealthItem('Storage', 85.0, AppColors.warning),
          _buildHealthItem('Authentication', 100.0, AppColors.success),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: TextStyle(color: AppColors.grey700))),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          AppSpacing.hGapMD,
          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppColors.info),
              AppSpacing.hGapSM,
              Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          AppSpacing.gapLG,
          if (_recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: AppSpacing.paddingXL,
                child: Text('Chưa có hoạt động nào', style: TextStyle(color: AppColors.grey500)),
              ),
            )
          else
            ..._recentActivity.map((event) {
              final category = event['category'] ?? '';
              final eventName = event['event_name'] ?? '';
              final createdAt = event['created_at'] != null
                  ? DateTime.tryParse(event['created_at'])
                  : null;
              final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';
              final (icon, color) = _activityIconForCategory(category);
              return _buildActivityItem(eventName, timeAgo, icon, color);
            }),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  (IconData, Color) _activityIconForCategory(String category) {
    return switch (category) {
      'auth' => (Icons.login, AppColors.success),
      'business' => (Icons.business, AppColors.info),
      'page_view' => (Icons.visibility, Colors.indigo),
      'user_action' => (Icons.touch_app, AppColors.warning),
      'error' => (Icons.error, AppColors.error),
      'performance' => (Icons.speed, Colors.purple),
      _ => (Icons.circle, AppColors.grey500),
    };
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: AppSpacing.paddingSM,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                Text(time, style: TextStyle(fontSize: 11, color: AppColors.grey500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.warning),
              AppSpacing.hGapSM,
              Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          AppSpacing.gapLG,
          Row(
            children: [
              Expanded(child: _buildActionButton('Add Company', Icons.add_business, AppColors.info, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm công ty: Chuyển sang tab Companies')),
                );
              })),
              AppSpacing.hGapMD,
              Expanded(child: _buildActionButton('Add User', Icons.person_add, AppColors.success, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm user: Chuyển sang tab Users')),
                );
              })),
            ],
          ),
          AppSpacing.gapMD,
          Row(
            children: [
              Expanded(child: _buildActionButton('System Backup', Icons.backup, AppColors.primary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup: Supabase tự động backup hàng ngày (PITR)')),
                );
              })),
              AppSpacing.hGapMD,
              Expanded(child: _buildActionButton('View Logs', Icons.article, AppColors.warning, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xem logs: Chuyển sang tab Audit Logs')),
                );
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: AppSpacing.paddingVMD,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ============================================================================
// COMPANIES MANAGEMENT PAGE
// ============================================================================
class _CompaniesManagementPage extends ConsumerStatefulWidget {
  const _CompaniesManagementPage();

  @override
  ConsumerState<_CompaniesManagementPage> createState() => _CompaniesManagementPageState();
}

class _CompaniesManagementPageState extends ConsumerState<_CompaniesManagementPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final supabase = SupabaseService().client;
      final result = await supabase
          .from('companies')
          .select('*, employees(count)')
          .order('created_at', ascending: false);
      
      setState(() {
        _companies = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading companies: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;
    return _companies.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header & Search
        Container(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Companies Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCompanyDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLG,
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search companies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
              ),
            ],
          ),
        ),
        // Companies List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadCompanies,
                  child: ListView.builder(
                    padding: AppSpacing.paddingHLG,
                    itemCount: _filteredCompanies.length,
                    itemBuilder: (context, index) {
                      final company = _filteredCompanies[index];
                      return _buildCompanyCard(company);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final isActive = company['is_active'] ?? true;
    final status = isActive ? 'active' : 'inactive';
    final businessType = company['business_type'] ?? 'unknown';
    final employeeCount = company['employees']?[0]?['count'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: AppSpacing.paddingLG,
        leading: CircleAvatar(
          backgroundColor: _getBusinessTypeColor(businessType).withOpacity(0.2),
          child: Icon(
            _getBusinessTypeIcon(businessType),
            color: _getBusinessTypeColor(businessType),
          ),
        ),
        title: Row(
          children: [
            Text(company['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            AppSpacing.hGapSM,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: status == 'active' ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapXXS,
            Text('Type: ${_formatBusinessType(businessType)}', style: TextStyle(color: AppColors.grey600)),
            Text('$employeeCount employees', style: TextStyle(color: AppColors.grey600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditCompanyDialog(context, company);
            } else if (value == 'delete') {
              _confirmDeleteCompany(company);
            } else if (value == 'toggle') {
              _toggleCompanyStatus(company);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(status == 'active' ? Icons.pause : Icons.play_arrow),
                title: Text(status == 'active' ? 'Disable' : 'Enable'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error))),
            ),
          ],
        ),
        onTap: () => _showCompanyDetails(company),
      ),
    );
  }

  IconData _getBusinessTypeIcon(String type) {
    switch (type) {
      case 'billiards': return Icons.sports_bar;
      case 'distribution': return Icons.local_shipping;
      case 'manufacturing': return Icons.factory;
      case 'fnb': return Icons.restaurant;
      default: return Icons.business;
    }
  }

  Color _getBusinessTypeColor(String type) {
    switch (type) {
      case 'billiards': return AppColors.info;
      case 'distribution': return AppColors.success;
      case 'manufacturing': return Colors.purple;
      case 'fnb': return AppColors.warning;
      default: return AppColors.grey500;
    }
  }

  String _formatBusinessType(String type) {
    switch (type) {
      case 'billiards': return 'Billiards';
      case 'distribution': return 'Distribution';
      case 'manufacturing': return 'Manufacturing';
      case 'fnb': return 'F&B';
      default: return type;
    }
  }

  void _showAddCompanyDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'billiards';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
            ),
            AppSpacing.gapLG,
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Business Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'billiards', child: Text('Billiards')),
                DropdownMenuItem(value: 'distribution', child: Text('Distribution')),
                DropdownMenuItem(value: 'manufacturing', child: Text('Manufacturing')),
                DropdownMenuItem(value: 'fnb', child: Text('F&B')),
              ],
              onChanged: (value) => selectedType = value!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await SupabaseService().client.from('companies').insert({
                  'name': nameController.text,
                  'business_type': selectedType,
                  'is_active': true,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCompanies();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(BuildContext context, Map<String, dynamic> company) {
    final nameController = TextEditingController(text: company['name']);
    String selectedType = company['business_type'] ?? 'billiards';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
            ),
            AppSpacing.gapLG,
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Business Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'billiards', child: Text('Billiards')),
                DropdownMenuItem(value: 'distribution', child: Text('Distribution')),
                DropdownMenuItem(value: 'manufacturing', child: Text('Manufacturing')),
                DropdownMenuItem(value: 'fnb', child: Text('F&B')),
              ],
              onChanged: (value) => selectedType = value!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await SupabaseService().client.from('companies').update({
                  'name': nameController.text,
                  'business_type': selectedType,
                }).eq('id', company['id']);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCompanies();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompany(Map<String, dynamic> company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete "${company['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Soft delete - sets is_active=false
              await SupabaseService().client.from('companies').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', company['id']);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadCompanies();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleCompanyStatus(Map<String, dynamic> company) async {
    final currentActive = company['is_active'] ?? true;
    await SupabaseService().client.from('companies').update({'is_active': !currentActive}).eq('id', company['id']);
    _loadCompanies();
  }

  void _showCompanyDetails(Map<String, dynamic> company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: AppSpacing.paddingXL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              AppSpacing.gapXL,
              Text(company['name'] ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              AppSpacing.gapSM,
              Text('ID: ${company['id']}', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
              AppSpacing.gapXL,
              _buildDetailRow('Business Type', _formatBusinessType(company['business_type'] ?? '')),
              _buildDetailRow('Status', (company['status'] ?? 'active').toUpperCase()),
              _buildDetailRow('Created', company['created_at']?.toString().substring(0, 10) ?? 'N/A'),
              AppSpacing.gapXL,
              const Text('Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              AppSpacing.gapSM,
              Text('${company['employees']?[0]?['count'] ?? 0} total employees'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.grey600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// USERS MANAGEMENT PAGE
// ============================================================================
class _UsersManagementPage extends ConsumerStatefulWidget {
  const _UsersManagementPage();

  @override
  ConsumerState<_UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<_UsersManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final supabase = SupabaseService().client;
      final result = await supabase
          .from('employees')
          .select('*, companies(name, business_type)')
          .order('created_at', ascending: false);
      
      setState(() {
        _users = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? u['username'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_roleFilter != 'all') {
      filtered = filtered.where((u) => (u['role'] ?? '').toString().toLowerCase() == _roleFilter).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Users Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(context),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                  ),
                ],
              ),
              AppSpacing.gapLG,
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
              ),
              AppSpacing.gapMD,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('CEO', 'ceo'),
                    _buildFilterChip('Manager', 'manager'),
                    _buildFilterChip('Staff', 'staff'),
                    _buildFilterChip('Driver', 'driver'),
                    _buildFilterChip('Warehouse', 'warehouse'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: AppSpacing.paddingHLG,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _roleFilter = selected ? value : 'all'),
        selectedColor: AppColors.error.withOpacity(0.2),
        checkmarkColor: AppColors.error,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = (user['role'] ?? 'staff').toString().toUpperCase();
    final companyName = user['companies']?['name'] ?? 'No Company';
    final isActive = user['is_active'] ?? true;
    final status = isActive ? 'active' : 'inactive';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withOpacity(0.2),
          child: Text(
            (user['full_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
            style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            AppSpacing.hGapSM,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(role, style: TextStyle(fontSize: 10, color: _getRoleColor(role), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? user['username'] ?? 'N/A', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
            Text(companyName, style: TextStyle(color: AppColors.grey500, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status == 'active' ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditUserDialog(context, user);
                } else if (value == 'delete') {
                  _confirmDeleteUser(user);
                } else if (value == 'toggle') {
                  _toggleUserStatus(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(status == 'active' ? Icons.block : Icons.check),
                    title: Text(status == 'active' ? 'Disable' : 'Enable'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN': return AppColors.error;
      case 'CEO': return AppColors.info;
      case 'MANAGER': return AppColors.success;
      case 'SHIFT_LEADER': return AppColors.primary;
      case 'STAFF': return AppColors.warning;
      case 'DRIVER': return Color(0xFF0EA5E9);
      case 'WAREHOUSE': return Color(0xFFF97316);
      default: return AppColors.grey500;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    String selectedRole = 'staff';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm nhân viên mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            AppSpacing.gapMD,
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.account_circle),
              ),
            ),
            AppSpacing.gapMD,
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Vai trò',
                prefixIcon: Icon(Icons.badge),
              ),
              items: const [
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'shiftLeader', child: Text('Shift Leader')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'driver', child: Text('Driver')),
                DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
              ],
              onChanged: (v) => selectedRole = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng sử dụng trang Quản lý nhân viên để tạo tài khoản đầy đủ')),
              );
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    String selectedRole = (user['role'] ?? 'staff').toString().toLowerCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            AppSpacing.gapLG,
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ceo', child: Text('CEO')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'driver', child: Text('Driver')),
                DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
              ],
              onChanged: (value) => selectedRole = value!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await SupabaseService().client.from('employees').update({
                  'full_name': nameController.text,
                  'role': selectedRole,
                }).eq('id', user['id']);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadUsers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user['full_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Soft delete - sets is_active=false
              await SupabaseService().client.from('employees').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', user['id']);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) async {
    final currentActive = user['is_active'] ?? true;
    await SupabaseService().client.from('employees').update({'is_active': !currentActive}).eq('id', user['id']);
    _loadUsers();
  }
}

// ============================================================================
// SYSTEM SETTINGS PAGE
// ============================================================================
class _SystemSettingsPage extends ConsumerStatefulWidget {
  const _SystemSettingsPage();

  @override
  ConsumerState<_SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<_SystemSettingsPage> {
  // Local state for feature flags (persist to Supabase when ready)
  bool _aiEnabled = true;
  bool _realtimeEnabled = true;
  bool _multiLangEnabled = false;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          AppSpacing.gapXL,
          
          // General Settings
          _buildSettingsSection(
            'General',
            Icons.settings,
            [
              _buildSettingTile('Platform Name', 'SABOHUB', Icons.edit, () {
                _showInfoSnack('Platform name: SABOHUB (read-only)');
              }),
              _buildSettingTile('Default Language', 'Vietnamese', Icons.language, () {
                _showInfoSnack('Ngôn ngữ mặc định: Tiếng Việt');
              }),
              _buildSettingTile('Time Zone', 'Asia/Ho_Chi_Minh', Icons.access_time, () {
                _showInfoSnack('Múi giờ: UTC+7 (Ho Chi Minh)');
              }),
            ],
          ),
          AppSpacing.gapLG,
          
          // Feature Flags
          _buildSettingsSection(
            'Feature Flags',
            Icons.flag,
            [
              _buildSwitchTile('Enable AI Assistant', _aiEnabled, (v) => setState(() => _aiEnabled = v)),
              _buildSwitchTile('Enable Real-time Tracking', _realtimeEnabled, (v) => setState(() => _realtimeEnabled = v)),
              _buildSwitchTile('Enable Multi-language', _multiLangEnabled, (v) => setState(() => _multiLangEnabled = v)),
              _buildSwitchTile('Maintenance Mode', _maintenanceMode, (v) {
                if (v) {
                  _showConfirmDialog(
                    'Bật Maintenance Mode?',
                    'Toàn bộ user sẽ thấy thông báo bảo trì. Tiếp tục?',
                    () => setState(() => _maintenanceMode = true),
                  );
                } else {
                  setState(() => _maintenanceMode = false);
                }
              }),
            ],
          ),
          AppSpacing.gapLG,
          
          // Security Settings
          _buildSettingsSection(
            'Security',
            Icons.security,
            [
              _buildSettingTile('Session Timeout', '30 minutes', Icons.timer, () {
                _showInfoSnack('Session timeout: 30 phút (mặc định Supabase)');
              }),
              _buildSettingTile('Password Policy', 'Strong (8+ chars)', Icons.lock, () {
                _showInfoSnack('Password: min 8 ký tự, đổi qua change_employee_password RPC');
              }),
              _buildSettingTile('2FA Requirement', 'Optional', Icons.verified_user, () {
                _showInfoSnack('2FA chưa triển khai — employee login qua mã nhân viên');
              }),
            ],
          ),
          AppSpacing.gapLG,
          
          // Backup & Maintenance
          _buildSettingsSection(
            'Backup & Maintenance',
            Icons.backup,
            [
              _buildSettingTile('Auto Backup', 'Supabase manages', Icons.schedule, () {
                _showInfoSnack('Supabase tự động backup hàng ngày (Point-in-Time Recovery)');
              }),
              _buildActionTile('Clear Analytics Events', Icons.clear_all, AppColors.warning, () {
                _showConfirmDialog(
                  'Clear Analytics?',
                  'Xóa toàn bộ analytics_events cũ hơn 30 ngày?',
                  () async {
                    try {
                      final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
                      await supabase.client.from('analytics_events').delete().lt('created_at', cutoff);
                      if (mounted) _showInfoSnack('Đã xóa analytics events cũ hơn 30 ngày');
                    } catch (e) {
                      if (mounted) _showInfoSnack('Lỗi: $e');
                    }
                  },
                );
              }),
            ],
          ),
          AppSpacing.gapLG,
          
          // Danger Zone
          _buildSettingsSection(
            'Danger Zone',
            Icons.warning,
            [
              _buildActionTile('Reset All Settings', Icons.restore, AppColors.warning, () {
                _showConfirmDialog(
                  'Reset Settings?',
                  'Reset tất cả feature flags về mặc định?',
                  () => setState(() {
                    _aiEnabled = true;
                    _realtimeEnabled = true;
                    _multiLangEnabled = false;
                    _maintenanceMode = false;
                  }),
                );
              }),
            ],
            isDanger: true,
          ),
        ],
      ),
    );
  }

  void _showInfoSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children, {bool isDanger = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDanger ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingLG,
            child: Row(
              children: [
                Icon(icon, color: isDanger ? AppColors.error : AppColors.info),
                AppSpacing.hGapSM,
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDanger ? AppColors.error : null)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey500),
      title: Text(title),
      subtitle: Text(value, style: TextStyle(color: AppColors.grey600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.success,
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }
}

// ============================================================================
// AUDIT LOGS PAGE — Real data from analytics_events table
// ============================================================================
class _AuditLogsPage extends ConsumerStatefulWidget {
  const _AuditLogsPage();

  @override
  ConsumerState<_AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<_AuditLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      var query = supabase.client
          .from('analytics_events')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      if (_typeFilter != 'all') {
        query = supabase.client
            .from('analytics_events')
            .select('*')
            .eq('category', _typeFilter)
            .order('created_at', ascending: false)
            .limit(50);
      }

      final response = await query;
      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '?';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return timestamp.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: AppSpacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () { setState(() => _isLoading = true); _loadLogs(); },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              AppSpacing.gapSM,
              Text('${_logs.length} events', style: TextStyle(color: AppColors.grey600, fontSize: 13)),
              AppSpacing.gapMD,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Auth', 'auth'),
                    _buildFilterChip('Business', 'business'),
                    _buildFilterChip('Page View', 'page_view'),
                    _buildFilterChip('User Action', 'user_action'),
                    _buildFilterChip('Error', 'error'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 48, color: AppColors.grey300),
                          AppSpacing.gapSM,
                          Text('Chưa có log nào', style: TextStyle(color: AppColors.grey500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _loadLogs();
                      },
                      child: ListView.builder(
                        padding: AppSpacing.paddingHLG,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => _buildLogCard(_logs[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _typeFilter = selected ? value : 'all';
            _isLoading = true;
          });
          _loadLogs();
        },
        selectedColor: AppColors.error.withValues(alpha: 0.2),
        checkmarkColor: AppColors.error,
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final category = log['category']?.toString() ?? 'unknown';
    final eventName = log['event_name']?.toString() ?? 'unknown';
    final userId = log['user_id']?.toString() ?? 'system';
    final createdAt = log['created_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: AppSpacing.paddingSM,
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getLogIcon(category), color: _getCategoryColor(category), size: 20),
        ),
        title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userId, style: TextStyle(color: AppColors.grey600, fontSize: 12)),
            Text(_formatTime(createdAt), style: TextStyle(color: AppColors.grey400, fontSize: 11)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(fontSize: 9, color: _getCategoryColor(category), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'auth': return AppColors.success;
      case 'business': return AppColors.info;
      case 'page_view': return Colors.purple;
      case 'user_action': return AppColors.warning;
      case 'error': return AppColors.error;
      case 'performance': return Colors.teal;
      default: return AppColors.grey500;
    }
  }

  IconData _getLogIcon(String category) {
    switch (category) {
      case 'auth': return Icons.login;
      case 'business': return Icons.business;
      case 'page_view': return Icons.visibility;
      case 'user_action': return Icons.touch_app;
      case 'error': return Icons.error_outline;
      case 'performance': return Icons.speed;
      default: return Icons.info;
    }
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================
class _SuperAdminProfilePage extends ConsumerWidget {
  const _SuperAdminProfilePage();

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingXXL,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.error, AppColors.errorDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ),
                AppSpacing.gapLG,
                Text(
                  user?.name ?? 'Super Admin',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                AppSpacing.gapXXS,
                Text(
                  user?.email ?? 'admin@sabohub.com',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
                AppSpacing.gapSM,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          AppSpacing.gapXL,
          
          // Settings Cards
          _buildSettingsCard('Account Settings', [
            _buildMenuItem(Icons.person, 'Edit Profile', () {
              _showSnack(context, 'Chỉnh sửa profile qua Supabase Dashboard');
            }),
            _buildMenuItem(Icons.lock, 'Change Password', () {
              _showSnack(context, 'Đổi mật khẩu qua change_employee_password RPC');
            }),
            _buildMenuItem(Icons.verified_user, 'Two-Factor Auth', () {
              _showSnack(context, '2FA chưa triển khai — xác thực qua mã nhân viên');
            }),
          ]),
          AppSpacing.gapLG,
          
          _buildSettingsCard('Preferences', [
            _buildMenuItem(Icons.notifications, 'Notifications', () {
              _showSnack(context, 'Cài đặt thông báo: Telegram bot đã tích hợp');
            }),
            _buildMenuItem(Icons.dark_mode, 'Theme', () {
              _showSnack(context, 'Dark mode đang phát triển');
            }),
            _buildMenuItem(Icons.language, 'Language', () {
              _showSnack(context, 'Ngôn ngữ: Tiếng Việt (mặc định)');
            }),
          ]),
          AppSpacing.gapLG,
          
          _buildSettingsCard('Support', [
            _buildMenuItem(Icons.help, 'Help Center', () {
              _showSnack(context, 'Liên hệ admin@sabohub.com để được hỗ trợ');
            }),
            _buildMenuItem(Icons.bug_report, 'Report Bug', () {
              _showSnack(context, 'Báo lỗi qua tab Bug Reports trong sidebar');
            }),
            _buildMenuItem(Icons.info, 'About', () {
              _showSnack(context, 'SABOHUB v1.2.0+16 — Hệ thống quản lý đa ngành');
            }),
          ]),
          AppSpacing.gapXXL,
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: AppSpacing.paddingVLG,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingLG,
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
      onTap: onTap,
    );
  }
}
