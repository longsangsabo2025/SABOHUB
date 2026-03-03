import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration for SABOHUB
/// All .env keys are accessed through this class
class AppConfig {
  AppConfig._();

  // ─── Supabase ─────────────────────────────────────────
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // ─── Sentry ───────────────────────────────────────────
  static String get sentryDsn =>
      dotenv.env['SENTRY_DSN'] ?? '';
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;

  // ─── AI: Gemini (FREE) ────────────────────────────────
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';
  static bool get isGeminiEnabled => geminiApiKey.isNotEmpty;

  // ─── AI: OpenAI (paid) ────────────────────────────────
  static String get openaiApiKey =>
      dotenv.env['OPENAI_API_KEY'] ?? '';
  static bool get isOpenAIEnabled => openaiApiKey.isNotEmpty;

  // ─── Telegram Bot ─────────────────────────────────────
  static String get telegramBotToken =>
      dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '';
  static String get telegramChatId =>
      dotenv.env['TELEGRAM_CHAT_ID'] ?? '';
  static bool get isTelegramEnabled =>
      telegramBotToken.isNotEmpty && telegramChatId.isNotEmpty;

  // ─── App Info ─────────────────────────────────────────
  static const String appName = 'SABOHUB';
  static const String appVersion = '1.2.0+16';
  static const String productionUrl = 'https://sabohub-app.vercel.app';

  // ─── Feature Flags ────────────────────────────────────
  /// AI mode: Gemini > OpenAI > Local-only
  static String get aiMode {
    if (isGeminiEnabled) return 'gemini';
    if (isOpenAIEnabled) return 'openai';
    return 'local';
  }

  /// Summary of active integrations
  static Map<String, bool> get integrationStatus => {
        'supabase': supabaseUrl.isNotEmpty,
        'sentry': isSentryEnabled,
        'gemini_ai': isGeminiEnabled,
        'openai': isOpenAIEnabled,
        'telegram': isTelegramEnabled,
      };
}
