import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../ceo_documents_page.dart';
import '../ceo_reports_settings_page.dart' show CEOReportsPage;
import '../ai_management/ai_assistants_page.dart';
import '../ceo_today_page.dart';
import '../media_dashboard_page.dart';
import '../revenue_dashboard_page.dart';
import '../kanban_board_page.dart';
import '../task_templates_page.dart';
import '../performance_scorecard_page.dart';
import '../ceo_schedule_overview_page.dart';
import '../pdf_report_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// CEO More Page — Contains all shared features accessible via AppBar menu
class CEOMorePage extends ConsumerWidget {
  const CEOMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tính năng khác'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.rocket_launch,
            color: Colors.blue.shade700,
            title: 'Hôm nay',
            subtitle: '1 nút giao việc, theo dõi tiến độ hôm nay',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEOTodayPage()),
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle(context, 'Quản lý nghiệp vụ'),
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
          _buildSectionTitle(context, 'Nhân sự & Vận hành'),
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
          _buildSectionTitle(context, 'Công cụ'),
          _buildMenuItem(
            context,
            icon: Icons.smart_toy,
            color: AppColors.paymentRefunded,
            title: 'Trợ lý AI',
            subtitle: 'Hỏi doanh thu, đơn hàng, xuất báo cáo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AIAssistantsPage()),
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
            onTap: () => context.push(AppRoutes.ceoCompanies),
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
            onTap: () => context.push(AppRoutes.ceoAnalytics),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface54)),
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
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
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
