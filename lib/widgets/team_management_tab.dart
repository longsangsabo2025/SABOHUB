import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart' as app_user;
import '../providers/employee_provider.dart';
import '../providers/auth_provider.dart';

// Import UserRole
typedef UserRole = app_user.UserRole;

/// Team Management Tab - Enhanced version for Manager Dashboard
/// 🎯 Polished Team Tab with employee CRUD, search, filters, and actions
class TeamManagementTab extends ConsumerStatefulWidget {
  const TeamManagementTab({super.key});

  @override
  ConsumerState<TeamManagementTab> createState() => _TeamManagementTabState();
}

class _TeamManagementTabState extends ConsumerState<TeamManagementTab> {
  String _searchQuery = '';
  app_user.UserRole? _selectedRoleFilter;
  String _selectedStatusFilter = 'all'; // all, active, inactive
  bool _showFilters = false;

  List<app_user.User> _getFilteredEmployees(List<app_user.User> employees) {
    return employees.where((employee) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final name = employee.name?.toLowerCase() ?? '';
        final email = employee.email.toLowerCase();
        final phone = employee.phone ?? '';
        if (!name.contains(searchLower) &&
            !email.contains(searchLower) &&
            !phone.contains(searchLower)) {
          return false;
        }
      }

      // Role filter
      if (_selectedRoleFilter != null && employee.role != _selectedRoleFilter) {
        return false;
      }

      // Status filter - check isActive from User model
      if (_selectedStatusFilter == 'active' && employee.isActive != true) {
        return false;
      }
      if (_selectedStatusFilter == 'inactive' && employee.isActive != false) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user's companyId
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;

    if (companyId == null) {
      return const Center(
        child: Text('Không tìm thấy thông tin công ty'),
      );
    }

    // Watch real employee data from provider
    final teamAsync = ref.watch(companyEmployeesProvider(companyId));

    return teamAsync.when(
      data: (employees) {
        final filteredEmployees = _getFilteredEmployees(employees);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_showFilters) ...[
              _buildFiltersSection(),
              const SizedBox(height: 16),
            ],
            _buildQuickStats(employees),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTeamList(filteredEmployees),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Lỗi tải danh sách nhân viên: $error'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '👥 Quản lý nhóm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            color: _showFilters ? Colors.blue.shade600 : Colors.grey.shade600,
          ),
          tooltip: 'Bộ lọc',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showAddEmployeeModal,
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Thêm nhân viên'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên (tên, email, SĐT)...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: [
              const Text('Lọc theo: ',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),

              // Role filter
              DropdownButton<UserRole?>(
                value: _selectedRoleFilter,
                hint: const Text('Chức vụ'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...UserRole.values.map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleDisplayName(role)),
                      )),
                ],
                onChanged: (value) =>
                    setState(() => _selectedRoleFilter = value),
              ),
              const SizedBox(width: 16),

              // Status filter
              DropdownButton<String>(
                value: _selectedStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(
                      value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Tạm nghỉ')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedStatusFilter = value!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<app_user.User> employees) {
    final activeMembers =
        employees.where((m) => m.isActive == true).length;
    final inactiveMembers =
        employees.where((m) => m.isActive != true).length;
    // Performance is not tracked in User model, so we skip it or use default
    const avgPerformance = 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng nhân viên',
            '${employees.length}',
            Icons.people,
            Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Đang hoạt động',
            '$activeMembers',
            Icons.check_circle,
            Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tạm nghỉ',
            '$inactiveMembers',
            Icons.pause_circle,
            Colors.orange.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hiệu suất TB',
            '${avgPerformance.toStringAsFixed(0)}%',
            Icons.trending_up,
            Colors.purple.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList(List<app_user.User> employees) {
    if (employees.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: employees.length,
              itemExtent: 80.0, // Fixed height for better performance
              cacheExtent: 1000, // Pre-cache items for smoother scrolling
              itemBuilder: (context, index) {
                final employee = employees[index];
                return _buildTeamMemberCard(
                    employee, index == employees.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Nhân viên',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Chức vụ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Ca làm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Hiệu suất',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Space for actions
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          // Employee info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      _getRoleColor(member.role).withValues(alpha: 0.1),
                  child: member.avatar != null
                      ? ClipOval(
                          child:
                              Image.network(member.avatar!, fit: BoxFit.cover))
                      : Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(member.role),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Role
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleDisplayName(member.role),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(member.role),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Shift
          Expanded(
            flex: 2,
            child: Text(
              member.shift,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // Performance
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPerformanceColor(member.performance)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${member.performance}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getPerformanceColor(member.performance),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16),
                    SizedBox(width: 8),
                    Text('Xem chi tiết'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: member.status == 'active' ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      member.status == 'active'
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(member.status == 'active' ? 'Tạm nghỉ' : 'Kích hoạt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleEmployeeAction(member, value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy nhân viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc thêm nhân viên mới',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddEmployeeModal,
            icon: const Icon(Icons.person_add),
            label: const Text('Thêm nhân viên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return 'CEO';
      case UserRole.manager:
        return 'Manager';
      case UserRole.shiftLeader:
        return 'Trưởng ca';
      case UserRole.staff:
        return 'Nhân viên';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return Colors.purple.shade600;
      case UserRole.manager:
        return Colors.blue.shade600;
      case UserRole.shiftLeader:
        return Colors.green.shade600;
      case UserRole.staff:
        return Colors.orange.shade600;
    }
  }

  Color _getPerformanceColor(int performance) {
    if (performance >= 90) return Colors.green.shade600;
    if (performance >= 80) return Colors.blue.shade600;
    if (performance >= 70) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  // Action handlers
  void _showAddEmployeeModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhân viên mới'),
        content: const Text('Chức năng thêm nhân viên sẽ được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/employees/create');
            },
            child: const Text('Đến trang tạo'),
          ),
        ],
      ),
    );
  }

  void _handleEmployeeAction(TeamMember member, String action) {
    switch (action) {
      case 'view':
        _showEmployeeDetails(member);
        break;
      case 'edit':
        _editEmployee(member);
        break;
      case 'activate':
      case 'deactivate':
        _toggleEmployeeStatus(member);
        break;
      case 'delete':
        _deleteEmployee(member);
        break;
    }
  }

  void _showEmployeeDetails(TeamMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              _getRoleColor(member.role).withValues(alpha: 0.1),
                          child: Text(
                            member.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(member.role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRoleDisplayName(member.role),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getRoleColor(member.role),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: member.status == 'active'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            member.status == 'active'
                                ? 'Đang hoạt động'
                                : 'Tạm nghỉ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: member.status == 'active'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('📧 Email', member.email),
                    _buildDetailRow('📱 Điện thoại', member.phone),
                    _buildDetailRow('⏰ Ca làm việc', member.shift),
                    _buildDetailRow('📅 Ngày gia nhập',
                        '${member.joinDate.day}/${member.joinDate.month}/${member.joinDate.year}'),
                    _buildDetailRow('📊 Hiệu suất', '${member.performance}%'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editEmployee(member);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleEmployeeStatus(member);
                            },
                            icon: Icon(member.status == 'active'
                                ? Icons.pause
                                : Icons.play_arrow),
                            label: Text(member.status == 'active'
                                ? 'Tạm nghỉ'
                                : 'Kích hoạt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: member.status == 'active'
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editEmployee(TeamMember member) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✏️ Chỉnh sửa thông tin ${member.name}'),
        backgroundColor: Colors.blue.shade600,
        action: SnackBarAction(
          label: 'Đi đến',
          textColor: Colors.white,
          onPressed: () => context.push('/employees/edit/${member.id}'),
        ),
      ),
    );
  }

  void _toggleEmployeeStatus(TeamMember member) {
    if (!context.mounted) return;

    final newStatus = member.status == 'active' ? 'inactive' : 'active';
    final statusText = newStatus == 'active' ? 'kích hoạt' : 'tạm nghỉ';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã $statusText tài khoản ${member.name}'),
        backgroundColor: newStatus == 'active'
            ? Colors.green.shade600
            : Colors.orange.shade600,
      ),
    );

    // Update member status in real implementation
    setState(() {
      final index = _mockTeamMembers.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _mockTeamMembers[index] = member.copyWith(status: newStatus);
      }
    });
  }

  void _deleteEmployee(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản "${member.name}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _mockTeamMembers.removeWhere((m) => m.id == member.id);
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ Đã xóa tài khoản ${member.name}'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

/// Team Member Model for Team Management
class TeamMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String shift;
  final String status; // active, inactive
  final String? avatar;
  final DateTime joinDate;
  final int performance; // 0-100

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.shift,
    required this.status,
    this.avatar,
    required this.joinDate,
    required this.performance,
  });

  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? shift,
    String? status,
    String? avatar,
    DateTime? joinDate,
    int? performance,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shift: shift ?? this.shift,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      joinDate: joinDate ?? this.joinDate,
      performance: performance ?? this.performance,
    );
  }
}
