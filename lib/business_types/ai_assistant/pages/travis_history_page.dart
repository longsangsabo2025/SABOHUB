import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../../../services/travis_service.dart';

/// Travis History — list of past conversation sessions.
class TravisHistoryPage extends ConsumerStatefulWidget {
  const TravisHistoryPage({super.key});

  @override
  ConsumerState<TravisHistoryPage> createState() => _TravisHistoryPageState();
}

class _TravisHistoryPageState extends ConsumerState<TravisHistoryPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _sessions;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.parse('${TravisService.baseUrl}/sessions');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is List)
            ? data.cast<Map<String, dynamic>>()
            : (data['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _sessions = list;
          _loading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải lịch sử',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_sessions == null || _sessions!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Chưa có cuộc trò chuyện nào',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Bắt đầu chat với Travis ở tab Chat',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final session = _sessions![index];
          final lastMessage = session['last_message'] as String? ?? '';
          final messageCount = session['message_count'] as int? ?? 0;
          final timestamp = session['updated_at'] as String? ?? '';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF8B5CF6)),
              ),
              title: Text(
                lastMessage.length > 60 ? '${lastMessage.substring(0, 60)}...' : lastMessage,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$messageCount messages • ${_formatTime(timestamp)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return timestamp;
    }
  }
}
