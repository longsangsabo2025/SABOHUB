import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Staff Tables Page
/// Table management for staff - billiards table operations
class StaffTablesPage extends ConsumerStatefulWidget {
  const StaffTablesPage({super.key});

  @override
  ConsumerState<StaffTablesPage> createState() => _StaffTablesPageState();
}

class _StaffTablesPageState extends ConsumerState<StaffTablesPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick table action
        },
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add_circle, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Quản lý bàn',
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
                content: Text('🔄 Làm mới danh sách bàn'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 Thông báo từ bếp'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Hoạt động', 'Trống', 'Bảo trì'];

    return Container(
      margin: const EdgeInsets.all(16),
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
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildActiveTablesTab();
      case 1:
        return _buildEmptyTablesTab();
      case 2:
        return _buildMaintenanceTab();
      default:
        return _buildActiveTablesTab();
    }
  }

  Widget _buildActiveTablesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildActiveTablesList(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Tình trạng bàn hiện tại',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildStatItem('Đang chơi', '12', const Color(0xFF10B981)),
              ),
              Expanded(
                child: _buildStatItem('Trống', '6', const Color(0xFF3B82F6)),
              ),
              Expanded(
                child: _buildStatItem('Bảo trì', '2', const Color(0xFFF59E0B)),
              ),
              Expanded(
                child:
                    _buildStatItem('Tổng cộng', '20', const Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTablesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Bàn đang hoạt động',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(8, (index) {
            final tableNumbers = [
              'Bàn 1',
              'Bàn 3',
              'Bàn 5',
              'Bàn 7',
              'Bàn 8',
              'Bàn 10',
              'Bàn 12',
              'Bàn 15'
            ];
            final customerCounts = [4, 2, 6, 4, 8, 2, 4, 6];
            final durations = [
              '2h 15m',
              '45m',
              '1h 30m',
              '3h 20m',
              '1h 05m',
              '2h 45m',
              '55m',
              '4h 10m'
            ];
            final amounts = [
              '320K',
              '150K',
              '480K',
              '750K',
              '285K',
              '620K',
              '200K',
              '980K'
            ];
            final lastOrders = [
              '10 phút trước',
              '5 phút trước',
              '15 phút trước',
              '2 phút trước',
              '8 phút trước',
              '12 phút trước',
              '3 phút trước',
              '7 phút trước'
            ];

            return _buildActiveTableItem(
              tableNumbers[index],
              customerCounts[index],
              durations[index],
              amounts[index],
              lastOrders[index],
              index == 7, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveTableItem(String tableName, int customerCount,
      String duration, String amount, String lastOrder, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.table_restaurant,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  tableName.split(' ')[1],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$customerCount khách • Chơi $duration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gọi món: $lastOrder',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📋 Xem hóa đơn $tableName'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF3B82F6),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🍽️ Thêm món cho $tableName'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTablesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEmptyTablesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyTablesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Bàn trống - Sẵn sàng phục vụ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(6, (index) {
            final tableNumbers = [
              'Bàn 2',
              'Bàn 4',
              'Bàn 6',
              'Bàn 9',
              'Bàn 11',
              'Bàn 14'
            ];
            final lastCleaned = [
              '10 phút trước',
              '25 phút trước',
              '15 phút trước',
              '5 phút trước',
              '30 phút trước',
              '12 phút trước'
            ];
            final tableTypes = [
              'Pool 8',
              'Pool 9',
              'Snooker',
              'Pool 8',
              'Pool 9',
              'Snooker'
            ];
            final conditions = [
              'Sạch sẽ',
              'Sạch sẽ',
              'Cần dọn',
              'Sạch sẽ',
              'Sạch sẽ',
              'Sạch sẽ'
            ];
            final conditionColors = [
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              const Color(0xFF10B981)
            ];

            return _buildEmptyTableItem(
              tableNumbers[index],
              tableTypes[index],
              conditions[index],
              conditionColors[index],
              lastCleaned[index],
              index == 5, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyTableItem(String tableName, String tableType,
      String condition, Color conditionColor, String lastCleaned, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.table_restaurant_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  tableName.split(' ')[1],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loại: $tableType',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dọn dẹp: $lastCleaned',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: conditionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  condition,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: conditionColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('👥 Xếp khách vào $tableName'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🧹 Dọn dẹp $tableName'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF8B5CF6),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.cleaning_services,
                        size: 14,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMaintenanceList(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Bàn đang bảo trì',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(2, (index) {
            final tableNumbers = ['Bàn 13', 'Bàn 16'];
            final issues = ['Lỗ bóng bị hỏng', 'Nỉ bàn cần thay'];
            final reportedTimes = ['2 giờ trước', '1 ngày trước'];
            final estimatedFix = ['30 phút', '2 giờ'];
            final priorities = ['Cao', 'Trung bình'];
            final priorityColors = [
              const Color(0xFFEF4444),
              const Color(0xFFF59E0B)
            ];

            return _buildMaintenanceItem(
              tableNumbers[index],
              issues[index],
              reportedTimes[index],
              estimatedFix[index],
              priorities[index],
              priorityColors[index],
              index == 1, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(
      String tableName,
      String issue,
      String reportedTime,
      String estimatedFix,
      String priority,
      Color priorityColor,
      bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build,
                  color: priorityColor,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  tableName.split(' ')[1],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vấn đề: $issue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Báo cáo: $reportedTime • Ước tính: $estimatedFix',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📞 Liên hệ bảo trì $tableName'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: priorityColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: priorityColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Liên hệ',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
