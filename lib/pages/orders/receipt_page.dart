import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class ReceiptPage extends ConsumerWidget {
  final Receipt receipt;

  const ReceiptPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
      ),
      body: const Center(
        child: Text('Trang hóa đơn đang được phát triển'),
      ),
    );
  }
}
