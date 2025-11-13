import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../models/user.dart';
import '../../providers/auth_provider.dart';

/// Shift Leader Team Page - Show team members in same branch
class ShiftLeaderTeamPage extends ConsumerStatefulWidget {
  const ShiftLeaderTeamPage({super.key});

  @override
  ConsumerState<ShiftLeaderTeamPage> createState() =>
      _ShiftLeaderTeamPageState();
}

class _ShiftLeaderTeamPageState extends ConsumerState<ShiftLeaderTeamPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;
  bool _isLoading = true;
  List<User> _employees = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null || currentUser.companyId == null) {
        throw Exception('User not authenticated or no company assigned');
      }

      // Get team members from same company and branch (from employees table, not users)
      final response = await Supabase.instance.client
          .from('employees')
          .select('''
            id,
            full_name,
            email,
            phone,
            role,
            company_id,
            branch_id,
            is_active,
            created_at,
            updated_at
          ''')
          .eq('company_id', currentUser.companyId!)
          .eq('branch_id', currentUser.branchId ?? '') // Filter by same branch
          .eq('is_active', true) // Only active employees
          .inFilter('role', ['STAFF', 'SHIFT_LEADER']) // Only staff and shift leaders
          .isFilter('deleted_at', null) // Only active employees
          .order('full_name', ascending: true);

      final employees = (response as List).map((json) {
        return User(
          id: json['id'] as String,
          name: json['full_name'] as String? ?? 'Unknown',
          email: json['email'] as String,
          phone: json['phone'] as String?,
          role: _parseRole(json['role'] as String?),
          companyId: json['company_id'] as String?,
          branchId: json['branch_id'] as String?,
          isActive: json['is_active'] as bool? ?? true,
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load employees: $e';
        _isLoading = false;
      });
    }
  }

  UserRole _parseRole(String? roleString) {
    if (roleString == null) return UserRole.staff;
    switch (roleString.toLowerCase()) {
      case 'ceo':
        return UserRole.ceo;
      case 'manager':
      case 'branch_manager':
        return UserRole.manager;
      case 'shift_leader':
        return UserRole.shiftLeader;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }

  List<User> get _filteredEmployees {
    var filtered = _employees;

    // Filter by role
    if (_filterRole != null) {
      filtered = filtered.where((e) => e.role == _filterRole).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((e) =>
              (e.name?.toLowerCase().contains(query) ?? false) ||
              (e.email?.toLowerCase().contains(query) ?? false) ||
              (e.phone?.contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEmployees = _filteredEmployees;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Đội nhóm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm nhân viên...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Role filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _filterRole == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterRole = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...UserRole.values.map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(role.displayName),
                            selected: _filterRole == role,
                            onSelected: (selected) {
                              setState(() {
                                _filterRole = selected ? role : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Employee count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Text(
              '${filteredEmployees.length} nhân viên',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Employee list
          Expanded(
            child: _buildContent(filteredEmployees, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<User> employees, ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterRole != null
                  ? 'Không tìm thấy nhân viên'
                  : 'Chưa có nhân viên nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return _EmployeeCard(
            employee: employee,
            onTap: () => _showEmployeeDetails(employee),
          );
        },
      ),
    );
  }

  void _showEmployeeDetails(User employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _EmployeeDetailsSheet(
            employee: employee,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Employee Card Widget
class _EmployeeCard extends StatelessWidget {
  final User employee;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getRoleColor(employee.role).withOpacity(0.1),
                child: Text(
                  (employee.name?.isNotEmpty ?? false) ? employee.name![0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(employee.role),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name ?? 'Chưa có tên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (employee.isActive ?? true)
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (employee.isActive ?? true) ? 'Hoạt động' : 'Tạm khóa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (employee.isActive ?? true)
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RoleBadge(role: employee.role),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            employee.email ?? 'Chưa có email',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (employee.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            employee.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.shiftLeader:
        return Colors.orange;
      case UserRole.staff:
        return Colors.green;
    }
  }
}

/// Role Badge Widget
class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getColor(),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (role) {
      case UserRole.ceo:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.shiftLeader:
        return Colors.orange;
      case UserRole.staff:
        return Colors.green;
    }
  }
}

/// Employee Details Bottom Sheet
class _EmployeeDetailsSheet extends StatelessWidget {
  final User employee;
  final ScrollController scrollController;

  const _EmployeeDetailsSheet({
    required this.employee,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar and name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: _getRoleColor().withOpacity(0.1),
                  child: Text(
                    (employee.name?.isNotEmpty ?? false) 
                        ? employee.name![0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  employee.name ?? 'Chưa có tên',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _RoleBadge(role: employee.role),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Information sections
          _buildInfoSection(
            'Thông tin liên hệ',
            [
              _buildInfoRow(Icons.email, 'Email', employee.email ?? 'Chưa có email'),
              if (employee.phone != null)
                _buildInfoRow(Icons.phone, 'Số điện thoại', employee.phone!),
            ],
          ),

          const SizedBox(height: 24),

          _buildInfoSection(
            'Trạng thái',
            [
              _buildInfoRow(
                Icons.check_circle,
                'Tài khoản',
                (employee.isActive ?? true) ? 'Đang hoạt động' : 'Tạm khóa',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày tạo',
                _formatDate(employee.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              if (employee.phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call phone
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi điện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (employee.phone != null) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Send email
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (employee.role) {
      case UserRole.ceo:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.shiftLeader:
        return Colors.orange;
      case UserRole.staff:
        return Colors.green;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
