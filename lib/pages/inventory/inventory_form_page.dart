import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class InventoryFormPage extends ConsumerStatefulWidget {
  final InventoryItem? item;

  const InventoryFormPage({super.key, this.item});

  @override
  ConsumerState<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends ConsumerState<InventoryFormPage> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: const Center(
        child: Text('Form thêm/sửa sản phẩm đang được phát triển'),
      ),
    );
  }
}
