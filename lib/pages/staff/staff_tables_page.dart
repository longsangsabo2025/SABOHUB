import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

/// Staff Tables Page — Real Supabase data from `tables` table
/// Shows table status (active/empty/maintenance) for staff operations
class StaffTablesPage extends ConsumerStatefulWidget {
  const StaffTablesPage({super.key});

  @override
  ConsumerState<StaffTablesPage> createState() => _StaffTablesPageState();
}

class _StaffTablesPageState extends ConsumerState<StaffTablesPage> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) {
        if (mounted) setState(() { _isLoading = false; _error = 'Chưa có company'; });
        return;
      }

      final response = await Supabase.instance.client
          .from('tables')
          .select('*')
          .eq('company_id', companyId)
          .order('table_number', ascending: true);

      if (mounted) {
        setState(() {
          _tables = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _activeTables =>
      _tables.where((t) => t['status'] == 'OCCUPIED').toList();

  List<Map<String, dynamic>> get _emptyTables =>
      _tables.where((t) => t['status'] == 'AVAILABLE').toList();

  List<Map<String, dynamic>> get _maintenanceTables =>
      _tables.where((t) => t['status'] == 'MAINTENANCE' || t['status'] == 'OUT_OF_SERVICE').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Quản lý bàn',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTables();
            },
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 8),
                    Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () { setState(() => _isLoading = true); _loadTables(); },
                        child: const Text('Thử lại')),
                  ],
                ))
              : Column(
                  children: [
                    _buildTabBar(),
                    Expanded(child: _buildContent()),
                  ],
                ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      'Hoạt động (${_activeTables.length})',
      'Trống (${_emptyTables.length})',
      'Bảo trì (${_maintenanceTables.length})',
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2)),
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
                  color: isSelected ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
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
        return _buildTableList(_activeTables, 'Bàn đang hoạt động', AppColors.success, Icons.table_restaurant);
      case 1:
        return _buildTableList(_emptyTables, 'Bàn trống - Sẵn sàng', AppColors.info, Icons.table_restaurant_outlined);
      case 2:
        return _buildTableList(_maintenanceTables, 'Bàn đang bảo trì', AppColors.warning, Icons.build);
      default:
        return _buildTableList(_activeTables, 'Bàn đang hoạt động', AppColors.success, Icons.table_restaurant);
    }
  }

  Widget _buildTableList(List<Map<String, dynamic>> tables, String title, Color color, IconData icon) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadTables();
      },
      child: tables.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Không có bàn nào', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  _buildQuickStats(),
                  const SizedBox(height: 16),
                  // Table list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ...tables.asMap().entries.map((e) => _buildTableItem(e.value, color, icon, e.key == tables.length - 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tình trạng bàn hiện tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Đang chơi', '${_activeTables.length}', AppColors.success)),
              Expanded(child: _buildStatItem('Trống', '${_emptyTables.length}', AppColors.info)),
              Expanded(child: _buildStatItem('Bảo trì', '${_maintenanceTables.length}', AppColors.warning)),
              Expanded(child: _buildStatItem('Tổng cộng', '${_tables.length}', const Color(0xFF6B7280))),
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildTableItem(Map<String, dynamic> table, Color color, IconData icon, bool isLast) {
    final tableNum = table['table_number']?.toString() ?? '?';
    final tableType = table['table_type']?.toString() ?? '';
    final hourlyRate = (table['hourly_rate'] as num?)?.toDouble() ?? 0;
    final status = table['status']?.toString() ?? 'AVAILABLE';

    String statusLabel;
    switch (status) {
      case 'OCCUPIED':
        statusLabel = 'Đang chơi';
        break;
      case 'AVAILABLE':
        statusLabel = 'Sẵn sàng';
        break;
      case 'MAINTENANCE':
        statusLabel = 'Bảo trì';
        break;
      case 'OUT_OF_SERVICE':
        statusLabel = 'Ngưng hoạt động';
        break;
      default:
        statusLabel = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(tableNum, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bàn $tableNum', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (tableType.isNotEmpty)
                  Text('Loại: $tableType', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (hourlyRate > 0)
                  Text('${hourlyRate.toInt()}k/giờ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
    );
  }
}
