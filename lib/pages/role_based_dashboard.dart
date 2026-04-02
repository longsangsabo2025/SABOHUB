import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
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
import '../business_types/service/layouts/service_shift_leader_layout.dart';
import '../business_types/ai_assistant/layouts/ai_assistant_ceo_layout.dart';
import '../layouts/shift_leader_main_layout.dart';
import '../layouts/driver_main_layout.dart';
import '../layouts/warehouse_main_layout.dart';
import 'ceo/ceo_main_layout.dart';
import 'ceo/distribution/distribution_ceo_layout.dart';
import 'ceo/service/service_ceo_layout.dart';
import 'ceo/manufacturing/manufacturing_ceo_layout.dart';
import 'shareholder/shareholder_dashboard.dart';
import 'staff_main_layout.dart';
import '../providers/auth_provider.dart';
import '../providers/company_context_provider.dart';
import '../models/user.dart' as app_user;
import '../utils/app_logger.dart';
import '../widgets/realtime_notification_widgets.dart';

/// User Role Enum
enum UserRole {
  superAdmin('SUPER_ADMIN', 'Super Admin', AppColors.error, Icons.admin_panel_settings),
  ceo('CEO', 'Tổng Giám Đốc', AppColors.info, Icons.business_center),
  manager('MANAGER', 'Quản Lý', AppColors.success, Icons.supervisor_account),
  shiftLeader('SHIFT_LEADER', 'Trưởng Ca', AppColors.primary, Icons.group),
  staff('STAFF', 'Nhân Viên', AppColors.success, Icons.person),
  driver('DRIVER', 'Tài Xế', Color(0xFF0EA5E9), Icons.local_shipping),
  warehouse('WAREHOUSE', 'Nhân Viên Kho', Color(0xFFF97316), Icons.warehouse),
  finance('FINANCE', 'Kế Toán', AppColors.success, Icons.account_balance),
  shareholder('SHAREHOLDER', 'Cổ Đông', AppColors.roleFinance, Icons.pie_chart);

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
        child: RealtimeNotificationListener(
          child: _buildRoleLayout(_selectedRole!),
        ),
      );
    }

    // Only show role selection if user has no role (shouldn't happen normally)
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Text(
          'Chọn vai trò',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
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
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
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
            AppColors.infoDark,
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
          Text(
            '🎉 SABOHUB FLUTTER',
            style: AppTextStyles.number.copyWith(color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống quản lý billiards đa vai trò',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '6 Role Navigation Systems',
              style: AppTextStyles.chip.copyWith(color: AppColors.textOnPrimary),
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
        Text(
          'Chọn vai trò của bạn',
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 4),
        Text(
          'Mỗi vai trò có navigation system và tính năng riêng',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: role.color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                color: AppColors.textSecondary,
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
      case UserRole.finance:
        return '3 tabs • Accounting';
      case UserRole.shareholder:
        return '2 tabs • Investor';
    }
  }

  Widget _buildSystemInfo() {
    return Container(
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
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tất cả navigation systems đã hoàn thành!',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.success),
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
              style: AppTextStyles.bodyBold,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
      case app_user.UserRole.finance:
        return UserRole.finance;
      case app_user.UserRole.shareholder:
        return UserRole.shareholder;
    }
  }

  Widget _buildRoleLayout(UserRole role) {
    // Get current user to check business type and department
    final currentUser = ref.read(currentUserProvider);
    final businessType = currentUser?.businessType;
    final department = currentUser?.department;
    
    // Check if CEO+corporation has selected a subsidiary to operate in
    final selectedSubsidiary = ref.watch(selectedSubsidiaryProvider);
    
    // 🔥 DEBUG: Log routing decision
    AppLogger.box('🧭 ROUTING DECISION', {
      'role': role.toString(),
      'businessType': businessType?.toString() ?? 'NULL',
      'department': department ?? 'NULL',
      'isDistribution': businessType?.isDistribution.toString() ?? 'N/A',
      'userName': currentUser?.name ?? 'Unknown',
      'companyName': currentUser?.companyName ?? 'Unknown',
      'selectedSubsidiary': selectedSubsidiary?.name ?? 'NONE',
    });

    // ── AI Assistant — Travis-centric layout for any role ──
    if (businessType != null && businessType.isAiAssistant) {
      AppLogger.nav('→ Routing to AiAssistantCeoLayout (businessType=aiAssistant)');
      return const AiAssistantCeoLayout();
    }
    
    switch (role) {
      case UserRole.superAdmin:
        AppLogger.nav('→ Routing to SuperAdminMainLayout');
        return const SuperAdminMainLayout();
      case UserRole.ceo:
        // ── Corporation CEO with subsidiary selected → route to subsidiary layout ──
        if (selectedSubsidiary != null && businessType != null && businessType.isCorporation) {
          final subType = selectedSubsidiary.type;
          Widget layout;
          if (subType.isManufacturing) {
            AppLogger.nav('→ Routing to ManufacturingCEOLayout (subsidiary: ${selectedSubsidiary.name})');
            layout = const ManufacturingCEOLayout();
          } else if (subType.isDistribution) {
            AppLogger.nav('→ Routing to DistributionCEOLayout (subsidiary: ${selectedSubsidiary.name})');
            layout = const DistributionCEOLayout();
          } else {
            AppLogger.nav('→ Routing to ServiceCEOLayout (subsidiary: ${selectedSubsidiary.name})');
            layout = const ServiceCEOLayout();
          }
          // Override currentUserProvider so subsidiary layout reads the subsidiary's data
          return Column(
            children: [
              // ── Back to Corporation banner ──
              Material(
                color: selectedSubsidiary.type.color.withValues(alpha: 0.12),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(selectedSubsidiary.type.icon, size: 18, color: selectedSubsidiary.type.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang xem: ${selectedSubsidiary.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selectedSubsidiary.type.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.read(selectedSubsidiaryProvider.notifier).clear(),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Về Tổng Công Ty', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: selectedSubsidiary.type.color,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Subsidiary layout with overridden provider ──
              Expanded(
                child: ProviderScope(
                  overrides: [
                    currentUserProvider.overrideWith((ref) {
                      // Use captured currentUser (avoid circular dependency)
                      if (currentUser == null) return null;
                      return currentUser.copyWith(
                        companyId: selectedSubsidiary.id,
                        companyName: selectedSubsidiary.name,
                        businessType: selectedSubsidiary.type,
                      );
                    }),
                  ],
                  child: layout,
                ),
              ),
            ],
          );
        }
        // ── Normal CEO routing (non-corporation or no subsidiary selected) ──
        // Route CEO to business-type-specific layout
        if (businessType != null && businessType.isManufacturing) {
          AppLogger.nav('→ Routing to ManufacturingCEOLayout (CEO + isManufacturing=true)');
          return const ManufacturingCEOLayout();
        }
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionCEOLayout (CEO + isDistribution=true)');
          return const DistributionCEOLayout();
        }
        if (businessType != null && businessType.isService && !businessType.isCorporation) {
          AppLogger.nav('→ Routing to ServiceCEOLayout (CEO + isService=true / Vận Hành)');
          return const ServiceCEOLayout();
        }
        // corporation hoặc businessType null → generic CEO
        AppLogger.nav('→ Routing to CEOMainLayout (fallback: corporation/null)');
        return const CEOMainLayout();
      case UserRole.manager:
        // ── Corporation Manager with subsidiary selected → route to subsidiary layout ──
        if (selectedSubsidiary != null && businessType != null && businessType.isCorporation) {
          final subType = selectedSubsidiary.type;
          Widget layout;
          if (subType.isManufacturing) {
            AppLogger.nav('→ Routing to ManufacturingManagerLayout (manager subsidiary: ${selectedSubsidiary.name})');
            layout = const ManufacturingManagerLayout();
          } else if (subType.isDistribution) {
            AppLogger.nav('→ Routing to DistributionManagerLayout (manager subsidiary: ${selectedSubsidiary.name})');
            layout = const DistributionManagerLayout();
          } else {
            AppLogger.nav('→ Routing to ServiceManagerLayout (manager subsidiary: ${selectedSubsidiary.name})');
            layout = const ServiceManagerLayout();
          }
          return Column(
            children: [
              // ── Back to Corporation banner ──
              Material(
                color: selectedSubsidiary.type.color.withValues(alpha: 0.12),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(selectedSubsidiary.type.icon, size: 18, color: selectedSubsidiary.type.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang xem: ${selectedSubsidiary.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selectedSubsidiary.type.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.read(selectedSubsidiaryProvider.notifier).clear(),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Về Tổng Công Ty', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: selectedSubsidiary.type.color,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Subsidiary layout with overridden provider ──
              Expanded(
                child: ProviderScope(
                  overrides: [
                    currentUserProvider.overrideWith((ref) {
                      // Use captured currentUser (avoid circular dependency)
                      if (currentUser == null) return null;
                      return currentUser.copyWith(
                        companyId: selectedSubsidiary.id,
                        companyName: selectedSubsidiary.name,
                        businessType: selectedSubsidiary.type,
                      );
                    }),
                  ],
                  child: layout,
                ),
              ),
            ],
          );
        }
        // ── Normal Manager routing (non-corporation or no subsidiary selected) ──
        // Route to different layout based on business type
        if (businessType != null && businessType.isManufacturing) {
          AppLogger.nav('→ Routing to ManufacturingManagerLayout (isManufacturing=true)');
          return const ManufacturingManagerLayout();
        }
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionManagerLayout (isDistribution=true)');
          return const DistributionManagerLayout();
        }
        if (businessType != null && businessType.isService && !businessType.isCorporation) {
          AppLogger.nav('→ Routing to ServiceManagerLayout (isService=true / Vận Hành)');
          return const ServiceManagerLayout();
        }
        // corporation hoặc businessType null → generic Manager
        AppLogger.nav('→ Routing to ManagerMainLayout (default: corporation/null)');
        return const ManagerMainLayout();
      case UserRole.shiftLeader:
        // Route shiftLeader by businessType — service companies need billiards-aware layout
        if (businessType != null && businessType.isService && !businessType.isCorporation) {
          AppLogger.nav('→ Routing to ServiceShiftLeaderLayout (shiftLeader + isService)');
          return const ServiceShiftLeaderLayout();
        }
        // Distribution / manufacturing / corporation / null → generic
        AppLogger.nav('→ Routing to ShiftLeaderMainLayout (shiftLeader + default)');
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
          // Distribution staff nhưng department không xác định → fallback Sales (phổ biến nhất)
          AppLogger.nav('→ Routing to DistributionSalesLayout (staff + distribution + unknown dept: $department)');
          return const DistributionSalesLayout();
        }
        if (businessType != null && businessType.isService && !businessType.isCorporation) {
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
      case UserRole.finance:
        // Finance role gets distribution finance layout when in distribution company
        if (businessType != null && businessType.isDistribution) {
          AppLogger.nav('→ Routing to DistributionFinanceLayout (finance + distribution)');
          return const DistributionFinanceLayout();
        }
        // For other business types, route to staff layout with accounting features
        AppLogger.nav('→ Routing to StaffMainLayout (finance role - default)');
        return const StaffMainLayout();
      case UserRole.shareholder:
        // Shareholder gets read-only dashboard to view their shares
        AppLogger.nav('→ Routing to ShareholderDashboard (shareholder role)');
        return ShareholderDashboard();
    }
  }
}
