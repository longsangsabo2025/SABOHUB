import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Staff Messages Page
/// Team communication and announcements for staff
class StaffMessagesPage extends ConsumerStatefulWidget {
  const StaffMessagesPage({super.key});

  @override
  ConsumerState<StaffMessagesPage> createState() => _StaffMessagesPageState();
}

class _StaffMessagesPageState extends ConsumerState<StaffMessagesPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Send quick message
        },
        backgroundColor: AppColors.success,
        child: Icon(Icons.send, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Tin nhắn',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔍 Tìm kiếm tin nhắn'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 Thông báo mới'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.info,
              ),
            );
          },
          icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface54),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Nhóm', 'Cá nhân', 'Thông báo'];

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildGroupMessagesTab();
      case 1:
        return _buildPersonalMessagesTab();
      case 2:
        return _buildAnnouncementsTab();
      default:
        return _buildGroupMessagesTab();
    }
  }

  Widget _buildGroupMessagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildGroupChats(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liên lạc nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'SOS',
                  'Hỗ trợ khẩn cấp',
                  Icons.emergency,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Quản lý',
                  'Liên hệ trực tiếp',
                  Icons.person,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Kỹ thuật',
                  'Sự cố thiết bị',
                  Icons.build,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, String subtitle, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💬 Tin nhắn $title - $subtitle'),
            duration: const Duration(seconds: 2),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChats() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Nhóm chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(4, (index) {
            final groupNames = [
              'Ca chiều',
              'Nhóm khu A',
              'Bartenders',
              'Toàn nhân viên'
            ];
            final lastMessages = [
              'Mai: Bàn 5 cần hỗ trợ khẩn cấp',
              'Hùng: Đã vệ sinh xong khu vực',
              'Linh: Còn thiếu nguyên liệu cocktail',
              'Quản lý: Họp briefing 15h hôm nay'
            ];
            final times = ['2 phút', '5 phút', '15 phút', '1 giờ'];
            final memberCounts = [6, 4, 3, 15];
            final unreadCounts = [2, 0, 1, 0];
            final colors = [
              AppColors.success,
              AppColors.info,
              AppColors.primary,
              AppColors.warning,
            ];

            return _buildGroupChatItem(
              groupNames[index],
              lastMessages[index],
              times[index],
              memberCounts[index],
              unreadCounts[index],
              colors[index],
              index == 3, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGroupChatItem(String groupName, String lastMessage, String time,
      int memberCount, int unreadCount, Color color, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  Icons.group,
                  color: color,
                  size: 24,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$memberCount',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        unreadCount > 0 ? Theme.of(context).colorScheme.onSurface87 : Colors.grey.shade600,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalMessagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPersonalChats(),
        ],
      ),
    );
  }

  Widget _buildPersonalChats() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Tin nhắn cá nhân',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(6, (index) {
            final names = [
              'Quản lý Minh',
              'Trưởng ca Hùng',
              'Đồng nghiệp Mai',
              'Kỹ thuật viên Sơn',
              'Thu ngân Linh',
              'Bảo vệ Nam'
            ];
            final lastMessages = [
              'Nhớ hoàn thành báo cáo ca làm',
              'Ngày mai bạn làm ca sáng nhé',
              'Cảm ơn bạn đã hỗ trợ hôm nay',
              'Máy pha chế đã sửa xong',
              'Có khách hỏi về menu mới',
              'Xe khách VIP vừa đến'
            ];
            final times = [
              '10 phút',
              '30 phút',
              '1 giờ',
              '2 giờ',
              '3 giờ',
              '4 giờ'
            ];
            final unreadCounts = [1, 0, 0, 1, 0, 0];
            final statuses = [
              'online',
              'away',
              'online',
              'offline',
              'away',
              'online'
            ];

            return _buildPersonalChatItem(
              names[index],
              lastMessages[index],
              times[index],
              unreadCounts[index],
              statuses[index],
              index == 5, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalChatItem(String name, String lastMessage, String time,
      int unreadCount, String status, bool isLast) {
    Color statusColor = status == 'online'
        ? AppColors.success
        : status == 'away'
            ? AppColors.warning
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface87,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        unreadCount > 0 ? Theme.of(context).colorScheme.onSurface87 : Colors.grey.shade600,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnnouncementsList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Thông báo từ quản lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(5, (index) {
            final titles = [
              'Thay đổi lịch làm việc cuối tuần',
              'Quy định mới về trang phục',
              'Chương trình khuyến mãi tháng 11',
              'Họp toàn thể nhân viên',
              'Bảo trì hệ thống âm thanh'
            ];
            final contents = [
              'Từ thứ 7 tuần tới, ca tối sẽ kéo dài đến 23h30',
              'Nhân viên nam bắt buộc đeo cà vạt, nữ đeo nơ',
              'Ưu đãi 20% cho combo billiards + đồ uống',
              'Ngày 5/11 lúc 14h tại sảnh chính',
              'Bảo trì từ 2h-6h sáng ngày 3/11'
            ];
            final times = [
              '2 giờ trước',
              '1 ngày',
              '2 ngày',
              '3 ngày',
              '5 ngày'
            ];
            final priorities = [
              'Cao',
              'Trung bình',
              'Thấp',
              'Cao',
              'Trung bình'
            ];
            final colors = [
              AppColors.error,
              AppColors.info,
              AppColors.success,
              AppColors.error,
              AppColors.info,
            ];
            final isNew = [true, false, false, true, false];

            return _buildAnnouncementItem(
              titles[index],
              contents[index],
              times[index],
              priorities[index],
              colors[index],
              isNew[index],
              index == 4, // isLast
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String content, String time,
      String priority, Color priorityColor, bool isNew, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:
            isNew ? priorityColor.withValues(alpha: 0.02) : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign,
              color: priorityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MỚI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
