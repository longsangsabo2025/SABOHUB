import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../widgets/dev_role_switcher.dart';
import '../widgets/unified_bottom_navigation.dart';
import 'staff/staff_checkin_page.dart';
import 'staff/staff_messages_page.dart';
import 'staff/staff_tables_page.dart';
import 'staff/staff_tasks_page.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    children: const [
                      StaffTablesPage(),
                      StaffCheckinPage(),
                      StaffTasksPage(),
                      StaffMessagesPage(),
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
          // DEV: Role Switcher Button
          const DevRoleSwitcher(),
        ],
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
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ca chiều • 14:00 - 22:00',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
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
                    _buildStatItem('Bàn phục vụ', '3', Icons.table_restaurant),
              ),
              Expanded(
                child: _buildStatItem('Nhiệm vụ', '8', Icons.task_alt),
              ),
              Expanded(
                child: _buildStatItem('Tin nhắn', '2', Icons.message),
              ),
              Expanded(
                child: _buildStatItem('Giờ làm', '6.5h', Icons.schedule),
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
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.9),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                const Color(0xFF10B981),
                () {},
              ),
              _buildActionButton(
                'Tạo đơn',
                Icons.add_shopping_cart,
                const Color(0xFF3B82F6),
                () {},
              ),
              _buildActionButton(
                'Gọi bếp',
                Icons.kitchen,
                const Color(0xFFF59E0B),
                () {},
              ),
              _buildActionButton(
                'SOS',
                Icons.emergency,
                const Color(0xFFEF4444),
                () {},
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Xuất sắc',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
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
                    'Bàn phục vụ', '12', '15', const Color(0xFF10B981)),
              ),
              Expanded(
                child: _buildMetricItem(
                    'Đánh giá', '4.8', '5.0', const Color(0xFF3B82F6)),
              ),
              Expanded(
                child: _buildMetricItem(
                    'Tip nhận', '250K', '300K', const Color(0xFFF59E0B)),
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
            color: Colors.grey.shade600,
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
            color: Colors.grey.shade500,
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
