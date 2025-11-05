import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../employees/employee_list_page.dart';

/// CEO Employees Management Page
/// Quản lý nhân viên toàn công ty từ góc nhìn CEO
class CEOEmployeesPage extends ConsumerStatefulWidget {
  const CEOEmployeesPage({super.key});

  @override
  ConsumerState<CEOEmployeesPage> createState() => _CEOEmployeesPageState();
}

class _CEOEmployeesPageState extends ConsumerState<CEOEmployeesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Quản lý nhân viên',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              actions: [
                // Search button
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {
                    // TODO: Implement search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔍 Tìm kiếm nhân viên'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                // Filter button
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87),
                  onPressed: () {
                    // TODO: Implement filter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📊 Lọc nhân viên'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                // Add employee button
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  onPressed: () {
                    // TODO: Navigate to create employee
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('➕ Thêm nhân viên mới'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[700],
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.people),
                    text: 'Tất cả',
                  ),
                  Tab(
                    icon: Icon(Icons.check_circle),
                    text: 'Hoạt động',
                  ),
                  Tab(
                    icon: Icon(Icons.block),
                    text: 'Tạm khóa',
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: All employees
            _buildEmployeeContent('all'),
            // Tab 2: Active employees
            _buildEmployeeContent('active'),
            // Tab 3: Inactive employees
            _buildEmployeeContent('inactive'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create employee dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('➕ Tạo tài khoản nhân viên mới'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildEmployeeContent(String filter) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Stats Card
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  '156',
                  'Tổng NV',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.supervised_user_circle,
                  '12',
                  'Quản lý',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.groups,
                  '24',
                  'Trưởng ca',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.person,
                  '120',
                  'Nhân viên',
                  Colors.purple,
                ),
              ],
            ),
          ),
          // Employee List
          Expanded(
            child: const EmployeeListPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String count,
    String label,
    Color color,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
