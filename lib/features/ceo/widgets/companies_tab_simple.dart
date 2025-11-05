import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/company.dart';
import '../../../pages/ceo/add_company_page.dart';
import '../../../pages/ceo/company_details_page.dart';
import '../../../pages/ceo/quick_add_company_modal.dart';
import '../../../providers/company_provider.dart';

/// Simple Companies Tab Widget for CEO Dashboard
/// Fetches real company data from Supabase database
class CompaniesTab extends ConsumerStatefulWidget {
  const CompaniesTab({super.key});

  @override
  ConsumerState<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends ConsumerState<CompaniesTab> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    // ✅ Fetch real companies from database
    final companiesAsync = ref.watch(companiesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(companiesProvider);
      },
      child: companiesAsync.when(
        data: (companies) => _buildContent(companies),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu công ty...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(companiesProvider);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Company> companies) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildQuickStats(companies),
          const SizedBox(height: 24),
          Expanded(child: _buildCompanyList(companies)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '🏢 Quản lý công ty',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _showAddCompanyOptions(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm công ty'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(List<Company> companies) {
    final totalCompanies = companies.length;
    final activeCompanies = companies.where((c) => c.status == 'active').length;

    // Aggregate stats - note: these are 0 because Company model doesn't fetch them
    // In production, fetch these separately using companyStatsProvider
    final totalEmployees =
        companies.fold<int>(0, (sum, c) => sum + c.employeeCount);
    final totalTables = companies.fold<int>(0, (sum, c) => sum + c.tableCount);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Tổng công ty',
            '$totalCompanies',
            Icons.business,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Đang hoạt động',
            '$activeCompanies',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Nhân viên',
            '$totalEmployees',
            Icons.people,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Bàn/Phòng',
            '$totalTables',
            Icons.table_restaurant,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 160, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyList(List<Company> companies) {
    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có công ty nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm công ty đầu tiên của bạn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildCompanyCard(Company company) {
    final businessTypeInfo = _getBusinessTypeInfo(company.type);
    final statusLabel = company.status == 'active' ? 'Hoạt động' : 'Tạm ngừng';

    return GestureDetector(
      onTap: () {
        // Navigate to Company Details Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyDetailsPage(companyId: company.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Company Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: businessTypeInfo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  businessTypeInfo['icon'],
                  color: businessTypeInfo['color'],
                  size: 32,
                ),
              ),

              const SizedBox(width: 20),

              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(statusLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(businessTypeInfo['icon'],
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          businessTypeInfo['label'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickStat(
                          Icons.people,
                          company.employeeCount.toString(),
                          'Nhân viên',
                        ),
                        const SizedBox(width: 20),
                        _buildQuickStat(
                          Icons.table_restaurant,
                          company.tableCount.toString(),
                          'Bàn',
                        ),
                        const SizedBox(width: 20),
                        _buildQuickStat(
                          Icons.attach_money,
                          _formatRevenue(company.monthlyRevenue),
                          'Doanh thu',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action Menu
              PopupMenuButton(
                onSelected: (action) {
                  // TODO: Handle company actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Xem chi tiết'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Cài đặt'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
        ),
      ), // End Container
    ); // End GestureDetector
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Hoạt động';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showAddCompanyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn cách thêm công ty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Quick Add Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: Colors.orange),
              ),
              title: const Text('⚡ Thêm nhanh'),
              subtitle:
                  const Text('Chọn template có sẵn (Billiards, Café, v.v.)'),
              onTap: () async {
                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const QuickAddCompanyModal(),
                );
                if (result != null) {
                  // ✅ Refresh provider to reload companies from database
                  ref.invalidate(companiesProvider);
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content:
                            Text('✅ Đã thêm ${result['name']} thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),

            const Divider(),

            // Detailed Form Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('📝 Form chi tiết'),
              subtitle: const Text('Nhập đầy đủ thông tin công ty'),
              onTap: () async {
                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCompanyPage(),
                  ),
                );
                if (result == true) {
                  // ✅ Refresh provider to reload companies from database
                  ref.invalidate(companiesProvider);
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã thêm công ty thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Get business type icon and color
  Map<String, dynamic> _getBusinessTypeInfo(dynamic type) {
    final typeStr = type.toString().split('.').last;

    switch (typeStr.toLowerCase()) {
      case 'restaurant':
        return {
          'icon': Icons.restaurant,
          'color': Colors.orange,
          'label': 'Nhà hàng'
        };
      case 'cafe':
        return {
          'icon': Icons.local_cafe,
          'color': Colors.brown,
          'label': 'Quán cà phê'
        };
      case 'billiards':
        return {
          'icon': Icons.sports_baseball,
          'color': Colors.green,
          'label': 'Billiards'
        };
      case 'karaoke':
        return {'icon': Icons.mic, 'color': Colors.purple, 'label': 'Karaoke'};
      default:
        return {
          'icon': Icons.business,
          'color': Colors.blue,
          'label': 'Doanh nghiệp'
        };
    }
  }

  /// Format revenue to display string
  String _formatRevenue(double revenue) {
    if (revenue == 0) return '0₫';
    if (revenue >= 1000000) {
      return '${(revenue / 1000000).toStringAsFixed(0)}M';
    } else if (revenue >= 1000) {
      return '${(revenue / 1000).toStringAsFixed(0)}K';
    }
    return _currencyFormat.format(revenue);
  }
}
