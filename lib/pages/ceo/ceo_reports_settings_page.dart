import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import 'ceo_profile_page.dart';

/// CEO Reports Page
/// Generate and view comprehensive business reports
class CEOReportsPage extends ConsumerStatefulWidget {
  const CEOReportsPage({super.key});

  @override
  ConsumerState<CEOReportsPage> createState() => _CEOReportsPageState();
}

class _CEOReportsPageState extends ConsumerState<CEOReportsPage> {
  String _selectedReportType = 'financial';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildReportTypeSelector(),
          Expanded(child: _buildReportsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Báo cáo',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lọc báo cáo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Theo thời gian'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Chọn khoảng thời gian')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Theo công ty'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chọn công ty')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Theo bộ phận'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chọn bộ phận')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.filter_list, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt báo cáo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Tự động tạo báo cáo'),
                      subtitle: const Text('Tạo báo cáo định kỳ hàng tuần'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    SwitchListTile(
                      title: const Text('Gửi email thông báo'),
                      subtitle: const Text('Nhận thông báo khi có báo cáo mới'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.format_list_bulleted),
                      title: const Text('Định dạng mặc định'),
                      trailing: const Text('PDF'),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.picture_as_pdf),
                                  title: const Text('PDF'),
                                  trailing: const Icon(Icons.check,
                                      color: Colors.green),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Định dạng PDF đã được chọn')),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.table_chart),
                                  title: const Text('Excel'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Định dạng Excel đã được chọn')),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.description),
                                  title: const Text('Word'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Định dạng Word đã được chọn')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.settings, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTypeChip('financial', 'Tài chính', Icons.attach_money),
          const SizedBox(width: 8),
          _buildTypeChip('operations', 'Vận hành', Icons.business),
          const SizedBox(width: 8),
          _buildTypeChip('hr', 'Nhân sự', Icons.people),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedReportType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReportType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    final reports = _getReportsForType(_selectedReportType);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: reports.length,
      itemBuilder: (context, index) => _buildReportCard(reports[index]),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: report['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    report['icon'],
                    color: report['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) => _handleReportAction(value, report),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Xem'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16),
                          SizedBox(width: 8),
                          Text('Tải xuống'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 8),
                          Text('Chia sẻ'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricChip(
                    'Cập nhật',
                    report['lastUpdated'],
                    Icons.access_time,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    'Kích thước',
                    report['size'],
                    Icons.description,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    'Định dạng',
                    report['format'],
                    Icons.file_present,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReportAction('view', report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: report['color']),
                      foregroundColor: report['color'],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleReportAction('download', report),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Tải xuống'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: report['color'],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getReportsForType(String type) {
    switch (type) {
      case 'financial':
        return _financialReports;
      case 'operations':
        return _operationsReports;
      case 'hr':
        return _hrReports;
      default:
        return _financialReports;
    }
  }

  void _handleReportAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'download':
        _downloadReport(report);
        break;
      case 'share':
        _shareReport(report);
        break;
    }
  }

  void _viewReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title']),
        content: const Text('Xem báo cáo chi tiết sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang tải xuống ${report['title']}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chia sẻ ${report['title']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Mock data
final List<Map<String, dynamic>> _financialReports = [
  {
    'title': 'Báo cáo tài chính tháng',
    'description': 'Tổng hợp doanh thu, chi phí và lợi nhuận tháng 10/2024',
    'lastUpdated': '2 giờ trước',
    'size': '2.4 MB',
    'format': 'PDF',
    'icon': Icons.assessment,
    'color': const Color(0xFF10B981),
  },
  {
    'title': 'Phân tích dòng tiền',
    'description': 'Chi tiết thu chi và dòng tiền các công ty',
    'lastUpdated': '1 ngày trước',
    'size': '1.8 MB',
    'format': 'Excel',
    'icon': Icons.trending_up,
    'color': const Color(0xFF3B82F6),
  },
  {
    'title': 'Báo cáo thuế quý',
    'description': 'Báo cáo thuế quý 4/2024 cho tất cả công ty',
    'lastUpdated': '3 ngày trước',
    'size': '3.2 MB',
    'format': 'PDF',
    'icon': Icons.receipt_long,
    'color': const Color(0xFFF59E0B),
  },
];

final List<Map<String, dynamic>> _operationsReports = [
  {
    'title': 'Hiệu suất vận hành',
    'description': 'Đánh giá hiệu suất hoạt động của từng công ty',
    'lastUpdated': '4 giờ trước',
    'size': '1.2 MB',
    'format': 'PDF',
    'icon': Icons.speed,
    'color': const Color(0xFF8B5CF6),
  },
  {
    'title': 'Báo cáo khách hàng',
    'description': 'Thống kê lưu lượng và hành vi khách hàng',
    'lastUpdated': '6 giờ trước',
    'size': '950 KB',
    'format': 'Excel',
    'icon': Icons.people,
    'color': const Color(0xFF06B6D4),
  },
];

final List<Map<String, dynamic>> _hrReports = [
  {
    'title': 'Báo cáo nhân sự',
    'description': 'Tổng hợp thông tin nhân viên toàn hệ thống',
    'lastUpdated': '1 ngày trước',
    'size': '800 KB',
    'format': 'Excel',
    'icon': Icons.badge,
    'color': const Color(0xFF10B981),
  },
  {
    'title': 'Chấm công và lương',
    'description': 'Báo cáo chấm công và tính lương tháng 10',
    'lastUpdated': '2 ngày trước',
    'size': '1.5 MB',
    'format': 'PDF',
    'icon': Icons.access_time,
    'color': const Color(0xFFEF4444),
  },
];

/// CEO Settings Page
/// System-wide configuration and preferences
class CEOSettingsPage extends ConsumerWidget {
  const CEOSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProfile(context, ref),
            const SizedBox(height: 24),
            _buildSystemSettings(),
            const SizedBox(height: 24),
            _buildCompanySettings(),
            const SizedBox(height: 24),
            _buildSecuritySettings(),
            const SizedBox(height: 24),
            _buildSupportSection(context, ref),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Cài đặt',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, WidgetRef ref) {
    // ✅ Get real user data from authProvider
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final displayName = user?.name ?? 'CEO';
    final displayEmail = user?.email ?? 'ceo@sabohub.com';
    final displayRole = user?.role.value ?? 'CEO';

    // Get initials for avatar
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'CEO';

    return Container(
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
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản trị viên hệ thống',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang mở trang chỉnh sửa hồ sơ...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return _buildSettingsSection(
      'Cài đặt hệ thống',
      [
        _buildSettingItem(
          'Ngôn ngữ',
          'Tiếng Việt',
          Icons.language,
          () {},
        ),
        _buildSettingItem(
          'Múi giờ',
          'GMT+7 (Hồ Chí Minh)',
          Icons.access_time,
          () {},
        ),
        _buildSettingItem(
          'Định dạng tiền tệ',
          'VND (₫)',
          Icons.attach_money,
          () {},
        ),
        _buildSettingItem(
          'Thông báo',
          'Bật',
          Icons.notifications,
          () {},
          hasSwitch: true,
        ),
      ],
    );
  }

  Widget _buildCompanySettings() {
    return _buildSettingsSection(
      'Quản lý công ty',
      [
        _buildSettingItem(
          'Thêm công ty mới',
          '',
          Icons.add_business,
          () {},
        ),
        _buildSettingItem(
          'Cấu hình chung',
          'Áp dụng cho tất cả công ty',
          Icons.settings,
          () {},
        ),
        _buildSettingItem(
          'Quyền truy cập',
          'Phân quyền nhân viên',
          Icons.security,
          () {},
        ),
        _buildSettingItem(
          'Backup dữ liệu',
          'Tự động hàng ngày',
          Icons.backup,
          () {},
          hasSwitch: true,
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      'Bảo mật',
      [
        _buildSettingItem(
          'Đổi mật khẩu',
          '',
          Icons.lock,
          () {},
        ),
        _buildSettingItem(
          'Xác thực 2 bước',
          'Bật',
          Icons.verified_user,
          () {},
          hasSwitch: true,
        ),
        _buildSettingItem(
          'Phiên đăng nhập',
          'Quản lý thiết bị',
          Icons.devices,
          () {},
        ),
        _buildSettingItem(
          'Lịch sử hoạt động',
          '',
          Icons.history,
          () {},
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, WidgetRef ref) {
    return _buildSettingsSection(
      'Hỗ trợ',
      [
        _buildSettingItem(
          'Trung tâm trợ giúp',
          '',
          Icons.help,
          () {},
        ),
        _buildSettingItem(
          'Liên hệ hỗ trợ',
          '',
          Icons.contact_support,
          () {},
        ),
        _buildSettingItem(
          'Về ứng dụng',
          'Phiên bản 1.0.0',
          Icons.info,
          () {},
        ),
        _buildSettingItem(
          'Đăng xuất',
          '',
          Icons.logout,
          () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Xác nhận đăng xuất'),
                content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã đăng xuất thành công'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                context.go('/login');
              }
            }
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool hasSwitch = false,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: hasSwitch ? null : onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: hasSwitch
          ? Switch(
              value: true,
              onChanged: (value) {},
              activeThumbColor: const Color(0xFF10B981),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
