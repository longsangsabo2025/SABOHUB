import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/bill.dart';
import '../../../services/bill_service.dart';
import '../../../services/commission_service.dart';
import '../../../providers/auth_provider.dart';
import '../../manager/commission/manager_upload_bill_page.dart';

/// Bills Management Page - CEO/Manager xem và quản lý bills
class BillsManagementPage extends ConsumerStatefulWidget {
  const BillsManagementPage({super.key});

  @override
  ConsumerState<BillsManagementPage> createState() =>
      _BillsManagementPageState();
}

class _BillsManagementPageState extends ConsumerState<BillsManagementPage> {
  final _billService = BillService();
  final _commissionService = CommissionService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  String? _statusFilter;

  Future<void> _approveBill(Bill bill, String userId) async {
    try {
      // Approve bill
      await _billService.approveBill(bill.id, userId: userId);

      // Calculate commissions for all employees
      await _commissionService.calculateBillCommissions(billId: bill.id);

      // Approve all commissions
      await _commissionService.approveBillCommissions(bill.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã duyệt bill và tính hoa hồng!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBill(Bill bill, String userId) async {
    try {
      await _billService.rejectBill(bill.id, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Đã từ chối bill'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {}); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid(Bill bill) async {
    try {
      // Mark bill as paid
      await _billService.markAsPaid(bill.id);

      // Mark all commissions as paid
      await _commissionService.markBillCommissionsAsPaid(bill.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💰 Đã đánh dấu là đã thanh toán!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final companyId = user.user?.companyId;
    final userId = user.user?.id ?? '';
    final userRole = user.user?.role;

    if (companyId == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy company ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Quản Lý Bills'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _statusFilter,
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tất cả'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('⏳ Chờ duyệt'),
              ),
              const PopupMenuItem(
                value: 'approved',
                child: Text('✅ Đã duyệt'),
              ),
              const PopupMenuItem(
                value: 'paid',
                child: Text('💰 Đã thanh toán'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('❌ Từ chối'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Bill>>(
        future: _billService.getBillsByCompany(
          companyId: companyId,
          status: _statusFilter,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final bills = snapshot.data ?? [];

          if (bills.isEmpty) {
            return const Center(
              child: Text('Chưa có bill nào'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bill = bills[index];
                return _buildBillCard(bill, userRole?.name, userId);
              },
            ),
          );
        },
      ),
      floatingActionButton: userRole?.name == 'manager' || userRole?.name == 'ceo'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerUploadBillPage(),
                  ),
                );

                if (result == true) {
                  setState(() {}); // Refresh list
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Upload Bill'),
            )
          : null,
    );
  }

  Widget _buildBillCard(Bill bill, String? userRole, String userId) {
    final status = BillStatus.fromString(bill.status);
    Color statusColor;

    switch (status) {
      case BillStatus.pending:
        statusColor = Colors.orange;
        break;
      case BillStatus.approved:
        statusColor = Colors.green;
        break;
      case BillStatus.rejected:
        statusColor = Colors.red;
        break;
      case BillStatus.paid:
        statusColor = Colors.purple;
        break;
    }

    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Text(
            status.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          bill.billNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currencyFormat.format(bill.totalAmount),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: statusColor,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(bill.billDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (bill.storeName != null)
              Text(
                '🏪 ${bill.storeName}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bill.billImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      bill.billImageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (bill.notes != null) ...[
                  Text(
                    '📝 Ghi chú:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.notes!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons for CEO
                if (userRole == 'ceo') ...[
                  if (bill.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveBill(bill, userId),
                            icon: const Icon(Icons.check),
                            label: const Text('Duyệt & Tính HH'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectBill(bill, userId),
                            icon: const Icon(Icons.close),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bill.status == 'approved') ...[
                    ElevatedButton.icon(
                      onPressed: () => _markAsPaid(bill),
                      icon: const Icon(Icons.payments),
                      label: const Text('Đánh dấu đã thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
