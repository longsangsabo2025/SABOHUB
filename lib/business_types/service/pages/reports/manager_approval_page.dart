import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../models/daily_cashflow.dart';
import '../../services/daily_cashflow_service.dart';

/// Manager approval page - Quản lý duyệt báo cáo cuối ngày
class ManagerApprovalPage extends ConsumerStatefulWidget {
  const ManagerApprovalPage({super.key});

  @override
  ConsumerState<ManagerApprovalPage> createState() =>
      _ManagerApprovalPageState();
}

class _ManagerApprovalPageState extends ConsumerState<ManagerApprovalPage>
    with SingleTickerProviderStateMixin {
  final _service = DailyCashflowService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  late TabController _tabController;
  List<DailyCashflow> _pendingReports = [];
  List<DailyCashflow> _approvedReports = [];
  List<DailyCashflow> _rejectedReports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final user = ref.read(currentUserProvider);
    if (user?.companyId == null) return;

    setState(() => _isLoading = true);

    try {
      final pending = await _service.getReportsByStatus(
        companyId: user!.companyId!,
        status: ReportStatus.pending,
      );
      final approved = await _service.getReportsByStatus(
        companyId: user.companyId!,
        status: ReportStatus.approved,
        limit: 20,
      );
      final rejected = await _service.getReportsByStatus(
        companyId: user.companyId!,
        status: ReportStatus.rejected,
        limit: 10,
      );

      setState(() {
        _pendingReports = pending;
        _approvedReports = approved;
        _rejectedReports = rejected;
      });
    } catch (e) {
      _showSnackBar('Lỗi tải dữ liệu: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveReport(DailyCashflow report) async {
    final user = ref.read(currentUserProvider);
    if (user?.id == null) return;

    try {
      await _service.approveReport(
        reportId: report.id,
        approverId: user!.id,
      );
      _showSnackBar('Đã duyệt báo cáo');
      _loadReports();
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  Future<void> _rejectReport(DailyCashflow report, String reason) async {
    final user = ref.read(currentUserProvider);
    if (user?.id == null) return;

    try {
      await _service.rejectReport(
        reportId: report.id,
        approverId: user!.id,
        reason: reason,
      );
      _showSnackBar('Đã từ chối báo cáo');
      _loadReports();
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
      appBar: AppBar(
        title: const Text('Duyệt báo cáo doanh thu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _pendingReports.isNotEmpty,
                label: Text('${_pendingReports.length}'),
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Chờ duyệt',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _approvedReports.isNotEmpty,
                label: Text('${_approvedReports.length}'),
                child: const Icon(Icons.check_circle),
              ),
              text: 'Đã duyệt',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _rejectedReports.isNotEmpty,
                label: Text('${_rejectedReports.length}'),
                child: const Icon(Icons.cancel),
              ),
              text: 'Từ chối',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildApprovedTab(),
                _buildRejectedTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingReports.isEmpty) {
      return _buildEmptyState('Không có báo cáo chờ duyệt', Icons.inbox);
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReports.length,
        itemBuilder: (context, index) {
          return _buildPendingCard(_pendingReports[index]);
        },
      ),
    );
  }

  Widget _buildApprovedTab() {
    if (_approvedReports.isEmpty) {
      return _buildEmptyState('Chưa có báo cáo được duyệt', Icons.check_circle_outline);
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedReports.length,
        itemBuilder: (context, index) {
          return _buildApprovedCard(_approvedReports[index]);
        },
      ),
    );
  }

  Widget _buildRejectedTab() {
    if (_rejectedReports.isEmpty) {
      return _buildEmptyState('Không có báo cáo bị từ chối', Icons.cancel_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rejectedReports.length,
        itemBuilder: (context, index) {
          return _buildRejectedCard(_rejectedReports[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(DailyCashflow report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(report, Colors.orange),
            const Divider(height: 24),
            _buildRevenueBreakdown(report),
            const SizedBox(height: 16),
            _buildTotalRow(report),
            if (report.reviewedBy != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.indigo.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Đã được tổ trưởng xác nhận',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(report),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveReport(report),
                    icon: const Icon(Icons.check),
                    label: Text('Duyệt'),
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

  Widget _buildApprovedCard(DailyCashflow report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check, color: Colors.green.shade700),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(report.reportDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_currencyFormat.format(report.totalRevenue)),
        trailing: report.approvedAt != null
            ? Text(
                DateFormat('HH:mm').format(report.approvedAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            : null,
      ),
    );
  }

  Widget _buildRejectedCard(DailyCashflow report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.close, color: Colors.red.shade700),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(report.reportDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_currencyFormat.format(report.totalRevenue)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lý do từ chối:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  report.rejectionReason ?? 'Không có lý do',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader(DailyCashflow report, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long, color: color),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(DailyCashflow report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAmountChip('Tiền mặt', report.cashAmount, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAmountChip('Chuyển khoản', report.transferAmount, Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAmountChip('Thẻ', report.cardAmount, Colors.purple),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAmountChip('Ví điện tử', report.ewalletAmount, Colors.pink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  _currencyFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(DailyCashflow report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              const Text(
                'Tổng doanh thu',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            _currencyFormat.format(report.totalRevenue),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(DailyCashflow report) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Báo cáo ngày ${DateFormat('dd/MM/yyyy').format(report.reportDate)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                _showSnackBar('Vui lòng nhập lý do', isError: true);
                return;
              }
              Navigator.pop(ctx);
              _rejectReport(report, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
