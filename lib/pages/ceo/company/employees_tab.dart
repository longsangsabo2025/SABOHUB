import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/company.dart';
import '../../../models/user.dart' as app_user;
import '../../../providers/employee_provider.dart';
import '../../../providers/cached_data_providers.dart';
import '../../../services/employee_service.dart';
import '../edit_employee_dialog.dart';
import 'create_employee_dialog.dart';

/// Employees Tab for Company Details
/// Shows employee list with search, filter, and CRUD operations
class EmployeesTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const EmployeesTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<EmployeesTab> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  app_user.UserRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync =
        ref.watch(cachedCompanyEmployeesProvider(widget.companyId));
    final statsAsync =
        ref.watch(companyEmployeesStatsProvider(widget.companyId));

    return Column(
      children: [
        // Header with Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Danh sách nhân viên',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateEmployeeDialog(widget.company),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Thêm nhân viên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats Row - using real data
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.people,
                        count: '${stats['total']}',
                        label: 'Tổng NV',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.supervised_user_circle,
                        count: '${stats['manager']}',
                        label: 'Quản lý',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.groups,
                        count: '${stats['shift_leader']}',
                        label: 'Trưởng ca',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.person,
                        count: '${stats['staff']}',
                        label: 'Nhân viên',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Row(
                  children: [
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.people,
                        count: '0',
                        label: 'Tổng NV',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.supervised_user_circle,
                        count: '0',
                        label: 'Quản lý',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.groups,
                        count: '0',
                        label: 'Trưởng ca',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEmployeeStatCard(
                        icon: Icons.person,
                        count: '0',
                        label: 'Nhân viên',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên, email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedRoleFilter == null,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter = null);
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.supervised_user_circle,
                              size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Quản lý'),
                        ],
                      ),
                      selected:
                          _selectedRoleFilter == app_user.UserRole.manager,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.manager : null);
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Trưởng ca'),
                        ],
                      ),
                      selected:
                          _selectedRoleFilter == app_user.UserRole.shiftLeader,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.shiftLeader : null);
                      },
                      selectedColor: Colors.orange[100],
                      checkmarkColor: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.purple),
                          SizedBox(width: 4),
                          Text('Nhân viên'),
                        ],
                      ),
                      selected: _selectedRoleFilter == app_user.UserRole.staff,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter =
                            selected ? app_user.UserRole.staff : null);
                      },
                      selectedColor: Colors.purple[100],
                      checkmarkColor: Colors.purple[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Employee List - using real data
        Expanded(
          child: employeesAsync.when(
            data: (employees) {
              // Apply search and filter
              var filteredEmployees = employees.where((employee) {
                // Search filter
                final matchesSearch = _searchQuery.isEmpty ||
                    employee.name?.toLowerCase().contains(_searchQuery) ==
                        true ||
                    employee.email.toLowerCase().contains(_searchQuery);

                // Role filter
                final matchesRole = _selectedRoleFilter == null ||
                    employee.role == _selectedRoleFilter;

                return matchesSearch && matchesRole;
              }).toList();

              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _showCreateEmployeeDialog(widget.company),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nhân viên đầu tiên'),
                      ),
                    ],
                  ),
                );
              }

              if (filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_searchQuery.isNotEmpty ||
                          _selectedRoleFilter != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedRoleFilter = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEmployees.length,
                itemBuilder: (context, index) {
                  return _buildEmployeeCard(filteredEmployees[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu nhân viên',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidateCompanyEmployees(widget.companyId);
                      ref.invalidate(
                          companyEmployeesStatsProvider(widget.companyId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(app_user.User employee) {
    // Determine color based on role
    Color roleColor;
    String roleLabel;

    switch (employee.role) {
      case app_user.UserRole.manager:
        roleColor = Colors.green;
        roleLabel = 'Quản lý';
        break;
      case app_user.UserRole.shiftLeader:
        roleColor = Colors.orange;
        roleLabel = 'Trưởng ca';
        break;
      case app_user.UserRole.staff:
        roleColor = Colors.purple;
        roleLabel = 'Nhân viên';
        break;
      case app_user.UserRole.ceo:
        roleColor = Colors.blue;
        roleLabel = 'CEO';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withValues(alpha: 0.2),
              child: Text(
                (employee.name != null && employee.name!.isNotEmpty)
                    ? employee.name![0].toUpperCase()
                    : employee.email[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name ?? employee.email.split('@').first,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          employee.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          employee.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Action Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await _showEditEmployeeDialog(employee);
                    break;
                  case 'deactivate':
                    await _toggleEmployeeStatus(employee);
                    break;
                  case 'delete':
                    await _deleteEmployee(employee);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(
                        (employee.isActive ?? true)
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                        color: (employee.isActive ?? true)
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text((employee.isActive ?? true)
                          ? 'Vô hiệu hóa'
                          : 'Kích hoạt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Employee Management Methods
  Future<void> _showCreateEmployeeDialog(Company company) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateEmployeeDialog(company: company),
    );

    // Refresh employee list if employee was created
    if (result == true) {
      ref.invalidate(companyEmployeesProvider(widget.companyId));
    }
  }

  Future<void> _showEditEmployeeDialog(app_user.User employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditEmployeeDialog(
        employee: employee,
        companyId: widget.companyId,
      ),
    );

    if (result == true && mounted) {
      ref.invalidateCompanyEmployees(widget.companyId);
      ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
    }
  }

  Future<void> _toggleEmployeeStatus(app_user.User employee) async {
    final newStatus = !(employee.isActive ?? true);
    final action = newStatus ? 'kích hoạt' : 'vô hiệu hóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text(
          'Bạn có chắc muốn $action tài khoản của ${employee.name ?? employee.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(newStatus ? 'Kích hoạt' : 'Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = EmployeeService();
        await service.toggleEmployeeStatus(employee.id, newStatus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã $action tài khoản ${employee.name ?? employee.email}',
              ),
              backgroundColor: Colors.green,
            ),
          );

          ref.invalidate(companyEmployeesProvider(widget.companyId));
          ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteEmployee(app_user.User employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xóa tài khoản của ${employee.name ?? employee.email}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = EmployeeService();
        await service.deleteEmployee(employee.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã xóa tài khoản ${employee.name ?? employee.email}',
              ),
              backgroundColor: Colors.green,
            ),
          );

          ref.invalidate(companyEmployeesProvider(widget.companyId));
          ref.invalidate(companyEmployeesStatsProvider(widget.companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
