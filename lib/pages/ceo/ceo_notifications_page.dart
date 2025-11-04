import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CEO Notifications Page
/// Displays system notifications, alerts, and updates for CEO
class CEONotificationsPage extends ConsumerStatefulWidget {
  const CEONotificationsPage({super.key});

  @override
  ConsumerState<CEONotificationsPage> createState() =>
      _CEONotificationsPageState();
}

class _CEONotificationsPageState extends ConsumerState<CEONotificationsPage> {
  List<Map<String, dynamic>> _getMockNotifications() {
    return [
      {
        'id': '1',
        'title': 'Báo cáo doanh thu tháng',
        'message': 'Doanh thu tháng 11 đạt 2.5 tỷ VND, tăng 15% so với tháng trước',
        'time': DateTime.now().subtract(const Duration(minutes: 30)),
        'type': 'success',
        'isRead': false,
        'priority': 'high',
      },
      {
        'id': '2',
        'title': 'Cảnh báo nhân sự',
        'message': 'Cần tuyển thêm 5 nhân viên cho chi nhánh Hà Nội trong tháng 12',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'type': 'warning',
        'isRead': false,
        'priority': 'medium',
      },
      {
        'id': '3',
        'title': 'Kế hoạch mở rộng',
        'message': 'Đề xuất mở thêm 2 chi nhánh mới tại TP.HCM và Đà Nẵng',
        'time': DateTime.now().subtract(const Duration(hours: 5)),
        'type': 'info',
        'isRead': true,
        'priority': 'medium',
      },
      {
        'id': '4',
        'title': 'Cập nhật hệ thống',
        'message': 'Hệ thống sẽ được bảo trì từ 23:00 - 01:00 ngày mai',
        'time': DateTime.now().subtract(const Duration(hours: 8)),
        'type': 'info',
        'isRead': true,
        'priority': 'low',
      },
      {
        'id': '5',
        'title': 'Thông báo khẩn cấp',
        'message': 'Sự cố hệ thống thanh toán đã được khắc phục hoàn toàn',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'type': 'error',
        'isRead': true,
        'priority': 'high',
      },
    ];
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _getMockNotifications();
    final unreadCount = notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đánh dấu tất cả là đã đọc'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Đánh dấu đã đọc',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có thông báo nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng quan thông báo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$unreadCount thông báo chưa đọc • ${notifications.length} tổng cộng',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: notification['isRead']
                              ? Colors.white
                              : Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: !notification['isRead']
                              ? Border.all(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  width: 1,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification['type'])
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: _getNotificationColor(notification['type']),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: notification['isRead']
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!notification['isRead'])
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                notification['message'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getTimeAgo(notification['time']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: notification['priority'] == 'high'
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : notification['priority'] == 'medium'
                                              ? Colors.orange
                                                  .withValues(alpha: 0.1)
                                              : Colors.grey
                                                  .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      notification['priority'] == 'high'
                                          ? 'Cao'
                                          : notification['priority'] == 'medium'
                                              ? 'Trung bình'
                                              : 'Thấp',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: notification['priority'] == 'high'
                                            ? Colors.red
                                            : notification['priority'] ==
                                                    'medium'
                                                ? Colors.orange
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            // Handle notification tap
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Đã mở thông báo: ${notification['title']}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}