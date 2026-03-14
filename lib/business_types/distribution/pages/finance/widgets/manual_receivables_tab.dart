import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../widgets/customer_avatar.dart';

class ManualReceivablesTab extends StatelessWidget {
  const ManualReceivablesTab({
    super.key,
    required this.manualReceivables,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> manualReceivables;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (manualReceivables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Chua co khoan nhap no nao', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: manualReceivables.length,
        itemBuilder: (context, index) {
          final rec = manualReceivables[index];
          final customer = rec['customers'] as Map<String, dynamic>?;
          final original = (rec['original_amount'] as num?)?.toDouble() ?? 0;
          final paid = (rec['paid_amount'] as num?)?.toDouble() ?? 0;
          final remaining = (rec['remaining_amount'] as num?)?.toDouble() ?? (original - paid);
          final status = (rec['status'] ?? '').toString();
          final dueDate = DateTime.tryParse((rec['due_date'] ?? '').toString());
          final createdAt = DateTime.tryParse((rec['created_at'] ?? '').toString());
          final dateLabel = createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal()) : '';
          final dueDateLabel = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate) : 'Khong co han';
          final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && remaining > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rec['invoice_number']?.toString() ?? 'RCV-${rec['id'].toString().substring(0, 8)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CustomerAvatar(seed: customer?['name'] ?? 'K', radius: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?['name']?.toString() ?? 'Khach hang',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${customer?['code'] ?? ''} ${customer?['phone'] != null ? '• ${customer?['phone']}' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _moneyColumn('Gia tri', currencyFormat.format(original), Colors.blue.shade700),
                    ),
                    Expanded(
                      child: _moneyColumn('Da thu', currencyFormat.format(paid), Colors.green.shade700),
                    ),
                    Expanded(
                      child: _moneyColumn(
                        'Con lai',
                        currencyFormat.format(remaining),
                        remaining > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoPill(Icons.event, 'Ngay nhap: $dateLabel'),
                    _infoPill(Icons.schedule, 'Han: $dueDateLabel', color: isOverdue ? Colors.red : Colors.grey.shade700),
                    if ((rec['reference_number'] ?? '').toString().isNotEmpty)
                      _infoPill(Icons.tag, 'Ref: ${rec['reference_number']}'),
                  ],
                ),
                if ((rec['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ghi chu: ${rec['notes']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _moneyColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text, {Color? color}) {
    final fg = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Da thanh toan';
      case 'partial':
        return 'Thanh toan mot phan';
      case 'overdue':
        return 'Qua han';
      case 'open':
        return 'Dang mo';
      default:
        return status.isEmpty ? 'Khong ro' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partial':
        return Colors.amber.shade800;
      case 'overdue':
        return Colors.red.shade700;
      case 'open':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
