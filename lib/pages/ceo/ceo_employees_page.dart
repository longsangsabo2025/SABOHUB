import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../models/company.dart';
import '../../models/business_type.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';
import '../employees/employee_list_page.dart';
import 'company/create_employee_dialog.dart';

/// CEO Employees Management Page
/// Real stats from DB + functional add/search/filter
class CEOEmployeesPage extends ConsumerStatefulWidget {
  const CEOEmployeesPage({super.key});

  @override
  ConsumerState<CEOEmployeesPage> createState() => _CEOEmployeesPageState();
}

class _CEOEmployeesPageState extends ConsumerState<CEOEmployeesPage> {
  List<User> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final user = ref.read(authProvider).user;
      final companyId = user?.companyId;
      if (companyId == null) return;

      final service = ref.read(employeeServiceProvider);
      final employees = await service.getCompanyEmployees(companyId);

      if (mounted) {
        setState(() {
          _employees = employees;
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

  @override
  Widget build(BuildContext context) {
    final managers = _employees.where((e) =>
        e.role == UserRole.manager).length;
    final shiftLeaders = _employees.where((e) =>
        e.role == UserRole.shiftLeader).length;
    final staff = _employees.where((e) =>
        e.role == UserRole.staff ||
        e.role == UserRole.driver ||
        e.role == UserRole.warehouse).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Real stats card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.people, '${_employees.length}',
                        'Tổng NV', Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.supervised_user_circle, '$managers',
                        'Quản lý', Colors.green,
                      ),
                      _buildStatItem(
                        Icons.groups, '$shiftLeaders',
                        'Trưởng ca', Colors.orange,
                      ),
                      _buildStatItem(
                        Icons.person, '$staff',
                        'Nhân viên', Colors.purple,
                      ),
                    ],
                  ),
          ),
          // Employee List (has its own search, filter, stats)
          const Expanded(child: EmployeeListPage()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEmployee,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon, String count, String label, Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
