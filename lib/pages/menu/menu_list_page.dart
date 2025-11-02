import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuListPage extends ConsumerStatefulWidget {
  const MenuListPage({super.key});

  @override
  ConsumerState<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends ConsumerState<MenuListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to add menu item page
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: const Center(
        child: Text('Danh sách thực đơn đang được phát triển'),
      ),
    );
  }
}
