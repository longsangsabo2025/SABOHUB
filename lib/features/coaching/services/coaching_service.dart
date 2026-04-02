import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_logger.dart';
import '../models/coaching_models.dart';

/// CoachingService — AI-powered self-improvement coaching via admin-api.
///
/// All Gemini calls go server-side through /api/coaching/*.
/// Supports 10 coaching programs with mem0 + Brain RAG.
class CoachingService {
  static final CoachingService _instance = CoachingService._internal();
  factory CoachingService() => _instance;
  CoachingService._internal();

  http.Client _client = http.Client();

  void setClient(http.Client client) => _client = client;

  static String get _apiUrl =>
      dotenv.env['TRAVIS_API_URL'] ?? 'http://localhost:8300';

  static String get _apiKey => dotenv.env['TRAVIS_API_KEY'] ?? '';

  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
      };

  final Map<String, List<Map<String, String>>> _histories = {};

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  /// Fetch available coaching programs.
  Future<List<CoachingProgram>> getPrograms() async {
    try {
      final url = Uri.parse('$_apiUrl/api/coaching/programs');
      final response =
          await _client.get(url, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final list = json['programs'] as List<dynamic>;
        return list
            .map((e) =>
                CoachingProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw CoachingException('Failed to get programs: ${response.statusCode}');
    } catch (e) {
      if (e is CoachingException) rethrow;
      AppLogger.error('Coaching getPrograms error: $e');
      throw CoachingException('Không thể tải danh sách chương trình: $e');
    }
  }

  /// Send a chat message within a coaching program.
  Future<CoachingMessage> chat({
    required String message,
    required String programId,
    String? userContext,
  }) async {
    AppLogger.api('Coaching[$programId] chat → $message');

    // Manage per-program conversation history
    _histories.putIfAbsent(programId, () => []);
    final history = _histories[programId]!;
    history.add({'role': 'user', 'content': message});

    final url = Uri.parse('$_apiUrl/api/coaching/chat');
    final body = jsonEncode({
      'message': message,
      'program_id': programId,
      'user_id': _userId,
      'user_context': userContext,
      'conversation_history': history,
    });

    try {
      final response =
          await _client.post(url, headers: _headers, body: body).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = json['text'] as String? ?? '';

        if (text.isEmpty) {
          throw CoachingException('Empty response from coaching AI');
        }

        history.add({'role': 'assistant', 'content': text});

        // Keep history reasonable
        if (history.length > 20) {
          history.removeRange(0, history.length - 20);
        }

        AppLogger.api(
            'Coaching[$programId] ← ${text.length} chars (${json['memories_used'] ?? 0} memories, ${json['brain_results'] ?? 0} brain)');
        return CoachingMessage.assistant(text);
      }

      AppLogger.error('Coaching API error: ${response.statusCode}');
      throw CoachingException('Coaching AI error: ${response.statusCode}');
    } catch (e) {
      if (e is CoachingException) rethrow;
      AppLogger.error('Coaching error: $e');

      // Remove failed user message
      if (history.isNotEmpty) history.removeLast();

      throw CoachingException('Không thể kết nối Coaching AI: $e');
    }
  }

  /// Generate a structured plan for a program.
  Future<Map<String, dynamic>> generatePlan({
    required String programId,
    int? days,
    String? customGoal,
  }) async {
    AppLogger.api('Coaching[$programId] plan → ${days ?? 'default'} days');

    final url = Uri.parse('$_apiUrl/api/coaching/plan');
    final body = jsonEncode({
      'user_id': _userId,
      'program_id': programId,
      if (days != null) 'days': days,
      if (customGoal != null) 'custom_goal': customGoal,
    });

    try {
      final response = await _client
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['plan'] as Map<String, dynamic>;
      }
      throw CoachingException('Plan generation failed: ${response.statusCode}');
    } catch (e) {
      if (e is CoachingException) rethrow;
      throw CoachingException('Không thể tạo kế hoạch: $e');
    }
  }

  /// Clear conversation history for a program.
  void clearHistory(String programId) {
    _histories.remove(programId);
  }
}

class CoachingException implements Exception {
  final String message;
  CoachingException(this.message);

  @override
  String toString() => message;
}
