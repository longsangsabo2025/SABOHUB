import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/bug_report_dialog.dart';

/// Driver Profile Page - Trang cá nhân tài xế
class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar với khả năng thay đổi
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                              image: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Center(
                                    child: Text(
                                      (user?.name ?? 'T')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(Icons.camera_alt, size: 16, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Tài xế',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Tài xế giao hàng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.companyName ?? 'Công ty',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        iconColor: Colors.blue,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Xem và chỉnh sửa thông tin',
                        onTap: () => _showPersonalInfoSheet(user),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.directions_car_outlined,
                        iconColor: Colors.orange,
                        title: 'Phương tiện',
                        subtitle: 'Quản lý xe giao hàng',
                        onTap: () => _showVehicleSheet(),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bar_chart_outlined,
                        iconColor: Colors.green,
                        title: 'Thống kê',
                        subtitle: 'Xem hiệu suất làm việc',
                        onTap: () => _showStatsSheet(),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.purple,
                        title: 'Thông báo',
                        subtitle: 'Quản lý thông báo',
                        onTap: () => _showNotificationSettings(),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        iconColor: Colors.grey,
                        title: 'Cài đặt',
                        subtitle: 'Tùy chỉnh ứng dụng',
                        onTap: () => _showAppSettings(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bug report & Support
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        iconColor: Colors.teal,
                        title: 'Trợ giúp',
                        subtitle: 'Hướng dẫn sử dụng',
                        onTap: () => _showHelpSheet(),
                      ),
                      _buildDivider(),
                      Builder(
                        builder: (context) => _buildMenuItem(
                          icon: Icons.bug_report_outlined,
                          iconColor: Colors.red,
                          title: 'Báo cáo lỗi',
                          subtitle: 'Gửi phản hồi về vấn đề gặp phải',
                          onTap: () => BugReportDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) => ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Đăng xuất'),
                            content: const Text('Bạn có chắc muốn đăng xuất?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authProvider.notifier).logout();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // AVATAR METHODS
  // ============================================================================

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAvatarOptionButton(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (ref.read(authProvider).user?.avatarUrl != null)
                  _buildAvatarOptionButton(
                    icon: Icons.delete,
                    label: 'Xóa ảnh',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeAvatar();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await image.readAsBytes();
      await _uploadAvatar(bytes, image.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _uploadAvatar(Uint8List bytes, String fileName) async {
    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final supabase = Supabase.instance.client;
      
      // Generate unique file name
      final ext = fileName.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';
      final path = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.$validExt';

      // Upload to Supabase Storage
      await supabase.storage.from('public').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$validExt'),
      );

      // Get public URL
      final publicUrl = supabase.storage.from('public').getPublicUrl(path);

      // Update employee record
      await supabase.from('employees').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Update local auth state
      ref.read(authProvider.notifier).updateProfile(avatarUrl: publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã cập nhật ảnh đại diện!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      setState(() => _isUploadingAvatar = true);

      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final supabase = Supabase.instance.client;

      // Update employee record to remove avatar
      await supabase.from('employees').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Update local auth state
      ref.read(authProvider.notifier).updateProfile(avatarUrl: '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa ảnh đại diện!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ============================================================================
  // SHEET IMPLEMENTATIONS
  // ============================================================================

  void _showPersonalInfoSheet(dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: Colors.blue.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Thông tin cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInfoTile('Họ tên', user?.name ?? 'Chưa cập nhật', Icons.person_outline),
                    _buildInfoTile('Email', user?.email ?? 'Chưa cập nhật', Icons.email_outlined),
                    _buildInfoTile('Số điện thoại', user?.phone ?? 'Chưa cập nhật', Icons.phone_outlined),
                    _buildInfoTile('Vai trò', 'Tài xế giao hàng', Icons.badge_outlined),
                    _buildInfoTile('Công ty', user?.companyName ?? 'Chưa cập nhật', Icons.business_outlined),
                    const SizedBox(height: 20),
                    Text(
                      'Liên hệ quản lý để thay đổi thông tin',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
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

  void _showVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.directions_car, color: Colors.orange.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Phương tiện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.directions_car_outlined, size: 48, color: Colors.orange.shade300),
                    ),
                    const SizedBox(height: 16),
                    Text('Chưa có thông tin phương tiện', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text('Liên hệ quản lý để cập nhật', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatsSheet() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authState = ref.read(authProvider);
      final driverId = authState.user?.id;
      final companyId = authState.user?.companyId;

      if (driverId == null || companyId == null) {
        Navigator.pop(context);
        return;
      }

      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get monthly stats
      final monthlyData = await supabase
          .from('deliveries')
          .select('id, sales_orders:order_id(total, payment_status)')
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('completed_at', startOfMonth.toIso8601String());

      // Get weekly stats
      final weeklyData = await supabase
          .from('deliveries')
          .select('id, sales_orders:order_id(total, payment_status)')
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('completed_at', startOfWeek.toIso8601String());

      // Calculate stats
      int monthlyOrders = monthlyData.length;
      double monthlyRevenue = 0;
      for (var d in monthlyData) {
        final order = d['sales_orders'] as Map<String, dynamic>?;
        if (order?['payment_status'] == 'paid') {
          monthlyRevenue += (order?['total'] as num?)?.toDouble() ?? 0;
        }
      }

      int weeklyOrders = weeklyData.length;
      double weeklyRevenue = 0;
      for (var d in weeklyData) {
        final order = d['sales_orders'] as Map<String, dynamic>?;
        if (order?['payment_status'] == 'paid') {
          weeklyRevenue += (order?['total'] as num?)?.toDouble() ?? 0;
        }
      }

      Navigator.pop(context); // Close loading

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.bar_chart, color: Colors.green.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Thống kê hiệu suất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Tuần này', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Đơn giao', '$weeklyOrders', Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatBox('Thu hộ', currencyFormat.format(weeklyRevenue), Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Tháng ${now.month}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Đơn giao', '$monthlyOrders', Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatBox('Thu hộ', currencyFormat.format(monthlyRevenue), Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.notifications, color: Colors.purple.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cài đặt thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSwitchTile('Đơn hàng mới', 'Nhận thông báo khi có đơn mới', true),
                  _buildSwitchTile('Cập nhật đơn hàng', 'Khi đơn được cập nhật trạng thái', true),
                  _buildSwitchTile('Tin nhắn', 'Thông báo tin nhắn từ quản lý', true),
                  _buildSwitchTile('Âm thanh', 'Bật âm thông báo', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.settings, color: Colors.grey.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cài đặt ứng dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoTile('Phiên bản', '1.0.0', Icons.info_outline),
                  _buildInfoTile('Ngôn ngữ', 'Tiếng Việt', Icons.language),
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 SABO Hub - Odori',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.help, color: Colors.teal.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Trợ giúp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHelpItem('Nhận đơn', 'Vào tab Giao hàng > Chọn đơn > Nhấn "Nhận đơn"'),
                  _buildHelpItem('Hoàn thành giao hàng', 'Chọn đơn đang giao > Nhấn "Đã giao" > Chọn hình thức thanh toán'),
                  _buildHelpItem('Hiện QR chuyển khoản', 'Khi hoàn thành > Chọn "Chuyển khoản" > Nhấn "Hiện QR cho khách quét"'),
                  _buildHelpItem('Xem lịch sử', 'Vào tab Lịch sử để xem các đơn đã giao'),
                  _buildHelpItem('Xem thống kê thu hộ', 'Trang chủ > Click vào card "Thu hộ hôm nay"'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hotline hỗ trợ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('0909 xxx xxx', style: TextStyle(color: Colors.blue.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER WIDGETS
  // ============================================================================

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade700)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color.shade600)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool initialValue) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initialValue;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (v) => setState(() => value = v),
                activeColor: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.check, color: Colors.teal.shade600, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

String getPaymentMethodLabel(String method) {
  switch (method.toLowerCase()) {
    case 'cod':
      return 'Tiền mặt (COD)';
    case 'cash':
      return 'Tiền mặt';
    case 'transfer':
      return 'Chuyển khoản';
    case 'card':
      return 'Thẻ tín dụng';
    default:
      return method;
  }
}

String getPaymentStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return 'Đã thanh toán';
    case 'unpaid':
      return 'Chưa thanh toán';
    case 'partial':
      return 'Thanh toán một phần';
    case 'debt':
      return 'Ghi nợ';
    default:
      return status;
  }
}
