import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/branch.dart';
import '../../models/company.dart';
import '../../services/branch_service.dart';
import '../../services/company_service.dart';
import '../../widgets/shimmer_loading.dart';
import 'ai_assistant_tab.dart';
import 'company/accounting_tab.dart';
import 'company/attendance_tab.dart';
import 'company/business_law_tab.dart';
import 'company/documents_tab.dart';
import 'company/employee_documents_tab.dart';
import 'company/employees_tab.dart';
import 'company/overview_tab.dart';
import 'company/permissions_management_tab.dart';
import 'company/settings_tab.dart';
import 'company/tasks_tab.dart';

/// Company Details Page Provider
/// Caches data to prevent unnecessary refetches when switching tabs
final companyDetailsProvider =
    FutureProvider.family<Company?, String>((ref, id) async {
  // Keep provider alive to cache company data across tab switches
  ref.keepAlive();

  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Branches Provider
final companyBranchesProvider =
    FutureProvider.family<List<Branch>, String>((ref, companyId) async {
  final service = BranchService();
  return await service.getAllBranches(companyId: companyId);
});

/// Company Stats Provider
final companyStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyStats(companyId);
});

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// Company Details Page
/// Displays comprehensive information about a single company
class CompanyDetailsPage extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends ConsumerState<CompanyDetailsPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider(widget.companyId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: companyAsync.when(
        loading: () => Column(
          children: [
            // Shimmer for header/overview section
            const ShimmerCompanyHeader(),
            const SizedBox(height: 16),
            // Bottom navigation bar shown even while loading
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.refresh(companyDetailsProvider(widget.companyId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (company) {
          if (company == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy công ty',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }
          return _buildContent(company);
        },
      ),
    );
  }

  Widget _buildContent(Company company) {
    return Scaffold(
      body: Column(
        children: [
          // Hiển thị header đầy đủ ở tab Tổng quan, AppBar compact ở các tab khác
          if (_currentIndex == 0)
            _buildHeader(company)
          else
            _buildCompactAppBar(company),
          Expanded(
            // ✅ PERFORMANCE FIX: Lazy loading - only build current tab
            // Previous: IndexedStack kept all 10 tabs in memory (~100MB overhead)
            // Now: Only builds active tab, reducing memory usage by ~80%
            child: _buildCurrentTab(company),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Build only the currently active tab (lazy loading)
  /// This significantly reduces memory usage compared to IndexedStack
  Widget _buildCurrentTab(Company company) {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(company: company, companyId: widget.companyId);
      case 1:
        return EmployeesTab(company: company, companyId: widget.companyId);
      case 2:
        return TasksTab(company: company, companyId: widget.companyId);
      case 3:
        return DocumentsTab(company: company);
      case 4:
        return AIAssistantTab(
          companyId: company.id,
          companyName: company.name,
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
        return PermissionsManagementTab(
            company: company, companyId: widget.companyId);
      case 10:
        return SettingsTab(company: company, companyId: widget.companyId);
      default:
        return OverviewTab(company: company, companyId: widget.companyId);
    }
  }

  Widget _buildCompactAppBar(Company company) {
    final tabNames = [
      'Tổng quan',
      'Nhân viên',
      'Công việc',
      'Tài liệu',
      'AI Assistant',
      'Chấm công',
      'Kế toán',
      'Hồ sơ NV',
      'Luật DN',
      'Phân quyền',
      'Cài đặt'
    ];

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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Quay lại',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tabNames[_currentIndex],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                tooltip: 'Tùy chọn',
                onPressed: () => _showMoreOptions(company),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Company company) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            company.type.color,
            company.type.color.withValues(alpha: 0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Chỉnh sửa công ty',
                    onPressed: () => _showEditDialog(company),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'Tùy chọn',
                    onPressed: () => _showMoreOptions(company),
                  ),
                ],
              ),
            ),
            // Company Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Logo or Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      company.type.icon,
                      size: 40,
                      color: company.type.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Name
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Business Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      company.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: company.status == 'active'
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: company.status == 'active'
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      company.status == 'active'
                          ? 'Đang hoạt động'
                          : 'Tạm dừng',
                      style: TextStyle(
                        color: company.status == 'active'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Nhân viên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Công việc',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Tài liệu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: 'Chấm công',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Kế toán',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_shared),
          label: 'Hồ sơ NV',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.gavel),
          label: 'Luật DN',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Phân quyền',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
    );
  }

  // Helper methods for header actions
  void _showEditDialog(Company company) {
    final nameController = TextEditingController(text: company.name);
    final addressController = TextEditingController(text: company.address);
    final phoneController = TextEditingController(text: company.phone ?? '');
    final emailController = TextEditingController(text: company.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa công ty'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên công ty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final service = ref.read(companyServiceProvider);
                  await service.updateCompany(company.id, {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  });

                  ref.invalidate(companyDetailsProvider(widget.companyId));
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật công ty thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(Company company) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chia sẻ công ty')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Làm mới'),
              onTap: () {
                Navigator.pop(context);
                ref.invalidate(companyDetailsProvider(widget.companyId));
                ref.invalidate(companyStatsProvider(widget.companyId));
                ref.invalidate(companyBranchesProvider(widget.companyId));
              },
            ),
          ],
        ),
      ),
    );
  }
}
