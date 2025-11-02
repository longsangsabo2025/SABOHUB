import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_provider.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import 'company_details_page.dart';

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// All Companies Provider (Legacy - use cachedCompaniesProvider instead)
@Deprecated('Use cachedCompaniesProvider instead')
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getAllCompanies();
});

/// Cached All Companies Provider (NEW - Facebook-style caching)
/// 15-minute cache, persists across tab switches
final cachedCompaniesProvider = StateNotifierProvider<
    CachedStateNotifier<List<Company>>,
    AsyncValue<CachedData<List<Company>>>>((ref) {
  final service = ref.watch(companyServiceProvider);

  final notifier = CachedStateNotifier<List<Company>>(
    fetchData: () => service.getAllCompanies(),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  ref.keepAlive(); // Prevents disposal on tab switch
  notifier.fetch();

  return notifier;
});

/// CEO Companies Management Page
/// Manages all companies in the enterprise
class CEOCompaniesPage extends ConsumerStatefulWidget {
  const CEOCompaniesPage({super.key});

  @override
  ConsumerState<CEOCompaniesPage> createState() => _CEOCompaniesPageState();
}

class _CEOCompaniesPageState extends ConsumerState<CEOCompaniesPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use cached provider - persists across tab switches
    final companiesAsync = ref.watch(cachedCompaniesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        // Pull-to-refresh support
        onRefresh: () async {
          await ref.read(cachedCompaniesProvider.notifier).refresh();
        },
        child: Column(
          children: [
            _buildHeader(companiesAsync),
            Expanded(
              child: companiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Lỗi: $error',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(cachedCompaniesProvider.notifier).refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (cachedData) {
                  // Unwrap cached data
                  final companies = cachedData.data;
                  return _buildCompanyList(companies);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCompanyDialog(),
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm công ty',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<CachedData<List<Company>>> companiesAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý công ty',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quản lý tất cả công ty trong hệ thống',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              companiesAsync.when(
                data: (cachedData) =>
                    _buildCompanyCount(cachedData.data.length),
                loading: () => _buildCompanyCount(0),
                error: (_, __) => _buildCompanyCount(0),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildCompanyCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count công ty',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm công ty...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCompanyList(List<Company> companies) {
    final filteredCompanies = companies
        .where((company) =>
            company.name.toLowerCase().contains(_searchQuery) ||
            (company.address.toLowerCase().contains(_searchQuery)))
        .toList();

    if (filteredCompanies.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy công ty nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCompanies.length,
      itemBuilder: (context, index) {
        final company = filteredCompanies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyDetailsPage(companyId: company.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              company.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                company.type.label,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                company.address,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: company.status == 'active'
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      company.status == 'active'
                          ? 'Hoạt động'
                          : 'Không hoạt động',
                      style: TextStyle(
                        color: company.status == 'active'
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                      Icons.people, '${company.employeeCount} nhân viên'),
                  const SizedBox(width: 16),
                  _buildStatItem(
                      Icons.table_restaurant, '${company.tableCount} bàn'),
                ],
              ),
              if (company.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      company.phone!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (company.email != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        company.email!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCompanyDetails(company),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem chi tiết'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showEditCompanyDialog(company),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteCompany(company),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label:
                        const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showCreateCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CompanyFormDialog(),
    );
  }

  void _showEditCompanyDialog(Company company) {
    showDialog(
      context: context,
      builder: (context) => _CompanyFormDialog(company: company),
    );
  }

  void _showCompanyDetails(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(company.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loại hình: ${company.type.label}'),
            Text('Địa chỉ: ${company.address}'),
            if (company.phone != null) Text('Điện thoại: ${company.phone}'),
            if (company.email != null) Text('Email: ${company.email}'),
            Text('Nhân viên: ${company.employeeCount}'),
            Text('Số bàn: ${company.tableCount}'),
            Text('Trạng thái: ${company.status}'),
          ],
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

  void _confirmDeleteCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa công ty "${company.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(companyServiceProvider);
                await service.deleteCompany(company.id);

                // ✅ Refresh cached provider after delete
                ref.read(cachedCompaniesProvider.notifier).refresh();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa công ty thành công')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CompanyFormDialog extends ConsumerStatefulWidget {
  final Company? company;

  const _CompanyFormDialog({this.company});

  @override
  ConsumerState<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends ConsumerState<_CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _addressController =
        TextEditingController(text: widget.company?.address ?? '');
    _phoneController = TextEditingController(text: widget.company?.phone ?? '');
    _emailController = TextEditingController(text: widget.company?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.company == null
          ? 'Thêm công ty mới'
          : 'Sửa thông tin công ty'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên công ty *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công ty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(widget.company == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final service = ref.read(companyServiceProvider);

      if (widget.company == null) {
        // Create new company
        await service.createCompany(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
      } else {
        // Update existing company
        await service.updateCompany(widget.company!.id, {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        });
      }

      // ✅ Refresh cached provider after create/update
      ref.read(cachedCompaniesProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.company == null
                ? 'Đã thêm công ty thành công'
                : 'Đã cập nhật công ty thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
