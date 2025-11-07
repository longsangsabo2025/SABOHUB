import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/table.dart';
import '../../providers/table_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import 'table_form_page.dart';

class TableListPage extends ConsumerStatefulWidget {
  const TableListPage({super.key});

  @override
  ConsumerState<TableListPage> createState() => _TableListPageState();
}

class _TableListPageState extends ConsumerState<TableListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bàn billiards'),
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple.shade900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToTableForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Thêm bàn mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildTableStats(),
              TabBar(
                controller: _tabController,
                labelColor: Colors.purple.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.purple.shade700,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Trống'),
                  Tab(text: 'Đang chơi'),
                  Tab(text: 'Đã đặt'),
                  Tab(text: 'Bảo trì'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTablesTab(),
          _buildTablesByStatusTab(TableStatus.available),
          _buildTablesByStatusTab(TableStatus.occupied),
          _buildTablesByStatusTab(TableStatus.reserved),
          _buildTablesByStatusTab(TableStatus.maintenance),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTableForm(),
        backgroundColor: Colors.purple.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTableStats() {
    final statsAsync = ref.watch(tableStatsProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatChip('Tổng', stats['total'] ?? 0, Colors.blue),
            _buildStatChip('Trống', stats['available'] ?? 0, Colors.green),
            _buildStatChip('Đang chơi', stats['occupied'] ?? 0, Colors.red),
            _buildStatChip('Đã đặt', stats['reserved'] ?? 0, Colors.orange),
          ],
        ),
        loading: () => const SizedBox(height: 40),
        error: (error, stack) => const SizedBox(height: 40),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTablesTab() {
    final tablesAsync = ref.watch(tablesProvider);

    return tablesAsync.when(
      data: (tables) => tables.isEmpty
          ? _buildEmptyState()
          : _buildTableGrid(tables),
      loading: () => const LoadingIndicator(message: 'Đang tải danh sách bàn...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTablesByStatusTab(TableStatus status) {
    final tablesAsync = ref.watch(tablesByStatusProvider(status));

    return tablesAsync.when(
      data: (tables) => tables.isEmpty
          ? _buildEmptyState(status: status)
          : _buildTableGrid(tables),
      loading: () => const LoadingIndicator(message: 'Đang tải danh sách bàn...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTableGrid(List<BilliardsTable> tables) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tablesProvider);
        ref.invalidate(tablesByStatusProvider);
        ref.invalidate(tableStatsProvider);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return _buildTableCard(table);
        },
      ),
    );
  }

  Widget _buildTableCard(BilliardsTable table) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              table.status.color.withOpacity(0.1),
              table.status.color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: table.status.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _showTableActions(table),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Table icon and number
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: table.status.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    table.status.icon,
                    color: table.status.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Table number
                Text(
                  'Bàn ${table.tableNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: table.status.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    table.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Playing time if occupied
                if (table.status == TableStatus.occupied && table.playingDuration != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(table.playingDuration!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({TableStatus? status}) {
    String message;
    String subtitle;
    
    switch (status) {
      case TableStatus.available:
        message = 'Không có bàn trống';
        subtitle = 'Tất cả bàn đều đang được sử dụng';
        break;
      case TableStatus.occupied:
        message = 'Không có bàn đang chơi';
        subtitle = 'Chưa có khách hàng nào đang chơi';
        break;
      case TableStatus.reserved:
        message = 'Không có bàn đã đặt';
        subtitle = 'Chưa có đặt bàn nào';
        break;
      case TableStatus.maintenance:
        message = 'Không có bàn bảo trì';
        subtitle = 'Tất cả bàn đều hoạt động tốt';
        break;
      default:
        message = 'Chưa có bàn nào';
        subtitle = 'Thêm bàn billiards đầu tiên';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status?.icon ?? Icons.table_bar,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          if (status == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToTableForm,
              icon: const Icon(Icons.add),
              label: const Text('Thêm bàn mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(tablesProvider);
              ref.invalidate(tablesByStatusProvider);
              ref.invalidate(tableStatsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _navigateToTableForm([BilliardsTable? table]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableFormPage(table: table),
      ),
    );
  }

  void _showTableActions(BilliardsTable table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bàn ${table.tableNumber}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: table.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                table.status.label,
                style: TextStyle(
                  color: table.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(table),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BilliardsTable table) {
    return Column(
      children: [
        if (table.status == TableStatus.available) ...[
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Bắt đầu chơi',
            color: Colors.green,
            onPressed: () {
              Navigator.of(context).pop();
              _startTableSession(table.id);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.bookmark,
            label: 'Đặt bàn',
            color: Colors.orange,
            onPressed: () {
              Navigator.of(context).pop();
              _updateTableStatus(table.id, TableStatus.reserved);
            },
          ),
        ],
        
        if (table.status == TableStatus.occupied) ...[
          _buildActionButton(
            icon: Icons.stop,
            label: 'Kết thúc',
            color: Colors.red,
            onPressed: () {
              Navigator.of(context).pop();
              _endTableSession(table.id);
            },
          ),
        ],
        
        if (table.status == TableStatus.reserved) ...[
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Bắt đầu chơi',
            color: Colors.green,
            onPressed: () {
              Navigator.of(context).pop();
              _startTableSession(table.id);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.cancel,
            label: 'Hủy đặt bàn',
            color: Colors.blue,
            onPressed: () {
              Navigator.of(context).pop();
              _updateTableStatus(table.id, TableStatus.available);
            },
          ),
        ],
        
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.build,
          label: table.status == TableStatus.maintenance ? 'Hoàn thành bảo trì' : 'Bảo trì',
          color: Colors.purple,
          onPressed: () {
            Navigator.of(context).pop();
            _updateTableStatus(
              table.id, 
              table.status == TableStatus.maintenance 
                  ? TableStatus.available 
                  : TableStatus.maintenance
            );
          },
        ),
        
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Chỉnh sửa',
          color: Colors.blue,
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToTableForm(table);
          },
        ),
        
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: 'Xóa bàn',
          color: Colors.red,
          onPressed: () {
            Navigator.of(context).pop();
            _showDeleteConfirmation(table);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _startTableSession(String tableId) async {
    try {
      final actions = ref.read(tableActionsProvider);
      await actions.startTableSession(tableId: tableId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bắt đầu phiên chơi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endTableSession(String tableId) async {
    try {
      final actions = ref.read(tableActionsProvider);
      await actions.endTableSession(tableId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã kết thúc phiên chơi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTableStatus(String tableId, TableStatus status) async {
    try {
      final actions = ref.read(tableActionsProvider);
      await actions.updateTableStatus(tableId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái bàn thành ${status.label}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BilliardsTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa bàn'),
        content: Text('Bạn có chắc muốn xóa Bàn ${table.tableNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTable(table.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTable(String tableId) async {
    try {
      final actions = ref.read(tableActionsProvider);
      await actions.deleteTable(tableId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bàn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
