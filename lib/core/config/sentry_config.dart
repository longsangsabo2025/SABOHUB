import 'package:flutter_dotenv/flutter_dotenv.dart';

class SentryConfig {
  static String get dsn => dotenv.env['SENTRY_DSN'] ?? '';
  static bool get isEnabled => dsn.isNotEmpty;
  static const double tracesSampleRate = 0.3;
  static const String environment = String.fromEnvironment('SENTRY_ENV', defaultValue: 'production');
}
