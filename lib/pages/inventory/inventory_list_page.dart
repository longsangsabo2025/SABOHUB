import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class InventoryListPage extends ConsumerStatefulWidget {
  const InventoryListPage({super.key});

  @override
  ConsumerState<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends ConsumerState<InventoryListPage> {
  @override
  Widget build(BuildContext context) {
    final inventoryItems = <InventoryItem>[]; // TODO: Add getter to AuthState

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kho'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to add inventory item page
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: inventoryItems.isEmpty
          ? const Center(
              child: Text('Chưa có sản phẩm nào trong kho'),
            )
          : ListView.builder(
              itemCount: inventoryItems.length,
              itemBuilder: (context, index) {
                final item = inventoryItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Tồn kho: ${item.quantity} ${item.unit}'),
                  trailing: Text(
                    '${item.unitPrice.toStringAsFixed(0)}đ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // TODO: Navigate to inventory item details
                  },
                );
              },
            ),
    );
  }
}
