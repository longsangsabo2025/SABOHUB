import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';

/// Employee List Page
/// Danh sách nhân viên với khả năng tìm kiếm và quản lý
class EmployeeListPage extends ConsumerStatefulWidget {
  const EmployeeListPage({super.key});

  @override
  ConsumerState<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends ConsumerState<EmployeeListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;
  String _sortBy = 'name'; // name, role, created_date

  // Mock data for demonstration
  final List<EmployeeModel> _employees = [
    EmployeeModel(
      id: '1',
      name: 'Nguyễn Văn Nam',
      email: 'nam@sabohub.com',
      phone: '0123456789',
      role: UserRole.manager,
      avatar: null,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    EmployeeModel(
      id: '2',
      name: 'Trần Thị Lan',
      email: 'lan@sabohub.com',
      phone: '0987654321',
      role: UserRole.shiftLeader,
      avatar: null,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    EmployeeModel(
      id: '3',
      name: 'Lê Hoàng Minh',
      email: 'minh@sabohub.com',
      phone: '0567891234',
      role: UserRole.staff,
      avatar: null,
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    EmployeeModel(
      id: '4',
      name: 'Phạm Thị Hoa',
      email: 'hoa@sabohub.com',
      phone: '0345678912',
      role: UserRole.staff,
      avatar: null,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EmployeeModel> get _filteredEmployees {
    var employees = _employees.where((employee) {
      final matchesSearch =
          employee.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              employee.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == null || employee.role == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();

    // Sort employees
    employees.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'role':
          return a.role.index.compareTo(b.role.index);
        case 'created_date':
          return b.createdAt.compareTo(a.createdAt);
        default:
          return 0;
      }
    });

    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Danh sách nhân viên',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black87),
            onPressed: () => _navigateToCreateEmployee(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildStatsCards(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          // Filter and sort row
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Chức vụ',
                  value: _filterRole?.name ?? 'Tất cả',
                  onTap: () => _showRoleFilterDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Sắp xếp',
                  value: _getSortLabel(_sortBy),
                  onTap: () => _showSortDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalEmployees = _employees.length;
    final activeEmployees = _employees.where((e) => e.isActive).length;
    final inactiveEmployees = totalEmployees - activeEmployees;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Tổng số',
              value: totalEmployees.toString(),
              color: Colors.blue,
              icon: Icons.people,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Hoạt động',
              value: activeEmployees.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Tạm khóa',
              value: inactiveEmployees.toString(),
              color: Colors.red,
              icon: Icons.block,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    final employees = _filteredEmployees;

    if (employees.isEmpty) {
      return Center(
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
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(employees[index]);
      },
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  _getRoleColor(employee.role).withValues(alpha: 0.1),
              child: employee.avatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        employee.avatar!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      employee.name
                          .split(' ')
                          .map((word) => word[0])
                          .take(2)
                          .join(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(employee.role),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Employee info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _buildStatusChip(employee.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          employee.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      _buildRoleChip(employee.role),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) => _handleEmployeeAction(value, employee),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: employee.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        employee.isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                        color: employee.isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(employee.isActive ? 'Tạm khóa' : 'Kích hoạt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
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

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Tạm khóa',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    final roleInfo = _getRoleInfo(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleInfo['icon'],
            size: 12,
            color: roleInfo['color'],
          ),
          const SizedBox(width: 4),
          Text(
            roleInfo['title'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: roleInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return {
          'title': 'CEO',
          'icon': Icons.business_center,
          'color': Colors.purple,
        };
      case UserRole.manager:
        return {
          'title': 'Quản lý',
          'icon': Icons.supervisor_account,
          'color': Colors.orange,
        };
      case UserRole.shiftLeader:
        return {
          'title': 'Trưởng ca',
          'icon': Icons.people_outline,
          'color': Colors.green,
        };
      case UserRole.staff:
        return {
          'title': 'Nhân viên',
          'icon': Icons.person,
          'color': Colors.blue,
        };
    }
  }

  Color _getRoleColor(UserRole role) {
    return _getRoleInfo(role)['color'];
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'name':
        return 'Tên';
      case 'role':
        return 'Chức vụ';
      case 'created_date':
        return 'Ngày tạo';
      default:
        return 'Tên';
    }
  }

  void _showRoleFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo chức vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleFilterOption(null, 'Tất cả'),
            ...UserRole.values.map((role) =>
                _buildRoleFilterOption(role, _getRoleInfo(role)['title'])),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterOption(UserRole? role, String title) {
    final isSelected = _filterRole == role;
    return ListTile(
      title: Text(title),
      leading: Radio<UserRole?>(
        value: role,
        groupValue: _filterRole,
        onChanged: null,
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _filterRole = role;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp xếp theo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('name', 'Tên'),
            _buildSortOption('role', 'Chức vụ'),
            _buildSortOption('created_date', 'Ngày tạo'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String title) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(title),
      leading: Radio<String>(
        value: value,
        groupValue: _sortBy,
        onChanged: null,
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _handleEmployeeAction(String action, EmployeeModel employee) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit employee page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉnh sửa thông tin ${employee.name}'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleEmployeeStatus(employee);
        break;
      case 'delete':
        _showDeleteConfirmDialog(employee);
        break;
    }
  }

  void _toggleEmployeeStatus(EmployeeModel employee) {
    setState(() {
      final index = _employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _employees[index] = employee.copyWith(isActive: !employee.isActive);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${employee.isActive ? 'Kích hoạt' : 'Tạm khóa'} tài khoản ${employee.name} thành công',
        ),
        backgroundColor: employee.isActive ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showDeleteConfirmDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _deleteEmployee(employee);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(EmployeeModel employee) {
    setState(() {
      _employees.removeWhere((e) => e.id == employee.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa tài khoản ${employee.name}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToCreateEmployee() {
    // TODO: Navigate to create employee page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chuyển đến trang tạo nhân viên'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Employee Model for demonstration
class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    required this.isActive,
    required this.createdAt,
  });

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatar,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
