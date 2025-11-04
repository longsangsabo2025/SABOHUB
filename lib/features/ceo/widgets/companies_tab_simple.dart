import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pages/ceo/add_company_page.dart';
import '../../../pages/ceo/quick_add_company_modal.dart';

/// Simple Companies Tab Widget for CEO Dashboard
/// Placeholder for company management functionality
class CompaniesTab extends ConsumerStatefulWidget {
  const CompaniesTab({super.key});

  @override
  ConsumerState<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends ConsumerState<CompaniesTab> {
  List<Map<String, dynamic>> companies = [
    {
      'name': 'Nhà hàng Sabo HCM',
      'type': 'Restaurant',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'address': '123 Nguyễn Huệ, Q.1, TP.HCM',
      'employees': 15,
      'tables': 25,
      'status': 'Hoạt động',
      'revenue': '125M'
    },
    {
      'name': 'Cafe Sabo Hà Nội',
      'type': 'Cafe',
      'icon': Icons.local_cafe,
      'color': Colors.brown,
      'address': '456 Hoàn Kiếm, Hà Nội',
      'employees': 10,
      'tables': 23,
      'status': 'Hoạt động', 
      'revenue': '89M'
    },
  ];

  void _addNewCompany(Map<String, dynamic> newCompany) {
    setState(() {
      companies.add(newCompany);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          Expanded(child: _buildCompanyList()),
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

  Widget _buildQuickStats() {
    final totalCompanies = companies.length;
    final activeCompanies = companies.where((c) => c['status'] == 'Hoạt động').length;
    final totalEmployees = companies.fold<int>(0, (sum, c) => sum + (c['employees'] as int? ?? 0));
    final totalTables = companies.fold<int>(0, (sum, c) => sum + (c['tables'] as int? ?? 0));
    
    return Row(
      children: [
        _buildStatCard(
          'Tổng công ty',
          '$totalCompanies',
          Icons.business,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Đang hoạt động',
          '$activeCompanies',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Nhân viên',
          '$totalEmployees',
          Icons.people,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Bàn/Phòng',
          '$totalTables',
          Icons.table_restaurant,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
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

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                color: (company['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                company['icon'] as IconData,
                color: company['color'] as Color,
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
                          company['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(company['status'] as String),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(company['icon'] as IconData, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        company['type'] as String,
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
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          company['address'] as String,
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
                        company['employees'].toString(),
                        'Nhân viên',
                      ),
                      const SizedBox(width: 20),
                      _buildQuickStat(
                        Icons.table_restaurant,
                        company['tables'].toString(),
                        'Bàn',
                      ),
                      const SizedBox(width: 20),
                      _buildQuickStat(
                        Icons.attach_money,
                        company['revenue'] as String,
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
    );
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: Colors.orange),
              ),
              title: const Text('⚡ Thêm nhanh'),
              subtitle: const Text('Chọn template có sẵn (Billiards, Café, v.v.)'),
              onTap: () async {
                Navigator.pop(context);
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const QuickAddCompanyModal(),
                );
                if (result != null) {
                  _addNewCompany(result);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã thêm ${result['name']} thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            
            const Divider(),
            
            // Detailed Form Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('📝 Form chi tiết'),
              subtitle: const Text('Nhập đầy đủ thông tin công ty'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCompanyPage(),
                  ),
                );
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã thêm công ty thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}