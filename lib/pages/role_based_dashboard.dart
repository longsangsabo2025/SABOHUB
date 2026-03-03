import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layouts/manager_main_layout.dart';
import 'super_admin/super_admin_main_layout.dart';
import '../business_types/distribution/layouts/distribution_manager_layout.dart';
import '../business_types/distribution/layouts/distribution_sales_layout.dart';
import '../business_types/distribution/layouts/distribution_warehouse_layout.dart';
import '../business_types/distribution/pages/driver/distribution_driver_layout_refactored.dart';
import '../business_types/distribution/layouts/distribution_customer_service_layout.dart';
import '../business_types/distribution/layouts/distribution_finance_layout.dart';
import '../business_types/manufacturing/layouts/manufacturing_manager_layout.dart';
import '../business_types/service/layouts/service_manager_layout.dart';
import '../business_types/service/layouts/service_staff_layout.dart';
import '../layouts/shift_leader_main_layout.dart';
import '../layouts/driver_main_layout.dart';
import '../layouts/warehouse_main_layout.dart';
import 'ceo/ceo_main_layout.dart';
import 'ceo/distribution/distribution_ceo_layout.dart';
import 'ceo/service/service_ceo_layout.dart';
import 'ceo/manufacturing/manufacturing_ceo_layout.dart';
import 'staff_main_layout.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart' as app_user;
import '../utils/app_logger.dart';

/// User Role Enum
enum UserRole {
  superAdmin('SUPER_ADMIN', 'Super Admin', AppColors.error, Icons.admin_panel_settings),
  ceo('CEO', 'Tổng Giám Đốc', AppColors.info, Icons.business_center),
  manager('MANAGER', 'Quản Lý', AppColors.success, Icons.supervisor_account),
  shiftLeader('SHIFT_LEADER', 'Trưởng Ca', AppColors.primary, Icons.group),
  staff('STAFF', 'Nhân Viên', AppColors.success, Icons.person),
  driver('DRIVER', 'Tài Xế', Color(0xFF0EA5E9), Icons.local_shipping),
  warehouse('WAREHOUSE', 'Nhân Viên Kho', Color(0xFFF97316), Icons.warehouse);

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
    if (_selectedRole == null && currentUser != null) {
      // Auto-select based on user's actual role
      _selectedRole = _mapUserRoleToEnum(currentUser.role);
    }

    if (_selectedRole != null) {
      // Wrap in Listener to record activity for session timeout
      return Listener(
        onPointerDown: (_) => ref.read(authProvider.notifier).recordActivity(),
        child: _buildRoleLayout(_selectedRole!),
      );
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
          if (kDebugMode)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRole = UserRole.staff;
                });
              },
              icon: const Icon(Icons.flash_on, size: 16),
              label: const Text('Quick Test'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
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
            AppColors.info,
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
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
              '6 Role Navigation Systems',
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
      case UserRole.superAdmin:
        return '6 tabs • Platform';
      case UserRole.ceo:
        return '4 tabs • Executive';
      case UserRole.manager:
        return '4 tabs • Management';
      case UserRole.shiftLeader:
        return '3 tabs • Operations';
      case UserRole.staff:
        return '5 tabs • Daily Work';
      case UserRole.driver:
        return '3 tabs • Delivery';
      case UserRole.warehouse:
        return '3 tabs • Warehouse';
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
              Icon(Icons.info_outline, color: AppColors.info),
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
          _buildInfoRow('✅ DRIVER System', '3 tabs - Delivery tasks'),
          _buildInfoRow('✅ WAREHOUSE System', '3 tabs - Warehouse ops'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tất cả navigation systems đã hoàn thành!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
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
      case app_user.UserRole.superAdmin:
        return UserRole.superAdmin;
      case app_user.UserRole.ceo:
        return UserRole.ceo;
      case app_user.UserRole.manager:
        return UserRole.manager;
      case app_user.UserRole.shiftLeader:
        return UserRole.shiftLeader;
      case app_user.UserRole.staff:
        return UserRole.staff;
      case app_user.UserRole.driver:
        return UserRole.driver;
      case app_user.UserRole.warehouse:
        return UserRole.warehouse;
    }
  }

  Widget _buildRoleLayout(UserRole role) {
    // Get current user to check business type and department
    final currentUser = ref.read(currentUserProvider);
    final businessType = currentUser?.businessType;
    final department = currentUser?.department;
    
    // 🔥 DEBUG: Log routing decision
    AppLogger.box('🧭 ROUTING DECISION', {
      'role': role.toString(),
      'businessType': businessType?.toString() ?? 'NULL',
      'department': department ?? 'NULL',
      'isDistribution': businessType?.isDistribution.toString() ?? 'N/A',
      'userName': currentUser?.name ?? 'Unknown',
      'companyName': currentUser?.companyName ?? 'Unknown',
    });
    
    switch (role) {
      case UserRole.superAdmin:
        AppLogger.nav('→ Routing to SuperAdminMainLayout');
        return const SuperAdminMainLayout();
      case UserRole.ceo:
        // Route CEO to business-type-specific layout (same pattern as Manager)
        if (businessType != null && businessType.isManufacturing) {
          AppLogger.nav('→ Routing to ManufacturingCEOLayout (CEO + isManufacturing=true)');
          return const ManufacturingCEOLayout();
        }
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionCEOLayout (CEO + isDistribution=true)');
          return const DistributionCEOLayout();
        }
        if (businessType != null && businessType.isService) {
          AppLogger.nav('→ Routing to ServiceCEOLayout (CEO + isService=true / Vận Hành)');
          return const ServiceCEOLayout();
        }
        AppLogger.nav('→ Routing to CEOMainLayout (fallback)');
        return const CEOMainLayout();
      case UserRole.manager:
        // Route to different layout based on business type
        if (businessType != null && businessType.isManufacturing) {
          AppLogger.nav('→ Routing to ManufacturingManagerLayout (isManufacturing=true)');
          return const ManufacturingManagerLayout();
        }
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionManagerLayout (isDistribution=true)');
          return const DistributionManagerLayout();
        }
        if (businessType != null && businessType.isService) {
          AppLogger.nav('→ Routing to ServiceManagerLayout (isService=true / Vận Hành)');
          return const ServiceManagerLayout();
        }
        AppLogger.nav('→ Routing to ManagerMainLayout (default)');
        return const ManagerMainLayout();
      case UserRole.shiftLeader:
        AppLogger.nav('→ Routing to ShiftLeaderMainLayout');
        return const ShiftLeaderMainLayout();
      case UserRole.staff:
        // Route STAFF based on department and business type
        if (businessType != null && businessType.isDistribution) {
          if (department == 'sales') {
            AppLogger.nav('→ Routing to DistributionSalesLayout (staff + sales dept + distribution)');
            return const DistributionSalesLayout();
          }
          if (department == 'warehouse') {
            AppLogger.nav('→ Routing to DistributionWarehouseLayout (staff + warehouse dept + distribution)');
            return const DistributionWarehouseLayout();
          }
          if (department == 'delivery' || department == 'driver') {
            AppLogger.nav('→ Routing to DistributionDriverLayout (staff + delivery dept + distribution)');
            return const DistributionDriverLayout();
          }
          if (department == 'customer_service') {
            AppLogger.nav('→ Routing to DistributionCustomerServiceLayout (staff + customer_service dept + distribution)');
            return const DistributionCustomerServiceLayout();
          }
          if (department == 'finance') {
            AppLogger.nav('→ Routing to DistributionFinanceLayout (staff + finance dept + distribution)');
            return const DistributionFinanceLayout();
          }
          // Other distribution staff go to default staff layout for now
        }
        if (businessType != null && businessType.isService) {
          AppLogger.nav('→ Routing to ServiceStaffLayout (staff + isService / Vận Hành)');
          return const ServiceStaffLayout();
        }
        AppLogger.nav('→ Routing to StaffMainLayout');
        return const StaffMainLayout();
      case UserRole.driver:
        // Distribution company drivers use DistributionDriverLayout
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionDriverLayout (driver + distribution)');
          return const DistributionDriverLayout();
        }
        AppLogger.nav('→ Routing to DriverMainLayout');
        return const DriverMainLayout();
      case UserRole.warehouse:
        // Distribution warehouse gets specialized layout with more tabs
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionWarehouseLayout (warehouse + distribution)');
          return const DistributionWarehouseLayout();
        }
        AppLogger.nav('→ Routing to WarehouseMainLayout (default)');
        return const WarehouseMainLayout();
    }
  }
}
