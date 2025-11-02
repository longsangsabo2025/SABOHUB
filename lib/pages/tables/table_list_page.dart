import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TableListPage extends ConsumerStatefulWidget {
  const TableListPage({super.key});

  @override
  ConsumerState<TableListPage> createState() => _TableListPageState();
}

class _TableListPageState extends ConsumerState<TableListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bàn billiards'),
      ),
      body: const Center(
        child: Text('Danh sách bàn đang được phát triển'),
      ),
    );
  }
}
