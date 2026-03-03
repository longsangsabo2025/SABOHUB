import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';

// Analytics event categories
class AnalyticsCategory {
  static const String pageView = 'page_view';
  static const String userAction = 'user_action';
  static const String business = 'business';
  static const String error = 'error';
  static const String performance = 'performance';
  static const String auth = 'auth';
}

// Common event names
class AnalyticsEventName {
  // Auth events
  static const String login = 'login';
  static const String logout = 'logout';
  static const String loginFailed = 'login_failed';

  // Page views
  static const String pageView = 'page_view';

  // Business events
  static const String orderCreated = 'order_created';
  static const String orderUpdated = 'order_updated';
  static const String customerCreated = 'customer_created';
  static const String customerVisited = 'customer_visited';
  static const String deliveryStarted = 'delivery_started';
  static const String deliveryCompleted = 'delivery_completed';
  static const String inventoryTransfer = 'inventory_transfer';
  static const String attendanceCheckin = 'attendance_checkin';
  static const String attendanceCheckout = 'attendance_checkout';

  // UI events
  static const String buttonClick = 'button_click';
  static const String searchPerformed = 'search_performed';
  static const String filterApplied = 'filter_applied';
  static const String exportData = 'export_data';
}

/// Self-hosted analytics tracking service using Supabase
/// Tracks user behavior, business events, and performance metrics
/// Logs events to the `analytics_events` table.
///
/// NOTE: This is separate from [AnalyticsService] which provides
/// dashboard KPIs and company metrics.
class AnalyticsTrackingService {
  static final AnalyticsTrackingService _instance =
      AnalyticsTrackingService._internal();
  factory AnalyticsTrackingService() => _instance;
  AnalyticsTrackingService._internal();

  final _supabase = Supabase.instance.client;
  final _sessionId = const Uuid().v4();

  String? _userId;
  String? _companyId;
  String? _currentPage;

  // Buffer events and batch insert for performance
  final List<Map<String, dynamic>> _eventBuffer = [];
  static const int _batchSize = 10;
  bool _isFlushing = false;

  /// Initialize with user context
  void setUser({required String userId, required String companyId}) {
    _userId = userId;
    _companyId = companyId;
  }

  /// Clear user context on logout
  void clearUser() {
    _userId = null;
    _companyId = null;
    _flush(); // Send remaining events before clearing
  }

  /// Track a page view
  void trackPageView(String pagePath) {
    _currentPage = pagePath;
    track(
      AnalyticsEventName.pageView,
      category: AnalyticsCategory.pageView,
      properties: {'page': pagePath},
    );
  }

  /// Track a custom event
  void track(
    String eventName, {
    String category = 'general',
    Map<String, dynamic>? properties,
  }) {
    // Don't track in debug mode to avoid noise
    if (kDebugMode) {
      AppLogger.info('📊 Analytics: $eventName', properties);
      return;
    }

    final event = {
      'event_name': eventName,
      'event_category': category,
      'properties': properties ?? {},
      'user_id': _userId,
      'company_id': _companyId,
      'session_id': _sessionId,
      'page_path': _currentPage,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    _eventBuffer.add(event);

    // Auto-flush when buffer is full
    if (_eventBuffer.length >= _batchSize) {
      _flush();
    }
  }

  /// Flush buffered events to Supabase
  Future<void> _flush() async {
    if (_eventBuffer.isEmpty || _isFlushing) return;
    _isFlushing = true;

    final eventsToSend = List<Map<String, dynamic>>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      await _supabase.from('analytics_events').insert(eventsToSend);
    } catch (e) {
      AppLogger.error('Failed to flush analytics events', e);
      // Don't re-add to buffer to avoid infinite loop
    } finally {
      _isFlushing = false;
    }
  }

  /// Force flush (call on app lifecycle events)
  Future<void> forceFlush() => _flush();

  /// Get analytics summary for CEO dashboard
  Future<Map<String, dynamic>> getCompanySummary({
    required String companyId,
    int days = 7,
  }) async {
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();

    try {
      // Total events
      final events = await _supabase
          .from('analytics_events')
          .select('event_name, event_category')
          .eq('company_id', companyId)
          .gte('created_at', since);

      // Count by category
      final Map<String, int> byCategory = {};
      final Map<String, int> byEvent = {};
      for (final e in events) {
        final cat = e['event_category'] as String;
        final name = e['event_name'] as String;
        byCategory[cat] = (byCategory[cat] ?? 0) + 1;
        byEvent[name] = (byEvent[name] ?? 0) + 1;
      }

      // Unique users
      final uniqueUsers = await _supabase
          .from('analytics_events')
          .select('user_id')
          .eq('company_id', companyId)
          .gte('created_at', since)
          .not('user_id', 'is', null);

      final uniqueUserIds =
          uniqueUsers.map((e) => e['user_id']).toSet().length;

      return {
        'total_events': events.length,
        'unique_users': uniqueUserIds,
        'by_category': byCategory,
        'by_event': byEvent,
        'period_days': days,
      };
    } catch (e) {
      AppLogger.error('Failed to get analytics summary', e);
      return {'error': e.toString()};
    }
  }
}

/// Global analytics tracking instance
final analyticsTracking = AnalyticsTrackingService();
