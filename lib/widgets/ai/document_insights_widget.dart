import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_uploaded_file.dart';

/// Widget to display document insights
class DocumentInsightsWidget extends ConsumerWidget {
  final AIUploadedFile file;

  const DocumentInsightsWidget({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!file.hasAnalysis) {
      return _buildNoInsights(context);
    }

    final insights = _extractInsights(file.analysisResults!);

    if (insights.isEmpty) {
      return _buildNoInsights(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phân tích chi tiết',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => _buildInsightCard(context, insight)),
      ],
    );
  }

  Widget _buildNoInsights(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chưa có phân tích chi tiết',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    Map<String, dynamic> insight,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(insight['icon'] as String),
                  size: 20,
                  color: _getColor(insight['type'] as String),
                ),
                const SizedBox(width: 8),
                Text(
                  insight['title'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getColor(insight['type'] as String),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight['description'] as String,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _extractInsights(Map<String, dynamic> analysis) {
    final insights = <Map<String, dynamic>>[];

    // Image insights
    if (file.isImage) {
      if (analysis['cleanliness'] != null) {
        insights.add({
          'type': 'cleanliness',
          'title': 'Vệ sinh',
          'description': analysis['cleanliness'],
          'icon': 'cleaning',
        });
      }

      if (analysis['lighting'] != null) {
        insights.add({
          'type': 'lighting',
          'title': 'Ánh sáng',
          'description': analysis['lighting'],
          'icon': 'light',
        });
      }

      if (analysis['layout'] != null) {
        insights.add({
          'type': 'layout',
          'title': 'Bố cục',
          'description': analysis['layout'],
          'icon': 'layout',
        });
      }

      if (analysis['improvements'] != null) {
        insights.add({
          'type': 'improvements',
          'title': 'Đề xuất cải thiện',
          'description': analysis['improvements'],
          'icon': 'improve',
        });
      }
    }

    // Document insights
    if (file.isPdf || file.isDocument) {
      if (analysis['summary'] != null) {
        insights.add({
          'type': 'summary',
          'title': 'Tóm tắt',
          'description': analysis['summary'],
          'icon': 'summary',
        });
      }

      if (analysis['key_points'] != null) {
        final keyPoints = analysis['key_points'] is List
            ? (analysis['key_points'] as List).join('\n• ')
            : analysis['key_points'].toString();

        insights.add({
          'type': 'key_points',
          'title': 'Điểm chính',
          'description': '• $keyPoints',
          'icon': 'list',
        });
      }
    }

    // General analysis
    if (analysis['description'] != null &&
        !insights.any((i) => i['type'] == 'summary')) {
      insights.add({
        'type': 'general',
        'title': 'Mô tả',
        'description': analysis['description'],
        'icon': 'description',
      });
    }

    return insights;
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'light':
        return Icons.lightbulb_outline;
      case 'layout':
        return Icons.dashboard_outlined;
      case 'improve':
        return Icons.tips_and_updates_outlined;
      case 'summary':
        return Icons.summarize_outlined;
      case 'list':
        return Icons.list_alt;
      case 'description':
        return Icons.description_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'cleanliness':
        return Colors.green;
      case 'lighting':
        return Colors.orange;
      case 'layout':
        return Colors.blue;
      case 'improvements':
        return Colors.purple;
      case 'summary':
        return Colors.indigo;
      case 'key_points':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
