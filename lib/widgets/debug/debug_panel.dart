import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../debug/debug_manager.dart';

/// Debug Panel Widget for Flutter Web - Shows debug info overlay
class DebugPanel extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DebugPanel({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _isVisible = false;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topLeft, // Fix: Add non-directional alignment
        children: [
          widget.child,
          if (_isVisible) _buildDebugOverlay(),
          _buildToggleButton(),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Positioned(
      top: 50,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
            if (_isVisible) {
              DebugManager.userAction('Debug Panel Opened');
            } else {
              DebugManager.userAction('Debug Panel Closed');
            }
          });
        },
        backgroundColor: _isVisible ? Colors.red : Colors.blue,
        child: Icon(_isVisible ? Icons.close : Icons.bug_report),
      ),
    );
  }

  Widget _buildDebugOverlay() {
    final stats = DebugManager.getStats();
    final logs = DebugManager.getLogs();
    final context = DebugManager.getContext();

    return Positioned(
      top: 100,
      right: 16,
      width: _isExpanded ? 600 : 300,
      height: _isExpanded ? 500 : 300,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            children: [
              _buildHeader(stats),
              Expanded(
                child: _isExpanded
                    ? _buildExpandedView(logs, context)
                    : _buildCompactView(stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Debug Console',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${stats['total']}',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.compress : Icons.expand,
              color: Colors.white,
              size: 18,
            ),
          ),
          IconButton(
            onPressed: () {
              DebugManager.clearLogs();
              setState(() {});
            },
            icon: const Icon(Icons.clear_all, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatItem('📊 Total Logs', '${stats['total']}'),
          const SizedBox(height: 8),
          const Text(
            'By Level:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...((stats['byLevel'] as Map<String, int>).entries.map(
                (entry) => _buildStatItem(
                  _getLevelIcon(entry.key),
                  '${entry.value}',
                  isSmall: true,
                ),
              )),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportLogs,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openConsole,
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text('Console', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(List<DebugLog> logs, Map<String, dynamic> context) {
    return Column(
      children: [
        // Context section
        if (context.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[800],
            child: Text(
              '🔍 Context: ${context.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
        ],

        // Logs section
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: logs.length,
            reverse: true, // Show newest logs first
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index];
              return _buildLogItem(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(DebugLog log) {
    final color = _getLogColor(log.level);
    final icon = DebugManager._getLevelIcon(log.level);
    final time =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.grey[700]!, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  log.tag,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  log.message,
                  style: TextStyle(color: color, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (log.data != null && log.data!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '📊 ${log.data!.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
              style: const TextStyle(color: Colors.white54, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmall ? 10 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey; // VERBOSE
      case 1:
        return Colors.blue; // DEBUG
      case 2:
        return Colors.green; // INFO
      case 3:
        return Colors.orange; // WARNING
      case 4:
        return Colors.red; // ERROR
      case 5:
        return Colors.purple; // CRITICAL
      default:
        return Colors.white;
    }
  }

  String _getLevelIcon(String levelName) {
    switch (levelName.toLowerCase()) {
      case 'verbose':
        return '🔍';
      case 'debug':
        return '🐛';
      case 'info':
        return 'ℹ️';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'critical':
        return '🚨';
      default:
        return '📝';
    }
  }

  void _exportLogs() {
    final data = DebugManager.exportLogs();
    Clipboard.setData(ClipboardData(text: data));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug logs exported to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );

    DebugManager.userAction('Logs Exported');
  }

  void _openConsole() {
    DebugManager.info('🔧 Open Chrome DevTools to see detailed console logs');
    DebugManager.userAction('Console Opened');
  }
}

/// Debug Info Widget - Shows quick debug info
class DebugInfo extends StatelessWidget {
  final String? title;
  final Map<String, dynamic>? data;

  const DebugInfo({
    super.key,
    this.title,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (data != null) ...[
            ...data!.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}: ',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
