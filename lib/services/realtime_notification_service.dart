import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification model for in-app notifications
class AppNotification {
  final String id;
  final String userId;
  final String? companyId;
  final String title;
  final String? body;
  final String type; // 'info', 'success', 'warning', 'error', 'task', 'attendance', 'announcement'
  final String? referenceType;
  final String? referenceId;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final bool isRead;
  final DateTime? readAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.companyId,
    required this.title,
    this.body,
    required this.type,
    this.referenceType,
    this.referenceId,
    this.actionUrl,
    this.actionData,
    required this.isRead,
    this.readAt,
    this.createdBy,
    required this.createdAt,
    this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String? ?? 'info',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      actionUrl: json['action_url'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  /// Get icon based on notification type
  IconData get icon {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'task':
        return Icons.task_alt;
      case 'attendance':
        return Icons.access_time;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  /// Get color based on notification type
  Color get color {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'task':
        return Colors.blue;
      case 'attendance':
        return Colors.purple;
      case 'announcement':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Supabase Realtime Notification Service
/// Handles in-app notifications using Supabase Realtime subscriptions
class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final _supabase = Supabase.instance.client;
  
  // Stream controllers
  final _notificationsController = StreamController<List<AppNotification>>.broadcast();
  final _newNotificationController = StreamController<AppNotification>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  
  // State
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  RealtimeChannel? _channel;
  String? _currentUserId;

  // Streams
  Stream<List<AppNotification>> get notificationsStream => _notificationsController.stream;
  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Initialize service and subscribe to realtime updates
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return; // Already initialized for this user
    
    // Clean up previous subscription
    await dispose();
    _currentUserId = userId;

    // Load initial notifications
    await _loadNotifications();
    await _loadUnreadCount();

    // Subscribe to realtime changes
    _subscribeToRealtimeUpdates();
  }

  /// Load notifications from database
  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      _notificationsController.add(_notifications);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  /// Load unread count
  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _currentUserId!)
          .eq('is_read', false);

      _unreadCount = (response as List).length;
      _unreadCountController.add(_unreadCount);
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Subscribe to realtime notification updates
  void _subscribeToRealtimeUpdates() {
    if (_currentUserId == null) return;

    _channel = _supabase.channel('notifications:$_currentUserId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _currentUserId,
        ),
        callback: (payload) {
          _handleNewNotification(payload.newRecord);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _currentUserId,
        ),
        callback: (payload) {
          _handleUpdatedNotification(payload.newRecord);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _currentUserId,
        ),
        callback: (payload) {
          _handleDeletedNotification(payload.oldRecord);
        },
      )
      ..subscribe();

    debugPrint('📡 Subscribed to notifications realtime for user: $_currentUserId');
  }

  /// Handle new notification from realtime
  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      final notification = AppNotification.fromJson(data);
      
      // Add to beginning of list
      _notifications.insert(0, notification);
      _notificationsController.add(_notifications);
      
      // Update unread count
      if (!notification.isRead) {
        _unreadCount++;
        _unreadCountController.add(_unreadCount);
      }
      
      // Emit new notification for popup/toast
      _newNotificationController.add(notification);
      
      debugPrint('🔔 New notification: ${notification.title}');
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  /// Handle updated notification from realtime
  void _handleUpdatedNotification(Map<String, dynamic> data) {
    try {
      final updatedNotification = AppNotification.fromJson(data);
      
      final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
      if (index != -1) {
        final wasUnread = !_notifications[index].isRead;
        final nowRead = updatedNotification.isRead;
        
        _notifications[index] = updatedNotification;
        _notificationsController.add(_notifications);
        
        // Update unread count if read status changed
        if (wasUnread && nowRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.maxFinite.toInt());
          _unreadCountController.add(_unreadCount);
        }
      }
    } catch (e) {
      debugPrint('Error handling updated notification: $e');
    }
  }

  /// Handle deleted notification from realtime
  void _handleDeletedNotification(Map<String, dynamic> data) {
    try {
      final deletedId = data['id'] as String?;
      if (deletedId == null) return;
      
      final index = _notifications.indexWhere((n) => n.id == deletedId);
      if (index != -1) {
        final wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        _notificationsController.add(_notifications);
        
        if (wasUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.maxFinite.toInt());
          _unreadCountController.add(_unreadCount);
        }
      }
    } catch (e) {
      debugPrint('Error handling deleted notification: $e');
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    if (_currentUserId == null) return false;

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _currentUserId!)
          .eq('is_read', false);
      
      // Update local state
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        companyId: n.companyId,
        title: n.title,
        body: n.body,
        type: n.type,
        referenceType: n.referenceType,
        referenceId: n.referenceId,
        actionUrl: n.actionUrl,
        actionData: n.actionData,
        isRead: true,
        readAt: DateTime.now(),
        createdBy: n.createdBy,
        createdAt: n.createdAt,
        expiresAt: n.expiresAt,
      )).toList();
      
      _notificationsController.add(_notifications);
      _unreadCount = 0;
      _unreadCountController.add(_unreadCount);
      
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
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
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'company_id': companyId,
            'title': title,
            'body': body,
            'type': type,
            'reference_type': referenceType,
            'reference_id': referenceId,
            'action_url': actionUrl,
            'created_by': _currentUserId,
          })
          .select('id')
          .single();
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return null;
    }
  }

  /// Send notification to all users in a company
  Future<int> sendCompanyNotification({
    required String companyId,
    required String title,
    String? body,
    String type = 'announcement',
    bool excludeSelf = true,
  }) async {
    try {
      // Get all users in company
      var query = _supabase
          .from('users')
          .select('id')
          .eq('company_id', companyId);
      
      if (excludeSelf && _currentUserId != null) {
        query = query.neq('id', _currentUserId!);
      }
      
      final users = await query;
      
      // Send notification to each user
      int count = 0;
      for (final user in users as List) {
        final userId = user['id'] as String;
        final result = await sendNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          companyId: companyId,
        );
        if (result != null) count++;
      }
      
      return count;
    } catch (e) {
      debugPrint('Error sending company notification: $e');
      return 0;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }

  /// Dispose service
  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
    _currentUserId = null;
    _notifications = [];
    _unreadCount = 0;
  }
}
