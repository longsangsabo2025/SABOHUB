import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/manager_permissions.dart';
import '../../services/manager_permissions_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_permissions_provider.dart';

/// CEO Manager Permissions Page
/// Allows CEO to grant/revoke permissions for each Manager
class CEOManagerPermissionsPage extends ConsumerStatefulWidget {
  final String companyId;

  const CEOManagerPermissionsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CEOManagerPermissionsPage> createState() =>
      _CEOManagerPermissionsPageState();
}

class _CEOManagerPermissionsPageState
    extends ConsumerState<CEOManagerPermissionsPage> {
  String? _selectedManagerId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final allManagersAsync =
        ref.watch(allManagerPermissionsProvider(widget.companyId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Phân quyền Manager',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: allManagersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải danh sách Manager',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
        data: (managers) {
          if (managers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Chưa có Manager nào trong công ty'),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Left panel: Manager list
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Danh sách Manager (${managers.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: managers.length,
                        itemBuilder: (context, index) {
                          final manager = managers[index];
                          final managerId = manager['manager_id'] as String;
                          final managerName = manager['manager_name'] as String;
                          final isSelected = _selectedManagerId == managerId;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedManagerId = managerId;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      managerName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          managerName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Manager',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFF3B82F6),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Right panel: Permission editor
              Expanded(
                child: _selectedManagerId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Chọn Manager để phân quyền'),
                          ],
                        ),
                      )
                    : _buildPermissionEditor(
                        _selectedManagerId!,
                        managers.firstWhere((m) =>
                            m['manager_id'] == _selectedManagerId)['manager_name']
                            as String,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionEditor(String managerId, String managerName) {
    final permissionsAsync = ref.watch(
      managerPermissionsByCompanyProvider({
        'managerId': managerId,
        'companyId': widget.companyId,
      }),
    );

    return permissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Lỗi: ${error.toString()}'),
      ),
      data: (permissions) {
        if (permissions == null) {
          return const Center(child: Text('Không tìm thấy quyền'));
        }

        return _buildPermissionForm(permissions, managerName);
      },
    );
  }

  Widget _buildPermissionForm(
      ManagerPermissions permissions, String managerName) {
    return _PermissionFormWidget(
      key: ValueKey(permissions.id),
      permissions: permissions,
      managerName: managerName,
      companyId: widget.companyId,
      managerId: _selectedManagerId!,
      onSaved: () {
        // Refresh data after save
        ref.invalidate(allManagerPermissionsProvider(widget.companyId));
      },
    );
  }
}

/// Stateful widget to manage permission form state
class _PermissionFormWidget extends ConsumerStatefulWidget {
  final ManagerPermissions permissions;
  final String managerName;
  final String companyId;
  final String managerId;
  final VoidCallback onSaved;

  const _PermissionFormWidget({
    required super.key,
    required this.permissions,
    required this.managerName,
    required this.companyId,
    required this.managerId,
    required this.onSaved,
  });

  @override
  ConsumerState<_PermissionFormWidget> createState() =>
      _PermissionFormWidgetState();
}

class _PermissionFormWidgetState extends ConsumerState<_PermissionFormWidget> {
  late Map<String, bool> _permissionValues;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _permissionValues = {
      'can_view_overview': widget.permissions.canViewOverview,
      'can_view_employees': widget.permissions.canViewEmployees,
      'can_view_tasks': widget.permissions.canViewTasks,
      'can_view_documents': widget.permissions.canViewDocuments,
      'can_view_ai_assistant': widget.permissions.canViewAiAssistant,
      'can_view_attendance': widget.permissions.canViewAttendance,
      'can_view_accounting': widget.permissions.canViewAccounting,
      'can_view_employee_docs': widget.permissions.canViewEmployeeDocs,
      'can_view_business_law': widget.permissions.canViewBusinessLaw,
      'can_view_settings': widget.permissions.canViewSettings,
      'can_create_employee': widget.permissions.canCreateEmployee,
      'can_edit_employee': widget.permissions.canEditEmployee,
      'can_delete_employee': widget.permissions.canDeleteEmployee,
      'can_create_task': widget.permissions.canCreateTask,
      'can_edit_task': widget.permissions.canEditTask,
      'can_delete_task': widget.permissions.canDeleteTask,
      'can_approve_attendance': widget.permissions.canApproveAttendance,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                child: Text(
                  managerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cấu hình quyền truy cập',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Tab View Permissions
          _buildPermissionSection(
            'Quyền xem các Tab',
            Icons.tab,
            [
              _PermissionItem('Tổng quan', 'can_view_overview',
                  permissions.canViewOverview),
              _PermissionItem('Nhân viên', 'can_view_employees',
                  permissions.canViewEmployees),
              _PermissionItem(
                  'Công việc', 'can_view_tasks', permissions.canViewTasks),
              _PermissionItem(
                  'Tài liệu', 'can_view_documents', permissions.canViewDocuments),
              _PermissionItem('Trợ lý AI', 'can_view_ai_assistant',
                  permissions.canViewAiAssistant),
              _PermissionItem('Chấm công', 'can_view_attendance',
                  permissions.canViewAttendance),
              _PermissionItem(
                  'Kế toán', 'can_view_accounting', permissions.canViewAccounting),
              _PermissionItem('Hồ sơ NV', 'can_view_employee_docs',
                  permissions.canViewEmployeeDocs),
              _PermissionItem('Luật DN', 'can_view_business_law',
                  permissions.canViewBusinessLaw),
              _PermissionItem(
                  'Cài đặt', 'can_view_settings', permissions.canViewSettings),
            ],
            permissions,
          ),

          const SizedBox(height: 32),

          // Action Permissions
          _buildPermissionSection(
            'Quyền thao tác',
            Icons.security,
            [
              _PermissionItem('Tạo nhân viên', 'can_create_employee',
                  permissions.canCreateEmployee),
              _PermissionItem('Sửa nhân viên', 'can_edit_employee',
                  permissions.canEditEmployee),
              _PermissionItem('Xóa nhân viên', 'can_delete_employee',
                  permissions.canDeleteEmployee),
              _PermissionItem(
                  'Tạo công việc', 'can_create_task', permissions.canCreateTask),
              _PermissionItem(
                  'Sửa công việc', 'can_edit_task', permissions.canEditTask),
              _PermissionItem(
                  'Xóa công việc', 'can_delete_task', permissions.canDeleteTask),
              _PermissionItem('Duyệt chấm công', 'can_approve_attendance',
                  permissions.canApproveAttendance),
            ],
            permissions,
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _savePermissions(permissions),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(
    String title,
    IconData icon,
    List<_PermissionItem> items,
    ManagerPermissions permissions,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildPermissionRow(item, permissions)),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
      _PermissionItem item, ManagerPermissions permissions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: item.value,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (newValue) {
              setState(() {
                // Update permission value
                _updatePermissionValue(permissions, item.key, newValue);
              });
            },
          ),
        ],
      ),
    );
  }

  void _updatePermissionValue(
      ManagerPermissions permissions, String key, bool value) {
    // This will trigger a rebuild with updated value
    // The actual update will be in the copyWith when saving
    ref.invalidate(managerPermissionsByCompanyProvider({
      'managerId': _selectedManagerId!,
      'companyId': widget.companyId,
    }));
  }

  Future<void> _savePermissions(ManagerPermissions permissions) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(managerPermissionsServiceProvider);

      // Save the current permissions
      await service.updatePermissions(
        permissionId: permissions.id,
        updates: permissions.toJson(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu quyền truy cập thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh data
      ref.invalidate(allManagerPermissionsProvider(widget.companyId));
      ref.invalidate(managerPermissionsByCompanyProvider({
        'managerId': _selectedManagerId!,
        'companyId': widget.companyId,
      }));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _PermissionItem {
  final String label;
  final String key;
  final bool value;

  _PermissionItem(this.label, this.key, this.value);
}
