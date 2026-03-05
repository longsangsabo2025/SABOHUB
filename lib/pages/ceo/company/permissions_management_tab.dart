import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/company.dart';
import '../../../models/manager_permissions.dart';
import '../../../providers/manager_permissions_provider.dart';
import '../../../utils/app_logger.dart';

/// Permissions Management Tab for CEO
/// Allows CEO to grant/revoke permissions for each Manager
class PermissionsManagementTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const PermissionsManagementTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<PermissionsManagementTab> createState() =>
      _PermissionsManagementTabState();
}

class _PermissionsManagementTabState
    extends ConsumerState<PermissionsManagementTab> {
  String? _selectedManagerId;
  final Map<String, bool> _editedPermissions = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    AppLogger.info('[PERMISSIONS TAB] Building with companyId: ${widget.companyId}');
    
    final allManagersAsync =
        ref.watch(allManagerPermissionsProvider(widget.companyId));

    return allManagersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Không thể tải danh sách Manager',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Error: $error',
                style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
      data: (managers) {
        // Auto-select first manager if none selected
        if (managers.isNotEmpty && _selectedManagerId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedManagerId = managers[0]['manager_id'] as String;
              AppLogger.info('[AUTO-SELECT] Selected first manager: $_selectedManagerId');
            });
          });
        }
        
        if (managers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Chưa có Manager nào trong công ty',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Manager mới sẽ tự động nhận quyền mặc định',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _autoCreatePermissions(),
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Tự động tạo quyền cho Manager'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Left panel: Manager list
            _buildManagerList(managers),
            
            // Right panel: Permission editor
            Expanded(
              child: _selectedManagerId == null
                  ? _buildEmptyState()
                  : _buildPermissionEditor(managers),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagerList(List<Map<String, dynamic>> managers) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.company.type.color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: widget.company.type.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${managers.length} người',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      _editedPermissions.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.company.type.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? widget.company.type.color
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              widget.company.type.color.withValues(alpha: 0.2),
                          child: Text(
                            managerName[0].toUpperCase(),
                            style: TextStyle(
                              color: widget.company.type.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                managerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: widget.company.type.color,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Chọn Manager để phân quyền',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click vào tên Manager bên trái',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionEditor(List<Map<String, dynamic>> managers) {
    final manager = managers.firstWhere(
      (m) => m['manager_id'] == _selectedManagerId,
    );
    final managerName = manager['manager_name'] as String;
    
    AppLogger.info('[EDITOR] Building for manager: $managerName');
    AppLogger.data('[EDITOR] Manager data', manager);

    // Convert manager data to ManagerPermissions model
    // The manager data already contains all permission fields
    final permissions = ManagerPermissions.fromJson(manager);
    
    AppLogger.data('[EDITOR] Permissions loaded', permissions.toJson());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(managerName),
          const SizedBox(height: 32),
          _buildTabPermissionsSection(permissions),
          const SizedBox(height: 24),
          _buildActionPermissionsSection(permissions),
          const SizedBox(height: 32),
          _buildSaveButton(permissions),
        ],
      ),
    );
  }

  Widget _buildHeader(String managerName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: widget.company.type.color.withValues(alpha: 0.2),
          child: Text(
            managerName[0].toUpperCase(),
            style: TextStyle(
              color: widget.company.type.color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                managerName,
                style: const TextStyle(
                  fontSize: 24,
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
        ),
      ],
    );
  }

  Widget _buildTabPermissionsSection(ManagerPermissions permissions) {
    return _buildPermissionCard(
      title: 'Quyền xem các Tab',
      icon: Icons.tab,
      items: [
        _PermissionItem('Tổng quan', 'can_view_overview',
            _getPermissionValue('can_view_overview', permissions.canViewOverview)),
        _PermissionItem('Nhân viên', 'can_view_employees',
            _getPermissionValue('can_view_employees', permissions.canViewEmployees)),
        _PermissionItem('Công việc', 'can_view_tasks',
            _getPermissionValue('can_view_tasks', permissions.canViewTasks)),
        _PermissionItem('Tài liệu', 'can_view_documents',
            _getPermissionValue('can_view_documents', permissions.canViewDocuments)),
        _PermissionItem('Trợ lý AI', 'can_view_ai_assistant',
            _getPermissionValue('can_view_ai_assistant', permissions.canViewAiAssistant)),
        _PermissionItem('Chấm công', 'can_view_attendance',
            _getPermissionValue('can_view_attendance', permissions.canViewAttendance)),
        _PermissionItem('Kế toán', 'can_view_accounting',
            _getPermissionValue('can_view_accounting', permissions.canViewAccounting)),
        _PermissionItem('Hồ sơ NV', 'can_view_employee_docs',
            _getPermissionValue('can_view_employee_docs', permissions.canViewEmployeeDocs)),
        _PermissionItem('Luật DN', 'can_view_business_law',
            _getPermissionValue('can_view_business_law', permissions.canViewBusinessLaw)),
        _PermissionItem('Cài đặt', 'can_view_settings',
            _getPermissionValue('can_view_settings', permissions.canViewSettings)),
      ],
      permissions: permissions,
    );
  }

  Widget _buildActionPermissionsSection(ManagerPermissions permissions) {
    return _buildPermissionCard(
      title: 'Quyền thao tác',
      icon: Icons.security,
      items: [
        _PermissionItem('Tạo nhân viên', 'can_create_employee',
            _getPermissionValue('can_create_employee', permissions.canCreateEmployee)),
        _PermissionItem('Sửa nhân viên', 'can_edit_employee',
            _getPermissionValue('can_edit_employee', permissions.canEditEmployee)),
        _PermissionItem('Xóa nhân viên', 'can_delete_employee',
            _getPermissionValue('can_delete_employee', permissions.canDeleteEmployee)),
        _PermissionItem('Tạo công việc', 'can_create_task',
            _getPermissionValue('can_create_task', permissions.canCreateTask)),
        _PermissionItem('Sửa công việc', 'can_edit_task',
            _getPermissionValue('can_edit_task', permissions.canEditTask)),
        _PermissionItem('Xóa công việc', 'can_delete_task',
            _getPermissionValue('can_delete_task', permissions.canDeleteTask)),
        _PermissionItem('Duyệt chấm công', 'can_approve_attendance',
            _getPermissionValue('can_approve_attendance', permissions.canApproveAttendance)),
      ],
      permissions: permissions,
    );
  }

  bool _getPermissionValue(String key, bool originalValue) {
    return _editedPermissions.containsKey(key)
        ? _editedPermissions[key]!
        : originalValue;
  }

  Widget _buildPermissionCard({
    required String title,
    required IconData icon,
    required List<_PermissionItem> items,
    required ManagerPermissions permissions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.company.type.color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: widget.company.type.color),
                const SizedBox(width: 12),
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
          ...items.map((item) => _buildPermissionRow(item)),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(_PermissionItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Switch(
            value: item.value,
            activeColor: widget.company.type.color,
            onChanged: (newValue) {
              setState(() {
                _editedPermissions[item.key] = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ManagerPermissions permissions) {
    final hasChanges = _editedPermissions.isNotEmpty;

    return Row(
      children: [
        if (hasChanges) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _editedPermissions.clear();
                      });
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hủy thay đổi'),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: hasChanges ? 1 : 2,
          child: ElevatedButton(
            onPressed: (!hasChanges || _isSaving)
                ? null
                : () => _savePermissions(permissions),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.company.type.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                    ),
                  )
                : Text(
                    hasChanges ? 'Lưu thay đổi' : 'Không có thay đổi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _savePermissions(ManagerPermissions permissions) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(managerPermissionsServiceProvider);

      // Merge edited permissions with original
      final updates = permissions.toJson();
      _editedPermissions.forEach((key, value) {
        updates[key] = value;
      });

      await service.updatePermissions(
        permissionId: permissions.id,
        updates: updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã lưu quyền truy cập thành công'),
            backgroundColor: widget.company.type.color,
          ),
        );
      }

      // Clear edited state and refresh
      setState(() {
        _editedPermissions.clear();
      });

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

  /// Auto-create permissions for all managers without permissions
  Future<void> _autoCreatePermissions() async {
    setState(() {
      _isSaving = true;
    });

    try {
      AppLogger.info('[AUTO-CREATE] Starting auto-create permissions...');
      
      final supabaseClient = supabase.client;
      
      // Get all managers in this company from employees table
      final employeesResponse = await supabaseClient
          .from('employees')
          .select('id, full_name')
          .eq('company_id', widget.companyId)
          .eq('role', 'MANAGER');

      final managers = employeesResponse as List;
      AppLogger.info('[AUTO-CREATE] Found ${managers.length} managers in employees table');

      if (managers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⚠️ Không tìm thấy Manager nào trong bảng employees'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      int created = 0;
      int skipped = 0;

      for (var manager in managers) {
        AppLogger.info('[AUTO-CREATE] Processing ${manager['full_name']}...');
        
        // Check if permission already exists
        final existing = await supabaseClient
            .from('manager_permissions')
            .select('id')
            .eq('manager_id', manager['id'])
            .eq('company_id', widget.companyId);

        if ((existing as List).isNotEmpty) {
          AppLogger.info('  Already has permissions, skipping');
          skipped++;
          continue;
        }

        // Create default permission
        await ref
            .read(managerPermissionsServiceProvider)
            .createDefaultPermissions(
              managerId: manager['id'],
              companyId: widget.companyId,
            );
        
        AppLogger.info('  Created default permissions');
        created++;
      }

      AppLogger.info('[AUTO-CREATE] Done! Created: $created, Skipped: $skipped');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo quyền cho $created Manager'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the list
        ref.invalidate(allManagerPermissionsProvider(widget.companyId));
      }
    } catch (e) {
      AppLogger.error('[AUTO-CREATE] Error', e);
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
