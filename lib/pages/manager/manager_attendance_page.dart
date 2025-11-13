import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:geolocator/geolocator.dart';

import '../../services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../providers/auth_provider.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// 
/// **NHÂN VIÊN KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// 
/// Quy tắc:
/// 1. CHỈ CÓ CEO được phép đăng ký và đăng nhập qua Supabase Auth
/// 2. TẤT CẢ NHÂN VIÊN (bao gồm Manager, Staff) được CEO tạo trong bảng `employees`
/// 3. Nhân viên login bằng MÃ NHÂN VIÊN, KHÔNG dùng email/password Supabase Auth
/// 4. Nhân viên KHÔNG CÓ user_id trong auth.users
/// 5. Nhân viên chỉ có employee_id trong bảng employees
/// 
/// DO ĐÓ:
/// - ❌ KHÔNG ĐƯỢC dùng `Supabase.instance.client.auth.currentUser`
/// - ❌ KHÔNG ĐƯỢC query bảng auth.users cho nhân viên
/// - ✅ PHẢI dùng `ref.read(authProvider).user` để lấy thông tin employee
/// - ✅ Employee có: id, name, role, company_id, branch_id trong bảng employees
/// - ✅ Attendance service nhận employee.id làm userId (KHÔNG phải auth user id)
///
/// Manager Attendance Page
/// Allows manager to check in/out and view attendance history
class ManagerAttendancePage extends ConsumerStatefulWidget {
  const ManagerAttendancePage({super.key});

  @override
  ConsumerState<ManagerAttendancePage> createState() =>
      _ManagerAttendancePageState();
}

class _ManagerAttendancePageState extends ConsumerState<ManagerAttendancePage> {
  final _attendanceService = AttendanceService();
  bool _isLoading = false;
  AttendanceRecord? _todayAttendance;
  List<AttendanceRecord> _recentAttendance = [];
  String? _branchId; // Changed from _storeId
  String? _companyId;
  String? _userId; // Store user ID from authProvider

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // FIXED: Get user from authProvider (employee login system)
      final currentUser = ref.read(authProvider).user;
      
      if (currentUser == null) {
        print('🔴 [ManagerAttendance] No user logged in from authProvider');
        return;
      }

      _userId = currentUser.id;
      print('🔍 [ManagerAttendance] Loading data for employee: ${currentUser.id}');
      print('� [ManagerAttendance] Employee name: ${currentUser.name}');
      print('🔍 [ManagerAttendance] Employee role: ${currentUser.role}');
      print('� [ManagerAttendance] Employee company: ${currentUser.companyId}');
      print('� [ManagerAttendance] Employee branch: ${currentUser.branchId}');

      // Get company_id and branch_id directly from user object
      _companyId = currentUser.companyId;
      _branchId = currentUser.branchId;

      print('� [ManagerAttendance] Direct from user: company=$_companyId, branch=$_branchId');

      // Load recent attendance using service
      if (_branchId != null && _companyId != null && _userId != null) {
        print('⏳ [ManagerAttendance] Loading attendance history...');
        _recentAttendance = await _attendanceService.getUserAttendance(
          userId: _userId!,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
        );
        print('✅ [ManagerAttendance] Loaded ${_recentAttendance.length} attendance records');

        // Find today's attendance
        final today = DateTime.now();
        _todayAttendance = _recentAttendance.where((record) {
          return record.checkInTime != null &&
              record.checkInTime!.year == today.year &&
              record.checkInTime!.month == today.month &&
              record.checkInTime!.day == today.day;
        }).firstOrNull;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkIn() async {
    print('🎯 [ManagerAttendance] _checkIn called');
    print('📊 [ManagerAttendance] Current state: user=$_userId, company=$_companyId, branch=$_branchId');
    
    if (_branchId == null || _companyId == null || _userId == null) {
      print('🔴 [ManagerAttendance] Missing data - user=$_userId, branch=$_branchId, company=$_companyId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin chi nhánh')),
      );
      return;
    }

    print('✅ [ManagerAttendance] Data validated, proceeding with check-in');

    try {
      setState(() => _isLoading = true);

      print('🌍 [ManagerAttendance] Getting GPS location...');
      
      // Get GPS location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('✅ [ManagerAttendance] GPS: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        // GPS not available, continue without it
        print('⚠️ [ManagerAttendance] GPS error: $e');
      }

      print('⏳ [ManagerAttendance] Calling attendance service...');
      
      await _attendanceService.checkIn(
        userId: _userId!,
        branchId: _branchId!,
        companyId: _companyId!,
        latitude: position?.latitude,
        longitude: position?.longitude,
        location: 'Office', // TODO: Get actual location name
      );

      print('✅ [ManagerAttendance] Check-in successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chấm công vào thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chấm công: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkOut() async {
    if (_todayAttendance == null) return;

    try {
      setState(() => _isLoading = true);

      await _attendanceService.checkOut(
        attendanceId: _todayAttendance!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chấm công ra thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chấm công: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildTodayCard()),
                    SliverToBoxAdapter(child: _buildActionButtons()),
                    _buildRecentAttendanceSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[700],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Chấm công',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now);
    final formattedTime = DateFormat('HH:mm:ss').format(now);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.access_time, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          if (_todayAttendance != null) _buildTodayStatus(),
        ],
      ),
    );
  }

  Widget _buildTodayStatus() {
    final checkIn = _todayAttendance!.checkInTime;
    final checkOut = _todayAttendance!.checkOutTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Vào',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                checkIn != null
                    ? DateFormat('HH:mm').format(checkIn)
                    : '--:--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              const Text(
                'Ra',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                checkOut != null
                    ? DateFormat('HH:mm').format(checkOut)
                    : '--:--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (checkOut != null && checkIn != null)
            Column(
              children: [
                const Text(
                  'Tổng',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(checkOut.difference(checkIn)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasCheckedIn = _todayAttendance != null;
    final hasCheckedOut = hasCheckedIn && _todayAttendance!.checkOutTime != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasCheckedIn || _isLoading ? null : _checkIn,
              icon: const Icon(Icons.login),
              label: const Text('Chấm công vào'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: !hasCheckedIn || hasCheckedOut || _isLoading
                  ? null
                  : _checkOut,
              icon: const Icon(Icons.logout),
              label: const Text('Chấm công ra'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceSection() {
    if (_recentAttendance.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử chấm công',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Lịch sử gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              );
            }

            final attendance = _recentAttendance[index - 1];
            return _buildAttendanceCard(attendance);
          },
          childCount: _recentAttendance.length + 1,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord attendance) {
    final checkIn = attendance.checkInTime;
    final checkOut = attendance.checkOutTime;
    final duration = checkOut != null && checkIn != null
        ? checkOut.difference(checkIn)
        : Duration.zero;

    if (checkIn == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today,
                      size: 20, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(checkIn),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendance.status.label,
                        style: TextStyle(
                          color: attendance.status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (checkOut != null)
                  Chip(
                    label: Text(
                      _formatDuration(duration),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(color: Colors.green[700]),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Vào',
                    DateFormat('HH:mm').format(checkIn),
                    Icons.login,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInfo(
                    'Ra',
                    checkOut != null
                        ? DateFormat('HH:mm').format(checkOut)
                        : '--:--',
                    Icons.logout,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
