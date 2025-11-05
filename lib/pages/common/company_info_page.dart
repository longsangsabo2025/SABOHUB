import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/company.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../ceo/company/business_law_tab.dart';
import '../ceo/company/documents_tab.dart';
import '../ceo/company/overview_tab.dart';

/// Company Info Page Provider
final companyInfoProvider =
    FutureProvider.family<Company?, String>((ref, id) async {
  ref.keepAlive();
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// Company Info Page for Shift Leader and Staff
/// Displays limited company information based on role permissions
class CompanyInfoPage extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyInfoPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends ConsumerState<CompanyInfoPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyInfoProvider(widget.companyId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: companyAsync.when(
        loading: () => Column(
          children: [
            const ShimmerCompanyHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải thông tin công ty',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.refresh(companyInfoProvider(widget.companyId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (company) {
          if (company == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy công ty',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }
          return _buildContent(company, currentUser);
        },
      ),
    );
  }

  Widget _buildContent(Company company, User? currentUser) {
    final userRole = currentUser?.role ?? UserRole.staff;

    return Scaffold(
      body: Column(
        children: [
          if (_currentIndex == 0)
            _buildHeader(company)
          else
            _buildCompactAppBar(company, userRole),
          Expanded(
            child: _buildCurrentTab(company, userRole),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(userRole),
    );
  }

  /// Get allowed tabs based on user role
  List<_TabConfig> _getAllowedTabs(UserRole role) {
    // Base tabs available to all roles
    final baseTabs = [
      _TabConfig(
        icon: Icons.info_outline,
        label: 'Thông tin',
        description: 'Thông tin công ty',
      ),
      _TabConfig(
        icon: Icons.rule,
        label: 'Nội quy',
        description: 'Nội quy công ty',
      ),
      _TabConfig(
        icon: Icons.description,
        label: 'Tài liệu',
        description: 'Tài liệu công ty',
      ),
    ];

    // Add role-specific tabs
    switch (role) {
      case UserRole.ceo:
      case UserRole.manager:
        // Full access - redirect to full company details page
        return baseTabs;

      case UserRole.shiftLeader:
        return [
          ...baseTabs,
          _TabConfig(
            icon: Icons.access_time,
            label: 'Chấm công',
            description: 'Lịch sử chấm công',
          ),
          _TabConfig(
            icon: Icons.folder_shared,
            label: 'Hồ sơ',
            description: 'Hồ sơ của tôi',
          ),
        ];

      case UserRole.staff:
        return [
          ...baseTabs,
          _TabConfig(
            icon: Icons.access_time,
            label: 'Chấm công',
            description: 'Lịch sử chấm công',
          ),
          _TabConfig(
            icon: Icons.folder_shared,
            label: 'Hồ sơ',
            description: 'Hồ sơ của tôi',
          ),
        ];
    }
  }

  Widget _buildCurrentTab(Company company, UserRole role) {
    final allowedTabs = _getAllowedTabs(role);
    final currentTab = allowedTabs[_currentIndex];

    switch (currentTab.label) {
      case 'Thông tin':
        return _buildInfoTab(company, role);
      case 'Nội quy':
        return BusinessLawTab(company: company, companyId: widget.companyId);
      case 'Tài liệu':
        return DocumentsTab(company: company);
      case 'Chấm công':
        return _buildMyAttendanceTab(company, role);
      case 'Hồ sơ':
        return _buildMyDocumentsTab(company, role);
      default:
        return _buildInfoTab(company, role);
    }
  }

  Widget _buildCompactAppBar(Company company, UserRole role) {
    final allowedTabs = _getAllowedTabs(role);
    final currentTab = allowedTabs[_currentIndex];

    return Container(
      decoration: BoxDecoration(
        color: company.type.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Quay lại',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentTab.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
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

  Widget _buildHeader(Company company) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            company.type.color,
            company.type.color.withValues(alpha: 0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Company Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Logo or Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      company.type.icon,
                      size: 40,
                      color: company.type.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Name
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Business Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      company.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildBottomNavigationBar(UserRole role) {
    final allowedTabs = _getAllowedTabs(role);

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: allowedTabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ))
          .toList(),
    );
  }

  // Info Tab - Basic company information (read-only)
  Widget _buildInfoTab(Company company, UserRole role) {
    return OverviewTab(company: company, companyId: widget.companyId);
  }

  // My Attendance Tab - Only show current user's attendance
  Widget _buildMyAttendanceTab(Company company, UserRole role) {
    final currentUser = ref.read(currentUserProvider);
    // Show simple attendance view for current user only
    return _MyAttendanceView(
      companyId: widget.companyId,
      userId: currentUser?.id ?? '',
      userName: currentUser?.name ?? 'Bạn',
    );
  }

  // My Documents Tab - Only show current user's documents
  Widget _buildMyDocumentsTab(Company company, UserRole role) {
    final currentUser = ref.read(currentUserProvider);
    // Show simple documents view for current user only
    return _MyDocumentsView(
      companyId: widget.companyId,
      userId: currentUser?.id ?? '',
      userName: currentUser?.name ?? 'Bạn',
    );
  }
}

/// My Attendance View - Shows only current user's attendance records
class _MyAttendanceView extends ConsumerWidget {
  final String companyId;
  final String userId;
  final String userName;

  const _MyAttendanceView({
    required this.companyId,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch sử chấm công',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Chấm công của $userName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.blue[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Lịch sử chấm công của bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xem lịch sử check-in/check-out của bạn tại đây.\nChức năng này đang được phát triển.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to full attendance history
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Xem lịch sử đầy đủ'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// My Documents View - Shows only current user's documents
class _MyDocumentsView extends ConsumerWidget {
  final String companyId;
  final String userId;
  final String userName;

  const _MyDocumentsView({
    required this.companyId,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.folder_shared, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hồ sơ của tôi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Giấy tờ và hợp đồng của $userName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Document Categories
          _buildDocumentCategory(
            context,
            'Hợp đồng lao động',
            Icons.description,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDocumentCategory(
            context,
            'CMND/CCCD',
            Icons.badge,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildDocumentCategory(
            context,
            'Bằng cấp',
            Icons.school,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildDocumentCategory(
            context,
            'Giấy khám sức khỏe',
            Icons.local_hospital,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCategory(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Chưa có tài liệu',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xem $title')),
          );
        },
      ),
    );
  }
}

/// Tab configuration
class _TabConfig {
  final IconData icon;
  final String label;
  final String description;

  _TabConfig({
    required this.icon,
    required this.label,
    required this.description,
  });
}
