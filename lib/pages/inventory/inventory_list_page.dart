import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/odori_providers.dart';
import '../../models/inventory_movement.dart';
import 'stock_adjustment_page.dart';

class InventoryListPage extends ConsumerStatefulWidget {
  const InventoryListPage({super.key});

  @override
  ConsumerState<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends ConsumerState<InventoryListPage> {
  String? _filterType;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  InventoryFilters get _currentFilters => InventoryFilters(
    type: _filterType,
  );

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(inventoryMovementsProvider(_currentFilters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tất cả')),
              const PopupMenuItem(value: 'in', child: Text('Nhập kho')),
              const PopupMenuItem(value: 'out', child: Text('Xuất kho')),
              const PopupMenuItem(value: 'adjustment', child: Text('Điều chỉnh')),
            ],
          ),
        ],
      ),
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(inventoryMovementsProvider(_currentFilters)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (movements) {
          if (movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có giao dịch kho nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn + để thêm giao dịch mới',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(inventoryMovementsProvider(_currentFilters));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                return _buildMovementCard(movement);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockAdjustmentPage(),
            ),
          );
          if (result == true) {
            ref.invalidate(inventoryMovementsProvider(_currentFilters));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nhập/Xuất kho'),
      ),
    );
  }

  Widget _buildMovementCard(InventoryMovement movement) {
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (movement.type) {
      case 'in':
        typeIcon = Icons.arrow_downward;
        typeColor = Colors.green;
        typeLabel = 'Nhập kho';
        break;
      case 'out':
        typeIcon = Icons.arrow_upward;
        typeColor = Colors.red;
        typeLabel = 'Xuất kho';
        break;
      case 'adjustment':
        typeIcon = Icons.sync;
        typeColor = Colors.orange;
        typeLabel = 'Điều chỉnh';
        break;
      default:
        typeIcon = Icons.inventory;
        typeColor = Colors.grey;
        typeLabel = movement.type;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        _dateFormat.format(movement.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${movement.type == 'out' ? '-' : '+'}${movement.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (movement.reason != null && movement.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do: ${movement.reason}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
            if (movement.notes != null && movement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      movement.notes!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (movement.referenceNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Ref: ${movement.referenceNumber}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuantityInfo('Trước', movement.beforeQuantity ?? 0),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                _buildQuantityInfo('Sau', movement.afterQuantity ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(String label, int quantity) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          quantity.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
