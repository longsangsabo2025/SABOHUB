import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider để lấy danh sách bug reports
final bugReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('bug_reports')
      .select('*, profiles(full_name, avatar_url)')
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
});

/// Trang quản lý bug reports cho Admin
class BugReportsManagementPage extends ConsumerStatefulWidget {
  const BugReportsManagementPage({super.key});

  @override
  ConsumerState<BugReportsManagementPage> createState() => _BugReportsManagementPageState();
}

class _BugReportsManagementPageState extends ConsumerState<BugReportsManagementPage> {
  String _filterStatus = 'all';
  
  @override
  Widget build(BuildContext context) {
    final bugReportsAsync = ref.watch(bugReportsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bug Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bugReportsProvider),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                const Text('Trạng thái:'),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tất cả')),
                    ButtonSegment(value: 'open', label: Text('Mới')),
                    ButtonSegment(value: 'in_progress', label: Text('Đang xử lý')),
                    ButtonSegment(value: 'resolved', label: Text('Đã xử lý')),
                    ButtonSegment(value: 'closed', label: Text('Đóng')),
                  ],
                  selected: {_filterStatus},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filterStatus = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          // Bug reports list
          Expanded(
            child: bugReportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(bugReportsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (reports) {
                // Filter reports
                final filteredReports = _filterStatus == 'all'
                    ? reports
                    : reports.where((r) => r['status'] == _filterStatus).toList();
                
                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Không có bug report nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _BugReportCard(
                      report: report,
                      onStatusChanged: () => ref.invalidate(bugReportsProvider),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BugReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onStatusChanged;

  const _BugReportCard({
    required this.report,
    required this.onStatusChanged,
  });

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'open':
        return 'Mới';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã xử lý';
      case 'closed':
        return 'Đóng';
      default:
        return 'Không xác định';
    }
  }

  IconData _getCategoryIcon(String? description) {
    if (description == null) return Icons.bug_report;
    if (description.startsWith('[Bug]')) return Icons.bug_report;
    if (description.startsWith('[Giao diện]')) return Icons.design_services;
    if (description.startsWith('[Hiệu năng]')) return Icons.speed;
    if (description.startsWith('[Dữ liệu]')) return Icons.storage;
    if (description.startsWith('[Đề xuất]')) return Icons.lightbulb;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final status = report['status'] as String?;
    final createdAt = report['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['created_at']))
        : 'N/A';
    final profile = report['profiles'] as Map<String, dynamic>?;
    final userName = profile?['full_name'] ?? 'Người dùng ẩn danh';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(report['description']),
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                report['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (report['image_url'] != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.image, size: 16, color: Colors.blue.shade400),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    final status = report['status'] as String?;
    final createdAt = report['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['created_at']))
        : 'N/A';
    final profile = report['profiles'] as Map<String, dynamic>?;
    final userName = profile?['full_name'] ?? 'Người dùng ẩn danh';
    final imageUrl = report['image_url'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getCategoryIcon(report['description']), color: _getStatusColor(status)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                report['title'] ?? 'Chi tiết Bug Report',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status
              Row(
                children: [
                  const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(color: _getStatusColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reporter
              Row(
                children: [
                  const Text('Người báo cáo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(userName),
                ],
              ),
              const SizedBox(height: 8),
              // Time
              Row(
                children: [
                  const Text('Thời gian: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(createdAt),
                ],
              ),
              const Divider(height: 24),
              // Description
              const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(report['description'] ?? 'Không có mô tả'),
              ),
              // Image
              if (imageUrl != null) ...[
                const SizedBox(height: 16),
                const Text('Hình ảnh đính kèm:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Không thể tải hình ảnh'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Status change buttons
          if (status == 'open') ...[
            TextButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.orange),
              label: const Text('Bắt đầu xử lý'),
              onPressed: () => _updateStatus(context, 'in_progress'),
            ),
          ],
          if (status == 'in_progress') ...[
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Đã xử lý'),
              onPressed: () => _updateStatus(context, 'resolved'),
            ),
          ],
          if (status != 'closed') ...[
            TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.grey),
              label: const Text('Đóng'),
              onPressed: () => _updateStatus(context, 'closed'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('bug_reports')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', report['id']);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái thành "${_getStatusText(newStatus)}"'),
            backgroundColor: Colors.green,
          ),
        );
        onStatusChanged();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
