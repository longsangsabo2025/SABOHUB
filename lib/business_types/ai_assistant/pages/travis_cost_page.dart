import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/travis_service.dart';

/// FutureProvider that fetches all cost data in parallel.
final _costDataProvider = FutureProvider.autoDispose<_CostData>((ref) async {
  final svc = TravisService();
  final results = await Future.wait([
    svc.budget(),
    svc.apmCost(),
    svc.apmTraces(limit: 15),
  ]);
  return _CostData(
    budget: results[0] as Map<String, dynamic>,
    cost: results[1] as Map<String, dynamic>,
    traces: results[2] as List<dynamic>,
  );
});

class _CostData {
  final Map<String, dynamic> budget;
  final Map<String, dynamic> cost;
  final List<dynamic> traces;
  const _CostData({required this.budget, required this.cost, required this.traces});
}

/// Travis Cost Tracking — budget, spend breakdown, recent queries.
class TravisCostPage extends ConsumerWidget {
  const TravisCostPage({super.key});

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costAsync = ref.watch(_costDataProvider);

    return RefreshIndicator(
      color: _purple,
      onRefresh: () async => ref.invalidate(_costDataProvider),
      child: costAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _purple)),
        error: (e, _) => _ErrorView(error: e, onRetry: () => ref.invalidate(_costDataProvider)),
        data: (data) => _CostContent(data: data),
      ),
    );
  }
}

class _CostContent extends StatelessWidget {
  final _CostData data;
  const _CostContent({required this.data});

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final budget = data.budget;
    final cost = data.cost;

    final dailyBudget = (budget['daily_budget_usd'] as num?)?.toDouble() ?? 2.0;
    final dailySpent = (budget['daily_spent_usd'] as num?)?.toDouble() ?? 0.0;
    final dailyRequests = (budget['daily_requests'] as num?)?.toInt() ?? 0;
    final totalCost = (cost['total_cost_usd'] as num?)?.toDouble() ?? 0.0;
    final usagePct = dailyBudget > 0 ? (dailySpent / dailyBudget).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Budget Gauge Card ──
        _buildCard(
          icon: Icons.account_balance_wallet,
          title: 'Budget hôm nay',
          child: Column(
            children: [
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: usagePct,
                        strokeWidth: 10,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          usagePct > 0.9 ? AppColors.error : usagePct > 0.7 ? AppColors.warning : _purple,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${dailySpent.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '/ \$${dailyBudget.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(label: 'Requests', value: '$dailyRequests'),
                  _StatChip(label: 'Total', value: '\$${totalCost.toStringAsFixed(4)}'),
                  _StatChip(
                    label: 'Avg/req',
                    value: dailyRequests > 0
                        ? '\$${(dailySpent / dailyRequests).toStringAsFixed(5)}'
                        : '-',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Specialist Breakdown ──
        _buildCard(
          icon: Icons.pie_chart_outline,
          title: 'Chi phí theo Specialist',
          child: _SpecialistBreakdown(
            bySpecialist: cost['by_specialist'] as Map<String, dynamic>? ?? {},
            budgetBySpecialist: (budget['config'] as Map<String, dynamic>?)?['specialist_caps'] as Map<String, dynamic>? ?? {},
          ),
        ),
        const SizedBox(height: 16),

        // ── Model Info ──
        _buildCard(
          icon: Icons.memory,
          title: 'Model & Pricing',
          child: Column(
            children: [
              _InfoRow('Model', cost['model'] as String? ?? 'gemini-2.5-flash'),
              _InfoRow('Input', '\$0.15 / 1M tokens'),
              _InfoRow('Output', '\$0.60 / 1M tokens'),
              if (cost['total_tokens'] != null) ...[
                const Divider(height: 20),
                _InfoRow(
                  'Input tokens',
                  _formatNumber((cost['total_tokens'] as Map?)?['input'] ?? 0),
                ),
                _InfoRow(
                  'Output tokens',
                  _formatNumber((cost['total_tokens'] as Map?)?['output'] ?? 0),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Recent Traces ──
        _buildCard(
          icon: Icons.receipt_long,
          title: 'Truy vấn gần đây',
          child: data.traces.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có truy vấn nào', style: TextStyle(color: AppColors.textSecondary)),
                )
              : Column(
                  children: data.traces.take(15).map((t) {
                    final trace = t as Map<String, dynamic>;
                    return _TraceRow(trace: trace);
                  }).toList(),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _purple, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  String _formatNumber(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Specialist Breakdown ──────────────────────────────────────

class _SpecialistBreakdown extends StatelessWidget {
  final Map<String, dynamic> bySpecialist;
  final Map<String, dynamic> budgetBySpecialist;

  const _SpecialistBreakdown({required this.bySpecialist, required this.budgetBySpecialist});

  static const _colors = {
    'ops': Colors.blue,
    'content': Colors.orange,
    'life': Colors.green,
    'ceo': Colors.purple,
    'comms': Colors.teal,
    'utility': Colors.grey,
    'general': Colors.blueGrey,
  };

  static const _icons = {
    'ops': Icons.build,
    'content': Icons.create,
    'life': Icons.favorite,
    'ceo': Icons.business,
    'comms': Icons.message,
    'utility': Icons.handyman,
    'general': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    if (bySpecialist.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final entries = bySpecialist.entries.toList()
      ..sort((a, b) {
        final costA = ((a.value as Map?)?['cost_usd'] as num?)?.toDouble() ?? 0;
        final costB = ((b.value as Map?)?['cost_usd'] as num?)?.toDouble() ?? 0;
        return costB.compareTo(costA);
      });

    return Column(
      children: entries.map((e) {
        final name = e.key;
        final data = e.value as Map<String, dynamic>? ?? {};
        final spent = (data['cost_usd'] as num?)?.toDouble() ?? 0;
        final requests = (data['requests'] as num?)?.toInt() ?? 0;
        final cap = (budgetBySpecialist[name] as num?)?.toDouble() ?? 0.5;
        final pct = cap > 0 ? (spent / cap).clamp(0.0, 1.0) : 0.0;
        final color = _colors[name] ?? Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(_icons[name] ?? Icons.circle, size: 18, color: color),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  name.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  '\$${spent.toStringAsFixed(4)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                child: Text(
                  '${requests}r',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Trace Row ─────────────────────────────────────────────────

class _TraceRow extends StatelessWidget {
  final Map<String, dynamic> trace;
  const _TraceRow({required this.trace});

  @override
  Widget build(BuildContext context) {
    final message = trace['message'] as String? ?? '';
    final specialist = trace['specialist'] as String? ?? '?';
    final cost = (trace['cost_usd'] as num?)?.toDouble() ?? 0;
    final latency = (trace['total_latency_ms'] as num?)?.toInt() ?? 0;
    final tools = trace['tools_called'] as List? ?? [];
    final timeStr = trace['time'] as String? ?? '';

    String timeAgo = '';
    if (timeStr.isNotEmpty) {
      final dt = DateTime.tryParse(timeStr);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _SpecialistBreakdown._colors[specialist]?.withValues(alpha: 0.12) ??
                  Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              specialist.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _SpecialistBreakdown._colors[specialist] ?? Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.length > 60 ? '${message.substring(0, 60)}...' : message,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tools.isNotEmpty)
                  Text(
                    tools.join(', '),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${cost.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '${latency}ms${timeAgo.isNotEmpty ? ' • $timeAgo' : ''}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu cost',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            ),
          ],
        ),
      ),
    );
  }
}
