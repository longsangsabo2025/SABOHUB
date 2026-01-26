import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_notification_service.dart';
import 'auth_provider.dart';

/// Provider for RealtimeNotificationService singleton
final realtimeNotificationServiceProvider = Provider<RealtimeNotificationService>((ref) {
  return RealtimeNotificationService();
});

/// Provider for notifications list
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  final authState = ref.watch(authProvider);
  
  // Initialize service when user is authenticated
  if (authState.isAuthenticated && authState.user != null) {
    service.initialize(authState.user!.id);
  }
  
  return service.notificationsStream;
});

/// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  final authState = ref.watch(authProvider);
  
  // Initialize service when user is authenticated
  if (authState.isAuthenticated && authState.user != null) {
    service.initialize(authState.user!.id);
  }
  
  return service.unreadCountStream;
});

/// Provider for new notification events (for showing toast/popup)
final newNotificationProvider = StreamProvider<AppNotification>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  return service.newNotificationStream;
});

/// Provider to get current unread count synchronously
final unreadCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(unreadNotificationCountProvider);
  return asyncValue.when(
    data: (count) => count,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Actions provider for notification operations
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  return NotificationActions(service);
});

/// Actions class for notification operations
class NotificationActions {
  final RealtimeNotificationService _service;
  
  NotificationActions(this._service);
  
  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }
  
  /// Mark all notifications as read
  Future<bool> markAllAsRead() {
    return _service.markAllAsRead();
  }
  
  /// Send a notification to a user
  Future<String?> sendNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'info',
    String? referenceType,
    String? referenceId,
    String? actionUrl,
    String? companyId,
  }) {
    return _service.sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      actionUrl: actionUrl,
      companyId: companyId,
    );
  }
  
  /// Send notification to all users in a company
  Future<int> sendCompanyNotification({
    required String companyId,
    required String title,
    String? body,
    String type = 'announcement',
    bool excludeSelf = true,
  }) {
    return _service.sendCompanyNotification(
      companyId: companyId,
      title: title,
      body: body,
      type: type,
      excludeSelf: excludeSelf,
    );
  }
  
  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }
  
  /// Refresh notifications
  Future<void> refresh() {
    return _service.refresh();
  }
}
