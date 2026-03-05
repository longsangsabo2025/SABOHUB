import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

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
      // Database uses 'message' instead of 'body'
      body: (json['body'] ?? json['message']) as String?,
      type: json['type'] as String? ?? 'info',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      // Database uses 'link' instead of 'action_url'
      actionUrl: (json['action_url'] ?? json['link']) as String?,
      // Database uses 'data' instead of 'action_data'
      actionData: (json['action_data'] ?? json['data']) as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  /// Get icon based on notification type
  /// Valid DB types: task_assigned, task_status_changed, task_completed, task_overdue,
  /// shift_reminder, attendance_issue, system, approval_request, approval_update
  IconData get icon {
    switch (type) {
      // Task types
      case 'task':
      case 'task_assigned':
      case 'task_status_changed':
        return Icons.task_alt;
      case 'task_completed':
        return Icons.check_circle;
      case 'task_overdue':
        return Icons.warning_amber;
      
      // Attendance types
      case 'attendance':
      case 'attendance_issue':
      case 'shift_reminder':
        return Icons.access_time;
      
      // Approval types
      case 'approval_request':
        return Icons.approval;
      case 'approval_update':
        return Icons.verified;
      
      // System & legacy types
      case 'system':
      case 'announcement':
        return Icons.campaign;
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      case 'overdue_payment':
        return Icons.money_off;
      case 'overdue_digest':
        return Icons.summarize;
      
      default:
        return Icons.notifications;
    }
  }

  /// Get color based on notification type
  Color get color {
    switch (type) {
      // Task types
      case 'task':
      case 'task_assigned':
        return Colors.blue;
      case 'task_status_changed':
        return Colors.indigo;
      case 'task_completed':
        return Colors.green;
      case 'task_overdue':
        return Colors.red;
      
      // Attendance types
      case 'attendance':
      case 'attendance_issue':
        return Colors.purple;
      case 'shift_reminder':
        return Colors.deepPurple;
      
      // Approval types
      case 'approval_request':
        return Colors.amber;
      case 'approval_update':
        return Colors.green;
      
      // System & legacy types
      case 'system':
        return Colors.blueGrey;
      case 'announcement':
        return Colors.teal;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
        return Colors.lightBlue;
      case 'overdue_payment':
        return Colors.red;
      case 'overdue_digest':
        return Colors.deepOrange;
      
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
  RealtimeNotificationService._internal() {
    _notificationsController = StreamController<List<AppNotification>>.broadcast();
    _newNotificationController = StreamController<AppNotification>.broadcast();
    _unreadCountController = StreamController<int>.broadcast();
  }

  final _supabase = Supabase.instance.client;
  
  // Stream controllers - use broadcast for multiple listeners
  late StreamController<List<AppNotification>> _notificationsController;
  late StreamController<AppNotification> _newNotificationController;
  late StreamController<int> _unreadCountController;
  
  // State
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  RealtimeChannel? _channel;
  String? _currentUserId; // Employee ID used for notifications
  String? _lastAuthUserId; // Track auth user ID to avoid unnecessary re-init
  bool _hasInitialData = false; // Track if initial data has been loaded

  // Streams - wrap with logic to emit current data for new listeners
  Stream<List<AppNotification>> get notificationsStream {
    // If we have data, emit it immediately for new subscribers
    if (_hasInitialData && _notifications.isNotEmpty) {
      return Stream.value(_notifications).asyncExpand((initial) async* {
        yield initial;
        await for (final update in _notificationsController.stream) {
          yield update;
        }
      });
    }
    return _notificationsController.stream;
  }
  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Initialize service and subscribe to realtime updates
  /// [userId] can be either:
  /// - employee.id (for Employee Login users)
  /// - auth.uid() (for Supabase Auth users)
  /// Notifications table stores user_id as employee.id
  Future<void> initialize(String userId) async {
    AppLogger.info('🔔 [NOTIF] initialize called with userId: $userId');
    
    // Skip if already initialized for this user
    if (_lastAuthUserId == userId && _currentUserId != null) {
      AppLogger.info('🔔 [NOTIF] Already initialized, skipping. currentUserId: $_currentUserId');
      return;
    }
    
    // Clean up previous subscription
    await dispose();
    _lastAuthUserId = userId;

    // Recreate stream controllers after dispose
    _notificationsController = StreamController<List<AppNotification>>.broadcast();
    _newNotificationController = StreamController<AppNotification>.broadcast();
    _unreadCountController = StreamController<int>.broadcast();
    
    // Lookup employee ID
    // The userId could be:
    // 1. Already an employee.id (Employee Login users)
    // 2. An auth_user_id (Supabase Auth users)
    // We need to find the employee.id to query notifications
    try {
      // First, check if userId is already an employee.id
      final employeeByIdResponse = await _supabase
          .from('employees')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (employeeByIdResponse != null) {
        // userId is already an employee.id - use it directly
        _currentUserId = userId;
        AppLogger.auth('📬 Notification service: userId is employee.id, using directly: $_currentUserId');
      } else {
        // userId might be an auth_user_id, lookup employee by auth_user_id
        final employeeByAuthResponse = await _supabase
            .from('employees')
            .select('id')
            .eq('auth_user_id', userId)
            .maybeSingle();
        
        if (employeeByAuthResponse != null) {
          _currentUserId = employeeByAuthResponse['id'] as String;
          AppLogger.auth('📬 Notification service: found employee by auth_user_id: $_currentUserId');
        } else {
          // No employee found, use userId as-is (might be legacy or demo user)
          _currentUserId = userId;
          AppLogger.warn('📬 Notification service: no employee found, using userId as-is: $_currentUserId');
        }
      }
    } catch (e) {
      // Fallback to userId as-is
      _currentUserId = userId;
      AppLogger.warn('📬 Notification service: error during lookup, using userId as-is', e);
    }
    
    AppLogger.info('🔔 [NOTIF] Final currentUserId: $_currentUserId');
    if (_currentUserId == null) return;

    // Load initial notifications
    await _loadNotifications();
    await _loadUnreadCount();

    // Subscribe to realtime changes
    _subscribeToRealtimeUpdates();
  }

  /// Load notifications from database
  Future<void> _loadNotifications() async {
    AppLogger.api('🔔 [NOTIF] _loadNotifications called, currentUserId: $_currentUserId');
    if (_currentUserId == null) {
      AppLogger.warn('🔔 [NOTIF] currentUserId is null, returning early');
      return;
    }

    try {
      AppLogger.api('🔔 [NOTIF] Querying notifications for user_id: $_currentUserId');
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(50);

      AppLogger.data('🔔 [NOTIF] Raw response: ${response.length} items');
      AppLogger.data('🔔 [NOTIF] First item: ${response.isNotEmpty ? response.first : "empty"}');
      
      _notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      AppLogger.data('🔔 [NOTIF] Parsed ${_notifications.length} notifications, adding to stream');
      _hasInitialData = true;
      _notificationsController.add(_notifications);
      AppLogger.info('🔔 [NOTIF] Stream updated successfully');
    } catch (e, stack) {
      AppLogger.error('❌ [NOTIF] Error loading notifications', e, stack);
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
      AppLogger.error('Error loading unread count', e);
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

    AppLogger.api('📡 Subscribed to notifications realtime for user: $_currentUserId');
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
      
      AppLogger.info('🔔 New notification: ${notification.title}');
    } catch (e) {
      AppLogger.error('Error handling new notification', e);
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
      AppLogger.error('Error handling updated notification', e);
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
      AppLogger.error('Error handling deleted notification', e);
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
      AppLogger.error('Error marking notification as read', e);
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
      AppLogger.error('Error marking all notifications as read', e);
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
      AppLogger.error('Error sending notification', e);
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
      // Get all employees in this company
      var employeesQuery = _supabase
          .from('employees')
          .select('id')
          .eq('company_id', companyId);
      
      if (excludeSelf && _currentUserId != null) {
        employeesQuery = employeesQuery.neq('id', _currentUserId!);
      }
      
      final employees = await employeesQuery;
      
      final allUserIds = <String>{};
      for (final employee in employees as List) {
        allUserIds.add(employee['id'] as String);
      }
      
      // Send notification to each user
      int count = 0;
      for (final userId in allUserIds) {
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
      AppLogger.error('Error sending company notification', e);
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
      AppLogger.error('Error deleting notification', e);
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
    _lastAuthUserId = null;
    _notifications = [];
    _unreadCount = 0;
    _hasInitialData = false;
    _notificationsController.close();
    _newNotificationController.close();
    _unreadCountController.close();
  }
}
