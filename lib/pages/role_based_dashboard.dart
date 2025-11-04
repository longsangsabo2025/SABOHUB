import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layouts/manager_main_layout.dart';
import '../layouts/shift_leader_main_layout.dart';
import '../pages/ceo/ceo_main_layout.dart';
import '../pages/staff_main_layout.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart' as app_user;

/// User Role Enum
enum UserRole {
  ceo('CEO', 'Tổng Giám Đốc', Color(0xFF3B82F6), Icons.business_center),
  manager('MANAGER', 'Quản Lý', Color(0xFF10B981), Icons.supervisor_account),
  shiftLeader('SHIFT_LEADER', 'Trưởng Ca', Color(0xFF8B5CF6), Icons.group),
  staff('STAFF', 'Nhân Viên', Color(0xFF10B981), Icons.person);

  const UserRole(this.id, this.displayName, this.color, this.icon);

  final String id;
  final String displayName;
  final Color color;
  final IconData icon;
}

/// Role-Based Dashboard Page
/// Shows navigation based on user role with actual Flutter layouts
class RoleBasedDashboard extends ConsumerStatefulWidget {
  final String? roleParam;

  const RoleBasedDashboard({super.key, this.roleParam});

  @override
  ConsumerState<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends ConsumerState<RoleBasedDashboard> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    // Check if role parameter is provided
    if (widget.roleParam != null) {
      final roleIndex = int.tryParse(widget.roleParam!);
      if (roleIndex != null &&
          roleIndex >= 0 &&
          roleIndex < UserRole.values.length) {
        _selectedRole = UserRole.values[roleIndex];
      }
    }
  }

  @override
  void didUpdateWidget(RoleBasedDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected role when roleParam changes
    if (widget.roleParam != oldWidget.roleParam) {
      if (widget.roleParam != null) {
        final roleIndex = int.tryParse(widget.roleParam!);
        if (roleIndex != null &&
            roleIndex >= 0 &&
            roleIndex < UserRole.values.length) {
          setState(() {
            _selectedRole = UserRole.values[roleIndex];
          });
        }
      } else {
        setState(() {
          _selectedRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from auth provider
    final currentUser = ref.watch(currentUserProvider);

    // If user has a role, use it (unless roleParam overrides it)
    if (_selectedRole == null &&
        currentUser != null &&
        currentUser.role != null) {
      // Auto-select based on user's actual role
      _selectedRole = _mapUserRoleToEnum(currentUser.role);
    }

    if (_selectedRole != null) {
      return _buildRoleLayout(_selectedRole!);
    }

    // Only show role selection if user has no role (shouldn't happen normally)
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Chọn vai trò',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Quick test button - tap to go to Staff layout directly
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedRole = UserRole.staff;
              });
            },
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text('Quick Test'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {
              // Logout functionality would go here
            },
            icon: const Icon(Icons.logout, color: Colors.black54),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 32),
            _buildRoleSelector(),
            const SizedBox(height: 32),
            _buildSystemInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎉 SABOHUB FLUTTER',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống quản lý billiards đa vai trò',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '4 Role Navigation Systems',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn vai trò của bạn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mỗi vai trò có navigation system và tính năng riêng',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),

        // Role cards grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: UserRole.values.length,
          itemBuilder: (context, index) {
            final role = UserRole.values[index];
            return _buildRoleCard(role);
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(UserRole role) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: role.color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role.icon,
                size: 32,
                color: role.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: role.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _getRoleDescription(role),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return '4 tabs • Executive';
      case UserRole.manager:
        return '4 tabs • Management';
      case UserRole.shiftLeader:
        return '3 tabs • Operations';
      case UserRole.staff:
        return '5 tabs • Daily Work';
    }
  }

  Widget _buildSystemInfo() {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'Navigation Systems Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('✅ CEO System', '4 tabs - Executive dashboard'),
          _buildInfoRow('✅ MANAGER System', '4 tabs - Business management'),
          _buildInfoRow('✅ SHIFT_LEADER System', '3 tabs - Operations'),
          _buildInfoRow('✅ STAFF System', '5 tabs - Daily operations'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tất cả navigation systems đã hoàn thành!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Map app_user.UserRole to local UserRole enum
  UserRole _mapUserRoleToEnum(app_user.UserRole userRole) {
    switch (userRole) {
      case app_user.UserRole.ceo:
        return UserRole.ceo;
      case app_user.UserRole.manager:
        return UserRole.manager;
      case app_user.UserRole.shiftLeader:
        return UserRole.shiftLeader;
      case app_user.UserRole.staff:
        return UserRole.staff;
    }
  }

  Widget _buildRoleLayout(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return const CEOMainLayout();
      case UserRole.manager:
        return const ManagerMainLayout();
      case UserRole.shiftLeader:
        return const ShiftLeaderMainLayout();
      case UserRole.staff:
        return const StaffMainLayout();
    }
  }
}
