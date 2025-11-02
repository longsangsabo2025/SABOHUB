import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CEO Company Overview Page
/// Overview of all companies in the CEO's portfolio
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

  // Mock data for companies
  final List<CompanyData> _companies = [
    CompanyData(
      id: '1',
      name: 'Quán Bida Diamond',
      type: 'Billiards',
      revenue: 125000000,
      profit: 45000000,
      employees: 25,
      customers: 1200,
      status: 'active',
      growth: 12.5,
    ),
    CompanyData(
      id: '2',
      name: 'Nhà Hàng Royal',
      type: 'Restaurant',
      revenue: 85000000,
      profit: 28000000,
      employees: 35,
      customers: 850,
      status: 'active',
      growth: 8.2,
    ),
    CompanyData(
      id: '3',
      name: 'Café Sunrise',
      type: 'Cafe',
      revenue: 45000000,
      profit: 18000000,
      employees: 15,
      customers: 650,
      status: 'active',
      growth: 15.8,
    ),
    CompanyData(
      id: '4',
      name: 'Hotel Paradise',
      type: 'Hotel',
      revenue: 200000000,
      profit: 65000000,
      employees: 80,
      customers: 2500,
      status: 'active',
      growth: 6.7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatsOverview(),
          Expanded(child: _buildCompanyList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new company
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
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
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tìm kiếm trong công ty...'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.search, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Chỉnh sửa công ty'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đang mở trang chỉnh sửa...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Chia sẻ thông tin'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Đang chia sẻ thông tin công ty...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Xuất báo cáo'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang xuất báo cáo...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_vert, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip('Tất cả', 'all'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip('Hoạt động', 'active'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip('Tạm dừng', 'inactive'),
          ),
          const SizedBox(width: 16),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade200,
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
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        items: const [
          DropdownMenuItem(value: 'revenue', child: Text('Doanh thu')),
          DropdownMenuItem(value: 'profit', child: Text('Lợi nhuận')),
          DropdownMenuItem(value: 'growth', child: Text('Tăng trưởng')),
          DropdownMenuItem(value: 'name', child: Text('Tên')),
        ],
        onChanged: (value) {
          setState(() {
            _sortBy = value!;
          });
        },
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng công ty',
              '${_companies.length}',
              Icons.business,
              const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Doanh thu',
              '${(_companies.fold(0.0, (sum, c) => sum + c.revenue) / 1000000).toStringAsFixed(1)}M',
              Icons.attach_money,
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Nhân viên',
              '${_companies.fold(0, (sum, c) => sum + c.employees)}',
              Icons.people,
              const Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Khách hàng',
              '${_companies.fold(0, (sum, c) => sum + c.customers)}',
              Icons.person,
              const Color(0xFFFF9800),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyList() {
    List<CompanyData> filteredCompanies = _companies.where((company) {
      if (_filterBy == 'all') return true;
      return company.status == _filterBy;
    }).toList();

    // Sort companies
    filteredCompanies.sort((a, b) {
      switch (_sortBy) {
        case 'revenue':
          return b.revenue.compareTo(a.revenue);
        case 'profit':
          return b.profit.compareTo(a.profit);
        case 'growth':
          return b.growth.compareTo(a.growth);
        case 'name':
          return a.name.compareTo(b.name);
        default:
          return 0;
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCompanies.length,
      itemBuilder: (context, index) {
        return _buildCompanyCard(filteredCompanies[index]);
      },
    );
  }

  Widget _buildCompanyCard(CompanyData company) {
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
                  color: _getTypeColor(company.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getTypeIcon(company.type),
                  color: _getTypeColor(company.type),
                  size: 24,
                ),
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
                      company.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: company.growth >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${company.growth >= 0 ? '+' : ''}${company.growth.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: company.growth >= 0 ? Colors.green : Colors.red,
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
                  'Doanh thu',
                  '${(company.revenue / 1000000).toStringAsFixed(1)}M',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Lợi nhuận',
                  '${(company.profit / 1000000).toStringAsFixed(1)}M',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Nhân viên',
                  '${company.employees}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Khách hàng',
                  '${company.customers}',
                  Icons.person,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View details
                  },
                  child: const Text('Chi tiết'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Quick actions
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Quản lý'),
                ),
              ),
            ],
          ),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'billiards':
        return const Color(0xFF1976D2);
      case 'restaurant':
        return const Color(0xFF4CAF50);
      case 'cafe':
        return const Color(0xFF9C27B0);
      case 'hotel':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'billiards':
        return Icons.sports_bar;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.business;
    }
  }
}

/// Company Data Model
class CompanyData {
  final String id;
  final String name;
  final String type;
  final double revenue;
  final double profit;
  final int employees;
  final int customers;
  final String status;
  final double growth;

  CompanyData({
    required this.id,
    required this.name,
    required this.type,
    required this.revenue,
    required this.profit,
    required this.employees,
    required this.customers,
    required this.status,
    required this.growth,
  });
}
