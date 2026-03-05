import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

/// Distribution CEO Operations — Warehouse + Delivery overview
class DistributionCEOOperations extends ConsumerStatefulWidget {
  const DistributionCEOOperations({super.key});

  @override
  ConsumerState<DistributionCEOOperations> createState() =>
      _DistributionCEOOperationsState();
}

class _DistributionCEOOperationsState
    extends ConsumerState<DistributionCEOOperations> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final client = Supabase.instance.client;

      // Get company IDs
      final empRecord = await client
          .from('employees')
          .select('company_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      if (empRecord == null) return;

      final companyId = empRecord['company_id'] as String;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final results = await Future.wait([
        // Warehouses
        client
            .from('warehouses')
            .select('id, name, is_active')
            .eq('company_id', companyId),
        // Today's deliveries
        client
            .from('deliveries')
            .select('id, status')
            .eq('company_id', companyId)
            .gte('created_at', '${today}T00:00:00'),
        // Low stock products
        client
            .from('inventory')
            .select('id, quantity, min_quantity')
            .eq('company_id', companyId),
        // Pending packing
        client
            .from('sales_orders')
            .select('id')
            .eq('company_id', companyId)
            .eq('status', 'confirmed'),
      ]);

      final warehouses = results[0] as List;
      final deliveries = results[1] as List;
      final inventory = results[2] as List;
      final pendingPack = results[3] as List;

      // Delivery stats
      int delivering = 0, delivered = 0, pending = 0, failed = 0;
      for (final d in deliveries) {
        switch (d['status'] as String? ?? '') {
          case 'in_progress':
          case 'loading':
            delivering++;
            break;
          case 'completed':
            delivered++;
            break;
          case 'pending':
            pending++;
            break;
          case 'failed':
            failed++;
            break;
        }
      }

      // Low stock count
      int lowStock = 0;
      for (final item in inventory) {
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        final minQty = (item['min_quantity'] as num?)?.toDouble() ?? 0;
        if (minQty > 0 && qty <= minQty) lowStock++;
      }

      setState(() {
        _data = {
          'warehouses': warehouses,
          'delivering': delivering,
          'delivered': delivered,
          'pendingDelivery': pending,
          'failedDelivery': failed,
          'totalDeliveries': deliveries.length,
          'lowStock': lowStock,
          'totalInventory': inventory.length,
          'pendingPacking': pendingPack.length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery section
            const Text('🚚 Giao hàng hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDeliveryStats(),

            const SizedBox(height: 24),

            // Warehouse section
            const Text('🏭 Kho hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildWarehouseStats(),

            const SizedBox(height: 24),

            // Alerts
            if ((_data['lowStock'] as int? ?? 0) > 0 ||
                (_data['failedDelivery'] as int? ?? 0) > 0)
              _buildAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDeliveryStat(
                  'Đang giao', '${_data['delivering'] ?? 0}', AppColors.info,
                  Icons.local_shipping),
              _buildDeliveryStat(
                  'Đã giao', '${_data['delivered'] ?? 0}', AppColors.success,
                  Icons.check_circle),
              _buildDeliveryStat(
                  'Chờ giao', '${_data['pendingDelivery'] ?? 0}',
                  AppColors.warning, Icons.pending),
              _buildDeliveryStat(
                  'Thất bại', '${_data['failedDelivery'] ?? 0}',
                  AppColors.error, Icons.cancel),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _totalDeliveries > 0
                  ? (_data['delivered'] as int? ?? 0) / _totalDeliveries
                  : 0,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_data['delivered'] ?? 0}/${_data['totalDeliveries'] ?? 0} hoàn thành',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  int get _totalDeliveries => _data['totalDeliveries'] as int? ?? 0;

  Widget _buildDeliveryStat(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWarehouseStats() {
    final warehouses = _data['warehouses'] as List? ?? [];
    final activeCount =
        warehouses.where((w) => w['is_active'] == true).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                    'Kho hoạt động', '$activeCount/${warehouses.length}',
                    AppColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoTile(
                    'Sản phẩm', '${_data['totalInventory'] ?? 0}',
                    AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoTile(
                    'Chờ soạn', '${_data['pendingPacking'] ?? 0}',
                    AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text('Cảnh báo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          if ((_data['lowStock'] as int? ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${_data['lowStock']} sản phẩm dưới mức tồn kho tối thiểu',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          if ((_data['failedDelivery'] as int? ?? 0) > 0)
            Text(
              '• ${_data['failedDelivery']} đơn giao thất bại hôm nay',
              style: const TextStyle(fontSize: 13),
            ),
        ],
      ),
    );
  }
}
