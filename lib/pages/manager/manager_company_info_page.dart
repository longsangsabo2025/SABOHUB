import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/company.dart';
import '../../models/manager_permissions.dart';
import '../../providers/manager_permissions_provider.dart';
import '../../services/company_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../ceo/company/accounting_tab.dart';
import '../ceo/company/attendance_tab.dart';
import '../ceo/company/business_law_tab.dart';
import '../ceo/company/documents_tab.dart';
import '../ceo/company/employee_documents_tab.dart';
import '../ceo/company/employees_tab.dart';
import '../ceo/company/overview_tab.dart';
import '../ceo/company/settings_tab.dart';
import '../ceo/company/tasks_tab.dart';

/// Company Info Provider for Manager
final managerCompanyInfoProvider =
    FutureProvider.family<Company?, String>((ref, id) async {
  ref.keepAlive();
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// Manager Company Info Page
/// Shows company information with tabs based on Manager's permissions
class ManagerCompanyInfoPage extends ConsumerStatefulWidget {
  final String companyId;

  const ManagerCompanyInfoPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<ManagerCompanyInfoPage> createState() =>
      _ManagerCompanyInfoPageState();
}

class _ManagerCompanyInfoPageState
    extends ConsumerState<ManagerCompanyInfoPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(managerCompanyInfoProvider(widget.companyId));
    final permissionsAsync = ref.watch(managerPermissionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: permissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải quyền truy cập',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ],
          ),
        ),
        data: (permissions) {
          if (permissions == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.orange[300]),
                  const SizedBox(height: 16),
                  const Text('Chưa được cấp quyền truy cập',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Vui lòng liên hệ CEO để được cấp quyền',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return companyAsync.when(
            loading: () => Column(
              children: [
                const ShimmerCompanyHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Không thể tải thông tin công ty',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
            data: (company) {
              if (company == null) {
                return const Center(
                  child: Text('Không tìm thấy công ty'),
                );
              }

              return Column(
                children: [
                  _buildCompactAppBar(company, permissions),
                  Expanded(
                    child: _buildCurrentTab(company, permissions),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: permissionsAsync.maybeWhen(
        data: (permissions) =>
            permissions != null ? _buildBottomNavigationBar(permissions) : null,
        orElse: () => null,
      ),
    );
  }

  /// Build app bar with company info
  Widget _buildCompactAppBar(Company company, ManagerPermissions permissions) {
    final tabNames = permissions.getEnabledTabNames();

    return Container(
      decoration: BoxDecoration(
        color: company.type.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Company Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  company.type.icon,
                  color: company.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Company Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tabNames.isNotEmpty
                          ? tabNames[_currentIndex]
                          : 'Không có quyền',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build current tab based on permissions
  Widget _buildCurrentTab(Company company, ManagerPermissions permissions) {
    final enabledIndices = permissions.getEnabledTabIndices();

    if (enabledIndices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Chưa có quyền truy cập',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final actualTabIndex = enabledIndices[_currentIndex];

    switch (actualTabIndex) {
      case 0:
        return OverviewTab(company: company, companyId: widget.companyId);
      case 1:
        return EmployeesTab(company: company, companyId: widget.companyId);
      case 2:
        return TasksTab(company: company, companyId: widget.companyId);
      case 3:
        return DocumentsTab(company: company);
      case 4:
        return const Center(
          child: Text('Trợ lý AI - Coming soon'),
        );
      case 5:
        return AttendanceTab(company: company, companyId: widget.companyId);
      case 6:
        return AccountingTab(company: company, companyId: widget.companyId);
      case 7:
        return EmployeeDocumentsTab(
            company: company, companyId: widget.companyId);
      case 8:
        return BusinessLawTab(company: company, companyId: widget.companyId);
      case 9:
        return SettingsTab(company: company, companyId: widget.companyId);
      default:
        return const Center(child: Text('Tab không hợp lệ'));
    }
  }

  /// Build bottom navigation bar with only enabled tabs
  Widget _buildBottomNavigationBar(ManagerPermissions permissions) {
    final tabNames = permissions.getEnabledTabNames();
    final tabIcons = [
      Icons.dashboard,
      Icons.people,
      Icons.task_alt,
      Icons.folder,
      Icons.smart_toy,
      Icons.access_time,
      Icons.calculate, // Changed from Icons.accounting
      Icons.description,
      Icons.gavel,
      Icons.settings,
    ];

    final enabledIndices = permissions.getEnabledTabIndices();
    final enabledIcons = enabledIndices.map((i) => tabIcons[i]).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabNames.length, (index) {
            final isActive = index == _currentIndex;
            return InkWell(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      enabledIcons[index],
                      color: isActive ? const Color(0xFF3B82F6) : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabNames[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? const Color(0xFF3B82F6) : Colors.grey,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
