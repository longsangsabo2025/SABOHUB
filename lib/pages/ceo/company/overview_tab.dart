import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/company.dart';
import '../../../providers/cached_data_providers.dart';
import '../../../business_types/service/providers/monthly_pnl_provider.dart';
import 'widgets/stat_card.dart';

/// Overview Tab - Hiển thị thông tin tổng quan về công ty
class OverviewTab extends ConsumerWidget {
  final Company company;
  final String companyId;

  const OverviewTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedCompanyStatsProvider(companyId));
    final financialAsync = ref.watch(financialSummaryProvider(companyId));
    final taskStatsAsync = ref.watch(cachedCompanyTaskStatsProvider(companyId));
    final attendanceAsync = ref.watch(cachedAttendanceStatsProvider(
      AttendanceQueryParams(companyId: companyId, date: DateTime.now()),
    ));

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. KPI Cards ──
          _buildSectionHeader('Tổng quan hoạt động', Icons.speed),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _buildStatsCards(stats),
          ),
          // Financial KPIs
          financialAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              if (summary['hasData'] != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildFinancialKPIs(context, summary),
              );
            },
          ),
          const SizedBox(height: 32),

          // ── 2. Tiến độ công việc ──
          _buildSectionHeader('Tiến độ công việc', Icons.assignment),
          const SizedBox(height: 16),
          taskStatsAsync.when(
            loading: () => _buildShimmerCard(context),
            error: (_, __) => _buildEmptyState('Không tải được dữ liệu'),
            data: (stats) => _buildTaskProgress(context, stats),
          ),
          const SizedBox(height: 32),

          // ── 3. Chấm công hôm nay ──
          _buildSectionHeader('Chấm công hôm nay', Icons.access_time),
          const SizedBox(height: 16),
          attendanceAsync.when(
            loading: () => _buildShimmerCard(context),
            error: (_, __) => _buildEmptyState('Không tải được dữ liệu'),
            data: (stats) => _buildAttendanceSnapshot(context, stats),
          ),
          const SizedBox(height: 32),

          // ── 4. Cần xử lý ──
          taskStatsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              final overdue = stats['overdue'] ?? 0;
              final todo = stats['todo'] ?? 0;
              if (overdue == 0 && todo == 0) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Cần xử lý', Icons.warning_amber_rounded),
                  const SizedBox(height: 16),
                  _buildPendingItems(stats),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),

          // ── 5. Thông tin ngân hàng ──
          if (company.bankName != null || company.bankName2 != null) ...[
            _buildSectionHeader('Tài khoản ngân hàng', Icons.account_balance),
            const SizedBox(height: 16),
            _buildBankInfoCard(context, company),
            const SizedBox(height: 32),
          ],

          // ── 6. Thông tin công ty ──
          _buildSectionHeader('Thông tin công ty', Icons.business),
          const SizedBox(height: 16),
          _buildInfoCard(context, company),
          const SizedBox(height: 32),

          // ── 7. Thông tin liên hệ ──
          _buildSectionHeader('Thông tin liên hệ', Icons.contact_phone),
          const SizedBox(height: 16),
          _buildContactCard(context, company),
          const SizedBox(height: 32),

          // ── 8. Thời gian ──
          _buildSectionHeader('Thời gian', Icons.schedule),
          const SizedBox(height: 16),
          _buildTimelineCard(context, company),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // Section Header
  // ══════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // 1. Stats + Financial KPI Cards
  // ══════════════════════════════════════════════════════

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.people,
            label: 'Nhân viên',
            value: '${stats['employeeCount'] ?? 0}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.store,
            label: 'Chi nhánh',
            value: '${stats['branchCount'] ?? 0}',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.table_restaurant,
            label: 'Bàn chơi',
            value: '${stats['tableCount'] ?? 0}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            label: 'Doanh thu/tháng',
            value: _formatCurrency(stats['monthlyRevenue'] ?? 0.0),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialKPIs(BuildContext context, Map<String, dynamic> summary) {
    final netProfit = (summary['latestNetProfit'] as num?)?.toDouble() ?? 0;
    final netMargin = (summary['latestNetMargin'] as num?)?.toDouble() ?? 0;
    final growth = (summary['revenueGrowthPct'] as num?)?.toDouble() ?? 0;
    final isProfitable = summary['isProfitable'] == true;
    final latestMonth = summary['latestMonth'] as String? ?? '';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Chỉ số tài chính — $latestMonth',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKpiTile(
                    label: 'Lợi nhuận ròng',
                    value: _formatCompact(netProfit),
                    icon: isProfitable
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: isProfitable ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiTile(
                    label: 'Biên lợi nhuận',
                    value: '${netMargin.toStringAsFixed(1)}%',
                    icon: netMargin >= 10
                        ? Icons.verified
                        : Icons.info_outline,
                    color: netMargin >= 10 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiTile(
                    label: 'Tăng trưởng',
                    value: '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    icon: growth >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: growth >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 2. Task Progress
  // ══════════════════════════════════════════════════════

  Widget _buildTaskProgress(BuildContext context, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final todo = stats['todo'] ?? 0;
    final inProgress = stats['inProgress'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final overdue = stats['overdue'] ?? 0;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (completed > 0)
                        Expanded(
                          flex: completed,
                          child: Container(color: Colors.green[400]),
                        ),
                      if (inProgress > 0)
                        Expanded(
                          flex: inProgress,
                          child: Container(color: Colors.blue[400]),
                        ),
                      if (todo > 0)
                        Expanded(
                          flex: todo,
                          child: Container(color: Colors.grey[300]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Stats row
            Row(
              children: [
                _buildTaskStat('Tổng', total, Colors.grey[700]!),
                _buildTaskStat('Hoàn thành', completed, Colors.green),
                _buildTaskStat('Đang làm', inProgress, Colors.blue),
                _buildTaskStat('Chờ', todo, Colors.grey),
                if (overdue > 0)
                  _buildTaskStat('Quá hạn', overdue, Colors.red),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              // Completion rate
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Tỉ lệ hoàn thành: ${total > 0 ? (completed * 100 ~/ total) : 0}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (total == 0)
              _buildEmptyState('Chưa có công việc nào'),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStat(String label, int count, Color? color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 3. Attendance Snapshot
  // ══════════════════════════════════════════════════════

  Widget _buildAttendanceSnapshot(BuildContext context, dynamic stats) {
    final int totalEmp = stats.totalEmployees ?? 0;
    final int present = stats.presentCount ?? 0;
    final int late_ = stats.lateCount ?? 0;
    final int absent = stats.absentCount ?? 0;
    final int onLeave = stats.onLeaveCount ?? 0;
    final double rate = stats.attendanceRate ?? 0.0;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (totalEmp > 0) ...[
              // Attendance rate bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: rate / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          rate >= 80
                              ? Colors.green
                              : rate >= 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rate >= 80
                          ? Colors.green[700]
                          : rate >= 60
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Detail chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildAttendanceChip(
                    Icons.check_circle, 'Có mặt', present, Colors.green),
                _buildAttendanceChip(
                    Icons.schedule, 'Đi trễ', late_, Colors.orange),
                _buildAttendanceChip(
                    Icons.cancel, 'Vắng', absent, Colors.red),
                if (onLeave > 0)
                  _buildAttendanceChip(
                      Icons.event_busy, 'Nghỉ phép', onLeave, Colors.blue),
              ],
            ),
            if (totalEmp == 0)
              _buildEmptyState('Chưa có dữ liệu chấm công'),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChip(
      IconData icon, String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 4. Pending Items
  // ══════════════════════════════════════════════════════

  Widget _buildPendingItems(Map<String, int> taskStats) {
    final overdue = taskStats['overdue'] ?? 0;
    final todo = taskStats['todo'] ?? 0;

    return Card(
      elevation: 0,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (overdue > 0)
              _buildPendingRow(
                icon: Icons.error_outline,
                color: Colors.red,
                title: '$overdue công việc quá hạn',
                subtitle: 'Cần xử lý ngay',
              ),
            if (overdue > 0 && todo > 0) const Divider(height: 20),
            if (todo > 0)
              _buildPendingRow(
                icon: Icons.pending_actions,
                color: Colors.orange[700]!,
                title: '$todo công việc đang chờ',
                subtitle: 'Chưa được bắt đầu',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // 5. Bank Info
  // ══════════════════════════════════════════════════════

  Widget _buildBankInfoCard(BuildContext context, Company company) {
    final activeBankNum = company.activeBankAccount;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Primary bank
            if (company.bankName != null) ...[
              _buildBankRow(
                bankName: company.bankName!,
                accountNumber: company.bankAccountNumber ?? '',
                accountName: company.bankAccountName ?? '',
                isActive: activeBankNum == 1,
                index: 1,
              ),
            ],
            // Secondary bank
            if (company.bankName2 != null) ...[
              if (company.bankName != null) const Divider(height: 24),
              _buildBankRow(
                bankName: company.bankName2!,
                accountNumber: company.bankAccountNumber2 ?? '',
                accountName: company.bankAccountName2 ?? '',
                isActive: activeBankNum == 2,
                index: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankRow({
    required String bankName,
    required String accountNumber,
    required String accountName,
    required bool isActive,
    required int index,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              isActive ? Colors.green[50] : Colors.grey[100],
          child: Icon(
            Icons.account_balance,
            color: isActive ? Colors.green[700] : Colors.grey[500],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        'Đang dùng',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                accountNumber.isNotEmpty ? accountNumber : 'Chưa có STK',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
              if (accountName.isNotEmpty)
                Text(
                  accountName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // 6. Company Info (existing)
  // ══════════════════════════════════════════════════════

  Widget _buildInfoCard(BuildContext context, Company company) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.business,
              label: 'Tên công ty',
              value: company.name,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Loại hình',
              value: company.type.label,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Địa chỉ',
              value: company.address.isNotEmpty
                  ? company.address
                  : 'Chưa cập nhật',
            ),
            if (company.phone != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: company.phone!,
              ),
            ],
            if (company.email != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: company.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 7. Contact (existing)
  // ══════════════════════════════════════════════════════

  Widget _buildContactCard(BuildContext context, Company company) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (company.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.phone, color: Colors.green[700]),
                ),
                title: const Text('Gọi điện'),
                subtitle: Text(company.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _launchPhone(context, company.phone!),
                ),
              ),
            if (company.phone != null && company.email != null)
              const Divider(height: 24),
            if (company.email != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.email, color: Colors.blue[700]),
                ),
                title: const Text('Gửi email'),
                subtitle: Text(company.email!),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _launchEmail(context, company.email!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 8. Timeline (existing)
  // ══════════════════════════════════════════════════════

  Widget _buildTimelineCard(BuildContext context, Company company) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo',
              value: company.createdAt != null
                  ? dateFormat.format(company.createdAt!)
                  : 'N/A',
            ),
            if (company.updatedAt != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Cập nhật cuối',
                value: dateFormat.format(company.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // Shared helpers
  // ══════════════════════════════════════════════════════

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String _formatCompact(double amount) {
    if (amount.abs() >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(1)} tỷ';
    } else if (amount.abs() >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(1)} tr';
    } else if (amount.abs() >= 1e3) {
      return '${(amount / 1e3).toStringAsFixed(0)}K';
    }
    return NumberFormat('#,###', 'vi_VN').format(amount);
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gọi $phoneNumber')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi email tới $email')),
      );
    }
  }
}
