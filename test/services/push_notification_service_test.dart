import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sabohub/services/push_notification_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockNotificationSettings extends Mock implements NotificationSettings {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoAuth extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late MockSupabaseClient mockSupabase;
  late MockGoAuth mockAuth;
  late PushNotificationService service;

  setUp(() async {
    mockMessaging = MockFirebaseMessaging();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoAuth();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null); // Anonymous by default

    service = PushNotificationService.test(
      messaging: mockMessaging,
      supabaseClient: mockSupabase,
    );
  });

  group('PushNotificationService Tests', () {
    test('initializes and requests permissions', () async {
      final mockSettings = MockNotificationSettings();
      when(() => mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.authorized);

      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            announcement: any(named: 'announcement'),
            badge: any(named: 'badge'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
            provisional: any(named: 'provisional'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => mockSettings);

      when(() => mockMessaging.getToken(vapidKey: any(named: 'vapidKey')))
          .thenAnswer((_) async => 'mock-token');

      when(() => mockMessaging.getInitialMessage()).thenAnswer((_) => Future<RemoteMessage?>.value(null));

      // Static method call inside may throw if Firebase is not initialized, we check if fcmToken is populated.
      // But we need to use Mockito to mock it if it is impossible to bypass.
      await service.initialize();

      verify(() => mockMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
      )).called(1);

      // Verify token
      verify(() => mockMessaging.getToken(vapidKey: any(named: 'vapidKey'))).called(1);
    });
  });
}
