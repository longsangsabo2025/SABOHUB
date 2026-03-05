import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/core/viewmodels/travis_chat_view_model.dart';
import 'package:flutter_sabohub/models/travis_message.dart';

void main() {
  group('TravisChatState', () {
    test('should create with required sessionId', () {
      final state = TravisChatState(sessionId: 'test-session');

      expect(state.sessionId, 'test-session');
      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
      expect(state.isOnline, isFalse);
      expect(state.health, isNull);
      expect(state.errorMessage, isNull);
    });

    group('copyWith', () {
      late TravisChatState baseState;

      setUp(() {
        baseState = TravisChatState(sessionId: 'base');
      });

      test('should copy messages', () {
        final msg = TravisMessage.user('hello');
        final updated = baseState.copyWith(messages: [msg]);
        expect(updated.messages, hasLength(1));
        expect(updated.messages.first.content, 'hello');
        // Original unchanged
        expect(baseState.messages, isEmpty);
      });

      test('should copy isSending', () {
        final updated = baseState.copyWith(isSending: true);
        expect(updated.isSending, isTrue);
        expect(baseState.isSending, isFalse);
      });

      test('should copy isOnline', () {
        final updated = baseState.copyWith(isOnline: true);
        expect(updated.isOnline, isTrue);
      });

      test('should copy sessionId', () {
        final updated = baseState.copyWith(sessionId: 'new-session');
        expect(updated.sessionId, 'new-session');
      });

      test('should copy health', () {
        final health = TravisHealth.fromJson(<String, dynamic>{
          'status': 'ok',
          'version': 'v7',
          'total_tools': 10,
          'uptime_formatted': '1h',
          'specialists': <String, dynamic>{},
        });
        final updated = baseState.copyWith(health: health);
        expect(updated.health, isNotNull);
        expect(updated.health!.status, 'ok');
      });

      test('should clear errorMessage when copyWith errorMessage: null', () {
        final withError = baseState.copyWith(errorMessage: 'some error');
        expect(withError.errorMessage, 'some error');

        // copyWith without errorMessage arg passes null directly
        // (not ?? this.errorMessage), so it clears errorMessage
        final cleared = withError.copyWith();
        expect(cleared.errorMessage, isNull);
      });

      test('should preserve unchanged fields', () {
        final msg = TravisMessage.system('welcome');
        final full = TravisChatState(
          sessionId: 'full',
          messages: [msg],
          isSending: true,
          isOnline: true,
          errorMessage: 'err',
        );

        final updated = full.copyWith(isSending: false);
        expect(updated.messages, hasLength(1));
        expect(updated.isOnline, isTrue);
        expect(updated.sessionId, 'full');
        expect(updated.isSending, isFalse);
      });
    });
  });
}
