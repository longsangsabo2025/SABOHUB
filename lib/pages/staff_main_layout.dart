import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../providers/auth_provider.dart';
import '../utils/performance_monitor.dart';
import '../widgets/error_boundary.dart';
import '../widgets/unified_bottom_navigation.dart';
import '../widgets/realtime_notification_widgets.dart';
import 'common/company_info_page.dart';
import 'staff/staff_checkin_page.dart';
import 'staff/staff_tasks_page.dart';
import 'staff/staff_messages_page.dart';

/// Staff Main Layout
/// Combines all staff pages with bottom navigation
class StaffMainLayout extends ConsumerStatefulWidget {
  const StaffMainLayout({super.key});

  @override
  ConsumerState<StaffMainLayout> createState() => _StaffMainLayoutState();
}

class _StaffMainLayoutState extends ConsumerState<StaffMainLayout>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationChanged(int index) {
    if (_currentIndex != index) {
      // Start performance tracking for navigation
      PerformanceMonitor().startMeasuring('staff_tab_navigation');
      
      // Haptic feedback for navigation
      HapticFeedback.lightImpact();

      setState(() {
        _currentIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Stop performance tracking
      PerformanceMonitor().stopMeasuring('staff_tab_navigation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final companyId = currentUser?.companyId;

    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          title: Text(currentUser?.companyName ?? 'SABOHUB'),
          actions: const [
            RealtimeNotificationBell(),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Main content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    children: [
                      const StaffCheckinPage(),
                      StaffTasksPage(),
                      StaffMessagesPage(),
                      // Company Info Page (new)
                      if (companyId != null)
                        CompanyInfoPage(companyId: companyId)
                      else
                        const Center(
                          child: Text('Bạn chưa được gán vào công ty nào'),
                        ),
                    ],
                  ),
                ),

                // Bottom Navigation
                UnifiedBottomNavigation(
                  userRole: UserRole.staff,
                  currentIndex: _currentIndex,
                  onTap: _onNavigationChanged,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Staff Dashboard Header Widget
/// Shows quick stats and current shift info
class StaffDashboardHeader extends ConsumerWidget {
  const StaffDashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success,
            AppColors.successDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào, Staff!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chưa có lịch ca',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick stats row
          Row(
            children: [
              Expanded(
                child:
                    _buildStatItem('Bàn phục vụ', '—', Icons.table_restaurant),
              ),
              Expanded(
                child: _buildStatItem('Nhiệm vụ', '—', Icons.task_alt),
              ),
              Expanded(
                child: _buildStatItem('Tin nhắn', '—', Icons.message),
              ),
              Expanded(
                child: _buildStatItem('Giờ làm', '—', Icons.schedule),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textOnPrimary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Staff Quick Actions Widget
/// Provides quick access to common staff actions
class StaffQuickActions extends ConsumerWidget {
  const StaffQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
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
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Quick action buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _buildActionButton(
                'Check In',
                Icons.login,
                AppColors.success,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã check-in ca làm việc'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              _buildActionButton(
                'Tạo đơn',
                Icons.add_shopping_cart,
                AppColors.info,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo đơn hàng mới — chọn bàn hoặc khách hàng'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              _buildActionButton(
                'Gọi bếp',
                Icons.kitchen,
                AppColors.warning,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gọi bếp — chọn món từ menu đơn hàng'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              _buildActionButton(
                'SOS',
                Icons.emergency,
                AppColors.error,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liên hệ quản lý ca trực ngay'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Staff Performance Widget
/// Shows daily performance metrics
class StaffPerformanceWidget extends ConsumerWidget {
  const StaffPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hiệu suất hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Performance metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                    'Bàn phục vụ', '0', '0', AppColors.success),
              ),
              Expanded(
                child: _buildMetricItem(
                    'Đánh giá', '0', '0', AppColors.info),
              ),
              Expanded(
                child: _buildMetricItem(
                    'Tip nhận', '0', '0', AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      String title, String current, String target, Color color) {
    final progress = double.parse(current.replaceAll(RegExp(r'[^0-9.]'), '')) /
        double.parse(target.replaceAll(RegExp(r'[^0-9.]'), ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          current,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mục tiêu: $target',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
