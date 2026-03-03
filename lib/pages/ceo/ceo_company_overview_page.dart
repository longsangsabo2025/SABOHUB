import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/company.dart';

/// CEO Company Overview Page — REAL DATA from Supabase
/// Shows all companies owned by the CEO with live stats
class CEOCompanyOverviewPage extends ConsumerStatefulWidget {
  const CEOCompanyOverviewPage({super.key});

  @override
  ConsumerState<CEOCompanyOverviewPage> createState() =>
      _CEOCompanyOverviewPageState();
}

class _CEOCompanyOverviewPageState
    extends ConsumerState<CEOCompanyOverviewPage> {
  String _sortBy = 'revenue';
  String _filterBy = 'all';
  bool _loading = true;
  List<_CompanyStats> _companies = [];
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final client = Supabase.instance.client;

      // Get companies via employee relationships (CEO role)
      final empRecords = await client
          .from('employees')
          .select('company_id')
          .eq('auth_user_id', user.id)
          .eq('is_active', true);

      final companyIds = (empRecords as List)
          .map((e) => e['company_id'] as String)
          .toSet()
          .toList();

      if (companyIds.isEmpty) {
        setState(() {
          _companies = [];
          _loading = false;
        });
        return;
      }

      // Get company details
      final companiesRaw = await client
          .from('companies')
          .select('*')
          .inFilter('id', companyIds)
          .isFilter('deleted_at', null)
          .order('name');

      final companies =
          (companiesRaw as List).map((j) => Company.fromJson(j)).toList();

      // Get stats for each company
      final now = DateTime.now();
      final firstDayOfMonth =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

      final statsList = <_CompanyStats>[];

      for (final company in companies) {
        final results = await Future.wait([
          // Employee count
          client
              .from('employees')
              .select('id')
              .eq('company_id', company.id)
              .eq('is_active', true),
          // Monthly revenue (sales_orders)
          client
              .from('sales_orders')
              .select('total')
              .eq('company_id', company.id)
              .gte('created_at', '${firstDayOfMonth}T00:00:00')
              .inFilter('status', ['completed', 'delivered', 'confirmed']),
          // Customer count
          client
              .from('customers')
              .select('id')
              .eq('company_id', company.id)
              .eq('is_active', true),
        ]);

        final employees = (results[0] as List).length;
        final orders = results[1] as List;
        final customers = (results[2] as List).length;

        double revenue = 0;
        for (final o in orders) {
          revenue += ((o['total'] ?? 0) as num).toDouble();
        }

        statsList.add(_CompanyStats(
          company: company,
          employeeCount: employees,
          customerCount: customers,
          monthlyRevenue: revenue,
          orderCount: orders.length,
        ));
      }

      setState(() {
        _companies = statsList;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading companies: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Quản lý công ty',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadCompanies,
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompanies,
              child: Column(
                children: [
                  _buildFilterBar(),
                  _buildStatsOverview(),
                  Expanded(child: _buildCompanyList()),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildFilterChip('Tất cả', 'all')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip('Hoạt động', 'active')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip('Tạm dừng', 'inactive')),
          const SizedBox(width: 16),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterBy == value;
    return GestureDetector(
      onTap: () => setState(() => _filterBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _sortBy,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort, size: 16),
        isDense: true,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        items: const [
          DropdownMenuItem(value: 'revenue', child: Text('Doanh thu')),
          DropdownMenuItem(value: 'employees', child: Text('Nhân viên')),
          DropdownMenuItem(value: 'customers', child: Text('Khách hàng')),
          DropdownMenuItem(value: 'name', child: Text('Tên')),
        ],
        onChanged: (value) => setState(() => _sortBy = value!),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalRevenue =
        _companies.fold(0.0, (sum, c) => sum + c.monthlyRevenue);
    final totalEmployees =
        _companies.fold(0, (sum, c) => sum + c.employeeCount);
    final totalCustomers =
        _companies.fold(0, (sum, c) => sum + c.customerCount);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Công ty',
              '${_companies.length}',
              Icons.business,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Doanh thu',
              _shortCurrency(totalRevenue),
              Icons.attach_money,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Nhân viên',
              '$totalEmployees',
              Icons.people,
              AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Khách hàng',
              '$totalCustomers',
              Icons.person,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyList() {
    var filtered = _companies.where((c) {
      if (_filterBy == 'all') return true;
      if (_filterBy == 'active') return c.company.status == 'active';
      return c.company.status != 'active';
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'revenue':
          return b.monthlyRevenue.compareTo(a.monthlyRevenue);
        case 'employees':
          return b.employeeCount.compareTo(a.employeeCount);
        case 'customers':
          return b.customerCount.compareTo(a.customerCount);
        case 'name':
          return a.company.name.compareTo(b.company.name);
        default:
          return 0;
      }
    });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _filterBy == 'all'
                  ? 'Chưa có công ty nào'
                  : 'Không có công ty ${_filterBy == 'active' ? 'đang hoạt động' : 'tạm dừng'}',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildCompanyCard(filtered[index]),
    );
  }

  Widget _buildCompanyCard(_CompanyStats stats) {
    final company = stats.company;
    final typeColor = _getTypeColor(company.type.name);
    final typeIcon = _getTypeIcon(company.type.name);
    final isActive = company.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      company.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Hoạt động' : 'Tạm dừng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Doanh thu tháng',
                  _shortCurrency(stats.monthlyRevenue),
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Đơn hàng',
                  '${stats.orderCount}',
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Nhân viên',
                  '${stats.employeeCount}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Khách hàng',
                  '${stats.customerCount}',
                  Icons.person,
                ),
              ),
            ],
          ),
          if (company.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    company.address,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _shortCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return _fmt.format(amount);
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'distribution':
        return AppColors.primary;
      case 'manufacturing':
        return Colors.blue;
      case 'billiards':
        return Colors.purple;
      case 'restaurant':
        return AppColors.success;
      case 'cafe':
        return Colors.brown;
      case 'hotel':
        return AppColors.warning;
      case 'retail':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'distribution':
        return Icons.local_shipping;
      case 'manufacturing':
        return Icons.precision_manufacturing;
      case 'billiards':
        return Icons.sports_bar;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'hotel':
        return Icons.hotel;
      case 'retail':
        return Icons.store;
      default:
        return Icons.business;
    }
  }
}

/// Internal stats model combining Company with live metrics
class _CompanyStats {
  final Company company;
  final int employeeCount;
  final int customerCount;
  final double monthlyRevenue;
  final int orderCount;

  const _CompanyStats({
    required this.company,
    required this.employeeCount,
    required this.customerCount,
    required this.monthlyRevenue,
    required this.orderCount,
  });
}
