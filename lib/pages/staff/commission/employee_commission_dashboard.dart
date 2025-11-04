import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commission_summary.dart';
import '../../../models/bill_commission.dart';
import '../../../services/commission_service.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// Employee Commission Dashboard - Nhân viên xem hoa hồng của mình
class EmployeeCommissionDashboard extends ConsumerStatefulWidget {
  const EmployeeCommissionDashboard({super.key});

  @override
  ConsumerState<EmployeeCommissionDashboard> createState() =>
      _EmployeeCommissionDashboardState();
}

class _EmployeeCommissionDashboardState
    extends ConsumerState<EmployeeCommissionDashboard> {
  final _commissionService = CommissionService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'month'; // today, week, month, all

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    setState(() {
      switch (_selectedPeriod) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'all':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).value?.id;

    if (userId == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Hoa Hồng Của Tôi'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'today',
                child: Text('📅 Hôm nay'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('📆 7 ngày qua'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('📊 Tháng này'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('🗓️ Tất cả'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Summary Cards
              FutureBuilder<CommissionSummary>(
                future: _commissionService.getEmployeeCommissionSummary(
                  employeeId: userId,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final summary =
                      snapshot.data ?? CommissionSummary.empty();

                  return _buildSummaryCards(summary);
                },
              ),

              // Commission List
              FutureBuilder<List<BillCommission>>(
                future: _commissionService.getEmployeeCommissions(
                  employeeId: userId,
                  fromDate: _startDate,
                  toDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final commissions = snapshot.data ?? [];

                  if (commissions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Chưa có hoa hồng nào'),
                      ),
                    );
                  }

                  return _buildCommissionList(commissions);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(CommissionSummary summary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '💰 Tổng Hoa Hồng',
                  _currencyFormat.format(summary.totalCommission),
                  Colors.blue,
                  '${summary.totalBills} bill',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  '⏳ Chờ Duyệt',
                  _currencyFormat.format(summary.pendingCommission),
                  Colors.orange,
                  '${summary.pendingBills} bill',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '✅ Đã Duyệt',
                  _currencyFormat.format(summary.approvedCommission),
                  Colors.green,
                  '${summary.approvedBills} bill',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  '💸 Đã Thanh Toán',
                  _currencyFormat.format(summary.paidCommission),
                  Colors.purple,
                  '${summary.paidBills} bill',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<BillCommission> commissions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return _buildCommissionCard(commission);
      },
    );
  }

  Widget _buildCommissionCard(BillCommission commission) {
    final status = CommissionStatus.fromString(commission.status);
    Color statusColor;

    switch (status) {
      case CommissionStatus.pending:
        statusColor = Colors.orange;
        break;
      case CommissionStatus.approved:
        statusColor = Colors.green;
        break;
      case CommissionStatus.rejected:
        statusColor = Colors.red;
        break;
      case CommissionStatus.paid:
        statusColor = Colors.purple;
        break;
    }

    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            status.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          _currencyFormat.format(commission.commissionAmount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${commission.commissionPercentage}% từ ${_currencyFormat.format(commission.baseAmount)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(commission.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
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
      ),
    );
  }
}
