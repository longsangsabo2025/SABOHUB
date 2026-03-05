import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sabohub/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles general Push Notifications using Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  @visibleForTesting
  PushNotificationService.test({FirebaseMessaging? messaging, SupabaseClient? supabaseClient}) {
    _firebaseMessaging = messaging ?? FirebaseMessaging.instance;
    _supabaseClient = supabaseClient;
  }

  PushNotificationService._internal() {
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  late FirebaseMessaging _firebaseMessaging;
  SupabaseClient? _supabaseClient;
  bool _initialized = false;
  String? _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Request permissions (for Web/iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get FCM token
        if (kIsWeb) {
          // Provide VAPID key via dotenv for production web.
          final vapidKey = dotenv.env['FIREBASE_VAPID_KEY'];
          _fcmToken = await _firebaseMessaging.getToken(vapidKey: vapidKey);
        } else {
          _fcmToken = await _firebaseMessaging.getToken();
        }
        
        AppLogger.info('FCM Token: $_fcmToken');
        
        // Save FCM token to DB if user is logged in
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          final client = _supabaseClient ?? Supabase.instance.client;
          final userId = client.auth.currentUser?.id;
          if (userId != null) {
            try {
              await client
                  .from('employees')
                  .update({'fcm_token': _fcmToken})
                  .eq('auth_user_id', userId);
              AppLogger.info('Saved FCM token to DB for user: $userId');
            } catch (dbError) {
              AppLogger.error('Failed to save FCM token to DB', dbError);
            }
          }
        }

        // 3. Listen to foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 4. Listen to background messages handling when app opens from background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check if app was opened via initial message
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }
      
      _initialized = true;
    } catch (e) {
      AppLogger.error('Failed to initialize PushNotificationService', e);
    }
  }

  /// Get current FCM token (to save to database for that user)
  String? get fcmToken => _fcmToken;

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received foreground message: ${message.notification?.title}');
    // We already have generic RealtimeNotificationService for UI.
    // We can show an extra Snackbar/Toast here if needed.
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('App opened from notification: ${message.data}');
    // Route navigation based on message.data['route'] can happen here.
  }

  /// Subscribe user to generic topics
  Future<void> subscribeToRoleTopics(String role) async {
    try {
      if (!kIsWeb) {
        // web doesn't support topic subscription on client side yet using standard flutterfire,
        // unless you manage it via backend.
        await _firebaseMessaging.subscribeToTopic('role_$role');
        await _firebaseMessaging.subscribeToTopic('all_users');
        AppLogger.info('Subscribed to push notification topics');
      }
    } catch (e) {
      AppLogger.error('Topic subscription failed', e);
    }
  }
}
