import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final TableSession session;

  const PaymentPage({super.key, required this.session});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: const Center(
        child: Text('Trang thanh toán đang được phát triển'),
      ),
    );
  }
}
