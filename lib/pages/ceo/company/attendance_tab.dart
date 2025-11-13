import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/attendance.dart';
import '../../../models/attendance_stats.dart';
import '../../../models/company.dart';
import '../../../providers/cached_data_providers.dart';

/// Attendance Tab for Company Details
/// Displays attendance management interface for CEO/Manager
class AttendanceTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const AttendanceTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  AttendanceStatus? _filterStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final params = AttendanceQueryParams(
      companyId: widget.companyId,
      date: _selectedDate,
    );
    final statsAsync = ref.watch(cachedAttendanceStatsProvider(params));
    final attendanceAsync = ref.watch(cachedCompanyAttendanceProvider(params));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý chấm công',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Theo dõi và quản lý chấm công nhân viên',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAttendanceReport(context),
                icon: const Icon(Icons.analytics),
                label: const Text('Báo cáo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Lỗi tải thống kê'),
            data: (stats) => _buildStatsCards(stats),
          ),

          const SizedBox(height: 32),

          // Date Picker & Filters
          _buildFilters(),

          const SizedBox(height: 24),

          // Attendance List
          attendanceAsync.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải dữ liệu chấm công...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().contains('TimeoutException')
                        ? 'Mất kết nối với máy chủ. Vui lòng thử lại.'
                        : 'Không thể tải dữ liệu chấm công. Vui lòng thử lại.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(cachedCompanyAttendanceProvider(params));
                        ref.invalidate(cachedAttendanceStatsProvider(params));
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
            data: (records) => _buildAttendanceList(records),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AttendanceStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng số',
            '${stats.totalEmployees}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Có mặt',
            '${stats.presentCount}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Đi muộn',
            '${stats.lateCount}',
            Icons.access_time,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Vắng',
            '${stats.absentCount}',
            Icons.cancel,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Tỷ lệ',
            '${stats.attendanceRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Date Picker
          SizedBox(
            width: 200,
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Filter
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<AttendanceStatus?>(
              initialValue: _filterStatus,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ...AttendanceStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: status.color, size: 12),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              status.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              onChanged: (value) => setState(() => _filterStatus = value),
            ),
          ),

          // Search
          SizedBox(
            width: 250,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<EmployeeAttendanceRecord> records) {
    // Apply filters
    var filteredRecords = records;

    if (_filterStatus != null) {
      filteredRecords = filteredRecords
          .where((record) => record.status == _filterStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredRecords = filteredRecords
          .where((record) => record.employeeName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bản ghi chấm công',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Nhân viên',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Giờ vào',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Giờ ra',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Giờ làm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),

        // Table Body
        ...filteredRecords.map((record) => _buildAttendanceRow(record)),
      ],
    );
  }

  Widget _buildAttendanceRow(EmployeeAttendanceRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Employee Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    record.employeeName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      if (record.lateMinutes > 0)
                        Text(
                          'Muộn ${record.lateMinutes} phút',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Check In
          Expanded(
            flex: 2,
            child: Text(
              record.checkIn != null
                  ? DateFormat('HH:mm').format(record.checkIn!)
                  : '--:--',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Check Out
          Expanded(
            flex: 2,
            child: Text(
              record.checkOut != null
                  ? DateFormat('HH:mm').format(record.checkOut!)
                  : '-',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Hours Worked
          Expanded(
            flex: 2,
            child: Text(
              record.hoursWorked > 0
                  ? '${record.hoursWorked.toStringAsFixed(1)}h'
                  : '-',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: record.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: record.status.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                record.status.label,
                style: TextStyle(
                  color: record.status.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 60,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleAction(value, record),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Xem chi tiết'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20),
                      SizedBox(width: 8),
                      Text('Lịch sử'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      // Refresh data - will trigger rebuild with new date
    }
  }

  void _handleAction(String action, EmployeeAttendanceRecord record) {
    switch (action) {
      case 'view':
        _showAttendanceDetail(record);
        break;
      case 'edit':
        _showEditDialog(record);
        break;
      case 'history':
        _showAttendanceHistory(record);
        break;
    }
  }

  void _showAttendanceDetail(EmployeeAttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết chấm công - ${record.employeeName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Ngày', DateFormat('dd/MM/yyyy').format(record.date)),
              _buildDetailRow('Giờ vào',
                  record.checkIn != null
                      ? DateFormat('HH:mm:ss').format(record.checkIn!)
                      : '--:--:--'),
              _buildDetailRow(
                  'Giờ ra',
                  record.checkOut != null
                      ? DateFormat('HH:mm:ss').format(record.checkOut!)
                      : 'Chưa ra ca'),
              _buildDetailRow('Tổng giờ làm',
                  '${record.hoursWorked.toStringAsFixed(2)} giờ'),
              _buildDetailRow('Trạng thái', record.status.label),
              if (record.lateMinutes > 0)
                _buildDetailRow('Đi muộn', '${record.lateMinutes} phút'),
              if (record.notes != null)
                _buildDetailRow('Ghi chú', record.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(EmployeeAttendanceRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chỉnh sửa đang phát triển')),
    );
  }

  void _showAttendanceHistory(EmployeeAttendanceRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Xem lịch sử chấm công của ${record.employeeName}')),
    );
  }

  void _showAttendanceReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng báo cáo đang phát triển')),
    );
  }
}
