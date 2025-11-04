import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ai_uploaded_file.dart';
import '../../../models/company.dart';
import '../../../providers/document_provider.dart';

/// Documents Tab for Company Details
/// Shows document list with AI insights analysis
class DocumentsTab extends ConsumerWidget {
  final Company company;

  const DocumentsTab({
    super.key,
    required this.company,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(companyDocumentsProvider(company.id));
    final insightsAsync = ref.watch(documentInsightsProvider(company.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài liệu vận hành',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hệ thống tài liệu và phân tích tự động từ AI',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // AI Insights Section
          insightsAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (insights) => _buildInsightsSection(insights),
          ),

          const SizedBox(height: 32),

          // Documents List
          const Text(
            'Danh sách tài liệu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          documentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $error'),
              ),
            ),
            data: (documents) {
              if (documents.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có tài liệu nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children:
                    documents.map((doc) => _buildDocumentCard(context, doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Phân tích tự động từ AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),

            // Org Chart
            if (insights['org_chart'] != null) ...[
              _buildOrgChartSummary(insights['org_chart']),
              const Divider(height: 32),
            ],

            // Tasks Summary
            if (insights['suggested_tasks'] != null) ...[
              _buildTasksSummary(insights['suggested_tasks']),
              const Divider(height: 32),
            ],

            // KPIs Summary
            if (insights['kpis'] != null) ...[
              _buildKPIsSummary(insights['kpis']),
              const Divider(height: 32),
            ],

            // Programs Summary
            if (insights['programs'] != null) ...[
              _buildProgramsSummary(insights['programs']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrgChartSummary(Map<String, dynamic> orgChart) {
    final positions = orgChart['positions'] as List? ?? [];
    final totalNeeded = orgChart['total_needed'] ?? 0;
    final totalCurrent = orgChart['total_current'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_tree, size: 20),
            const SizedBox(width: 8),
            const Text('Sơ đồ tổ chức',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('$totalCurrent/$totalNeeded vị trí'),
              backgroundColor: Colors.blue[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...positions.take(5).map((pos) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    pos['status'] == 'filled'
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color:
                        pos['status'] == 'filled' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(pos['title'] ?? '')),
                  if (pos['count'] != null)
                    Text('x${pos['count']}',
                        style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTasksSummary(List<dynamic> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_box, size: 20),
            const SizedBox(width: 8),
            const Text('Công việc gợi ý',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${tasks.length} tasks'),
              backgroundColor: Colors.green[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tasks.take(5).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle,
                      size: 8, color: _getPriorityColor(task['priority'])),
                  const SizedBox(width: 12),
                  Expanded(child: Text(task['title'] ?? '')),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task['category'] ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildKPIsSummary(List<dynamic> kpis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, size: 20),
            const SizedBox(width: 8),
            const Text('KPI đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${kpis.length} chỉ tiêu'),
              backgroundColor: Colors.purple[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...kpis.take(5).map((kpi) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(kpi['name'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500))),
                      Text('${kpi['weight']}%',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (kpi['weight'] ?? 0) / 100,
                    backgroundColor: Colors.grey[200],
                    color: Colors.purple,
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildProgramsSummary(List<dynamic> programs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 20),
            const SizedBox(width: 8),
            const Text('Chương trình & Sự kiện',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
              label: Text('${programs.length} chương trình'),
              backgroundColor: Colors.orange[50],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...programs.map((program) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getProgramColor(program['type']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      program['code'] ?? '',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        if (program['description'] != null)
                          Text(
                            program['description'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(program['status']),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, AIUploadedFile doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(Icons.description, color: Colors.blue[700]),
        ),
        title: Text(doc.fileName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${(doc.fileSize / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 4),
            Text(
              'Tạo: ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _buildDocStatusBadge(doc.status),
        onTap: () {
          // Show document detail dialog
          _showDocumentDetail(context, doc);
        },
      ),
    );
  }

  Widget _buildDocStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'analyzed':
        color = Colors.green;
        label = 'Đã phân tích';
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Đang xử lý';
        break;
      case 'error':
        color = Colors.red;
        label = 'Lỗi';
        break;
      default:
        color = Colors.blue;
        label = 'Đã tải lên';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Đang áp dụng';
        break;
      case 'planned':
        color = Colors.blue;
        label = 'Kế hoạch';
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Hoàn thành';
        break;
      default:
        color = Colors.orange;
        label = 'Chưa rõ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getProgramColor(String? type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'membership':
        return Colors.purple;
      case 'event':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showDocumentDetail(BuildContext context, AIUploadedFile doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description,
                        color: Colors.blue[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc.fileName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    doc.extractedText ?? 'Không có nội dung',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
