import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/travis_message.dart';
import '../utils/app_logger.dart';

/// Travis AI Service — REST client for Travis AI backend
///
/// Endpoints:
///   POST /chat        — send message, get response
///   GET  /health      — health check + tools count
///   GET  /stats        — usage statistics
///   GET  /history/:id — conversation history
///
/// Production: https://travis-ai-9npn.onrender.com
class TravisService {
  static final TravisService _instance = TravisService._internal();
  factory TravisService() => _instance;
  TravisService._internal();

  /// Base URL — configurable via .env or runtime override
  static String get baseUrl =>
      _runtimeBaseUrl ??
      dotenv.env['TRAVIS_API_URL'] ??
      'https://travis-ai-9npn.onrender.com';

  static String? _runtimeBaseUrl;

  /// Override base URL at runtime (e.g., from company settings)
  static void setBaseUrl(String? url) {
    _runtimeBaseUrl = url;
  }

  /// Reset state on logout
  static void reset() {
    _runtimeBaseUrl = null;
  }

  /// HTTP client (injectable for testing)
  http.Client _client = http.Client();

  /// Inject custom client (for testing)
  // ignore: use_setters_to_change_properties
  void setClient(http.Client client) => _client = client;

  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _healthTimeout = Duration(seconds: 10);

  // ─── Chat ─────────────────────────────────────────────────────

  /// Send a chat message to Travis AI.
  ///
  /// Returns a [TravisMessage] with specialist info, confidence, etc.
  /// Throws on network error or non-200 response.
  Future<TravisMessage> chat({
    required String message,
    required String sessionId,
  }) async {
    AppLogger.api('Travis chat → $message');

    final url = Uri.parse('$baseUrl/chat');
    final body = jsonEncode({
      'message': message,
      'session_id': sessionId,
    });

    final response = await _client
        .post(url, headers: _headers, body: body)
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = TravisMessage.fromTravisResponse(json);
      AppLogger.api('Travis response ← ${msg.specialist} (${msg.latencyMs}ms)');
      return msg;
    }

    AppLogger.error('Travis chat error: ${response.statusCode}');
    throw TravisApiException(
      'Travis AI error: ${response.statusCode} ${response.reasonPhrase}',
      statusCode: response.statusCode,
    );
  }

  // ─── Health ───────────────────────────────────────────────────

  /// Check if Travis AI is online and get system info.
  Future<TravisHealth> health() async {
    final url = Uri.parse('$baseUrl/health');
    final response = await _client.get(url).timeout(_healthTimeout);

    if (response.statusCode == 200) {
      return TravisHealth.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw TravisApiException(
      'Health check failed: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  /// Quick check — returns true if Travis is reachable and healthy.
  Future<bool> isAvailable() async {
    try {
      final h = await health();
      return h.isOnline;
    } catch (_) {
      return false;
    }
  }

  // ─── Stats ────────────────────────────────────────────────────

  /// Get usage statistics.
  Future<TravisStats> stats() async {
    final url = Uri.parse('$baseUrl/stats');
    final response = await _client.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return TravisStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw TravisApiException(
      'Stats failed: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  // ─── History ──────────────────────────────────────────────────

  /// Get conversation history for a session.
  Future<List<TravisMessage>> history(String sessionId) async {
    final url = Uri.parse('$baseUrl/history/$sessionId');
    final response = await _client.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'] as List? ?? [];
      return messages.map((m) {
        final map = m as Map<String, dynamic>;
        return TravisMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: map['role'] as String? ?? 'assistant',
          content: map['content'] as String? ?? '',
          timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    }

    throw TravisApiException(
      'History failed: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };
}

/// Custom exception for Travis AI API errors.
class TravisApiException implements Exception {
  final String message;
  final int? statusCode;

  const TravisApiException(this.message, {this.statusCode});

  @override
  String toString() => 'TravisApiException($statusCode): $message';
}
