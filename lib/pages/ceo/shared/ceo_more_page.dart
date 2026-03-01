import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../ceo_companies_page.dart';
import '../ceo_documents_page.dart';
import '../ceo_analytics_page.dart';
import '../ceo_reports_settings_page.dart' show CEOReportsPage;
import '../ai_management/ai_assistants_page.dart';

/// CEO More Page — Contains all shared features accessible via AppBar menu
/// Companies, Documents, Analytics, Reports, AI Assistant
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
          _buildMenuItem(
            context,
            icon: Icons.smart_toy,
            color: const Color(0xFF8B5CF6),
            title: 'Trợ lý AI',
            subtitle: 'Hỏi doanh thu, đơn hàng, xuất báo cáo PDF',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantsPage()),
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
            color: Colors.teal,
            title: 'Báo cáo',
            subtitle: 'Tạo và xem báo cáo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CEOReportsPage()),
            ),
          ),
        ],
      ),
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
