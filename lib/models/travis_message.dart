/// Travis AI Message Model
///
/// Represents a chat message in Travis AI conversation.
/// Lightweight — không lưu Supabase, chỉ local state + REST API.
class TravisMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  // Travis AI metadata (only for assistant messages)
  final String? specialist;
  final double? confidence;
  final List<String> toolsUsed;
  final int? latencyMs;

  const TravisMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.specialist,
    this.confidence,
    this.toolsUsed = const [],
    this.latencyMs,
  });

  /// Create user message
  factory TravisMessage.user(String content) {
    return TravisMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Create from Travis AI API response
  factory TravisMessage.fromTravisResponse(Map<String, dynamic> json) {
    return TravisMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: json['response'] as String? ?? '',
      timestamp: DateTime.now(),
      specialist: json['specialist'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      toolsUsed: (json['tools_used'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latencyMs: json['latency_ms'] as int?,
    );
  }

  /// Create system message (errors, status)
  factory TravisMessage.system(String content) {
    return TravisMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

  /// Serialize to JSON for local persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (specialist != null) 'specialist': specialist,
        if (confidence != null) 'confidence': confidence,
        if (toolsUsed.isNotEmpty) 'tools_used': toolsUsed,
        if (latencyMs != null) 'latency_ms': latencyMs,
      };

  /// Deserialize from JSON (local persistence).
  factory TravisMessage.fromJson(Map<String, dynamic> json) {
    return TravisMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'system',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      specialist: json['specialist'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      toolsUsed: (json['tools_used'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latencyMs: json['latency_ms'] as int?,
    );
  }
}

/// Travis AI health status
class TravisHealth {
  final String status;
  final String version;
  final int totalTools;
  final String uptimeFormatted;
  final Map<String, dynamic> specialists;

  const TravisHealth({
    required this.status,
    required this.version,
    required this.totalTools,
    required this.uptimeFormatted,
    required this.specialists,
  });

  factory TravisHealth.fromJson(Map<String, dynamic> json) {
    return TravisHealth(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '',
      totalTools: json['total_tools'] as int? ?? 0,
      uptimeFormatted: json['uptime_formatted'] as String? ?? '',
      specialists: json['specialists'] as Map<String, dynamic>? ?? {},
    );
  }

  bool get isOnline => status == 'ok' || status == 'healthy';
}

/// Travis AI usage stats
class TravisStats {
  final int totalConversations;
  final int totalMessages;
  final int uptimeSeconds;
  final Map<String, dynamic> specialists;

  const TravisStats({
    required this.totalConversations,
    required this.totalMessages,
    required this.uptimeSeconds,
    required this.specialists,
  });

  factory TravisStats.fromJson(Map<String, dynamic> json) {
    return TravisStats(
      totalConversations: json['total_conversations'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      uptimeSeconds: json['uptime_seconds'] as int? ?? 0,
      specialists: json['specialists'] as Map<String, dynamic>? ?? {},
    );
  }
}
