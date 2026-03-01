import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// Gemini AI Service — calls Google Gemini API for natural language responses
/// FREE tier: 15 requests/min, 1M tokens/day
/// Get key: https://aistudio.google.com/app/apikey
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static bool get isEnabled => apiKey.isNotEmpty;

  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Send a message to Gemini with business context
  Future<String> chat(String userMessage, {String? businessContext}) async {
    if (!isEnabled) {
      return '';
    }

    try {
      final systemPrompt = _buildSystemPrompt(businessContext);

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$systemPrompt\n\nCâu hỏi: $userMessage'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_ONLY_HIGH'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_ONLY_HIGH'
          },
        ],
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? '';
          }
        }
        return '⚠️ Gemini không trả về kết quả.';
      } else if (response.statusCode == 429) {
        AppLogger.warn('Gemini rate limit hit');
        return ''; // Fallback to local
      } else {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Unknown error';
        AppLogger.error('Gemini API error: ${response.statusCode} — $message');
        return ''; // Fallback to local
      }
    } catch (e) {
      AppLogger.error('Gemini service error', e);
      return ''; // Fallback to local on any error
    }
  }

  String _buildSystemPrompt(String? businessContext) {
    return '''Bạn là trợ lý AI của SABOHUB — hệ thống quản lý doanh nghiệp.
Trả lời bằng tiếng Việt, ngắn gọn, dùng emoji phù hợp.
Dùng **bold** cho số liệu quan trọng.
Nếu có dữ liệu thực bên dưới, hãy phân tích và đưa ra nhận xét/gợi ý.
Nếu không có dữ liệu, hãy trả lời dựa trên kiến thức chung về quản lý kinh doanh.

${businessContext != null ? 'DỮ LIỆU THỰC TẾ CỦA DOANH NGHIỆP:\n$businessContext' : ''}''';
  }
}
