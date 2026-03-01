import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// Send notifications to CEO via Telegram Bot API
/// Requires TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in .env
class TelegramNotifyService {
  static final TelegramNotifyService _instance =
      TelegramNotifyService._internal();
  factory TelegramNotifyService() => _instance;
  TelegramNotifyService._internal();

  static String get _botToken => dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '';
  static String get _chatId => dotenv.env['TELEGRAM_CHAT_ID'] ?? '';
  static bool get isEnabled => _botToken.isNotEmpty && _chatId.isNotEmpty;

  /// Send a text message to CEO's Telegram
  Future<bool> sendMessage(String text, {bool markdown = true}) async {
    if (!isEnabled) {
      AppLogger.warn('Telegram not configured — skipping notification');
      return false;
    }

    try {
      final url = Uri.parse(
          'https://api.telegram.org/bot$_botToken/sendMessage');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': _chatId,
              'text': text,
              'parse_mode': markdown ? 'Markdown' : null,
              'disable_web_page_preview': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }

      AppLogger.error(
          'Telegram send failed: ${response.statusCode} — ${response.body}');
      return false;
    } catch (e) {
      AppLogger.error('Telegram notify error', e);
      return false;
    }
  }

  /// Test the bot connection
  Future<bool> testConnection() async {
    return sendMessage(
      '✅ *SABOHUB Bot đã kết nối thành công!*\n\n'
      'Bot sẽ gửi thông báo quan trọng từ hệ thống SABOHUB.',
    );
  }

  /// Send an alert to CEO
  Future<bool> sendAlert(String title, String message) async {
    return sendMessage('⚠️ *$title*\n\n$message');
  }

  /// Send a quick status update  
  Future<bool> sendStatus(String status) async {
    return sendMessage('📢 $status');
  }
}
