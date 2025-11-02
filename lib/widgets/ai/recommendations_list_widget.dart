import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_recommendation.dart';
import '../../providers/ai_provider.dart';

/// Widget to display AI recommendations
class RecommendationsListWidget extends ConsumerWidget {
  final String assistantId;
  final String companyId;

  const RecommendationsListWidget({
    super.key,
    required this.assistantId,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync =
        ref.watch(recommendationsProvider(assistantId));

    return recommendationsAsync.when(
      data: (recommendations) => recommendations.isEmpty
          ? _buildEmptyState(context)
          : _buildRecommendationsList(context, ref, recommendations),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có đề xuất',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI sẽ tự động tạo đề xuất dựa trên các phân tích',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(
    BuildContext context,
    WidgetRef ref,
    List<AIRecommendation> recommendations,
  ) {
    // Group by status
    final pending =
        recommendations.where((r) => r.status == 'pending').toList();
    final accepted =
        recommendations.where((r) => r.status == 'accepted').toList();
    final implemented =
        recommendations.where((r) => r.status == 'implemented').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader(context, 'Chờ xét duyệt', pending.length),
          ...pending.map((r) => _buildRecommendationCard(context, ref, r)),
          const SizedBox(height: 16),
        ],
        if (accepted.isNotEmpty) ...[
          _buildSectionHeader(context, 'Đã chấp nhận', accepted.length),
          ...accepted.map((r) => _buildRecommendationCard(context, ref, r)),
          const SizedBox(height: 16),
        ],
        if (implemented.isNotEmpty) ...[
          _buildSectionHeader(context, 'Đã triển khai', implemented.length),
          ...implemented.map((r) => _buildRecommendationCard(context, ref, r)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    WidgetRef ref,
    AIRecommendation recommendation,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRecommendationDetails(context, ref, recommendation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(recommendation.category)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(recommendation.category),
                      size: 20,
                      color: _getCategoryColor(recommendation.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.categoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(recommendation.priority),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                recommendation.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  if (recommendation.confidence != null) ...[
                    Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${(recommendation.confidence! * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (recommendation.estimatedEffort != null) ...[
                    Icon(Icons.timer_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getEffortLabel(recommendation.estimatedEffort!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Spacer(),
                  _buildStatusChip(recommendation.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'low':
        color = Colors.green;
        label = 'Thấp';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'TB';
        break;
      case 'high':
        color = Colors.red;
        label = 'Cao';
        break;
      case 'critical':
        color = Colors.deepOrange;
        label = 'KCấp';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Chờ';
        break;
      case 'reviewing':
        color = Colors.blue;
        label = 'Đang xem';
        break;
      case 'accepted':
        color = Colors.green;
        label = 'Chấp nhận';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Từ chối';
        break;
      case 'implemented':
        color = Colors.purple;
        label = 'Hoàn thành';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'feature':
        return Icons.add_box_outlined;
      case 'process':
        return Icons.settings_suggest_outlined;
      case 'growth':
        return Icons.trending_up;
      case 'technology':
        return Icons.computer_outlined;
      case 'finance':
        return Icons.attach_money;
      case 'operations':
        return Icons.work_outline;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'feature':
        return Colors.blue;
      case 'process':
        return Colors.green;
      case 'growth':
        return Colors.purple;
      case 'technology':
        return Colors.indigo;
      case 'finance':
        return Colors.orange;
      case 'operations':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getEffortLabel(String effort) {
    switch (effort) {
      case 'low':
        return 'Dễ';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Khó';
      default:
        return effort;
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải đề xuất',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDetails(
    BuildContext context,
    WidgetRef ref,
    AIRecommendation recommendation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(recommendation.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(recommendation.category),
                          size: 28,
                          color: _getCategoryColor(recommendation.category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            Text(
                              recommendation.categoryLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Description
                      Text(
                        recommendation.description,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),

                      if (recommendation.reasoning != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Lý do',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recommendation.reasoning!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],

                      if (recommendation.implementationPlan != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Kế hoạch triển khai',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recommendation.implementationPlan!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],

                      if (recommendation.expectedImpact != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Tác động dự kiến',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recommendation.expectedImpact!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Actions
                      if (recommendation.status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _acceptRecommendation(
                                      context, ref, recommendation);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Chấp nhận'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _rejectRecommendation(
                                      context, ref, recommendation);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Từ chối'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (recommendation.status == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _markImplemented(context, ref, recommendation);
                            },
                            icon: const Icon(Icons.done_all),
                            label: const Text('Đánh dấu đã triển khai'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _acceptRecommendation(
    BuildContext context,
    WidgetRef ref,
    AIRecommendation recommendation,
  ) async {
    // TODO: Implement accept logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chấp nhận đề xuất')),
    );
  }

  void _rejectRecommendation(
    BuildContext context,
    WidgetRef ref,
    AIRecommendation recommendation,
  ) async {
    // TODO: Implement reject logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối đề xuất')),
    );
  }

  void _markImplemented(
    BuildContext context,
    WidgetRef ref,
    AIRecommendation recommendation,
  ) async {
    // TODO: Implement mark as implemented logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu hoàn thành')),
    );
  }
}
