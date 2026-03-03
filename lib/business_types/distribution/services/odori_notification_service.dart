// Odori Notification Service
// Handles in-app notifications and push notification integration for Odori module

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification Types for Odori
enum OdoriNotificationType {
  orderCreated,
  orderApproved,
  orderCancelled,
  deliveryStarted,
  deliveryCompleted,
  deliveryFailed,
  paymentReceived,
  lowStock,
  overduePayment,
  systemAlert,
}

/// Notification Priority
enum OdoriNotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification Model
class OdoriNotification {
  final String id;
  final OdoriNotificationType type;
  final String title;
  final String message;
  final OdoriNotificationPriority priority;
  final String? entityId;
  final String? entityType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;

  const OdoriNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.priority = OdoriNotificationPriority.normal,
    this.entityId,
    this.entityType,
    this.metadata,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
  });

  factory OdoriNotification.fromJson(Map<String, dynamic> json) {
    return OdoriNotification(
      id: json['id'] as String,
      type: OdoriNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OdoriNotificationType.systemAlert,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      priority: OdoriNotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => OdoriNotificationPriority.normal,
      ),
      entityId: json['entity_id'] as String?,
      entityType: json['entity_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'message': message,
    'priority': priority.name,
    'entity_id': entityId,
    'entity_type': entityType,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'is_read': isRead,
  };

  OdoriNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return OdoriNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      priority: priority,
      entityId: entityId,
      entityType: entityType,
      metadata: metadata,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get icon name based on notification type
  String get iconName {
    switch (type) {
      case OdoriNotificationType.orderCreated:
        return 'shopping_cart';
      case OdoriNotificationType.orderApproved:
        return 'check_circle';
      case OdoriNotificationType.orderCancelled:
        return 'cancel';
      case OdoriNotificationType.deliveryStarted:
        return 'local_shipping';
      case OdoriNotificationType.deliveryCompleted:
        return 'done_all';
      case OdoriNotificationType.deliveryFailed:
        return 'error';
      case OdoriNotificationType.paymentReceived:
        return 'payments';
      case OdoriNotificationType.lowStock:
        return 'inventory_2';
      case OdoriNotificationType.overduePayment:
        return 'warning';
      case OdoriNotificationType.systemAlert:
        return 'info';
    }
  }

  /// Get color based on priority
  int get colorValue {
    switch (priority) {
      case OdoriNotificationPriority.low:
        return 0xFF9E9E9E; // Grey
      case OdoriNotificationPriority.normal:
        return 0xFF2196F3; // Blue
      case OdoriNotificationPriority.high:
        return 0xFFFF9800; // Orange
      case OdoriNotificationPriority.urgent:
        return 0xFFF44336; // Red
    }
  }
}

/// Notification State
class OdoriNotificationState {
  final List<OdoriNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const OdoriNotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  OdoriNotificationState copyWith({
    List<OdoriNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return OdoriNotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId và companyId từ authProvider

/// Odori Notification Service
class OdoriNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  
  final _notificationController = StreamController<OdoriNotification>.broadcast();
  Stream<OdoriNotification> get onNotification => _notificationController.stream;

  // ⚠️ Lưu userId và companyId từ caller thay vì dùng auth
  String? _userId;
  String? _companyId;
  
  /// Set auth context từ authProvider
  void setAuthContext({String? userId, String? companyId}) {
    _userId = userId;
    _companyId = companyId;
  }

  /// Initialize real-time subscription
  void initialize({String? userId, String? companyId}) {
    // Cho phép truyền qua parameter hoặc dùng giá trị đã set
    final uid = userId ?? _userId;
    final cid = companyId ?? _companyId;
    
    if (uid == null || cid == null) return;
    
    _userId = uid;
    _companyId = cid;

    // Subscribe to order status changes
    _channel = _supabase.channel('odori_notifications')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'odori_sales_orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'company_id',
          value: _companyId!,
        ),
        callback: (payload) => _handleOrderChange(payload),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'odori_deliveries',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'company_id',
          value: _companyId!,
        ),
        callback: (payload) => _handleDeliveryChange(payload),
      )
      ..subscribe();
  }

  void _handleOrderChange(PostgresChangePayload payload) {
    final newData = payload.newRecord;
    final oldData = payload.oldRecord;
    
    if (newData['status'] != oldData['status']) {
      final orderNumber = newData['order_number'] as String? ?? '';
      final status = newData['status'] as String?;
      
      OdoriNotificationType type;
      String title;
      String message;
      
      switch (status) {
        case 'approved':
          type = OdoriNotificationType.orderApproved;
          title = 'Đơn hàng được duyệt';
          message = 'Đơn $orderNumber đã được duyệt';
          break;
        case 'cancelled':
          type = OdoriNotificationType.orderCancelled;
          title = 'Đơn hàng bị hủy';
          message = 'Đơn $orderNumber đã bị hủy';
          break;
        default:
          return;
      }

      final notification = OdoriNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        entityId: newData['id'] as String?,
        entityType: 'order',
        createdAt: DateTime.now(),
      );
      
      _notificationController.add(notification);
    }
  }

  void _handleDeliveryChange(PostgresChangePayload payload) {
    final newData = payload.newRecord;
    final oldData = payload.oldRecord;
    
    if (newData['status'] != oldData['status']) {
      final orderNumber = newData['order_number'] as String? ?? '';
      final status = newData['status'] as String?;
      
      OdoriNotificationType type;
      String title;
      String message;
      OdoriNotificationPriority priority;
      
      switch (status) {
        case 'in_progress':  // Valid: planned, loading, in_progress, completed, cancelled
          type = OdoriNotificationType.deliveryStarted;
          title = 'Bắt đầu giao hàng';
          message = 'Đơn $orderNumber đang được giao';
          priority = OdoriNotificationPriority.normal;
          break;
        case 'completed':  // was 'delivered'
          type = OdoriNotificationType.deliveryCompleted;
          title = 'Giao hàng thành công';
          message = 'Đơn $orderNumber đã giao xong';
          priority = OdoriNotificationPriority.normal;
          break;
        case 'failed':
          type = OdoriNotificationType.deliveryFailed;
          title = 'Giao hàng thất bại';
          message = 'Đơn $orderNumber giao không thành công';
          priority = OdoriNotificationPriority.high;
          break;
        default:
          return;
      }

      final notification = OdoriNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        priority: priority,
        entityId: newData['id'] as String?,
        entityType: 'delivery',
        createdAt: DateTime.now(),
      );
      
      _notificationController.add(notification);
    }
  }

  /// Create notification for low stock alert
  void notifyLowStock(String productName, int currentQty, int threshold) {
    final notification = OdoriNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OdoriNotificationType.lowStock,
      title: 'Hàng tồn thấp',
      message: '$productName còn $currentQty (dưới $threshold)',
      priority: OdoriNotificationPriority.high,
      createdAt: DateTime.now(),
    );
    
    _notificationController.add(notification);
  }

  /// Create notification for overdue payment
  void notifyOverduePayment(String customerName, double amount, int daysOverdue) {
    final notification = OdoriNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OdoriNotificationType.overduePayment,
      title: 'Công nợ quá hạn',
      message: '$customerName quá hạn $daysOverdue ngày',
      priority: daysOverdue > 30 
          ? OdoriNotificationPriority.urgent 
          : OdoriNotificationPriority.high,
      metadata: {'amount': amount, 'days_overdue': daysOverdue},
      createdAt: DateTime.now(),
    );
    
    _notificationController.add(notification);
  }

  /// Create notification for payment received
  void notifyPaymentReceived(String customerName, double amount) {
    final notification = OdoriNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OdoriNotificationType.paymentReceived,
      title: 'Nhận thanh toán',
      message: '$customerName thanh toán ${_formatCurrency(amount)}',
      priority: OdoriNotificationPriority.normal,
      createdAt: DateTime.now(),
    );
    
    _notificationController.add(notification);
  }

  String _formatCurrency(double value) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  /// Dispose resources
  void dispose() {
    _channel?.unsubscribe();
    _notificationController.close();
  }
}

// Singleton instance
final odoriNotificationService = OdoriNotificationService();

// ==================== RIVERPOD PROVIDERS ====================

/// Odori Notification Service Provider
final odoriNotificationServiceProvider = Provider((ref) {
  final service = odoriNotificationService;
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Notification State Provider (Riverpod 3.x Notifier pattern)
final odoriNotificationStateProvider = 
    NotifierProvider<OdoriNotificationStateNotifier, OdoriNotificationState>(
  OdoriNotificationStateNotifier.new,
);

class OdoriNotificationStateNotifier extends Notifier<OdoriNotificationState> {
  StreamSubscription? _subscription;

  @override
  OdoriNotificationState build() {
    final service = ref.watch(odoriNotificationServiceProvider);
    _subscription?.cancel();
    _subscription = service.onNotification.listen((notification) {
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );
    });
    
    ref.onDispose(() {
      _subscription?.cancel();
    });
    
    return const OdoriNotificationState();
  }

  void markAsRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  void markAllAsRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList(),
      unreadCount: 0,
    );
  }

  void deleteNotification(String id) {
    final notification = state.notifications.firstWhere((n) => n.id == id);
    
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
      unreadCount: notification.isRead 
          ? state.unreadCount 
          : state.unreadCount - 1,
    );
  }

  void clearAll() {
    state = const OdoriNotificationState();
  }
}

/// Unread Count Provider
final odoriUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(odoriNotificationStateProvider).unreadCount;
});

/// Notification Stream Provider
final odoriNotificationStreamProvider = StreamProvider<OdoriNotification>((ref) {
  return ref.watch(odoriNotificationServiceProvider).onNotification;
});
