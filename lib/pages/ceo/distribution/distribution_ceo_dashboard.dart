import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/ceo_business_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Distribution CEO Dashboard — Morning view
/// Today's pulse + Monthly KPIs + Pending approvals + Receivables aging
class DistributionCEODashboard extends ConsumerWidget {
  const DistributionCEODashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulseAsync = ref.watch(todayBusinessPulseProvider);
    final kpisAsync = ref.watch(realCEOKPIsProvider);
    final approvalsAsync = ref.watch(pendingApprovalsProvider);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayBusinessPulseProvider);
        ref.invalidate(realCEOKPIsProvider);
        ref.invalidate(pendingApprovalsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === TODAY'S PULSE ===
            _buildSectionTitle(context, '📊 Hôm nay', Icons.today),
            const SizedBox(height: 12),
            pulseAsync.when(
              data: (pulse) => _buildTodayPulse(context, pulse, fmt),
              loading: () => _buildLoadingCard(context),
              error: (e, _) => _buildErrorCard('Lỗi tải dữ liệu hôm nay'),
            ),

            const SizedBox(height: 24),

            // === MONTHLY KPIs ===
            _buildSectionTitle(context, '📈 Chỉ số tháng này', Icons.insights),
            const SizedBox(height: 12),
            kpisAsync.when(
              data: (kpis) => _buildMonthlyKPIs(context, kpis, fmt),
              loading: () => _buildLoadingCard(context),
              error: (e, _) => _buildErrorCard('Lỗi tải KPI'),
            ),

            const SizedBox(height: 24),

            // === APPROVAL CENTER ===
            _buildSectionTitle(context, '⏳ Chờ duyệt', Icons.pending_actions),
            const SizedBox(height: 12),
            approvalsAsync.when(
              data: (approvals) => _buildApprovalCenter(context, approvals),
              loading: () => _buildLoadingCard(context),
              error: (e, _) => _buildErrorCard('Lỗi tải phê duyệt'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayPulse(BuildContext context, TodayPulse pulse, NumberFormat fmt) {
    return Column(
      children: [
        // Revenue highlight
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.successDark, AppColors.success],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doanh thu hôm nay',
                  style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                fmt.format(pulse.todayRevenue),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${pulse.ordersCreated} đơn • ${pulse.completedOrders} hoàn thành • ${pulse.pendingOrders} chờ',
                style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Quick stats grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(context,
                'Giao hàng',
                '${pulse.deliveredCount}/${pulse.deliveredCount + pulse.deliveringCount}',
                Icons.local_shipping,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(context,
                'Thu tiền',
                fmt.format(pulse.paymentsCollected),
                Icons.payments,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(context,
                'KH mới',
                '${pulse.newCustomers}',
                Icons.person_add,
                AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyKPIs(BuildContext context, CEOKPIs kpis, NumberFormat fmt) {
    final growthColor = kpis.revenueGrowth >= 0 ? AppColors.success : AppColors.error;
    final growthIcon =
        kpis.revenueGrowth >= 0 ? Icons.trending_up : Icons.trending_down;

    return Column(
      children: [
        // Revenue + Growth
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doanh thu tháng',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(fmt.format(kpis.monthlyRevenue),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(growthIcon, size: 14, color: growthColor),
                    const SizedBox(width: 4),
                    Text(
                      '${kpis.revenueGrowth >= 0 ? '+' : ''}${kpis.revenueGrowth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: growthColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Detail KPIs
        Row(
          children: [
            Expanded(
                child: _buildKPITile(context,
                    'Lợi nhuận gộp', fmt.format(kpis.grossProfit),
                    subtitle: '${kpis.grossMargin.toStringAsFixed(1)}% margin')),
            const SizedBox(width: 8),
            Expanded(
                child: _buildKPITile(context,
                    'Công nợ', fmt.format(kpis.totalOutstanding),
                    isAlert: kpis.totalOutstanding > 0)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildKPITile(context,
                    'Nhân viên', '${kpis.totalEmployees}')),
            const SizedBox(width: 8),
            Expanded(
                child: _buildKPITile(context,
                    'Khách hàng', '${kpis.totalCustomers}')),
            const SizedBox(width: 8),
            Expanded(
                child: _buildKPITile(context,
                    'Đơn hoàn thành', '${kpis.completedOrdersThisMonth}')),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovalCenter(BuildContext context, PendingApprovals approvals) {
    if (approvals.totalPending == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Không có mục nào chờ duyệt',
                style: TextStyle(color: AppColors.success)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          if (approvals.pendingOrders.isNotEmpty)
            _buildApprovalRow(
              Icons.receipt_long,
              '${approvals.pendingOrders.length} đơn hàng chờ duyệt',
              AppColors.warning,
            ),
          if (approvals.pendingTaskApprovals.isNotEmpty)
            _buildApprovalRow(
              Icons.task,
              '${approvals.pendingTaskApprovals.length} task chờ duyệt',
              AppColors.info,
            ),
          if (approvals.pendingApprovalRequests.isNotEmpty)
            _buildApprovalRow(
              Icons.approval,
              '${approvals.pendingApprovalRequests.length} yêu cầu chờ duyệt',
              AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(text,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildKPITile(BuildContext context, String label, String value,
      {String? subtitle, bool isAlert = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert
            ? AppColors.warning.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Text(msg, style: const TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }
}
