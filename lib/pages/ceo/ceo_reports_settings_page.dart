import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_logger.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// CEO Reports Page — Real aggregated data from Supabase
class CEOReportsPage extends ConsumerStatefulWidget {
  const CEOReportsPage({super.key});

  @override
  ConsumerState<CEOReportsPage> createState() => _CEOReportsPageState();
}

class _CEOReportsPageState extends ConsumerState<CEOReportsPage> {
  String _selectedReportType = 'financial';
  bool _isLoading = true;
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Real aggregated data
  Map<String, dynamic> _financialData = {};
  Map<String, dynamic> _operationsData = {};
  Map<String, dynamic> _hrData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final supabase = Supabase.instance.client;

      // Get company IDs for this CEO
      final companies = await supabase
          .from('companies')
          .select('id, name')
          .eq('owner_id', user.id)
          .limit(50);
      final companyIds =
          (companies as List).map((c) => c['id'] as String).toList();

      if (companyIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final thisMonthStr = thisMonthStart.toIso8601String().split('T')[0];
      final lastMonthStr = lastMonthStart.toIso8601String().split('T')[0];

      // Parallel queries
      final results = await Future.wait([
        // 0. This month orders
        supabase
            .from('sales_orders')
            .select('id, total, status, payment_status')
            .inFilter('company_id', companyIds)
            .gte('order_date', thisMonthStr)
            .limit(1000),
        // 1. Last month orders
        supabase
            .from('sales_orders')
            .select('id, total, status')
            .inFilter('company_id', companyIds)
            .gte('order_date', lastMonthStr)
            .lt('order_date', thisMonthStr)
            .limit(1000),
        // 2. Active employees
        supabase
            .from('employees')
            .select('id, role, branch_id')
            .inFilter('company_id', companyIds)
            .eq('is_active', true)
            .limit(500),
        // 3. Active customers
        supabase
            .from('customers')
            .select('id, total_debt, status')
            .inFilter('company_id', companyIds)
            .eq('status', 'active')
            .limit(1000),
        // 4. This month deliveries
        supabase
            .from('deliveries')
            .select('id, status')
            .inFilter('company_id', companyIds)
            .gte('created_at', thisMonthStr)
            .limit(1000),
        // 5. Branches
        supabase
            .from('branches')
            .select('id')
            .inFilter('company_id', companyIds)
            .eq('is_active', true)
            .limit(100),
        // 6. This month payments
        supabase
            .from('customer_payments')
            .select('id, amount')
            .inFilter('company_id', companyIds)
            .gte('payment_date', thisMonthStr)
            .limit(1000),
      ]);

      final thisMonthOrders = results[0] as List;
      final lastMonthOrders = results[1] as List;
      final employees = results[2] as List;
      final customers = results[3] as List;
      final deliveries = results[4] as List;
      final branches = results[5] as List;
      final payments = results[6] as List;

      // --- FINANCIAL ---
      double thisRevenue = 0;
      double lastRevenue = 0;
      int paidOrders = 0;
      int unpaidOrders = 0;
      for (final o in thisMonthOrders) {
        final total = ((o['total'] ?? 0) as num).toDouble();
        thisRevenue += total;
        if (o['payment_status'] == 'paid') {
          paidOrders++;
        } else {
          unpaidOrders++;
        }
      }
      for (final o in lastMonthOrders) {
        lastRevenue += ((o['total'] ?? 0) as num).toDouble();
      }
      double totalDebt = 0;
      for (final c in customers) {
        totalDebt += ((c['total_debt'] ?? 0) as num).toDouble();
      }
      double totalPayments = 0;
      for (final p in payments) {
        totalPayments += ((p['amount'] ?? 0) as num).toDouble();
      }
      final revenueGrowth = lastRevenue > 0
          ? ((thisRevenue - lastRevenue) / lastRevenue * 100)
          : 0.0;

      _financialData = {
        'thisRevenue': thisRevenue,
        'lastRevenue': lastRevenue,
        'revenueGrowth': revenueGrowth,
        'totalOrders': thisMonthOrders.length,
        'paidOrders': paidOrders,
        'unpaidOrders': unpaidOrders,
        'totalDebt': totalDebt,
        'totalPayments': totalPayments,
      };

      // --- OPERATIONS ---
      int completedDeliveries = 0;
      int pendingDeliveries = 0;
      for (final d in deliveries) {
        if (d['status'] == 'completed') {
          completedDeliveries++;
        } else {
          pendingDeliveries++;
        }
      }
      final deliveryRate = deliveries.isNotEmpty
          ? (completedDeliveries / deliveries.length * 100)
          : 0.0;

      _operationsData = {
        'totalCustomers': customers.length,
        'totalBranches': branches.length,
        'totalDeliveries': deliveries.length,
        'completedDeliveries': completedDeliveries,
        'pendingDeliveries': pendingDeliveries,
        'deliveryRate': deliveryRate,
        'totalOrders': thisMonthOrders.length,
      };

      // --- HR ---
      final roleCount = <String, int>{};
      for (final e in employees) {
        final role = e['role'] as String? ?? 'staff';
        roleCount[role] = (roleCount[role] ?? 0) + 1;
      }

      _hrData = {
        'totalEmployees': employees.length,
        'roleCount': roleCount,
        'totalCompanies': companyIds.length,
      };

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      AppLogger.error('CEO Reports load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact action row replaces nested AppBar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
          child: Row(
            children: [
              Text(
                'Báo cáo tổng hợp',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadReportData();
                },
                icon: Icon(Icons.refresh_rounded,
                    color: Colors.grey.shade600, size: 20),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Tải lại',
              ),
            ],
          ),
        ),
        _buildReportTypeSelector(context),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildReportContent(),
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _buildTypeChip(context, 'financial', 'Tài chính', Icons.attach_money),
          const SizedBox(width: 8),
          _buildTypeChip(context, 'operations', 'Vận hành', Icons.business),
          const SizedBox(width: 8),
          _buildTypeChip(context, 'hr', 'Nhân sự', Icons.people),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type, String label, IconData icon) {
    final isSelected = _selectedReportType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReportType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.warning : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.warning : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade600, size: 20),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'financial':
        return _buildFinancialReport(context);
      case 'operations':
        return _buildOperationsReport(context);
      case 'hr':
        return _buildHRReport(context);
      default:
        return _buildFinancialReport(context);
    }
  }

  // ──────────────── FINANCIAL REPORT ────────────────
  Widget _buildFinancialReport(BuildContext context) {
    final thisRevenue = (_financialData['thisRevenue'] as num?)?.toDouble() ?? 0;
    final lastRevenue = (_financialData['lastRevenue'] as num?)?.toDouble() ?? 0;
    final growth = (_financialData['revenueGrowth'] as num?)?.toDouble() ?? 0;
    final totalOrders = _financialData['totalOrders'] ?? 0;
    final paidOrders = _financialData['paidOrders'] ?? 0;
    final unpaidOrders = _financialData['unpaidOrders'] ?? 0;
    final totalDebt = (_financialData['totalDebt'] as num?)?.toDouble() ?? 0;
    final totalPayments = (_financialData['totalPayments'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Doanh thu tháng ${DateFormat('MM/yyyy').format(DateTime.now())}'),
          _buildStatRow([
            _buildStatCard('Doanh thu', _currencyFmt.format(thisRevenue), AppColors.success,
                subtitle: growth >= 0
                    ? '+${growth.toStringAsFixed(1)}% vs tháng trước'
                    : '${growth.toStringAsFixed(1)}% vs tháng trước',
                subtitleColor: growth >= 0 ? Colors.green : Colors.red),
            _buildStatCard('Tháng trước', _currencyFmt.format(lastRevenue), Colors.grey),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Đơn hàng'),
          _buildStatRow([
            _buildStatCard('Tổng đơn', '$totalOrders', AppColors.info),
            _buildStatCard('Đã thanh toán', '$paidOrders', AppColors.success),
            _buildStatCard('Chưa TT', '$unpaidOrders', AppColors.warning),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Công nợ & Thu tiền'),
          _buildStatRow([
            _buildStatCard('Tổng nợ KH', _currencyFmt.format(totalDebt), AppColors.error),
            _buildStatCard('Đã thu tháng này', _currencyFmt.format(totalPayments), AppColors.success),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────── OPERATIONS REPORT ────────────────
  Widget _buildOperationsReport(BuildContext context) {
    final totalCustomers = _operationsData['totalCustomers'] ?? 0;
    final totalBranches = _operationsData['totalBranches'] ?? 0;
    final totalDeliveries = _operationsData['totalDeliveries'] ?? 0;
    final completedDel = _operationsData['completedDeliveries'] ?? 0;
    final pendingDel = _operationsData['pendingDeliveries'] ?? 0;
    final deliveryRate = (_operationsData['deliveryRate'] as num?)?.toDouble() ?? 0;
    final totalOrders = _operationsData['totalOrders'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Tổng quan vận hành'),
          _buildStatRow([
            _buildStatCard('Khách hàng', '$totalCustomers', AppColors.info),
            _buildStatCard('Chi nhánh', '$totalBranches', AppColors.primary),
            _buildStatCard('Đơn hàng', '$totalOrders', AppColors.warning),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Giao hàng tháng này'),
          _buildStatRow([
            _buildStatCard('Tổng giao', '$totalDeliveries', AppColors.info),
            _buildStatCard('Hoàn thành', '$completedDel', AppColors.success),
            _buildStatCard('Đang xử lý', '$pendingDel', AppColors.warning),
          ]),
          const SizedBox(height: 12),
          _buildProgressBar(context, 'Tỷ lệ giao thành công', deliveryRate, AppColors.success),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────── HR REPORT ────────────────
  Widget _buildHRReport(BuildContext context) {
    final totalEmployees = _hrData['totalEmployees'] ?? 0;
    final roleCount = _hrData['roleCount'] as Map<String, int>? ?? {};
    final totalCompanies = _hrData['totalCompanies'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Tổng quan nhân sự'),
          _buildStatRow([
            _buildStatCard('Tổng NV', '$totalEmployees', AppColors.primary),
            _buildStatCard('Công ty', '$totalCompanies', AppColors.info),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Phân bổ theo vai trò'),
          ...roleCount.entries.map((e) => _buildRoleRow(context, e.key, e.value, totalEmployees)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────── SHARED WIDGETS ────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface87)),
    );
  }

  Widget _buildStatRow(List<Widget> children) {
    return Row(
      children: children
          .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c)))
          .toList(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color,
      {String? subtitle, Color? subtitleColor}) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 10, color: subtitleColor ?? Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, String label, double percent, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${percent.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(BuildContext context, String role, int count, int total) {
    final pct = total > 0 ? (count / total * 100) : 0.0;
    final roleLabels = {
      'ceo': 'CEO',
      'manager': 'Manager',
      'staff': 'Nhân viên',
      'driver': 'Tài xế',
      'warehouse': 'Kho',
      'shiftLeader': 'Trưởng ca',
      'superAdmin': 'Super Admin',
    };
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(roleLabels[role] ?? role,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Text('$count người',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text('${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }
}

/// CEO Settings Page
/// System-wide configuration and preferences
class CEOSettingsPage extends ConsumerWidget {
  const CEOSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProfile(context, ref),
            const SizedBox(height: 24),
            _buildSystemSettings(context),
            const SizedBox(height: 24),
            _buildCompanySettings(context),
            const SizedBox(height: 24),
            _buildSecuritySettings(context),
            const SizedBox(height: 24),
            _buildSupportSection(context, ref),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Cài đặt',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface87,
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, WidgetRef ref) {
    // ✅ Get real user data from authProvider
    final user = ref.watch(currentUserProvider);

    final displayName = user?.name ?? 'CEO';
    final displayEmail = user?.email ?? 'ceo@sabohub.com';
    // final displayRole = user?.role.value ?? 'CEO';

    // Get initials for avatar
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'CEO';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.info, Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản trị viên hệ thống',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang mở trang chỉnh sửa hồ sơ...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings(BuildContext context) {
    return _buildSettingsSection(context, 
      'Cài đặt hệ thống',
      [
        _buildSettingItem(
          context,
          'Ngôn ngữ',
          'Tiếng Việt',
          Icons.language,
          () => _snack(context, 'Ngôn ngữ mặc định: Tiếng Việt'),
        ),
        _buildSettingItem(
          context,
          'Múi giờ',
          'GMT+7 (Hồ Chí Minh)',
          Icons.access_time,
          () => _snack(context, 'Múi giờ: UTC+7 (Ho Chi Minh)'),
        ),
        _buildSettingItem(
          context,
          'Định dạng tiền tệ',
          'VND (₫)',
          Icons.attach_money,
          () => _snack(context, 'Định dạng: VND (₫)'),
        ),
        _buildSettingItem(
          context,
          'Thông báo',
          'Bật',
          Icons.notifications,
          () => _snack(context, 'Telegram bot đã tích hợp — cấu hình trong .env'),
          hasSwitch: true,
        ),
      ],
    );
  }

  Widget _buildCompanySettings(BuildContext context) {
    return _buildSettingsSection(context, 
      'Quản lý công ty',
      [
        _buildSettingItem(
          context,
          'Thêm công ty mới',
          '',
          Icons.add_business,
          () => _snack(context, 'Thêm công ty: Chuyển sang tab Quản lý công ty'),
        ),
        _buildSettingItem(
          context,
          'Cấu hình chung',
          'Áp dụng cho tất cả công ty',
          Icons.settings,
          () => _snack(context, 'Cấu hình chung qua Company Settings mỗi công ty'),
        ),
        _buildSettingItem(
          context,
          'Quyền truy cập',
          'Phân quyền nhân viên',
          Icons.security,
          () => _snack(context, 'Phân quyền qua role (CEO/Manager/Staff/...) khi thêm nhân viên'),
        ),
        _buildSettingItem(
          context,
          'Backup dữ liệu',
          'Tự động hàng ngày',
          Icons.backup,
          () => _snack(context, 'Supabase tự động backup hàng ngày (Point-in-Time Recovery)'),
          hasSwitch: true,
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(BuildContext context) {
    return _buildSettingsSection(context, 
      'Bảo mật',
      [
        _buildSettingItem(
          context,
          'Đổi mật khẩu',
          '',
          Icons.lock,
          () => _snack(context, 'Đổi mật khẩu qua change_employee_password RPC'),
        ),
        _buildSettingItem(
          context,
          'Xác thực 2 bước',
          'Bật',
          Icons.verified_user,
          () => _snack(context, '2FA chưa triển khai — xác thực qua mã nhân viên'),
          hasSwitch: true,
        ),
        _buildSettingItem(
          context,
          'Phiên đăng nhập',
          'Quản lý thiết bị',
          Icons.devices,
          () => _snack(context, 'Session timeout: 30 phút không hoạt động → auto logout'),
        ),
        _buildSettingItem(
          context,
          'Lịch sử hoạt động',
          '',
          Icons.history,
          () => _snack(context, 'Xem analytics_events trong Supabase Dashboard'),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, WidgetRef ref) {
    return _buildSettingsSection(context, 
      'Hỗ trợ',
      [
        _buildSettingItem(
          context,
          'Trung tâm trợ giúp',
          '',
          Icons.help,
          () => _snack(context, 'Liên hệ admin@sabohub.com để được hỗ trợ'),
        ),
        _buildSettingItem(
          context,
          'Liên hệ hỗ trợ',
          '',
          Icons.contact_support,
          () => _snack(context, 'Email: admin@sabohub.com | Telegram: đã tích hợp'),
        ),
        _buildSettingItem(
          context,
          'Về ứng dụng',
          'SABOHUB v1.2.0+16',
          Icons.info,
          () => _snack(context, 'SABOHUB v1.2.0+16 — Hệ thống quản lý đa ngành'),
        ),
        _buildSettingItem(
          context,
          'Đăng xuất',
          '',
          Icons.logout,
          () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Xác nhận đăng xuất'),
                content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã đăng xuất thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/login');
              }
            }
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool hasSwitch = false,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: hasSwitch ? null : onTap,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: hasSwitch
          ? Switch(
              value: true,
              onChanged: (value) {},
              activeThumbColor: AppColors.success,
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
