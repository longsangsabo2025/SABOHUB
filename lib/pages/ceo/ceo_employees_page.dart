import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../models/user.dart';
import '../../models/company.dart';
import '../../models/business_type.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';
import 'company/create_employee_dialog.dart';
import 'edit_employee_dialog.dart';

/// CEO Employees Management Page — Compact unified view
/// Single stats row + search + filter chips + employee list
class CEOEmployeesPage extends ConsumerStatefulWidget {
  const CEOEmployeesPage({super.key});

  @override
  ConsumerState<CEOEmployeesPage> createState() => _CEOEmployeesPageState();
}

class _CEOEmployeesPageState extends ConsumerState<CEOEmployeesPage> {
  List<User> _employees = [];
  Map<String, String> _companyNames = {}; // company_id -> company_name
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;

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
    try {
      setState(() => _isLoading = true);

      final service = ref.read(employeeServiceProvider);
      // CEO sees ALL employees across all companies
      final employees = await service.getAllEmployees();
      
      // Load company names
      final companyIds = employees
          .where((e) => e.companyId != null)
          .map((e) => e.companyId!)
          .toSet()
          .toList();
      
      final companyNames = <String, String>{};
      if (companyIds.isNotEmpty) {
        final response = await Supabase.instance.client
            .from('companies')
            .select('id, name')
            .inFilter('id', companyIds);
        for (final row in response as List) {
          companyNames[row['id'] as String] = row['name'] as String;
        }
      }

      if (mounted) {
        setState(() {
          _employees = employees;
          _companyNames = companyNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCreateEmployee() {
    final user = ref.read(authProvider).user;
    if (user == null || user.companyId == null) return;

    showDialog(
      context: context,
      builder: (_) => CreateEmployeeDialog(
        company: Company(
          id: user.companyId!,
          name: user.companyName ?? 'SABO',
          type: user.businessType ?? BusinessType.billiards,
          address: '',
          tableCount: 0,
          monthlyRevenue: 0,
          employeeCount: _employees.length,
        ),
      ),
    ).then((created) {
      if (created == true) _loadEmployees();
    });
  }

  List<User> get _filteredEmployees {
    return _employees.where((e) {
      final name = e.name ?? '';
      final email = e.email ?? '';
      final matchesSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == null || e.role == _filterRole;
      return matchesSearch && matchesRole;
    }).toList()
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final total = _employees.length;
    final active = _employees.where((e) => e.isActive == true).length;
    final inactive = total - active;
    final filtered = _filteredEmployees;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // === Compact stats + search + filters ===
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    children: [
                      // Stats row — compact inline badges
                      Row(
                        children: [
                          _buildMiniStat(Icons.people, '$total', 'Tổng', Colors.blue),
                          const SizedBox(width: 6),
                          _buildMiniStat(Icons.check_circle_outline, '$active', 'HĐ', Colors.green),
                          const SizedBox(width: 6),
                          _buildMiniStat(Icons.block, '$inactive', 'Khóa', Colors.red),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _loadEmployees,
                            tooltip: 'Làm mới',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_add, size: 20, color: Colors.blue),
                            onPressed: _openCreateEmployee,
                            tooltip: 'Thêm nhân viên',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Search bar — compact
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm nhân viên...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.clear, size: 16),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filter chips — compact
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(null, 'Tất cả', Icons.people, Colors.blue),
                            _buildFilterChip(UserRole.manager, 'Quản lý', Icons.supervised_user_circle, Colors.green),
                            _buildFilterChip(UserRole.shiftLeader, 'Trưởng ca', Icons.groups, Colors.orange),
                            _buildFilterChip(UserRole.staff, 'Nhân viên', Icons.person, Colors.purple),
                            _buildFilterChip(UserRole.driver, 'Tài xế', Icons.local_shipping, Colors.teal),
                            _buildFilterChip(UserRole.warehouse, 'Kho', Icons.warehouse, Colors.brown),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // === Employee list ===
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                _employees.isEmpty ? 'Chưa có nhân viên' : 'Không tìm thấy',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmployees,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildEmployeeRow(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // --- Compact stat badge ---
  Widget _buildMiniStat(IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  // --- Filter chip ---
  Widget _buildFilterChip(UserRole? role, String label, IconData icon, Color color) {
    final selected = _filterRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey[700])),
          ],
        ),
        selected: selected,
        selectedColor: color,
        backgroundColor: Colors.grey[100],
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (_) => setState(() => _filterRole = role),
      ),
    );
  }

  // --- Compact employee row ---
  Widget _buildEmployeeRow(User employee) {
    final roleInfo = _getRoleInfo(employee.role);
    final isActive = employee.isActive ?? true;
    final name = employee.name ?? employee.email?.split('@').first ?? '?';
    final companyName = employee.companyId != null 
        ? _companyNames[employee.companyId!] 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showEditEmployeeDialog(employee),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar — small
              CircleAvatar(
                radius: 18,
                backgroundColor: (roleInfo['color'] as Color).withValues(alpha: 0.15),
                backgroundImage: employee.avatarUrl != null
                    ? NetworkImage(employee.avatarUrl!)
                    : null,
                child: employee.avatarUrl == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: roleInfo['color'] as Color,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Name + role + company
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Company name
                        if (companyName != null) ...[
                          Icon(Icons.business_outlined, size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              companyName,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                          Icon(Icons.phone_outlined, size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            employee.phone!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status chip
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Khóa',
                    style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.w500),
                  ),
                ),
              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (roleInfo['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  roleInfo['title'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: roleInfo['color'] as Color,
                  ),
                ),
              ),
              // Action menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onSelected: (v) => _handleAction(v, employee),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Sửa', style: TextStyle(fontSize: 13)),
                  ])),
                  const PopupMenuItem(value: 'reset_password', child: Row(children: [
                    Icon(Icons.lock_reset, size: 16, color: Colors.deepPurple), SizedBox(width: 8),
                    Text('Đặt lại mật khẩu', style: TextStyle(fontSize: 13)),
                  ])),
                  if (employee.role == UserRole.manager)
                    const PopupMenuItem(value: 'permissions', child: Row(children: [
                      Icon(Icons.security, size: 16, color: Colors.blue), SizedBox(width: 8),
                      Text('Phân quyền', style: TextStyle(fontSize: 13)),
                    ])),
                  PopupMenuItem(value: 'toggle', child: Row(children: [
                    Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 16, color: isActive ? Colors.orange : Colors.green),
                    const SizedBox(width: 8),
                    Text(isActive ? 'Khóa' : 'Mở khóa', style: const TextStyle(fontSize: 13)),
                  ])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(fontSize: 13, color: Colors.red)),
                  ])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return {'title': 'Admin', 'icon': Icons.admin_panel_settings, 'color': Colors.red};
      case UserRole.ceo:
        return {'title': 'CEO', 'icon': Icons.business_center, 'color': Colors.indigo};
      case UserRole.manager:
        return {'title': 'Quản lý', 'icon': Icons.supervised_user_circle, 'color': Colors.green};
      case UserRole.shiftLeader:
        return {'title': 'Trưởng ca', 'icon': Icons.groups, 'color': Colors.orange};
      case UserRole.staff:
        return {'title': 'Nhân viên', 'icon': Icons.person, 'color': Colors.purple};
      case UserRole.driver:
        return {'title': 'Tài xế', 'icon': Icons.local_shipping, 'color': Colors.teal};
      case UserRole.warehouse:
        return {'title': 'Kho', 'icon': Icons.warehouse, 'color': Colors.brown};
    }
  }

  void _handleAction(String action, User employee) {
    switch (action) {
      case 'edit':
        _showEditEmployeeDialog(employee);
        break;
      case 'reset_password':
        _showResetPasswordDialog(employee);
        break;
      case 'permissions':
        _showPermissionsDialog(employee);
        break;
      case 'toggle':
        _toggleStatus(employee);
        break;
      case 'delete':
        _deleteEmployee(employee);
        break;
    }
  }

  Future<void> _showEditEmployeeDialog(User employee) async {
    final user = ref.read(authProvider).user;
    final companyId = user?.companyId;
    if (companyId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditEmployeeDialog(
        employee: employee,
        companyId: companyId,
      ),
    );
    if (result == true) _loadEmployees();
  }

  Future<void> _toggleStatus(User employee) async {
    final newStatus = !(employee.isActive ?? true);
    final label = newStatus ? 'mở khóa' : 'khóa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Xác nhận $label'),
        content: Text('Bạn muốn $label tài khoản ${employee.name ?? ""}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: newStatus ? Colors.green : Colors.orange),
            child: Text(newStatus ? 'Mở khóa' : 'Khóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final service = ref.read(employeeServiceProvider);
      await service.toggleEmployeeStatus(employee.id, newStatus);
      await _loadEmployees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã $label ${employee.name ?? ""}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showResetPasswordDialog(User employee) async {
    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(employeeName: employee.name ?? ''),
    );

    if (confirmed == null || confirmed.isEmpty) return;

    try {
      final response = await Supabase.instance.client.rpc('change_employee_password', params: {
        'p_employee_id': employee.id,
        'p_new_password': confirmed,
      });

      final data = response as Map<String, dynamic>;
      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã đặt lại mật khẩu cho ${employee.name ?? ""}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Copy mật khẩu',
                textColor: Colors.white,
                onPressed: () => Clipboard.setData(ClipboardData(text: confirmed)),
              ),
            ),
          );
        }
      } else {
        throw Exception(data['error'] ?? 'Không thể đổi mật khẩu');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showPermissionsDialog(User employee) async {
    if (employee.role != UserRole.manager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ quản lý mới có phân quyền'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final companyId = user?.companyId;
    if (companyId == null) return;

    // Load all companies for multi-select
    List<Company> companies = [];
    try {
      final response = await Supabase.instance.client
          .from('companies')
          .select()
          .eq('is_active', true)
          .order('name');
      companies = (response as List).map((e) => Company.fromJson(e)).toList();
    } catch (_) {}

    // Load currently assigned companies from manager_companies table
    Set<String> selectedCompanyIds = {};
    String? primaryCompanyId;
    try {
      final response = await Supabase.instance.client
          .from('manager_companies')
          .select()
          .eq('manager_id', employee.id);
      for (final row in response as List) {
        selectedCompanyIds.add(row['company_id'] as String);
        if (row['is_primary'] == true) {
          primaryCompanyId = row['company_id'] as String;
        }
      }
    } catch (_) {}

    // Load current permissions
    Map<String, dynamic>? currentPerms;
    try {
      final response = await Supabase.instance.client
          .from('manager_permissions')
          .select()
          .eq('manager_id', employee.id)
          .eq('company_id', companyId)
          .maybeSingle();
      currentPerms = response;
    } catch (_) {}

    // Permission definitions
    final permGroups = [
      {
        'group': 'Xem trang',
        'icon': Icons.visibility,
        'perms': [
          {'key': 'can_view_overview', 'label': 'Tổng quan', 'default': true},
          {'key': 'can_view_employees', 'label': 'Nhân viên', 'default': true},
          {'key': 'can_view_tasks', 'label': 'Công việc', 'default': true},
          {'key': 'can_view_attendance', 'label': 'Chấm công', 'default': true},
          {'key': 'can_view_documents', 'label': 'Tài liệu', 'default': false},
          {'key': 'can_view_accounting', 'label': 'Kế toán', 'default': false},
          {'key': 'can_view_settings', 'label': 'Cài đặt', 'default': false},
        ],
      },
      {
        'group': 'Hành động',
        'icon': Icons.build,
        'perms': [
          {'key': 'can_create_employee', 'label': 'Tạo nhân viên', 'default': false},
          {'key': 'can_edit_employee', 'label': 'Sửa nhân viên', 'default': false},
          {'key': 'can_delete_employee', 'label': 'Xóa nhân viên', 'default': false},
          {'key': 'can_create_task', 'label': 'Tạo công việc', 'default': true},
          {'key': 'can_edit_task', 'label': 'Sửa công việc', 'default': true},
          {'key': 'can_delete_task', 'label': 'Xóa công việc', 'default': false},
          {'key': 'can_approve_attendance', 'label': 'Duyệt chấm công', 'default': true},
          {'key': 'can_edit_company_info', 'label': 'Sửa thông tin CT', 'default': false},
          {'key': 'can_manage_bank_account', 'label': 'Quản lý ngân hàng', 'default': false},
        ],
      },
    ];

    // Initialize with current or defaults
    final editedPerms = <String, bool>{};
    for (final group in permGroups) {
      for (final perm in group['perms'] as List) {
        final key = perm['key'] as String;
        editedPerms[key] = currentPerms?[key] as bool? ?? perm['default'] as bool;
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.security, color: Colors.blue, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('Phân quyền - ${employee.name ?? ""}', style: const TextStyle(fontSize: 16))),
          ]),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Company Assignment Section (Multi-Select) ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.business, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text('Công ty quản lý (${selectedCompanyIds.length})', 
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Chọn một hoặc nhiều công ty', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: companies.length,
                            itemBuilder: (_, i) {
                              final c = companies[i];
                              final isSelected = selectedCompanyIds.contains(c.id);
                              final isPrimary = primaryCompanyId == c.id;
                              return CheckboxListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                title: Row(
                                  children: [
                                    Icon(c.type.icon, size: 16, color: c.type.color),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(c.name, style: const TextStyle(fontSize: 12))),
                                    if (isPrimary) 
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Chính', style: TextStyle(fontSize: 9, color: Colors.orange)),
                                      ),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: (v) {
                                  setDialogState(() {
                                    if (v == true) {
                                      selectedCompanyIds.add(c.id);
                                      // Auto-set primary if first selection
                                      if (selectedCompanyIds.length == 1) {
                                        primaryCompanyId = c.id;
                                      }
                                    } else {
                                      selectedCompanyIds.remove(c.id);
                                      // Clear primary if removed
                                      if (primaryCompanyId == c.id) {
                                        primaryCompanyId = selectedCompanyIds.isNotEmpty 
                                            ? selectedCompanyIds.first 
                                            : null;
                                      }
                                    }
                                  });
                                },
                                activeColor: Colors.blue,
                              );
                            },
                          ),
                        ),
                        if (selectedCompanyIds.length > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Công ty chính: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: primaryCompanyId,
                                  isExpanded: true,
                                  isDense: true,
                                  underline: Container(height: 1, color: Colors.blue.shade200),
                                  items: selectedCompanyIds.map((id) {
                                    final c = companies.firstWhere((x) => x.id == id, orElse: () => companies.first);
                                    return DropdownMenuItem(value: id, child: Text(c.name, style: const TextStyle(fontSize: 11)));
                                  }).toList(),
                                  onChanged: (v) => setDialogState(() => primaryCompanyId = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ── Permission Groups ──
                  ...permGroups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Row(children: [
                            Icon(group['icon'] as IconData, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(group['group'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                          ]),
                        ),
                        ...(group['perms'] as List).map((perm) {
                          final key = perm['key'] as String;
                          return SwitchListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.only(left: 8),
                            title: Text(perm['label'] as String, style: const TextStyle(fontSize: 13)),
                            value: editedPerms[key] ?? false,
                            onChanged: (v) => setDialogState(() => editedPerms[key] = v),
                            activeColor: Colors.blue,
                          );
                        }),
                        const Divider(height: 1),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Lưu quyền', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final sb = Supabase.instance.client;
      
      // 1. Update manager_companies table (delete all then re-insert)
      await sb.from('manager_companies').delete().eq('manager_id', employee.id);
      
      if (selectedCompanyIds.isNotEmpty) {
        final insertRows = selectedCompanyIds.map((cid) => {
          'manager_id': employee.id,
          'company_id': cid,
          'is_primary': cid == primaryCompanyId,
          'granted_by': user?.id,
        }).toList();
        await sb.from('manager_companies').insert(insertRows);
        
        // Also update employees.company_id to primary company (for backward compatibility)
        await sb.from('employees').update({
          'company_id': primaryCompanyId ?? selectedCompanyIds.first,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', employee.id);
      }
      
      // 2. Update permissions
      final updates = Map<String, dynamic>.from(editedPerms);
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (currentPerms != null) {
        // Update existing
        await sb.from('manager_permissions').update(updates).eq('id', currentPerms['id']);
      } else {
        // Create new
        updates['manager_id'] = employee.id;
        updates['company_id'] = companyId;
        updates['granted_by'] = user?.id;
        await sb.from('manager_permissions').insert(updates);
      }

      // Reload employees to reflect changes
      await _loadEmployees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đã cập nhật quyền cho ${employee.name ?? ""} (${selectedCompanyIds.length} công ty)'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteEmployee(User employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa tài khoản ${employee.name ?? ""}? Không thể hoàn tác!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final service = ref.read(employeeServiceProvider);
      await service.deleteEmployee(employee.id);
      await _loadEmployees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa ${employee.name ?? ""}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Extracted Dialog — proper StatefulWidget lifecycle
// Fixes _dependents.isEmpty assertion from StatefulBuilder + Form
// ═══════════════════════════════════════════════════════════════
class _ResetPasswordDialog extends StatefulWidget {
  final String employeeName;
  const _ResetPasswordDialog({required this.employeeName});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.lock_reset, color: Colors.deepPurple, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Đặt lại mật khẩu - ${widget.employeeName}',
              style: const TextStyle(fontSize: 16)),
        ),
      ]),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập mật khẩu mới cho nhân viên:',
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 4) {
                  return 'Mật khẩu tối thiểu 4 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text('⚠️ Nhân viên sẽ sử dụng mật khẩu mới này để đăng nhập',
                style: TextStyle(fontSize: 11, color: Colors.orange[800])),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child:
              const Text('Đặt lại', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
