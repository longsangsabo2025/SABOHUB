import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ceo_business_provider.dart' show CEOKPIs, realCEOKPIsProvider;

/// Distribution CEO Finance — Receivables, debt aging, payments
class DistributionCEOFinance extends ConsumerStatefulWidget {
  const DistributionCEOFinance({super.key});

  @override
  ConsumerState<DistributionCEOFinance> createState() =>
      _DistributionCEOFinanceState();
}

class _DistributionCEOFinanceState
    extends ConsumerState<DistributionCEOFinance> {
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  bool _loading = true;
  List<Map<String, dynamic>> _agingData = [];
  Map<String, dynamic> _paymentStats = {};

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final client = Supabase.instance.client;
      final empRecord = await client
          .from('employees')
          .select('company_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      if (empRecord == null) return;

      final companyId = empRecord['company_id'] as String;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final firstDayOfMonth =
          DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().year, DateTime.now().month, 1));

      final results = await Future.wait([
        // Receivables aging
        client
            .from('v_receivables_aging')
            .select('*')
            .eq('company_id', companyId),
        // Payments this month
        client
            .from('payments')
            .select('id, amount, status, created_at')
            .eq('company_id', companyId)
            .gte('created_at', '${firstDayOfMonth}T00:00:00'),
        // Today's payments
        client
            .from('payments')
            .select('id, amount')
            .eq('company_id', companyId)
            .eq('status', 'completed')
            .gte('created_at', '${today}T00:00:00'),
      ]);

      final aging = (results[0] as List).cast<Map<String, dynamic>>();
      final monthPayments = results[1] as List;
      final todayPayments = results[2] as List;

      double monthTotal = 0, monthCompleted = 0;
      for (final p in monthPayments) {
        final amount = ((p['amount'] ?? 0) as num).toDouble();
        monthTotal += amount;
        if (p['status'] == 'completed') monthCompleted += amount;
      }

      double todayTotal = 0;
      for (final p in todayPayments) {
        todayTotal += ((p['amount'] ?? 0) as num).toDouble();
      }

      setState(() {
        _agingData = aging;
        _paymentStats = {
          'todayCollected': todayTotal,
          'monthTotal': monthTotal,
          'monthCompleted': monthCompleted,
          'monthCount': monthPayments.length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(realCEOKPIsProvider);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(realCEOKPIsProvider);
        await _loadFinanceData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI summary
            const Text('💰 Tài chính tổng quan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            kpisAsync.when(
              data: (kpis) => _buildFinanceSummary(kpis),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => const Text('Lỗi'),
            ),

            const SizedBox(height: 24),

            // Payments
            const Text('💳 Thu tiền',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentStats(),

            const SizedBox(height: 24),

            // Receivables aging
            const Text('📋 Công nợ phải thu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildAgingTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSummary(CEOKPIs kpis) {
    return Row(
      children: [
        Expanded(
          child: _buildFinanceCard(
            'Doanh thu',
            fmt.format(kpis.monthlyRevenue),
            AppColors.success,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFinanceCard(
            'Lợi nhuận gộp',
            fmt.format(kpis.grossProfit),
            AppColors.primary,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFinanceCard(
            'Công nợ',
            fmt.format(kpis.totalOutstanding),
            kpis.totalOutstanding > 0 ? AppColors.error : AppColors.success,
            Icons.receipt_long,
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPaymentStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text('Hôm nay:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                fmt.format(_paymentStats['todayCollected'] ?? 0),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text('Tháng này:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                fmt.format(_paymentStats['monthCompleted'] ?? 0),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_paymentStats['monthCount'] ?? 0} lần thu',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingTable() {
    if (_agingData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Không có công nợ phải thu',
                style: TextStyle(color: AppColors.success)),
          ],
        ),
      );
    }

    // Group aging data by bucket
    double current = 0, days30 = 0, days60 = 0, days90 = 0, over90 = 0;
    for (final a in _agingData) {
      final balance = ((a['balance'] ?? 0) as num).toDouble();
      switch (a['aging_bucket'] as String? ?? '') {
        case 'current':
          current += balance;
          break;
        case '1-30':
          days30 += balance;
          break;
        case '31-60':
          days60 += balance;
          break;
        case '61-90':
          days90 += balance;
          break;
        case '90+':
          over90 += balance;
          break;
      }
    }

    final total = current + days30 + days60 + days90 + over90;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildAgingRow('Tổng công nợ', total, Colors.black87, isBold: true),
          const Divider(),
          _buildAgingRow('Trong hạn', current, AppColors.success),
          _buildAgingRow('1-30 ngày', days30, AppColors.info),
          _buildAgingRow('31-60 ngày', days60, AppColors.warning),
          _buildAgingRow('61-90 ngày', days90, Colors.orange),
          _buildAgingRow(
              'Quá 90 ngày', over90, AppColors.error, isAlert: true),
        ],
      ),
    );
  }

  Widget _buildAgingRow(String label, double amount, Color color,
      {bool isBold = false, bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(
            fmt.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isAlert && amount > 0 ? AppColors.error : color,
            ),
          ),
        ],
      ),
    );
  }
}
