import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../models/daily_cashflow.dart';
import '../../services/daily_cashflow_service.dart';

/// Shift Leader review page - Duyệt báo cáo từ nhân viên
class ShiftLeaderReviewPage extends ConsumerStatefulWidget {
  const ShiftLeaderReviewPage({super.key});

  @override
  ConsumerState<ShiftLeaderReviewPage> createState() =>
      _ShiftLeaderReviewPageState();
}

class _ShiftLeaderReviewPageState extends ConsumerState<ShiftLeaderReviewPage> {
  final _service = DailyCashflowService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<DailyCashflow> _pendingReports = [];
  bool _isLoading = false;
  // ignore: unused_field
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingReports();
  }

  Future<void> _loadPendingReports() async {
    final user = ref.read(currentUserProvider);
    if (user?.companyId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _service.getPendingReports(
        companyId: user!.companyId!,
      );
      setState(() => _pendingReports = reports);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi tải báo cáo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewAndForward(DailyCashflow report) async {
    final user = ref.read(currentUserProvider);
    if (user?.id == null) return;

    try {
      await _service.reviewReport(
        reportId: report.id,
        reviewerId: user!.id,
      );

      _showSnackBar('Đã xác nhận và chuyển cho quản lý duyệt');
      _loadPendingReports();
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingReports,
              child: _pendingReports.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingReports.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(_pendingReports[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Không có báo cáo chờ duyệt',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kéo xuống để làm mới',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(DailyCashflow report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(report.reportDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (report.branchName != null)
                        Text(
                          report.branchName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Chờ duyệt',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Revenue breakdown
            Row(
              children: [
                Expanded(
                  child: _buildAmountItem(
                    'Tiền mặt',
                    report.cashAmount,
                    Icons.money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAmountItem(
                    'Chuyển khoản',
                    report.transferAmount,
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAmountItem(
                    'Thẻ',
                    report.cardAmount,
                    Icons.credit_card,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildAmountItem(
                    'Ví điện tử',
                    report.ewalletAmount,
                    Icons.phone_iphone,
                    Colors.pink,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng doanh thu',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _currencyFormat.format(report.totalRevenue),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            if (report.notes != null && report.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(report),
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewAndForward(report),
                    icon: const Icon(Icons.check),
                    label: Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              _currencyFormat.format(amount),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditDialog(DailyCashflow report) {
    final cashController = TextEditingController(
      text: report.cashAmount.toStringAsFixed(0),
    );
    final transferController = TextEditingController(
      text: report.transferAmount.toStringAsFixed(0),
    );
    final cardController = TextEditingController(
      text: report.cardAmount.toStringAsFixed(0),
    );
    final ewalletController = TextEditingController(
      text: report.ewalletAmount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: report.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa báo cáo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cashController,
                decoration: const InputDecoration(
                  labelText: 'Tiền mặt',
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: transferController,
                decoration: const InputDecoration(
                  labelText: 'Chuyển khoản',
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardController,
                decoration: const InputDecoration(
                  labelText: 'Thẻ',
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ewalletController,
                decoration: const InputDecoration(
                  labelText: 'Ví điện tử',
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final user = ref.read(currentUserProvider);
              if (user?.id == null) return;

              try {
                final cash = double.tryParse(
                      cashController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0;
                final transfer = double.tryParse(
                      transferController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0;
                final card = double.tryParse(
                      cardController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0;
                final ewallet = double.tryParse(
                      ewalletController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0;

                await _service.reviewReport(
                  reportId: report.id,
                  reviewerId: user!.id,
                  cashAmount: cash,
                  transferAmount: transfer,
                  cardAmount: card,
                  ewalletAmount: ewallet,
                  totalRevenue: cash + transfer + card + ewallet,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                _showSnackBar('Đã cập nhật và xác nhận báo cáo');
                _loadPendingReports();
              } catch (e) {
                _showSnackBar('Lỗi: $e', isError: true);
              }
            },
            child: const Text('Lưu & Xác nhận'),
          ),
        ],
      ),
    );
  }
}
