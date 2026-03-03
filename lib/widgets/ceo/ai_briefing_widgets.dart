import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/ceo_ai_insights_provider.dart';
import '../../services/ceo_ai_insights_service.dart';

/// ============================================================================
/// CEO AI BRIEFING WIDGETS — Smart, proactive UI components
/// The app acts as an AI Chief of Staff, not a passive dashboard
/// ============================================================================

// ─────────────────────────────────────────────────────────────────────
// 1. HEALTH SCORE RING — Visual system health at a glance
// ─────────────────────────────────────────────────────────────────────
class HealthScoreRing extends StatelessWidget {
  final int score;
  final String label;
  final double size;

  const HealthScoreRing({
    super.key,
    required this.score,
    required this.label,
    this.size = 80,
  });

  Color get _color {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 6,
              backgroundColor: _color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                  color: _color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 2. AI GREETING HERO — Personalized greeting with health score
// ─────────────────────────────────────────────────────────────────────
class AIGreetingHero extends StatelessWidget {
  final CEOBriefing briefing;
  final String ceoName;

  const AIGreetingHero({
    super.key,
    required this.briefing,
    required this.ceoName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('AI Trợ lý', style: TextStyle(
                              color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${briefing.greeting}, $ceoName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  briefing.summary,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${briefing.generatedAt.hour}:${briefing.generatedAt.minute.toString().padLeft(2, '0')} · ${briefing.generatedAt.day}/${briefing.generatedAt.month}/${briefing.generatedAt.year}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          HealthScoreRing(
            score: briefing.healthScore,
            label: briefing.healthLabel,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 3. QUICK PULSE ROW — Key numbers at a glance
// ─────────────────────────────────────────────────────────────────────
class QuickPulseRow extends StatelessWidget {
  final CEOBriefing briefing;

  const QuickPulseRow({super.key, required this.briefing});

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}tỷ';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildPulse('Hôm nay', _fmt(briefing.todayRevenue),
            Icons.payments, const Color(0xFF10B981)),
        const SizedBox(width: 8),
        _buildPulse('TB/ngày', _fmt(briefing.weekAvgDaily),
            Icons.analytics, const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        _buildPulse('Tháng', _fmt(briefing.thisMonthRevenue),
            Icons.calendar_month, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildPulse(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
                fontSize: 9, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 4. CRITICAL ACTIONS SECTION — What CEO should do RIGHT NOW
// ─────────────────────────────────────────────────────────────────────
class CriticalActionsSection extends StatelessWidget {
  final List<AIAction> actions;
  final VoidCallback? onViewAll;

  const CriticalActionsSection({
    super.key,
    required this.actions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, size: 16, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Hành động đề xuất',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${actions.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...actions.take(5).map((action) => _buildActionCard(action)),
      ],
    );
  }

  Widget _buildActionCard(AIAction action) {
    final color = _priorityColor(action.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(action.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _priorityLabel(action.priority),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(action.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(action.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(ActionPriority p) {
    switch (p) {
      case ActionPriority.critical:
        return const Color(0xFFEF4444);
      case ActionPriority.high:
        return const Color(0xFFF59E0B);
      case ActionPriority.medium:
        return const Color(0xFF3B82F6);
      case ActionPriority.low:
        return const Color(0xFF6B7280);
    }
  }

  String _priorityLabel(ActionPriority p) {
    switch (p) {
      case ActionPriority.critical:
        return 'KHẨN CẤP';
      case ActionPriority.high:
        return 'QUAN TRỌNG';
      case ActionPriority.medium:
        return 'NÊN LÀM';
      case ActionPriority.low:
        return 'GỢI Ý';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// 5. AI INSIGHTS FEED — Smart observations about business
// ─────────────────────────────────────────────────────────────────────
class AIInsightsFeed extends StatelessWidget {
  final List<AIInsight> insights;

  const AIInsightsFeed({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Chưa đủ dữ liệu để phân tích',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Ghi nhận doanh thu và task để AI đề xuất.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('AI Phân tích',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            Text('${insights.length} nhận định',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 10),
        ...insights.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    final color = _insightColor(insight.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text(insight.description,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          ),
          if (insight.metric.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(insight.metric,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
        ],
      ),
    );
  }

  Color _insightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return const Color(0xFF10B981);
      case InsightType.negative:
        return const Color(0xFFEF4444);
      case InsightType.warning:
        return const Color(0xFFF59E0B);
      case InsightType.info:
        return const Color(0xFF3B82F6);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// 6. OPERATIONAL MINI STATS — Quick operational view
// ─────────────────────────────────────────────────────────────────────
class OperationalMiniStats extends StatelessWidget {
  final CEOBriefing briefing;

  const OperationalMiniStats({super.key, required this.briefing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Tình hình vận hành',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              _statusDot(briefing),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(Icons.table_bar, '${briefing.activeTables}',
                  'Bàn', const Color(0xFFF59E0B)),
              _divider(),
              _buildMiniStat(Icons.timer, '${briefing.todaySessions}',
                  'Phiên', const Color(0xFF10B981)),
              _divider(),
              _buildMiniStat(Icons.people, '${briefing.totalEmployees}',
                  'NV', const Color(0xFF6366F1)),
              _divider(),
              _buildMiniStat(Icons.assignment_late, '${briefing.overdueTasks}',
                  'Quá hạn', briefing.overdueTasks > 0
                      ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              _divider(),
              _buildMiniStat(Icons.pending_actions, '${briefing.pendingApprovals}',
                  'Chờ', briefing.pendingApprovals > 0
                      ? const Color(0xFFF59E0B) : const Color(0xFF6B7280)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot(CEOBriefing b) {
    final hasIssues = b.overdueTasks > 0 || b.pendingApprovals > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasIssues
            ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
            : const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: hasIssues ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            hasIssues ? 'Cần chú ý' : 'Ổn định',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: hasIssues ? const Color(0xFFB45309) : const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.shade200,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 7. COMPLETE AI COMMAND CENTER TAB — Replaces old _CEOCommandCenter
// ─────────────────────────────────────────────────────────────────────
class CEOAICommandCenter extends ConsumerWidget {
  final String businessLabel;

  const CEOAICommandCenter({super.key, required this.businessLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(ceoBriefingProvider);

    return briefingAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI đang phân tích dữ liệu...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Lỗi: $e', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(ceoBriefingProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      data: (briefing) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ceoBriefingProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AI Greeting Hero with Health Score
              AIGreetingHero(
                briefing: briefing,
                ceoName: 'CEO',
              ),
              const SizedBox(height: 14),

              // 2. Quick Revenue Pulse
              QuickPulseRow(briefing: briefing),
              const SizedBox(height: 14),

              // 3. Operational Mini Stats
              OperationalMiniStats(briefing: briefing),
              const SizedBox(height: 18),

              // 4. Critical Actions (most important — what to DO)
              if (briefing.hasActions) ...[
                CriticalActionsSection(actions: briefing.actions),
                const SizedBox(height: 18),
              ],

              // 5. AI Insights Feed (analysis & observations)
              AIInsightsFeed(insights: briefing.insights),
              const SizedBox(height: 16),

              // 6. AI tip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kéo xuống để refresh · AI tự động cập nhật mỗi lần mở app',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
