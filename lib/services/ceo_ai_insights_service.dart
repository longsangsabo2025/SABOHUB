import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================================
/// CEO AI INSIGHTS SERVICE — Smart Analysis Engine
/// Tự động phân tích dữ liệu và tạo đề xuất thông minh cho CEO
/// Hoạt động như một AI Chief of Staff
/// ============================================================================

class CEOAIInsightsService {
  final _sb = Supabase.instance.client;

  /// Generate complete morning briefing for CEO
  Future<CEOBriefing> generateBriefing(String companyId) async {
    try {
      final now = DateTime.now();
      final today = _dateStr(now);
      final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
      final weekAgo = _dateStr(now.subtract(const Duration(days: 7)));
      final monthStart = _dateStr(DateTime(now.year, now.month, 1));
      final lastMonthStart = _dateStr(DateTime(now.year, now.month - 1, 1));

      // Parallel data fetch
      final results = await Future.wait([
        // 0: Overdue tasks
        _sb.from('tasks').select('id, title, due_date, priority, assigned_to, status')
            .eq('company_id', companyId)
            .neq('status', 'completed')
            .lt('due_date', '${today}T00:00:00')
            .limit(1000),
        // 1: Tasks due today
        _sb.from('tasks').select('id, title, due_date, priority, assigned_to, status')
            .eq('company_id', companyId)
            .neq('status', 'completed')
            .gte('due_date', '${today}T00:00:00')
            .lt('due_date', '${today}T23:59:59')
            .limit(1000),
        // 2: Pending approval tasks
        _sb.from('tasks').select('id, title, priority, created_at')
            .eq('company_id', companyId)
            .eq('status', 'pending_approval')
            .limit(500),
        // 3: Employees
        _sb.from('employees').select('id, full_name, role, is_active, last_active_at')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .limit(1000),
        // 4: Today revenue
        _sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .eq('date', today)
            .limit(100),
        // 5: Yesterday revenue
        _sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .eq('date', yesterday)
            .limit(100),
        // 6: Last 7 days revenue
        _sb.from('daily_revenue').select('date, total_revenue')
            .eq('company_id', companyId)
            .gte('date', weekAgo)
            .order('date')
            .limit(100),
        // 7: This month revenue
        _sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', monthStart)
            .limit(100),
        // 8: Last month revenue
        _sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', lastMonthStart)
            .lt('date', monthStart)
            .limit(100),
        // 9: Today sessions
        _sb.from('table_sessions').select('id, start_time, end_time, total_amount')
            .eq('company_id', companyId)
            .gte('start_time', '${today}T00:00:00')
            .limit(1000),
        // 10: Active tables right now
        _sb.from('tables').select('id, name')
            .eq('company_id', companyId)
            .eq('status', 'occupied')
            .limit(500),
        // 11: Recent task completions (last 7 days)
        _sb.from('tasks').select('id, completed_at, assigned_to')
            .eq('company_id', companyId)
            .eq('status', 'completed')
            .gte('completed_at', '${weekAgo}T00:00:00')
            .limit(1000),
        // 12: All tasks (for stats)
        _sb.from('tasks').select('id, status, priority')
            .eq('company_id', companyId)
            .neq('status', 'completed')
            .limit(1000),
      ]);

      final overdueTasks = _toList(results[0]);
      final todayTasks = _toList(results[1]);
      final pendingApproval = _toList(results[2]);
      final employees = _toList(results[3]);
      final todayRevData = _toList(results[4]);
      final yesterdayRevData = _toList(results[5]);
      final weekRevData = _toList(results[6]);
      final thisMonthRevData = _toList(results[7]);
      final lastMonthRevData = _toList(results[8]);
      final todaySessions = _toList(results[9]);
      final activeTables = _toList(results[10]);
      final recentCompletions = _toList(results[11]);
      final openTasks = _toList(results[12]);

      // === CALCULATE METRICS ===
      final todayRev = _sumField(todayRevData, 'total_revenue');
      final yesterdayRev = _sumField(yesterdayRevData, 'total_revenue');
      final weekRevTotal = _sumField(weekRevData, 'total_revenue');
      final weekAvgDaily = weekRevData.isNotEmpty ? weekRevTotal / weekRevData.length : 0.0;
      final thisMonthRev = _sumField(thisMonthRevData, 'total_revenue');
      final lastMonthRev = _sumField(lastMonthRevData, 'total_revenue');

      // High-priority overdue
      final urgentOverdue = overdueTasks.where((t) =>
          t['priority'] == 'high' || t['priority'] == 'urgent').toList();

      // === GENERATE INSIGHTS ===
      final insights = <AIInsight>[];
      final actions = <AIAction>[];

      // Greeting context
      final hour = now.hour;
      String greeting;
      if (hour < 12) {
        greeting = 'Chào buổi sáng';
      } else if (hour < 18) {
        greeting = 'Chào buổi chiều';
      } else {
        greeting = 'Chào buổi tối';
      }

      // --- INSIGHT 1: Revenue trend analysis ---
      if (todayRev > 0 && weekAvgDaily > 0) {
        final pctVsAvg = ((todayRev - weekAvgDaily) / weekAvgDaily * 100);
        if (pctVsAvg > 20) {
          insights.add(AIInsight(
            type: InsightType.positive,
            icon: '🔥',
            title: 'Doanh thu hôm nay đang tốt!',
            description: 'Cao hơn ${pctVsAvg.toStringAsFixed(0)}% so với trung bình 7 ngày. '
                'Giữ momentum này!',
            metric: _fmtMoney(todayRev),
          ));
        } else if (pctVsAvg < -30) {
          insights.add(AIInsight(
            type: InsightType.warning,
            icon: '⚠️',
            title: 'Doanh thu đang thấp hơn bình thường',
            description: 'Thấp hơn ${pctVsAvg.abs().toStringAsFixed(0)}% so với trung bình. '
                'Xem xét đẩy mạnh marketing hoặc khuyến mãi.',
            metric: _fmtMoney(todayRev),
          ));
          actions.add(AIAction(
            priority: ActionPriority.medium,
            icon: '📢',
            title: 'Tạo chương trình khuyến mãi flash',
            description: 'Doanh thu đang thấp — khuyến mãi 2h có thể tăng traffic.',
            actionType: ActionType.suggestion,
          ));
        }
      } else if (todayRev == 0 && hour >= 11) {
        insights.add(AIInsight(
          type: InsightType.warning,
          icon: '📊',
          title: 'Chưa ghi nhận doanh thu hôm nay',
          description: hour >= 14
              ? 'Đã ${hour}h mà chưa có doanh thu. Kiểm tra hệ thống ghi nhận hoặc liên hệ quản lý.'
              : 'Ngày mới bắt đầu. Theo dõi khi có phiên đầu tiên.',
          metric: '0₫',
        ));
      }

      // --- INSIGHT 2: Yesterday comparison ---
      if (yesterdayRev > 0) {
        final changeVsYesterday = todayRev - yesterdayRev;
        if (changeVsYesterday > 0 && todayRev > 0) {
          insights.add(AIInsight(
            type: InsightType.positive,
            icon: '📈',
            title: 'Tốt hơn hôm qua',
            description: 'Đang hơn hôm qua ${_fmtMoney(changeVsYesterday)}. '
                'Hôm qua tổng ${_fmtMoney(yesterdayRev)}.',
            metric: '+${_fmtMoney(changeVsYesterday)}',
          ));
        }
      }

      // --- INSIGHT 3: Month-over-month growth ---
      if (lastMonthRev > 0) {
        final growthPct = ((thisMonthRev - lastMonthRev) / lastMonthRev * 100);
        if (growthPct > 10) {
          insights.add(AIInsight(
            type: InsightType.positive,
            icon: '🚀',
            title: 'Tháng này đang tăng trưởng!',
            description: '+${growthPct.toStringAsFixed(0)}% so với tháng trước. '
                'Doanh thu: ${_fmtMoney(thisMonthRev)} vs ${_fmtMoney(lastMonthRev)}.',
            metric: '+${growthPct.toStringAsFixed(0)}%',
          ));
        } else if (growthPct < -10) {
          insights.add(AIInsight(
            type: InsightType.negative,
            icon: '📉',
            title: 'Doanh thu tháng đang giảm',
            description: '${growthPct.toStringAsFixed(0)}% so với tháng trước. '
                'Cần hành động để đảo chiều xu hướng.',
            metric: '${growthPct.toStringAsFixed(0)}%',
          ));
          actions.add(AIAction(
            priority: ActionPriority.high,
            icon: '🎯',
            title: 'Đánh giá chiến lược kinh doanh',
            description: 'Doanh thu tháng giảm ${growthPct.abs().toStringAsFixed(0)}%. '
                'Họp với managers để phân tích nguyên nhân.',
            actionType: ActionType.critical,
          ));
        }
      }

      // --- INSIGHT 4: Task health ---
      if (overdueTasks.isNotEmpty) {
        insights.add(AIInsight(
          type: InsightType.negative,
          icon: '⏰',
          title: '${overdueTasks.length} task quá hạn',
          description: urgentOverdue.isNotEmpty
              ? '${urgentOverdue.length} task ưu tiên cao cần xử lý ngay!'
              : 'Đa số là task thường. Cân nhắc reassign hoặc đóng nếu không còn phù hợp.',
          metric: '${overdueTasks.length}',
        ));
        actions.add(AIAction(
          priority: urgentOverdue.isNotEmpty
              ? ActionPriority.critical
              : ActionPriority.medium,
          icon: '🔄',
          title: 'Dọn dẹp ${overdueTasks.length} task quá hạn',
          description: 'Reassign, gia hạn, hoặc đóng các task đã quá hạn. '
              'Task tồn đọng làm giảm hiệu suất đội ngũ.',
          actionType: ActionType.taskAction,
          metadata: {'count': overdueTasks.length},
        ));
      }

      // --- INSIGHT 5: Pending approvals ---
      if (pendingApproval.isNotEmpty) {
        actions.add(AIAction(
          priority: ActionPriority.high,
          icon: '✅',
          title: 'Phê duyệt ${pendingApproval.length} task đang chờ',
          description: 'Nhân viên đang chờ phê duyệt. Hành động nhanh giúp đội ngũ không bị chặn.',
          actionType: ActionType.approval,
          metadata: {'count': pendingApproval.length},
        ));
      }

      // --- INSIGHT 6: Today's tasks focus ---
      if (todayTasks.isNotEmpty) {
        final highPriority = todayTasks.where((t) =>
            t['priority'] == 'high' || t['priority'] == 'urgent').toList();
        insights.add(AIInsight(
          type: InsightType.info,
          icon: '📋',
          title: '${todayTasks.length} task hết hạn hôm nay',
          description: highPriority.isNotEmpty
              ? '${highPriority.length} task ưu tiên cao. Đảm bảo được hoàn thành!'
              : 'Tất cả là task thường. Tiến độ tốt.',
          metric: '${todayTasks.length}',
        ));
      }

      // --- INSIGHT 7: Team productivity ---
      if (recentCompletions.isNotEmpty && employees.isNotEmpty) {
        final completionRate = recentCompletions.length / 7.0; // tasks/day
        insights.add(AIInsight(
          type: completionRate >= 2 ? InsightType.positive : InsightType.info,
          icon: '👥',
          title: 'Đội ngũ hoàn thành ${completionRate.toStringAsFixed(1)} task/ngày',
          description: '${recentCompletions.length} task hoàn thành trong 7 ngày qua. '
              '${employees.length} nhân viên đang hoạt động.',
          metric: '${recentCompletions.length}',
        ));
      }

      // --- INSIGHT 8: Operational status ---
      if (activeTables.isNotEmpty) {
        insights.add(AIInsight(
          type: InsightType.positive,
          icon: '🎱',
          title: '${activeTables.length} bàn đang hoạt động',
          description: 'Hiện tại có khách. ${todaySessions.length} phiên hôm nay.',
          metric: '${activeTables.length}',
        ));
      }

      // --- INSIGHT 9: Weekend/weekday pattern ---
      if (weekRevData.length >= 5) {
        _analyzeWeekdayPattern(weekRevData, now, insights);
      }

      // --- INSIGHT 10: Best performing day this week ---
      if (weekRevData.length >= 3) {
        _findBestDay(weekRevData, insights);
      }

      // --- ACTION: Daily task generation ---
      final uncompletedCount = openTasks.length;
      if (uncompletedCount < 3) {
        actions.add(AIAction(
          priority: ActionPriority.low,
          icon: '📝',
          title: 'Tạo task mới cho đội ngũ',
          description: 'Chỉ còn $uncompletedCount task mở. '
              'Giao thêm nhiệm vụ để nhân viên luôn có việc làm.',
          actionType: ActionType.suggestion,
        ));
      }

      // --- ACTION: Check inactive employees ---
      final inactiveEmployees = employees.where((e) {
        final lastActive = e['last_active_at'] as String?;
        if (lastActive == null) return true;
        final lastDate = DateTime.tryParse(lastActive);
        if (lastDate == null) return true;
        return now.difference(lastDate).inDays > 3;
      }).toList();

      if (inactiveEmployees.isNotEmpty) {
        actions.add(AIAction(
          priority: ActionPriority.medium,
          icon: '👻',
          title: '${inactiveEmployees.length} nhân viên chưa hoạt động gần đây',
          description: 'Không thấy hoạt động trong 3 ngày qua. '
              'Kiểm tra xem có vấn đề gì không.',
          actionType: ActionType.suggestion,
          metadata: {'employees': inactiveEmployees.map((e) => e['full_name']).toList()},
        ));
      }

      // Sort actions by priority
      actions.sort((a, b) => a.priority.index.compareTo(b.priority.index));

      // Generate summary sentence
      final summaryParts = <String>[];
      if (todayRev > 0) summaryParts.add('doanh thu ${_fmtMoney(todayRev)}');
      if (activeTables.isNotEmpty) summaryParts.add('${activeTables.length} bàn đang chạy');
      if (overdueTasks.isNotEmpty) summaryParts.add('${overdueTasks.length} task quá hạn');
      if (pendingApproval.isNotEmpty) summaryParts.add('${pendingApproval.length} chờ duyệt');
      if (todayTasks.isNotEmpty) summaryParts.add('${todayTasks.length} task hôm nay');

      final summary = summaryParts.isEmpty
          ? 'Chưa có hoạt động ghi nhận hôm nay. Kiểm tra hệ thống.'
          : summaryParts.join(' · ');

      // Health score (0-100)
      int healthScore = 70; // baseline
      if (overdueTasks.isEmpty) healthScore += 10;
      if (overdueTasks.length > 5) healthScore -= 15;
      if (overdueTasks.length > 10) healthScore -= 10;
      if (pendingApproval.isEmpty) healthScore += 5;
      if (todayRev > weekAvgDaily && weekAvgDaily > 0) healthScore += 10;
      if (todayRev < weekAvgDaily * 0.5 && weekAvgDaily > 0) healthScore -= 10;
      if (thisMonthRev > lastMonthRev && lastMonthRev > 0) healthScore += 5;
      if (recentCompletions.length >= 7) healthScore += 5;
      healthScore = healthScore.clamp(0, 100);

      String healthLabel;
      if (healthScore >= 80) {
        healthLabel = 'Xuất sắc';
      } else if (healthScore >= 60) {
        healthLabel = 'Tốt';
      } else if (healthScore >= 40) {
        healthLabel = 'Cần cải thiện';
      } else {
        healthLabel = 'Cần hành động ngay';
      }

      return CEOBriefing(
        greeting: greeting,
        summary: summary,
        healthScore: healthScore,
        healthLabel: healthLabel,
        todayRevenue: todayRev,
        yesterdayRevenue: yesterdayRev,
        weekAvgDaily: weekAvgDaily,
        thisMonthRevenue: thisMonthRev,
        lastMonthRevenue: lastMonthRev,
        activeTables: activeTables.length,
        todaySessions: todaySessions.length,
        totalEmployees: employees.length,
        overdueTasks: overdueTasks.length,
        todayTasksDue: todayTasks.length,
        pendingApprovals: pendingApproval.length,
        insights: insights,
        actions: actions,
        generatedAt: now,
      );
    } catch (e) {
      return CEOBriefing.empty(error: e.toString());
    }
  }

  void _analyzeWeekdayPattern(
      List<Map<String, dynamic>> weekData, DateTime now, List<AIInsight> insights) {
    // Check if today is typically a good/bad day
    final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday
    final dayNames = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // Weekend tendency
    final weekendDays = weekData.where((d) {
      final date = DateTime.tryParse(d['date'] as String? ?? '');
      return date != null && (date.weekday == 6 || date.weekday == 7);
    }).toList();
    final weekdayDays = weekData.where((d) {
      final date = DateTime.tryParse(d['date'] as String? ?? '');
      return date != null && date.weekday >= 1 && date.weekday <= 5;
    }).toList();

    if (weekendDays.isNotEmpty && weekdayDays.isNotEmpty) {
      final weekendAvg = _sumField(weekendDays, 'total_revenue') /
          weekendDays.length;
      final weekdayAvg = _sumField(weekdayDays, 'total_revenue') /
          weekdayDays.length;

      if (weekendAvg > weekdayAvg * 1.5 && (dayOfWeek == 6 || dayOfWeek == 7)) {
        insights.add(AIInsight(
          type: InsightType.info,
          icon: '📅',
          title: 'Hôm nay là ${dayNames[dayOfWeek]} — ngày cao điểm',
          description: 'Cuối tuần thường doanh thu cao hơn ${((weekendAvg / weekdayAvg - 1) * 100).toStringAsFixed(0)}% so với ngày thường. '
              'Đảm bảo đủ nhân viên.',
          metric: _fmtMoney(weekendAvg),
        ));
      } else if (weekdayAvg > weekendAvg * 1.3 && dayOfWeek >= 1 && dayOfWeek <= 5) {
        insights.add(AIInsight(
          type: InsightType.info,
          icon: '📅',
          title: 'Ngày thường doanh thu ổn định hơn',
          description: 'Các ${dayNames[dayOfWeek]} thường mạnh. Tận dụng để upsell.',
          metric: _fmtMoney(weekdayAvg),
        ));
      }
    }
  }

  void _findBestDay(List<Map<String, dynamic>> weekData, List<AIInsight> insights) {
    if (weekData.isEmpty) return;

    var bestDay = weekData.first;
    for (final d in weekData) {
      final rev = ((d['total_revenue'] as num?)?.toDouble() ?? 0);
      final bestRev = ((bestDay['total_revenue'] as num?)?.toDouble() ?? 0);
      if (rev > bestRev) bestDay = d;
    }

    final bestRev = (bestDay['total_revenue'] as num?)?.toDouble() ?? 0;
    if (bestRev > 0) {
      final bestDate = bestDay['date']?.toString() ?? '';
      insights.add(AIInsight(
        type: InsightType.info,
        icon: '🏆',
        title: 'Ngày tốt nhất tuần: $bestDate',
        description: 'Doanh thu ${_fmtMoney(bestRev)}. Phân tích xem ngày đó có event gì đặc biệt.',
        metric: _fmtMoney(bestRev),
      ));
    }
  }

  // === HELPERS ===
  List<Map<String, dynamic>> _toList(dynamic data) =>
      List<Map<String, dynamic>>.from(data as List? ?? []);

  double _sumField(List<Map<String, dynamic>> data, String field) =>
      data.fold<double>(0, (s, r) => s + ((r[field] as num?)?.toDouble() ?? 0));

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtMoney(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}tỷ';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}₫';
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class CEOBriefing {
  final String greeting;
  final String summary;
  final int healthScore;
  final String healthLabel;
  final double todayRevenue;
  final double yesterdayRevenue;
  final double weekAvgDaily;
  final double thisMonthRevenue;
  final double lastMonthRevenue;
  final int activeTables;
  final int todaySessions;
  final int totalEmployees;
  final int overdueTasks;
  final int todayTasksDue;
  final int pendingApprovals;
  final List<AIInsight> insights;
  final List<AIAction> actions;
  final DateTime generatedAt;
  final String? error;

  const CEOBriefing({
    required this.greeting,
    required this.summary,
    required this.healthScore,
    required this.healthLabel,
    required this.todayRevenue,
    required this.yesterdayRevenue,
    required this.weekAvgDaily,
    required this.thisMonthRevenue,
    required this.lastMonthRevenue,
    required this.activeTables,
    required this.todaySessions,
    required this.totalEmployees,
    required this.overdueTasks,
    required this.todayTasksDue,
    required this.pendingApprovals,
    required this.insights,
    required this.actions,
    required this.generatedAt,
    this.error,
  });

  factory CEOBriefing.empty({String? error}) => CEOBriefing(
        greeting: 'Xin chào',
        summary: 'Đang tải dữ liệu...',
        healthScore: 50,
        healthLabel: 'Đang phân tích',
        todayRevenue: 0,
        yesterdayRevenue: 0,
        weekAvgDaily: 0,
        thisMonthRevenue: 0,
        lastMonthRevenue: 0,
        activeTables: 0,
        todaySessions: 0,
        totalEmployees: 0,
        overdueTasks: 0,
        todayTasksDue: 0,
        pendingApprovals: 0,
        insights: [],
        actions: [],
        generatedAt: DateTime.now(),
        error: error,
      );

  bool get hasActions => actions.isNotEmpty;
  bool get hasInsights => insights.isNotEmpty;
  int get criticalActions =>
      actions.where((a) => a.priority == ActionPriority.critical).length;
}

class AIInsight {
  final InsightType type;
  final String icon;
  final String title;
  final String description;
  final String metric;

  const AIInsight({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.metric,
  });
}

enum InsightType { positive, negative, warning, info }

class AIAction {
  final ActionPriority priority;
  final String icon;
  final String title;
  final String description;
  final ActionType actionType;
  final Map<String, dynamic>? metadata;

  const AIAction({
    required this.priority,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionType,
    this.metadata,
  });
}

enum ActionPriority { critical, high, medium, low }
enum ActionType { critical, approval, taskAction, suggestion }
