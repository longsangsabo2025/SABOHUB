import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Projects Management Page
class AIProjectsPage extends ConsumerWidget {
  const AIProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.blue.shade200),
          const SizedBox(height: 16),
          const Text(
            'AI Projects',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Quản lý các dự án AI của doanh nghiệp',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          _buildProjectCard(
            icon: Icons.chat,
            title: 'AI Trợ lý bán hàng',
            description: 'Phân tích đơn hàng, khách hàng, dự báo doanh thu',
            status: 'Hoạt động',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProjectCard(
            icon: Icons.inventory,
            title: 'AI Quản lý tồn kho',
            description: 'Dự báo xu hướng tiêu thụ, cảnh báo hết hàng',
            status: 'Lên kế hoạch',
            statusColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProjectCard(
            icon: Icons.route,
            title: 'AI Tối ưu tuyến đường',
            description: 'Tối ưu hóa lộ trình giao hàng, tiết kiệm chi phí',
            status: 'Lên kế hoạch',
            statusColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
