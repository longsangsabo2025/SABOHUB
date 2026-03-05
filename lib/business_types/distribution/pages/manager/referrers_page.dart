import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../models/referrer.dart';
import '../../providers/odori_providers.dart';
import '../../providers/referrers_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/customer_avatar.dart';
import '../../../../utils/app_logger.dart';

/// ReferrersPage - Quản lý Người giới thiệu và Hoa hồng
/// Có 2 tabs: Danh sách người giới thiệu và Quản lý hoa hồng
class ReferrersPage extends ConsumerStatefulWidget {
  const ReferrersPage({super.key});

  @override
  ConsumerState<ReferrersPage> createState() => _ReferrersPageState();
}

class _ReferrersPageState extends ConsumerState<ReferrersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('👥 Người giới thiệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(referrersProvider);
              ref.invalidate(commissionsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 20), text: 'Danh sách'),
            Tab(icon: Icon(Icons.monetization_on, size: 20), text: 'Hoa hồng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReferrerListTab(
            onAddEdit: (referrer) => _showAddEditSheet(context, referrer: referrer),
            onShowDetail: (referrer) => _showDetailSheet(context, referrer),
          ),
          const _CommissionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, {Referrer? referrer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReferrerFormSheet(
        referrer: referrer,
        onSaved: () => ref.invalidate(referrersProvider),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Referrer referrer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReferrerDetailSheet(
        referrer: referrer,
        onEdit: () {
          Navigator.pop(context);
          _showAddEditSheet(context, referrer: referrer);
        },
        onRefresh: () {
          ref.invalidate(referrersProvider);
          ref.invalidate(commissionsProvider);
        },
      ),
    );
  }
}

// ==================== REFERRER LIST TAB ====================
class _ReferrerListTab extends ConsumerStatefulWidget {
  final Function(Referrer?) onAddEdit;
  final Function(Referrer) onShowDetail;
  
  const _ReferrerListTab({required this.onAddEdit, required this.onShowDetail});

  @override
  ConsumerState<_ReferrerListTab> createState() => _ReferrerListTabState();
}

class _ReferrerListTabState extends ConsumerState<_ReferrerListTab> {
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(referrerListFilterProvider);
    final referrersAsync = ref.watch(referrersProvider(ReferrerFilters(
      status: filter.selectedStatus == 'all' ? null : filter.selectedStatus,
      search: filter.searchQuery.isEmpty ? null : filter.searchQuery,
    )));

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, SĐT...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) =>
                    ref.read(referrerListFilterProvider.notifier).setSearchQuery(value),
              ),
              const SizedBox(height: 12),
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hoạt động', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ngưng', 'inactive'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: referrersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (referrers) {
                if (referrers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Chưa có người giới thiệu', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => widget.onAddEdit(null),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm mới'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: referrers.length,
                  itemBuilder: (context, index) => _buildReferrerCard(referrers[index]),
                );
              },
            ),
          ),
        ],
      );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = ref.watch(referrerListFilterProvider).selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          ref.read(referrerListFilterProvider.notifier).setStatusFilter(value),
      selectedColor: Colors.indigo.shade100,
      checkmarkColor: Colors.indigo,
    );
  }

  Widget _buildReferrerCard(Referrer referrer) {
    final pendingAmount = referrer.pendingAmount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onShowDetail(referrer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CustomerAvatar(
                    seed: referrer.name,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referrer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (referrer.phone != null)
                          Text(referrer.phone!, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  // Commission rate badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      '${referrer.commissionRate}%',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info row
              Row(
                children: [
                  _buildInfoChip(
                    Icons.receipt_long,
                    referrer.commissionTypeText,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (referrer.status == 'inactive')
                    _buildInfoChip(Icons.pause, 'Ngưng', Colors.grey),
                ],
              ),
              const Divider(height: 24),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Đã tích lũy',
                      '${_currencyFormat.format(referrer.totalEarned)}đ',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Đã trả',
                      '${_currencyFormat.format(referrer.totalPaid)}đ',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Còn lại',
                      '${_currencyFormat.format(pendingAmount)}đ',
                      pendingAmount > 0 ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _ReferrerFormSheet extends ConsumerStatefulWidget {
  final Referrer? referrer;
  final VoidCallback onSaved;

  const _ReferrerFormSheet({this.referrer, required this.onSaved});

  @override
  ConsumerState<_ReferrerFormSheet> createState() => _ReferrerFormSheetState();
}

class _ReferrerFormSheetState extends ConsumerState<_ReferrerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _commissionRateController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerSearchController = TextEditingController();
  
  String _commissionType = 'all_orders';
  String _status = 'active';
  bool _isLoading = false;
  
  // Customer selection
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isLoadingCustomers = true;
  bool _showCustomerDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.referrer != null) {
      _nameController.text = widget.referrer!.name;
      _phoneController.text = widget.referrer!.phone ?? '';
      _emailController.text = widget.referrer!.email ?? '';
      _bankNameController.text = widget.referrer!.bankName ?? '';
      _bankAccountController.text = widget.referrer!.bankAccount ?? '';
      _bankHolderController.text = widget.referrer!.bankHolder ?? '';
      _commissionRateController.text = widget.referrer!.commissionRate.toString();
      _notesController.text = widget.referrer!.notes ?? '';
      _commissionType = widget.referrer!.commissionType;
      _status = widget.referrer!.status;
    } else {
      _commissionRateController.text = '3'; // Default 3%
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final data = await Supabase.instance.client
          .from('customers')
          .select('id, name, phone, email, address')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        setState(() {
          _allCustomers = List<Map<String, dynamic>>.from(data);
          _filteredCustomers = _allCustomers;
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        final q = query.toLowerCase();
        _filteredCustomers = _allCustomers.where((c) {
          final name = (c['name'] ?? '').toString().toLowerCase();
          final phone = (c['phone'] ?? '').toString().toLowerCase();
          return name.contains(q) || phone.contains(q);
        }).toList();
      }
      _showCustomerDropdown = true;
    });
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer['name'] ?? '';
      _phoneController.text = customer['phone'] ?? '';
      _emailController.text = customer['email'] ?? '';
      _customerSearchController.text = customer['name'] ?? '';
      _showCustomerDropdown = false;
    });
  }

  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomer = null;
      _customerSearchController.clear();
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _showCustomerDropdown = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    _commissionRateController.dispose();
    _notesController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.referrer != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit : Icons.person_add,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'Chỉnh sửa người giới thiệu' : 'Thêm người giới thiệu',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer quick-select (only for new referrers)
                    if (!isEditing) ...[
                      const Text(
                        '🔍 Chọn từ khách hàng có sẵn',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tìm và chọn KH để tự động điền thông tin, hoặc bỏ qua để nhập tay',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCustomer != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCustomer!['name'] ?? '',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                    ),
                                    if (_selectedCustomer!['phone'] != null)
                                      Text(
                                        _selectedCustomer!['phone'],
                                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 18, color: Colors.green.shade600),
                                onPressed: _clearCustomerSelection,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            TextFormField(
                              controller: _customerSearchController,
                              decoration: InputDecoration(
                                labelText: 'Tìm khách hàng...',
                                hintText: 'Nhập tên hoặc SĐT',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _customerSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _customerSearchController.clear();
                                          _filterCustomers('');
                                          setState(() => _showCustomerDropdown = false);
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.indigo.shade50,
                              ),
                              onChanged: _filterCustomers,
                              onTap: () {
                                if (_allCustomers.isNotEmpty) {
                                  setState(() => _showCustomerDropdown = true);
                                }
                              },
                            ),
                            if (_isLoadingCustomers)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                            if (_showCustomerDropdown && _filteredCustomers.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                constraints: BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: _filteredCustomers.length > 20 ? 20 : _filteredCustomers.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final c = _filteredCustomers[index];
                                    return ListTile(
                                      dense: true,
                                      leading: CustomerAvatar(seed: c['name'] ?? '', radius: 16),
                                      title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 14)),
                                      subtitle: Text(
                                        [c['phone'], c['address']].where((s) => s != null && s.toString().isNotEmpty).join(' • '),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _selectCustomer(c),
                                    );
                                  },
                                ),
                              ),
                            if (_showCustomerDropdown && _filteredCustomers.isEmpty && _customerSearchController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Không tìm thấy KH nào',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                    ],
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ tên *',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone & Email
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại *',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập SĐT';
                              final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
                              if (!RegExp(r'^0\d{9,10}$').hasMatch(cleaned)) return 'SĐT không hợp lệ';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) {
                                  return 'Email không hợp lệ';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Commission section
                    const Text(
                      '💰 Cài đặt hoa hồng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _commissionRateController,
                            decoration: InputDecoration(
                              labelText: 'Tỷ lệ hoa hồng (%) *',
                              prefixIcon: const Icon(Icons.percent),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tỷ lệ';
                              final rate = double.tryParse(v.trim());
                              if (rate == null || rate <= 0 || rate > 100) return '0-100%';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _commissionType,
                            decoration: InputDecoration(
                              labelText: 'Áp dụng cho',
                              prefixIcon: const Icon(Icons.receipt),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all_orders', child: Text('Tất cả đơn')),
                              DropdownMenuItem(value: 'first_order', child: Text('Chỉ đơn đầu')),
                            ],
                            onChanged: (v) => setState(() => _commissionType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bank info
                    const Text(
                      '🏦 Thông tin ngân hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bankNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên ngân hàng',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bankAccountController,
                            decoration: InputDecoration(
                              labelText: 'Số tài khoản',
                              prefixIcon: const Icon(Icons.credit_card),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bankHolderController,
                            decoration: InputDecoration(
                              labelText: 'Chủ tài khoản',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Status
                    if (isEditing)
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          prefixIcon: const Icon(Icons.toggle_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('✅ Hoạt động')),
                          DropdownMenuItem(value: 'inactive', child: Text('⏸️ Ngưng')),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    const SizedBox(height: 80), // Space for button
                  ],
                ),
              ),
            ),
          ),
          // Save button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface),
                        )
                      : Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) throw Exception('Không tìm thấy company_id');

      final data = {
        'company_id': companyId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'bank_name': _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        'bank_account': _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
        'bank_holder': _bankHolderController.text.trim().isEmpty ? null : _bankHolderController.text.trim(),
        'commission_rate': double.tryParse(_commissionRateController.text) ?? 0,
        'commission_type': _commissionType,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'status': _status,
      };

      final supabase = Supabase.instance.client;

      if (widget.referrer != null) {
        await supabase.from('referrers').update(data).eq('id', widget.referrer!.id);
      } else {
        await supabase.from('referrers').insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.referrer != null ? 'Đã cập nhật' : 'Đã thêm mới'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('duplicate') 
            ? 'Người giới thiệu đã tồn tại với số điện thoại này'
            : e.toString().contains('network') || e.toString().contains('SocketException')
                ? 'Lỗi kết nối mạng. Vui lòng thử lại'
                : 'Không thể lưu. Vui lòng thử lại sau';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${widget.referrer!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('referrers')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.referrer!.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa'), backgroundColor: Colors.orange),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('foreign key') || e.toString().contains('referenced')
            ? 'Không thể xóa vì còn hoa hồng liên quan'
            : 'Không thể xóa. Vui lòng thử lại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ==================== COMMISSIONS TAB ====================
class _CommissionsTab extends ConsumerStatefulWidget {
  const _CommissionsTab();

  @override
  ConsumerState<_CommissionsTab> createState() => _CommissionsTabState();
}

class _CommissionsTabState extends ConsumerState<_CommissionsTab> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(commissionFilterProvider);
    final commissionsAsync = ref.watch(commissionsProvider(CommissionFilters(
      status: filter.selectedStatus == 'all' ? null : filter.selectedStatus,
      referrerId: filter.selectedReferrerId,
    )));
    final referrersAsync = ref.watch(activeReferrersProvider);

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Referrer dropdown
              referrersAsync.when(
                data: (referrers) => DropdownButtonFormField<String?>(
                  value: ref.watch(commissionFilterProvider).selectedReferrerId,
                  decoration: InputDecoration(
                    labelText: 'Người giới thiệu',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ...referrers.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name),
                    )),
                  ],
                  onChanged: (v) =>
                      ref.read(commissionFilterProvider.notifier).setSelectedReferrerId(v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Chờ duyệt', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã duyệt', 'approved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã trả', 'paid'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stats summary
        _buildStatsSummary(),
        // List
        Expanded(
          child: commissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (commissions) {
              if (commissions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Chưa có hoa hồng', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(
                        'Hoa hồng sẽ được tạo tự động khi\nđơn hàng hoàn thành với khách có người giới thiệu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: commissions.length + (filter.selectedStatus == 'pending' && commissions.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // Batch approve button at the end for pending list
                  if (filter.selectedStatus == 'pending' && index == commissions.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _batchApprove(commissions),
                        icon: const Icon(Icons.done_all),
                        label: Text('Duyệt tất cả ${commissions.length} hoa hồng'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    );
                  }
                  return _buildCommissionCard(commissions[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _batchApprove(List<Commission> commissions) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt tất cả'),
        content: Text('Duyệt ${commissions.length} hoa hồng đang chờ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Duyệt tất cả', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = ref.read(currentUserProvider);
      final supabase = Supabase.instance.client;
      final now = DateTime.now().toIso8601String();

      for (final c in commissions) {
        await supabase.from('commissions').update({
          'status': 'approved',
          'approved_at': now,
          'approved_by': user?.id,
          'updated_at': now,
        }).eq('id', c.id);
      }

      // Sync all affected referrer totals
      final referrerIds = commissions.map((c) => c.referrerId).toSet();
      for (final rid in referrerIds) {
        final allC = await supabase
            .from('commissions')
            .select('commission_amount, status')
            .eq('referrer_id', rid)
            .neq('status', 'cancelled');
        double totalEarned = 0, totalPaid = 0;
        for (final c in allC) {
          final amt = (c['commission_amount'] ?? 0).toDouble();
          totalEarned += amt;
          if (c['status'] == 'paid') totalPaid += amt;
        }
        await supabase.from('referrers').update({
          'total_earned': totalEarned,
          'total_paid': totalPaid,
        }).eq('id', rid);
      }

      ref.invalidate(commissionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã duyệt ${commissions.length} hoa hồng'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể duyệt. Vui lòng thử lại'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatsSummary() {
    final commissionsAsync = ref.watch(commissionsProvider(const CommissionFilters()));
    
    return commissionsAsync.when(
      data: (commissions) {
        final pending = commissions.where((c) => c.status == 'pending').fold<double>(0, (s, c) => s + c.commissionAmount);
        final approved = commissions.where((c) => c.status == 'approved').fold<double>(0, (s, c) => s + c.commissionAmount);
        final paid = commissions.where((c) => c.status == 'paid').fold<double>(0, (s, c) => s + c.commissionAmount);
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Chờ duyệt', pending, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Đã duyệt', approved, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Đã trả', paid, Colors.green)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = ref.watch(commissionFilterProvider).selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          ref.read(commissionFilterProvider.notifier).setStatusFilter(value),
      selectedColor: Colors.indigo.shade100,
      checkmarkColor: Colors.indigo,
    );
  }

  Widget _buildCommissionCard(Commission commission) {
    final statusColor = _getStatusColor(commission.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCommissionDetail(commission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.monetization_on, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commission.referrerName ?? 'Người giới thiệu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '→ ${commission.customerName ?? 'Khách hàng'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      commission.statusText,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đơn hàng', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(commission.orderCode ?? '#${commission.orderId?.substring(0, 8) ?? '---'}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giá trị đơn', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_currencyFormat.format(commission.orderAmount)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Hoa hồng (${commission.commissionRate.toStringAsFixed(1)}%)', 
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(
                          _currencyFormat.format(commission.commissionAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showCommissionDetail(Commission commission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommissionDetailSheet(
        commission: commission,
        currencyFormat: _currencyFormat,
        onUpdated: () => ref.invalidate(commissionsProvider),
      ),
    );
  }
}

// ==================== REFERRER DETAIL SHEET ====================
class _ReferrerDetailSheet extends ConsumerStatefulWidget {
  final Referrer referrer;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const _ReferrerDetailSheet({
    required this.referrer,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ReferrerDetailSheet> createState() => _ReferrerDetailSheetState();
}

class _ReferrerDetailSheetState extends ConsumerState<_ReferrerDetailSheet> {
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');
  List<Map<String, dynamic>> _linkedCustomers = [];
  List<Commission> _referrerCommissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // Load linked customers with order stats
      final customersData = await supabase
          .from('customers')
          .select('id, name, phone, status')
          .eq('referrer_id', widget.referrer.id)
          .order('name');

      // Load commissions for this referrer
      final commissionsData = await supabase
          .from('commissions')
          .select('*, customers(name)')
          .eq('referrer_id', widget.referrer.id)
          .order('created_at', ascending: false);

      // Load order count per customer
      final customerList = <Map<String, dynamic>>[];
      for (final c in customersData) {
        final ordersCount = await supabase
            .from('sales_orders')
            .select('id')
            .eq('customer_id', c['id']);
        final completedOrders = await supabase
            .from('sales_orders')
            .select('id, total')
            .eq('customer_id', c['id'])
            .eq('status', 'completed');
        final totalRevenue = (completedOrders as List).fold<double>(
          0, (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble(),
        );
        customerList.add({
          ...c,
          'order_count': (ordersCount as List).length,
          'completed_orders': completedOrders.length,
          'total_revenue': totalRevenue,
        });
      }

      if (mounted) {
        setState(() {
          _linkedCustomers = customerList;
          _referrerCommissions = (commissionsData as List)
              .map((j) => Commission.fromJson(j))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppLogger.error('Error loading referrer detail: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final referrer = widget.referrer;
    final pendingAmount = referrer.pendingAmount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CustomerAvatar(seed: referrer.name, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        referrer.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (referrer.phone != null)
                        Text(referrer.phone!, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${referrer.commissionRate}%',
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Chỉnh sửa',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Đã tích lũy',
                                '${_currencyFormat.format(referrer.totalEarned)}đ',
                                Colors.green,
                                Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Đã trả',
                                '${_currencyFormat.format(referrer.totalPaid)}đ',
                                Colors.blue,
                                Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Còn lại',
                                '${_currencyFormat.format(pendingAmount)}đ',
                                pendingAmount > 0 ? Colors.orange : Colors.grey,
                                Icons.schedule,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Summary stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Khách hàng',
                                '${_linkedCustomers.length}',
                                Colors.indigo,
                                Icons.people,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Hoa hồng',
                                '${_referrerCommissions.length}',
                                Colors.purple,
                                Icons.receipt_long,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Loại',
                                referrer.commissionTypeText,
                                Colors.teal,
                                Icons.settings,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Referrer info
                        if (referrer.email != null || referrer.bankName != null) ...[
                          _buildSectionHeader('📋 Thông tin', Icons.info_outline),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                if (referrer.email != null)
                                  _buildInfoRow('Email', referrer.email!),
                                if (referrer.bankName != null)
                                  _buildInfoRow('Ngân hàng', referrer.bankName!),
                                if (referrer.bankAccount != null)
                                  _buildInfoRow('STK', referrer.bankAccount!),
                                if (referrer.bankHolder != null)
                                  _buildInfoRow('Chủ TK', referrer.bankHolder!),
                                if (referrer.notes != null && referrer.notes!.isNotEmpty)
                                  _buildInfoRow('Ghi chú', referrer.notes!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Linked customers
                        _buildSectionHeader('👥 Khách hàng liên kết (${_linkedCustomers.length})', Icons.people),
                        const SizedBox(height: 8),
                        if (_linkedCustomers.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.person_off, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chưa có khách hàng nào được liên kết',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_linkedCustomers.map((c) => _buildCustomerCard(c))),

                        const SizedBox(height: 24),

                        // Commission history
                        _buildSectionHeader('💰 Lịch sử hoa hồng (${_referrerCommissions.length})', Icons.monetization_on),
                        const SizedBox(height: 8),
                        if (_referrerCommissions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.monetization_on_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chưa có hoa hồng nào',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_referrerCommissions.map((c) => _buildCommissionRow(c))),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final orderCount = customer['order_count'] ?? 0;
    final completedOrders = customer['completed_orders'] ?? 0;
    final totalRevenue = (customer['total_revenue'] ?? 0).toDouble();
    final isActive = customer['status'] != 'inactive';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CustomerAvatar(seed: customer['name'] ?? '', radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Ngưng', style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                        ),
                    ],
                  ),
                  if (customer['phone'] != null)
                    Text(customer['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.receipt_long, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '$orderCount đơn ($completedOrders hoàn thành)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      if (totalRevenue > 0)
                        Text(
                          '${_currencyFormat.format(totalRevenue)}đ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionRow(Commission commission) {
    final statusColor = _getCommissionStatusColor(commission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(Icons.monetization_on, color: statusColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          commission.orderCode ?? '#${commission.orderId?.substring(0, 8) ?? '---'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commission.statusText,
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '→ ${commission.customerName ?? 'KH'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Text(
                        '${_currencyFormat.format(commission.orderAmount)}đ × ${commission.commissionRate}% = ',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      Text(
                        '${_currencyFormat.format(commission.commissionAmount)}đ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (commission.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(commission.createdAt!),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
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

  Color _getCommissionStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ==================== COMMISSION DETAIL SHEET ====================
class _CommissionDetailSheet extends ConsumerStatefulWidget {
  final Commission commission;
  final NumberFormat currencyFormat;
  final VoidCallback onUpdated;

  const _CommissionDetailSheet({
    required this.commission,
    required this.currencyFormat,
    required this.onUpdated,
  });

  @override
  ConsumerState<_CommissionDetailSheet> createState() => _CommissionDetailSheetState();
}

class _CommissionDetailSheetState extends ConsumerState<_CommissionDetailSheet> {
  bool _isLoading = false;
  final _paymentNoteController = TextEditingController();

  @override
  void dispose() {
    _paymentNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commission = widget.commission;
    final statusColor = _getStatusColor(commission.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monetization_on, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết hoa hồng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commission.statusText,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Người giới thiệu', [
                    _buildInfoRow('Tên', commission.referrerName ?? '---'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Khách hàng', [
                    _buildInfoRow('Tên', commission.customerName ?? '---'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Đơn hàng', [
                    _buildInfoRow('Mã đơn', commission.orderCode ?? '#${commission.orderId?.substring(0, 8) ?? '---'}'),
                    _buildInfoRow('Giá trị', widget.currencyFormat.format(commission.orderAmount)),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Hoa hồng', [
                    _buildInfoRow('Tỷ lệ', '${commission.commissionRate.toStringAsFixed(1)}%'),
                    _buildInfoRow('Số tiền', widget.currencyFormat.format(commission.commissionAmount)),
                  ]),
                  if (commission.createdAt != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection('Thời gian', [
                      _buildInfoRow('Tạo lúc', DateFormat('dd/MM/yyyy HH:mm').format(commission.createdAt!)),
                      if (commission.approvedAt != null)
                        _buildInfoRow('Duyệt lúc', DateFormat('dd/MM/yyyy HH:mm').format(commission.approvedAt!)),
                      if (commission.paidAt != null)
                        _buildInfoRow('Trả lúc', DateFormat('dd/MM/yyyy HH:mm').format(commission.paidAt!)),
                    ]),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Actions
          if (commission.status == 'pending' || commission.status == 'approved')
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (commission.status == 'pending') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => _updateStatus('cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _updateStatus('approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
                              : const Text('Duyệt hoa hồng'),
                        ),
                      ),
                    ],
                    if (commission.status == 'approved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showPaymentDialog,
                          icon: const Icon(Icons.payment),
                          label: Text('Xác nhận đã trả'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'approved') {
        updates['approved_at'] = DateTime.now().toIso8601String();
        updates['approved_by'] = user?.id;
      }

      await Supabase.instance.client
          .from('commissions')
          .update(updates)
          .eq('id', widget.commission.id);

      // Sync referrer totals from actual commission data
      await _syncReferrerTotals();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved' ? 'Đã duyệt hoa hồng' : 'Đã từ chối'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.orange,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Recalculate referrer totals from actual commission data to avoid drift
  Future<void> _syncReferrerTotals() async {
    try {
      final supabase = Supabase.instance.client;
      final referrerId = widget.commission.referrerId;

      // Sum all non-cancelled commissions = total_earned
      final allCommissions = await supabase
          .from('commissions')
          .select('commission_amount, status')
          .eq('referrer_id', referrerId)
          .neq('status', 'cancelled');

      double totalEarned = 0;
      double totalPaid = 0;
      for (final c in allCommissions) {
        final amount = (c['commission_amount'] ?? 0).toDouble();
        totalEarned += amount;
        if (c['status'] == 'paid') totalPaid += amount;
      }

      await supabase
          .from('referrers')
          .update({'total_earned': totalEarned, 'total_paid': totalPaid})
          .eq('id', referrerId);
    } catch (e) {
      AppLogger.error('Error syncing referrer totals: $e');
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số tiền: ${widget.currencyFormat.format(widget.commission.commissionAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentNoteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'VD: Chuyển khoản Vietcombank...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markAsPaid();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Xác nhận đã trả', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      
      await Supabase.instance.client
          .from('commissions')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'paid_by': user?.id,
            'payment_note': _paymentNoteController.text.trim().isEmpty 
                ? null 
                : _paymentNoteController.text.trim(),
          })
          .eq('id', widget.commission.id);

      // Sync referrer totals from actual commission data
      await _syncReferrerTotals();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận thanh toán'), backgroundColor: Colors.green),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán thất bại. Vui lòng thử lại'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


}
