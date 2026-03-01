import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../ceo_companies_page.dart';
import '../ceo_documents_page.dart';
import '../ceo_analytics_page.dart';
import '../ceo_reports_settings_page.dart' show CEOReportsPage;
import '../ai_management/ai_assistants_page.dart';
import '../media_dashboard_page.dart';
import '../revenue_dashboard_page.dart';
import '../kanban_board_page.dart';
import '../task_templates_page.dart';
import '../performance_scorecard_page.dart';
import '../ceo_schedule_overview_page.dart';
import '../pdf_report_page.dart';

/// CEO More Page — Contains all shared features accessible via AppBar menu
class CEOMorePage extends ConsumerWidget {
  const CEOMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính năng khác'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Quản lý nghiệp vụ'),
          _buildMenuItem(
            context,
            icon: Icons.campaign,
            color: Colors.deepPurple,
            title: 'SABO Media',
            subtitle: 'Quản lý kênh YouTube, TikTok, Instagram...',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MediaDashboardPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.attach_money,
            color: Colors.green.shade700,
            title: 'Doanh thu',
            subtitle: 'Biểu đồ, chi tiết doanh thu theo ngày/tháng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RevenueDashboardPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.view_kanban,
            color: Colors.indigo,
            title: 'Kanban Board',
            subtitle: 'Kéo thả task giữa các trạng thái',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KanbanBoardPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.content_copy,
            color: Colors.teal,
            title: 'Task Templates',
            subtitle: 'Tạo task lặp lại nhanh chóng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskTemplatesPage()),
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('Nhân sự & Vận hành'),
          _buildMenuItem(
            context,
            icon: Icons.emoji_events,
            color: Colors.amber.shade700,
            title: 'Hiệu suất nhân viên',
            subtitle: 'Bảng xếp hạng, điểm task + chấm công',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PerformanceScorecardPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.calendar_month,
            color: Colors.blue.shade700,
            title: 'Lịch làm việc',
            subtitle: 'Tổng quan ca làm 7 ngày tới',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CEOScheduleOverviewPage()),
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('Công cụ'),
          _buildMenuItem(
            context,
            icon: Icons.smart_toy,
            color: const Color(0xFF8B5CF6),
            title: 'Trợ lý AI',
            subtitle: 'Hỏi doanh thu, đơn hàng, xuất báo cáo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantsPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.picture_as_pdf,
            color: Colors.red.shade600,
            title: 'Xuất PDF',
            subtitle: 'Tạo báo cáo nhiệm vụ, doanh thu, nhân viên',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PDFReportPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.business,
            color: AppColors.primary,
            title: 'Quản lý công ty',
            subtitle: 'Xem danh sách, thông tin công ty',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEOCompaniesPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.folder_outlined,
            color: AppColors.info,
            title: 'Tài liệu',
            subtitle: 'Quản lý tài liệu, hồ sơ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEODocumentsPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.insights,
            color: Colors.purple,
            title: 'Phân tích nâng cao',
            subtitle: 'Biểu đồ, xu hướng, so sánh',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEOAnalyticsPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.summarize,
            color: Colors.teal.shade700,
            title: 'Báo cáo & Cài đặt',
            subtitle: 'Tạo và xem báo cáo, cài đặt hệ thống',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEOReportsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54)),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}
