import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/manufacturing_service.dart';
import '../../models/manufacturing_models.dart';

class PayablesPage extends ConsumerStatefulWidget {
  const PayablesPage({super.key});

  @override
  ConsumerState<PayablesPage> createState() => _PayablesPageState();
}

class _PayablesPageState extends ConsumerState<PayablesPage> {
  final _service = ManufacturingService();
  List<Payable> _payables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayables();
  }

  Future<void> _loadPayables() async {
    setState(() => _loading = true);
    try {
      final payables = await _service.getPayables();
      setState(() {
        _payables = payables;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải công nợ phải trả: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'partial': return Colors.blue;
      case 'paid': return Colors.green;
      case 'overdue': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ thanh toán';
      case 'partial': return 'Trả một phần';
      case 'paid': return 'Đã thanh toán';
      case 'overdue': return 'Quá hạn';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công Nợ Phải Trả'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayables,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payables.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có công nợ phải trả'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payables.length,
                  itemBuilder: (context, index) {
                    final payable = _payables[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(payable.status),
                          child: const Icon(Icons.payment, color: Colors.white),
                        ),
                        title: Text('NCC: ${payable.supplierId}'),
                        subtitle: Text(
                          'PO: ${payable.purchaseOrderId ?? 'N/A'}\n'
                          '${_getStatusText(payable.status)}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${payable.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (payable.paidAmount > 0)
                              Text(
                                'Đã trả: ${payable.paidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ghi nhận thanh toán - Coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
