import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/travis_message.dart';

void main() {
  group('TravisMessage', () {
    group('TravisMessage.user()', () {
      test('should create user message with correct role', () {
        final msg = TravisMessage.user('Hello Travis');
        expect(msg.role, 'user');
        expect(msg.content, 'Hello Travis');
        expect(msg.isUser, isTrue);
        expect(msg.isAssistant, isFalse);
        expect(msg.isSystem, isFalse);
        expect(msg.id, isNotEmpty);
        expect(msg.timestamp, isA<DateTime>());
      });

      test('should have no specialist metadata', () {
        final msg = TravisMessage.user('test');
        expect(msg.specialist, isNull);
        expect(msg.confidence, isNull);
        expect(msg.toolsUsed, isEmpty);
        expect(msg.latencyMs, isNull);
      });
    });

    group('TravisMessage.system()', () {
      test('should create system message', () {
        final msg = TravisMessage.system('Welcome!');
        expect(msg.role, 'system');
        expect(msg.content, 'Welcome!');
        expect(msg.isSystem, isTrue);
        expect(msg.isUser, isFalse);
        expect(msg.isAssistant, isFalse);
      });
    });

    group('TravisMessage.fromTravisResponse()', () {
      test('should parse full API response', () {
        final json = {
          'response': 'Here is your report',
          'specialist': 'business_analyst',
          'confidence': 0.95,
          'tools_used': ['get_revenue', 'format_report'],
          'latency_ms': 1200,
        };

        final msg = TravisMessage.fromTravisResponse(json);
        expect(msg.role, 'assistant');
        expect(msg.content, 'Here is your report');
        expect(msg.specialist, 'business_analyst');
        expect(msg.confidence, 0.95);
        expect(msg.toolsUsed, ['get_revenue', 'format_report']);
        expect(msg.latencyMs, 1200);
        expect(msg.isAssistant, isTrue);
      });

      test('should handle missing optional fields', () {
        final json = {'response': 'Simple answer'};
        final msg = TravisMessage.fromTravisResponse(json);
        expect(msg.content, 'Simple answer');
        expect(msg.specialist, isNull);
        expect(msg.confidence, isNull);
        expect(msg.toolsUsed, isEmpty);
        expect(msg.latencyMs, isNull);
      });

      test('should handle null response', () {
        final json = <String, dynamic>{};
        final msg = TravisMessage.fromTravisResponse(json);
        expect(msg.content, '');
      });

      test('should handle confidence as int', () {
        final json = {'response': 'test', 'confidence': 1};
        final msg = TravisMessage.fromTravisResponse(json);
        expect(msg.confidence, 1.0);
      });
    });
  });

  group('TravisHealth', () {
    test('should parse JSON correctly', () {
      final json = {
        'status': 'ok',
        'version': 'v7.0',
        'total_tools': 79,
        'uptime_formatted': '2d 5h',
        'specialists': {'analyst': {'tools': 10}},
      };

      final health = TravisHealth.fromJson(json);
      expect(health.status, 'ok');
      expect(health.version, 'v7.0');
      expect(health.totalTools, 79);
      expect(health.uptimeFormatted, '2d 5h');
      expect(health.specialists, isNotEmpty);
    });

    test('isOnline should be true for "ok" status', () {
      final health = TravisHealth.fromJson({'status': 'ok'});
      expect(health.isOnline, isTrue);
    });

    test('isOnline should be true for "healthy" status', () {
      final health = TravisHealth.fromJson({'status': 'healthy'});
      expect(health.isOnline, isTrue);
    });

    test('isOnline should be false for other statuses', () {
      final health = TravisHealth.fromJson({'status': 'error'});
      expect(health.isOnline, isFalse);
    });

    test('should handle missing fields with defaults', () {
      final health = TravisHealth.fromJson({});
      expect(health.status, 'unknown');
      expect(health.version, '');
      expect(health.totalTools, 0);
      expect(health.uptimeFormatted, '');
      expect(health.specialists, isEmpty);
    });
  });

  group('TravisStats', () {
    test('should parse JSON correctly', () {
      final json = {
        'total_conversations': 150,
        'total_messages': 1200,
        'uptime_seconds': 86400,
        'specialists': {'analyst': 50},
      };

      final stats = TravisStats.fromJson(json);
      expect(stats.totalConversations, 150);
      expect(stats.totalMessages, 1200);
      expect(stats.uptimeSeconds, 86400);
      expect(stats.specialists, isNotEmpty);
    });

    test('should handle missing fields with defaults', () {
      final stats = TravisStats.fromJson({});
      expect(stats.totalConversations, 0);
      expect(stats.totalMessages, 0);
      expect(stats.uptimeSeconds, 0);
      expect(stats.specialists, isEmpty);
    });
  });
}
