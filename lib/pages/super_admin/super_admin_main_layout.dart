import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF1E1E2E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
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
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text('System OK', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
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
              backgroundColor: const Color(0xFFEF4444),
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
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
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
        color: const Color(0xFF1E1E2E),
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
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFFEF4444),
        unselectedItemColor: Colors.grey[600],
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
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.business,
              color: Colors.blue,
              title: 'New company registered',
              subtitle: '2 hours ago',
            ),
            _buildNotificationItem(
              icon: Icons.warning,
              color: Colors.orange,
              title: 'High CPU usage detected',
              subtitle: '5 hours ago',
            ),
            _buildNotificationItem(
              icon: Icons.check_circle,
              color: Colors.green,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
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
      
      setState(() {
        _stats = {
          'totalCompanies': totalCompanies,
          'totalUsers': totalEmployees,
          'activeCompanies': activeCompanies.count,
          'systemHealth': 98.5,
        };
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildSystemHealthCard(),
            const SizedBox(height: 20),
            _buildRecentActivityCard(),
            const SizedBox(height: 20),
            _buildQuickActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 8),
          Text(
            'Quản lý toàn bộ hệ thống SABOHUB',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
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
          color: const Color(0xFF3B82F6),
          trend: '+2 this month',
        ),
        _buildStatCard(
          icon: Icons.people,
          label: 'Total Users',
          value: '${_stats['totalUsers'] ?? 0}',
          color: const Color(0xFF10B981),
          trend: '+15 this week',
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          label: 'Active Companies',
          value: '${_stats['activeCompanies'] ?? 0}',
          color: const Color(0xFF8B5CF6),
          trend: '100% active',
        ),
        _buildStatCard(
          icon: Icons.speed,
          label: 'System Health',
          value: '${(_stats['systemHealth'] ?? 0).toStringAsFixed(1)}%',
          color: const Color(0xFFF59E0B),
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
      padding: const EdgeInsets.all(16),
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
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(trend, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.monitor_heart, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('System Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthItem('Database', 99.9, Colors.green),
          _buildHealthItem('API Server', 98.5, Colors.green),
          _buildHealthItem('Storage', 85.0, Colors.orange),
          _buildHealthItem('Authentication', 100.0, Colors.green),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: TextStyle(color: Colors.grey[700]))),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.history, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem('New company registered: Odori', '2 hours ago', Icons.business, Colors.blue),
          _buildActivityItem('User login: admin@sabohub.com', '3 hours ago', Icons.login, Colors.green),
          _buildActivityItem('System backup completed', '5 hours ago', Icons.backup, Colors.purple),
          _buildActivityItem('Settings updated', 'Yesterday', Icons.settings, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.flash_on, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton('Add Company', Icons.add_business, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton('Add User', Icons.person_add, const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton('System Backup', Icons.backup, const Color(0xFF8B5CF6))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton('View Logs', Icons.article, const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
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
          padding: const EdgeInsets.all(16),
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
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search companies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
        contentPadding: const EdgeInsets.all(16),
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
            const SizedBox(width: 8),
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
                  color: status == 'active' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${_formatBusinessType(businessType)}', style: TextStyle(color: Colors.grey[600])),
            Text('$employeeCount employees', style: TextStyle(color: Colors.grey[600])),
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
              child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
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
      case 'billiards': return Colors.blue;
      case 'distribution': return Colors.green;
      case 'manufacturing': return Colors.purple;
      case 'fnb': return Colors.orange;
      default: return Colors.grey;
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
            const SizedBox(height: 16),
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
                Navigator.pop(context);
                _loadCompanies();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
            const SizedBox(height: 16),
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
                Navigator.pop(context);
                _loadCompanies();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
              await SupabaseService().client.from('companies').delete().eq('id', company['id']);
              Navigator.pop(context);
              _loadCompanies();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(company['name'] ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('ID: ${company['id']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 20),
              _buildDetailRow('Business Type', _formatBusinessType(company['business_type'] ?? '')),
              _buildDetailRow('Status', (company['status'] ?? 'active').toUpperCase()),
              _buildDetailRow('Created', company['created_at']?.toString().substring(0, 10) ?? 'N/A'),
              const SizedBox(height: 20),
              const Text('Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
          Text(label, style: TextStyle(color: Colors.grey[600])),
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
          padding: const EdgeInsets.all(16),
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
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
        selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
        checkmarkColor: const Color(0xFFEF4444),
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
        contentPadding: const EdgeInsets.all(12),
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
            const SizedBox(width: 8),
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
            Text(user['email'] ?? user['username'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(companyName, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status == 'active' ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditUserDialog(context, user);
                else if (value == 'delete') _confirmDeleteUser(user);
                else if (value == 'toggle') _toggleUserStatus(user);
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
                  child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
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
      case 'SUPER_ADMIN': return const Color(0xFFEF4444);
      case 'CEO': return const Color(0xFF3B82F6);
      case 'MANAGER': return const Color(0xFF10B981);
      case 'SHIFT_LEADER': return const Color(0xFF8B5CF6);
      case 'STAFF': return const Color(0xFFF59E0B);
      case 'DRIVER': return const Color(0xFF0EA5E9);
      case 'WAREHOUSE': return const Color(0xFFF97316);
      default: return Colors.grey;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    // Simplified add user dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('Feature coming soon'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
            const SizedBox(height: 16),
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
                Navigator.pop(context);
                _loadUsers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
              await SupabaseService().client.from('employees').delete().eq('id', user['id']);
              Navigator.pop(context);
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
class _SystemSettingsPage extends ConsumerWidget {
  const _SystemSettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // General Settings
          _buildSettingsSection(
            'General',
            Icons.settings,
            [
              _buildSettingTile('Platform Name', 'SABOHUB', Icons.edit, () {}),
              _buildSettingTile('Default Language', 'Vietnamese', Icons.language, () {}),
              _buildSettingTile('Time Zone', 'Asia/Ho_Chi_Minh', Icons.access_time, () {}),
            ],
          ),
          const SizedBox(height: 16),
          
          // Feature Flags
          _buildSettingsSection(
            'Feature Flags',
            Icons.flag,
            [
              _buildSwitchTile('Enable AI Assistant', true, (value) {}),
              _buildSwitchTile('Enable Real-time Tracking', true, (value) {}),
              _buildSwitchTile('Enable Multi-language', false, (value) {}),
              _buildSwitchTile('Maintenance Mode', false, (value) {}),
            ],
          ),
          const SizedBox(height: 16),
          
          // Security Settings
          _buildSettingsSection(
            'Security',
            Icons.security,
            [
              _buildSettingTile('Session Timeout', '30 minutes', Icons.timer, () {}),
              _buildSettingTile('Password Policy', 'Strong', Icons.lock, () {}),
              _buildSettingTile('2FA Requirement', 'Optional', Icons.verified_user, () {}),
            ],
          ),
          const SizedBox(height: 16),
          
          // Backup & Maintenance
          _buildSettingsSection(
            'Backup & Maintenance',
            Icons.backup,
            [
              _buildSettingTile('Auto Backup', 'Daily at 2:00 AM', Icons.schedule, () {}),
              _buildSettingTile('Last Backup', 'Today, 2:00 AM', Icons.history, () {}),
              _buildActionTile('Run Backup Now', Icons.play_arrow, Colors.blue, () {}),
              _buildActionTile('Clear Cache', Icons.clear_all, Colors.orange, () {}),
            ],
          ),
          const SizedBox(height: 16),
          
          // Danger Zone
          _buildSettingsSection(
            'Danger Zone',
            Icons.warning,
            [
              _buildActionTile('Reset All Settings', Icons.restore, Colors.orange, () {}),
              _buildActionTile('Purge All Data', Icons.delete_forever, Colors.red, () {}),
            ],
            isDanger: true,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: isDanger ? Colors.red : const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDanger ? Colors.red : null)),
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
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      subtitle: Text(value, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF10B981),
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
// AUDIT LOGS PAGE
// ============================================================================
class _AuditLogsPage extends ConsumerStatefulWidget {
  const _AuditLogsPage();

  @override
  ConsumerState<_AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<_AuditLogsPage> {
  // Mock audit logs (in real app, fetch from database)
  final List<Map<String, dynamic>> _logs = [
    {'action': 'User Login', 'user': 'admin@sabohub.com', 'time': '10 minutes ago', 'type': 'auth', 'status': 'success'},
    {'action': 'Company Created', 'user': 'admin@sabohub.com', 'time': '2 hours ago', 'type': 'company', 'status': 'success'},
    {'action': 'User Updated', 'user': 'admin@sabohub.com', 'time': '3 hours ago', 'type': 'user', 'status': 'success'},
    {'action': 'Settings Changed', 'user': 'admin@sabohub.com', 'time': '5 hours ago', 'type': 'settings', 'status': 'success'},
    {'action': 'Failed Login Attempt', 'user': 'unknown@test.com', 'time': '6 hours ago', 'type': 'auth', 'status': 'failed'},
    {'action': 'System Backup', 'user': 'system', 'time': 'Yesterday', 'type': 'system', 'status': 'success'},
    {'action': 'Company Deleted', 'user': 'admin@sabohub.com', 'time': 'Yesterday', 'type': 'company', 'status': 'success'},
  ];

  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _typeFilter == 'all' 
        ? _logs 
        : _logs.where((l) => l['type'] == _typeFilter).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Auth', 'auth'),
                    _buildFilterChip('Company', 'company'),
                    _buildFilterChip('User', 'user'),
                    _buildFilterChip('Settings', 'settings'),
                    _buildFilterChip('System', 'system'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              return _buildLogCard(log);
            },
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
        onSelected: (selected) => setState(() => _typeFilter = selected ? value : 'all'),
        selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
        checkmarkColor: const Color(0xFFEF4444),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isSuccess = log['status'] == 'success';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getLogIcon(log['type']),
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log['user'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(log['time'], style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log['status'].toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'auth': return Icons.login;
      case 'company': return Icons.business;
      case 'user': return Icons.person;
      case 'settings': return Icons.settings;
      case 'system': return Icons.computer;
      default: return Icons.info;
    }
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================
class _SuperAdminProfilePage extends ConsumerWidget {
  const _SuperAdminProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Super Admin',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'admin@sabohub.com',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          
          // Settings Cards
          _buildSettingsCard('Account Settings', [
            _buildMenuItem(Icons.person, 'Edit Profile', () {}),
            _buildMenuItem(Icons.lock, 'Change Password', () {}),
            _buildMenuItem(Icons.verified_user, 'Two-Factor Auth', () {}),
          ]),
          const SizedBox(height: 16),
          
          _buildSettingsCard('Preferences', [
            _buildMenuItem(Icons.notifications, 'Notifications', () {}),
            _buildMenuItem(Icons.dark_mode, 'Theme', () {}),
            _buildMenuItem(Icons.language, 'Language', () {}),
          ]),
          const SizedBox(height: 16),
          
          _buildSettingsCard('Support', [
            _buildMenuItem(Icons.help, 'Help Center', () {}),
            _buildMenuItem(Icons.bug_report, 'Report Bug', () {}),
            _buildMenuItem(Icons.info, 'About', () {}),
          ]),
          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
