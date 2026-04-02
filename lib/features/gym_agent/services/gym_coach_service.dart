import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_logger.dart';
import '../models/gym_coach_message.dart';

/// GymCoachService — AI-powered gym coaching via Travis API backend.
///
/// All Gemini calls go through Travis API (/api/gym/chat).
/// API key stays server-side. mem0 provides long-term memory.
class GymCoachService {
  static final GymCoachService _instance = GymCoachService._internal();
  factory GymCoachService() => _instance;
  GymCoachService._internal();

  http.Client _client = http.Client();

  void setClient(http.Client client) => _client = client;

  static String get _apiUrl =>
      dotenv.env['TRAVIS_API_URL'] ?? 'http://localhost:8300';

  static String get _apiKey =>
      dotenv.env['TRAVIS_API_KEY'] ?? '';

  static const Duration _timeout = Duration(seconds: 30);

  /// System prompt is now on the server side.
  /// This is kept only for reference / local fallback detection.
  static const systemPrompt = 'Gym Coach AI — managed by backend';

  final List<Map<String, String>> _conversationHistory = [];

  /// Send a message to Gym Coach AI via Travis API.
  Future<GymCoachMessage> chat({
    required String message,
    String? userContext,
  }) async {
    AppLogger.api('GymCoach chat → $message');

    // Add user message to local history for multi-turn context
    _conversationHistory.add({'role': 'user', 'content': message});

    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

    final url = Uri.parse('$_apiUrl/api/gym/chat');
    final body = jsonEncode({
      'message': message,
      'user_id': userId,
      'user_context': userContext,
      'conversation_history': _conversationHistory,
    });

    try {
      final response = await _client
          .post(url, headers: _headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = json['text'] as String? ?? '';

        if (text.isEmpty) {
          throw GymCoachException('Empty response from Gym Coach AI');
        }

        // Add assistant response to local history
        _conversationHistory.add({'role': 'assistant', 'content': text});

        // Keep history reasonable (last 20 messages)
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(
              0, _conversationHistory.length - 20);
        }

        final messageType = _detectMessageType(text);
        AppLogger.api(
            'GymCoach response ← ${text.length} chars (${json['memories_used'] ?? 0} memories used)');
        return GymCoachMessage.assistant(text, type: messageType);
      }

      AppLogger.error('GymCoach API error: ${response.statusCode}');
      throw GymCoachException(
        'Gym Coach AI error: ${response.statusCode}',
      );
    } catch (e) {
      if (e is GymCoachException) rethrow;
      AppLogger.error('GymCoach error: $e');

      // Remove failed user message from history
      if (_conversationHistory.isNotEmpty) {
        _conversationHistory.removeLast();
      }

      throw GymCoachException('Không thể kết nối Gym Coach AI: $e');
    }
  }

  /// Clear conversation history (new session).
  void clearHistory() {
    _conversationHistory.clear();
    AppLogger.info('GymCoach: conversation cleared');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      };

  /// Detect the type of response for special UI rendering.
  GymMessageType _detectMessageType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('chương trình tập') ||
        lower.contains('workout plan') ||
        lower.contains('buổi tập') ||
        (lower.contains('set') && lower.contains('rep'))) {
      return GymMessageType.workoutPlan;
    }
    if (lower.contains('dinh dưỡng') ||
        lower.contains('protein') ||
        lower.contains('calories') ||
        lower.contains('macro')) {
      return GymMessageType.nutritionAdvice;
    }
    if (lower.contains('form') ||
        lower.contains('tư thế') ||
        lower.contains('kỹ thuật')) {
      return GymMessageType.formCorrection;
    }
    return GymMessageType.text;
  }
}

class GymCoachException implements Exception {
  final String message;
  const GymCoachException(this.message);

  @override
  String toString() => 'GymCoachException: $message';
}
