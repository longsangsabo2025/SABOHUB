import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_provider.dart';

/// CEO Analytics Page
/// Advanced analytics and insights for all stores
class CEOAnalyticsPage extends ConsumerStatefulWidget {
  const CEOAnalyticsPage({super.key});

  @override
  ConsumerState<CEOAnalyticsPage> createState() => _CEOAnalyticsPageState();
}

class _CEOAnalyticsPageState extends ConsumerState<CEOAnalyticsPage> {
  int _selectedTab = 0;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final periodName = {
          'week': 'tuần này',
          'month': 'tháng này',
          'quarter': 'quý này',
          'year': 'năm này',
        }[selectedPeriod] ??
        'tháng này';

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Phân tích dữ liệu',
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
              SnackBar(
                content: Text('Đang tải xuống báo cáo $periodName...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          },
          icon: const Icon(Icons.file_download, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chia sẻ báo cáo phân tích $periodName'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          },
          icon: const Icon(Icons.share, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          'Tuần này',
          'Tháng này',
          'Quý này',
          'Năm này',
        ].map((period) => _buildPeriodChip(period)).toList(),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final periodMap = {
      'Tuần này': 'week',
      'Tháng này': 'month',
      'Quý này': 'quarter',
      'Năm này': 'year',
    };

    final isSelected = selectedPeriod == periodMap[period];
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedPeriodProvider.notifier).state = periodMap[period]!;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('Doanh thu', 0),
          _buildTab('Khách hàng', 1),
          _buildTab('Hiệu suất', 2),
          _buildTab('So sánh', 3),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color:
                  isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRevenueAnalytics();
      case 1:
        return _buildCustomerAnalytics();
      case 2:
        return _buildPerformanceAnalytics();
      case 3:
        return _buildComparisonAnalytics();
      default:
        return _buildRevenueAnalytics();
    }
  }

  Widget _buildRevenueAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueOverview(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildRevenueByCompany(),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng doanh thu tháng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₫2,547,320,000',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'so với tháng trước',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biểu đồ doanh thu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Biểu đồ doanh thu sẽ được hiển thị ở đây\n(Sử dụng thư viện fl_chart)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCompany() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo công ty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._mockRevenueData
              .map((company) => _buildCompanyRevenueItem(company)),
        ],
      ),
    );
  }

  Widget _buildCompanyRevenueItem(Map<String, dynamic> company) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: company['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              company['icon'],
              color: company['color'],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company['name'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: company['percentage'] / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: company['color'],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                company['revenue'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${company['percentage']}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAnalytics() {
    return const Center(
      child: Text('Phân tích khách hàng'),
    );
  }

  Widget _buildPerformanceAnalytics() {
    return const Center(
      child: Text('Phân tích hiệu suất'),
    );
  }

  Widget _buildComparisonAnalytics() {
    return const Center(
      child: Text('So sánh công ty'),
    );
  }
}

// Mock data
final List<Map<String, dynamic>> _mockRevenueData = [
  {
    'name': 'Khách Sạn SaBo Plaza',
    'revenue': '₫1,050M',
    'percentage': 41,
    'icon': Icons.hotel,
    'color': const Color(0xFFF59E0B),
  },
  {
    'name': 'Nhà Hàng SaBo Central',
    'revenue': '₫850M',
    'percentage': 33,
    'icon': Icons.restaurant,
    'color': const Color(0xFF10B981),
  },
  {
    'name': 'Quán Bida SaBo',
    'revenue': '₫400M',
    'percentage': 16,
    'icon': Icons.sports_bar,
    'color': const Color(0xFF3B82F6),
  },
  {
    'name': 'Cafe SaBo Garden',
    'revenue': '₫247M',
    'percentage': 10,
    'icon': Icons.coffee,
    'color': const Color(0xFF8B5CF6),
  },
];
