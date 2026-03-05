import '../models/daily_work_report.dart';
import 'gemini_service.dart';

/// AI Service for analyzing work reports and providing insights
class ReportAIService {
  static final ReportAIService _instance = ReportAIService._internal();
  factory ReportAIService() => _instance;
  ReportAIService._internal();

  final _gemini = GeminiService();

  /// Analyze a single employee's reports and provide insights
  Future<ReportAIInsight> analyzeEmployeeReports({
    required List<DailyWorkReport> reports,
    required String employeeName,
  }) async {
    if (reports.isEmpty) {
      return ReportAIInsight.empty();
    }

    // Prepare report data for AI
    final reportData = _prepareReportData(reports, employeeName);
    
    // Get AI analysis
    final aiResponse = await _gemini.chat(
      'Phân tích báo cáo công việc của nhân viên và đưa ra nhận xét, gợi ý cải tiến',
      businessContext: reportData,
    );

    // Parse AI response into structured insight
    return _parseAIResponse(aiResponse, reports);
  }

  /// Analyze all branch reports and provide team insights
  Future<TeamAIInsight> analyzeTeamReports({
    required List<DailyWorkReport> allReports,
    required String branchName,
  }) async {
    if (allReports.isEmpty) {
      return TeamAIInsight.empty();
    }

    // Group by employee
    final byEmployee = <String, List<DailyWorkReport>>{};
    for (final r in allReports) {
      byEmployee.putIfAbsent(r.userName, () => []).add(r);
    }

    // Prepare summary
    final summary = StringBuffer();
    summary.writeln('=== THỐNG KÊ TỔNG HỢP CHI NHÁNH: $branchName ===');
    summary.writeln('Tổng số báo cáo: ${allReports.length}');
    summary.writeln('Số nhân viên: ${byEmployee.length}');
    summary.writeln('');
    
    for (final entry in byEmployee.entries) {
      final reports = entry.value;
      final avgHours = reports.fold<double>(0, (s, r) => s + r.totalHours) / reports.length;
      final totalTasks = reports.fold<int>(0, (s, r) => s + r.tasksCompleted);
      summary.writeln('👤 ${entry.key}:');
      summary.writeln('   - Số báo cáo: ${reports.length}');
      summary.writeln('   - Giờ làm TB: ${avgHours.toStringAsFixed(1)}h/ngày');
      summary.writeln('   - Tasks hoàn thành: $totalTasks');
      
      // Check challenges
      final challenges = reports.where((r) => r.challenges?.isNotEmpty == true).toList();
      if (challenges.isNotEmpty) {
        summary.writeln('   - Có ${challenges.length} ngày gặp khó khăn');
      }
      summary.writeln('');
    }

    // Get AI analysis
    final aiResponse = await _gemini.chat(
      '''Phân tích dữ liệu team và đưa ra:
1. Đánh giá hiệu suất chung
2. Điểm mạnh của team
3. Vấn đề cần cải thiện
4. Gợi ý cụ thể cho manager''',
      businessContext: summary.toString(),
    );

    return _parseTeamInsight(aiResponse, allReports, byEmployee.length);
  }

  String _prepareReportData(List<DailyWorkReport> reports, String employeeName) {
    final buffer = StringBuffer();
    buffer.writeln('=== BÁO CÁO CÔNG VIỆC CỦA: $employeeName ===');
    buffer.writeln('Tổng số ngày: ${reports.length}');
    
    // Calculate stats
    final totalHours = reports.fold<double>(0, (sum, r) => sum + r.totalHours);
    final avgHours = totalHours / reports.length;
    final totalTasksCompleted = reports.fold<int>(0, (sum, r) => sum + r.tasksCompleted);
    final totalTasksAssigned = reports.fold<int>(0, (sum, r) => sum + r.tasksAssigned);
    
    buffer.writeln('Tổng giờ làm: ${totalHours.toStringAsFixed(1)}h');
    buffer.writeln('Giờ làm TB/ngày: ${avgHours.toStringAsFixed(1)}h');
    buffer.writeln('Tasks hoàn thành: $totalTasksCompleted/${totalTasksAssigned > 0 ? totalTasksAssigned : "N/A"}');
    buffer.writeln('');
    buffer.writeln('CHI TIẾT TỪNG NGÀY:');
    
    // Sort by date descending
    final sortedReports = List.of(reports)..sort((a, b) => b.date.compareTo(a.date));
    
    for (final report in sortedReports.take(7)) { // Last 7 days
      buffer.writeln('');
      buffer.writeln('📅 ${_formatDate(report.date)} (${_formatWeekday(report.date)}):');
      buffer.writeln('   ⏰ Ca làm: ${_formatTime(report.checkInTime)} - ${_formatTime(report.checkOutTime)} (${report.totalHours.toStringAsFixed(1)}h)');
      buffer.writeln('   ✅ Tasks: ${report.tasksCompleted}/${report.tasksAssigned}');
      
      if (report.achievements?.isNotEmpty == true) {
        buffer.writeln('   🏆 Thành tựu: ${report.achievements!.join(", ")}');
      }
      if (report.challenges?.isNotEmpty == true) {
        buffer.writeln('   ⚠️ Khó khăn: ${report.challenges!.join(", ")}');
      }
      if (report.employeeNotes?.isNotEmpty == true) {
        buffer.writeln('   📝 Ghi chú: ${report.employeeNotes}');
      }
    }

    return buffer.toString();
  }

  ReportAIInsight _parseAIResponse(String aiResponse, List<DailyWorkReport> reports) {
    // Calculate basic stats
    final totalHours = reports.fold<double>(0, (s, r) => s + r.totalHours);
    final avgHours = totalHours / reports.length;
    final taskCompletion = reports.where((r) => r.tasksAssigned > 0).isEmpty
        ? 0.0
        : reports.fold<int>(0, (s, r) => s + r.tasksCompleted) /
          reports.fold<int>(0, (s, r) => s + r.tasksAssigned) * 100;

    // Determine trend
    final sortedByDate = List.of(reports)..sort((a, b) => a.date.compareTo(b.date));
    String trend = 'stable';
    if (sortedByDate.length >= 3) {
      final recentList = sortedByDate.sublist(sortedByDate.length - 3);
      final recent = recentList.map((r) => r.totalHours).reduce((a, b) => a + b) / 3;
      final olderList = sortedByDate.sublist(0, sortedByDate.length - 3);
      if (olderList.isNotEmpty) {
        final older = olderList.map((r) => r.totalHours).reduce((a, b) => a + b) / olderList.length;
        if (recent > older * 1.1) trend = 'improving';
        if (recent < older * 0.9) trend = 'declining';
      }
    }

    return ReportAIInsight(
      analysis: aiResponse.isEmpty ? _getDefaultAnalysis(reports) : aiResponse,
      avgHoursPerDay: avgHours,
      taskCompletionRate: taskCompletion,
      trend: trend,
      generatedAt: DateTime.now(),
    );
  }

  TeamAIInsight _parseTeamInsight(String aiResponse, List<DailyWorkReport> reports, int employeeCount) {
    final totalHours = reports.fold<double>(0, (s, r) => s + r.totalHours);
    final avgHours = totalHours / reports.length;

    // Find top performer
    final byEmployee = <String, double>{};
    for (final r in reports) {
      byEmployee.update(r.userName, (v) => v + r.totalHours, ifAbsent: () => r.totalHours);
    }
    final topPerformer = byEmployee.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return TeamAIInsight(
      analysis: aiResponse.isEmpty ? _getDefaultTeamAnalysis(reports) : aiResponse,
      totalReports: reports.length,
      employeeCount: employeeCount,
      avgHoursPerDay: avgHours,
      topPerformer: topPerformer,
      generatedAt: DateTime.now(),
    );
  }

  String _getDefaultAnalysis(List<DailyWorkReport> reports) {
    final avgHours = reports.fold<double>(0, (s, r) => s + r.totalHours) / reports.length;
    final hasIssues = reports.any((r) => r.challenges?.isNotEmpty == true);
    
    return '''📊 **Phân tích tự động**

⏰ **Giờ làm:** Trung bình ${avgHours.toStringAsFixed(1)} giờ/ngày

${avgHours >= 8 ? '✅ Đảm bảo thời gian làm việc chuẩn' : '⚠️ Giờ làm dưới mức tiêu chuẩn 8h'}

${hasIssues ? '🔔 Nhân viên có gặp một số khó khăn - cần follow up' : '👍 Không có vấn đề đặc biệt được báo cáo'}

💡 **Gợi ý:** ${avgHours < 7 ? 'Cân nhắc trao đổi về workload và khối lượng công việc' : 'Duy trì và khuyến khích tinh thần làm việc tốt'}''';
  }

  String _getDefaultTeamAnalysis(List<DailyWorkReport> reports) {
    return '''📈 **Phân tích team tự động**

Tổng số báo cáo: ${reports.length}

💡 *Bật API Gemini để có phân tích AI chi tiết hơn*''';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _formatWeekday(DateTime date) {
    const weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return weekdays[date.weekday - 1];
  }
}

/// AI Insight for a single employee
class ReportAIInsight {
  final String analysis;
  final double avgHoursPerDay;
  final double taskCompletionRate;
  final String trend; // 'improving', 'stable', 'declining'
  final DateTime generatedAt;

  const ReportAIInsight({
    required this.analysis,
    required this.avgHoursPerDay,
    required this.taskCompletionRate,
    required this.trend,
    required this.generatedAt,
  });

  factory ReportAIInsight.empty() => ReportAIInsight(
    analysis: 'Chưa có dữ liệu để phân tích',
    avgHoursPerDay: 0,
    taskCompletionRate: 0,
    trend: 'stable',
    generatedAt: DateTime.now(),
  );

  String get trendEmoji {
    switch (trend) {
      case 'improving': return '📈';
      case 'declining': return '📉';
      default: return '➡️';
    }
  }

  String get trendLabel {
    switch (trend) {
      case 'improving': return 'Đang tiến bộ';
      case 'declining': return 'Cần cải thiện';
      default: return 'Ổn định';
    }
  }
}

/// AI Insight for entire team/branch
class TeamAIInsight {
  final String analysis;
  final int totalReports;
  final int employeeCount;
  final double avgHoursPerDay;
  final String topPerformer;
  final DateTime generatedAt;

  const TeamAIInsight({
    required this.analysis,
    required this.totalReports,
    required this.employeeCount,
    required this.avgHoursPerDay,
    required this.topPerformer,
    required this.generatedAt,
  });

  factory TeamAIInsight.empty() => TeamAIInsight(
    analysis: 'Chưa có dữ liệu để phân tích',
    totalReports: 0,
    employeeCount: 0,
    avgHoursPerDay: 0,
    topPerformer: '',
    generatedAt: DateTime.now(),
  );
}
