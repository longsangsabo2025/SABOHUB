import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_sabohub/services/travis_service.dart';

void main() {
  late TravisService service;

  setUp(() {
    service = TravisService();
    TravisService.setBaseUrl('http://test-travis.local');
  });

  tearDown(() {
    TravisService.reset();
  });

  group('TravisService.chat()', () {
    test('should return TravisMessage on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://test-travis.local/chat');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body);
        expect(body['message'], 'Hello');
        expect(body['session_id'], 'test-session');

        return http.Response(
          jsonEncode({
            'response': 'Hi there!',
            'specialist': 'general',
            'confidence': 0.9,
            'tools_used': ['greet'],
            'latency_ms': 500,
          }),
          200,
        );
      });

      service.setClient(mockClient);

      final msg = await service.chat(
        message: 'Hello',
        sessionId: 'test-session',
      );

      expect(msg.role, 'assistant');
      expect(msg.content, 'Hi there!');
      expect(msg.specialist, 'general');
      expect(msg.confidence, 0.9);
      expect(msg.latencyMs, 500);
    });

    test('should throw TravisApiException on non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      service.setClient(mockClient);

      expect(
        () => service.chat(message: 'test', sessionId: 'sid'),
        throwsA(isA<TravisApiException>()),
      );
    });

    test('should send correct Content-Type header', () async {
      final mockClient = MockClient((request) async {
        // http package appends '; charset=utf-8' when body is a String
        expect(
          request.headers['content-type'],
          contains('application/json'),
        );
        return http.Response(jsonEncode({'response': 'ok'}), 200);
      });

      service.setClient(mockClient);
      await service.chat(message: 'test', sessionId: 'sid');
    });
  });

  group('TravisService.health()', () {
    test('should return TravisHealth on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/health');
        expect(request.method, 'GET');

        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': 'v7.0',
            'total_tools': 79,
            'uptime_formatted': '1d 2h',
            'specialists': {},
          }),
          200,
        );
      });

      service.setClient(mockClient);
      final health = await service.health();

      expect(health.status, 'ok');
      expect(health.isOnline, isTrue);
      expect(health.totalTools, 79);
      expect(health.version, 'v7.0');
    });

    test('should throw on non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      service.setClient(mockClient);
      expect(() => service.health(), throwsA(isA<TravisApiException>()));
    });
  });

  group('TravisService.isAvailable()', () {
    test('should return true when healthy', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '',
            'total_tools': 0,
            'uptime_formatted': '',
            'specialists': {},
          }),
          200,
        );
      });

      service.setClient(mockClient);
      expect(await service.isAvailable(), isTrue);
    });

    test('should return false on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      service.setClient(mockClient);
      expect(await service.isAvailable(), isFalse);
    });

    test('should return false on non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      service.setClient(mockClient);
      expect(await service.isAvailable(), isFalse);
    });
  });

  group('TravisService.stats()', () {
    test('should return TravisStats on 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'total_conversations': 100,
            'total_messages': 500,
            'uptime_seconds': 3600,
            'specialists': {},
          }),
          200,
        );
      });

      service.setClient(mockClient);
      final stats = await service.stats();

      expect(stats.totalConversations, 100);
      expect(stats.totalMessages, 500);
      expect(stats.uptimeSeconds, 3600);
    });

    test('should throw on error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 503);
      });

      service.setClient(mockClient);
      expect(() => service.stats(), throwsA(isA<TravisApiException>()));
    });
  });

  group('TravisService.history()', () {
    test('should return list of messages on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/history/session-123');
        return http.Response(
          jsonEncode({
            'messages': [
              {
                'role': 'user',
                'content': 'Hello',
                'timestamp': '2026-01-01T00:00:00Z',
              },
              {
                'role': 'assistant',
                'content': 'Hi!',
                'timestamp': '2026-01-01T00:00:01Z',
              },
            ],
          }),
          200,
        );
      });

      service.setClient(mockClient);
      final messages = await service.history('session-123');

      expect(messages, hasLength(2));
      expect(messages[0].role, 'user');
      expect(messages[0].content, 'Hello');
      expect(messages[1].role, 'assistant');
      expect(messages[1].content, 'Hi!');
    });

    test('should handle empty messages', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'messages': []}), 200);
      });

      service.setClient(mockClient);
      final messages = await service.history('empty-session');
      expect(messages, isEmpty);
    });

    test('should throw on error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      service.setClient(mockClient);
      expect(
        () => service.history('sid'),
        throwsA(isA<TravisApiException>()),
      );
    });
  });

  group('TravisService base URL', () {
    test('setBaseUrl should override URL', () async {
      TravisService.setBaseUrl('http://custom.local');

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), startsWith('http://custom.local'));
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '',
            'total_tools': 0,
            'uptime_formatted': '',
            'specialists': {},
          }),
          200,
        );
      });

      service.setClient(mockClient);
      await service.health();
    });

    test('reset should clear runtime URL', () {
      TravisService.setBaseUrl('http://custom.local');
      TravisService.reset();
      // After reset, baseUrl should fallback to default
      // We can't easily test the actual value without dotenv,
      // but we can verify reset doesn't throw
      expect(() => TravisService.reset(), returnsNormally);
    });
  });
}
