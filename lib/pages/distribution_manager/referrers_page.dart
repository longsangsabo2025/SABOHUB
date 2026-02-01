import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/referrer.dart';
import '../../providers/odori_providers.dart';
import '../../providers/auth_provider.dart';

class ReferrersPage extends ConsumerStatefulWidget {
  const ReferrersPage({super.key});

  @override
  ConsumerState<ReferrersPage> createState() => _ReferrersPageState();
}

class _ReferrersPageState extends ConsumerState<ReferrersPage> {
  String _selectedStatus = 'active';
  String _searchQuery = '';
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final referrersAsync = ref.watch(referrersProvider(ReferrerFilters(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Người giới thiệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(referrersProvider),
          ),
        ],
      ),
      body: Column(
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
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
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
                          onPressed: () => _showAddEditSheet(context),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = value),
      selectedColor: Colors.indigo.shade100,
      checkmarkColor: Colors.indigo,
    );
  }

  Widget _buildReferrerCard(Referrer referrer) {
    final pendingAmount = referrer.pendingAmount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAddEditSheet(context, referrer: referrer),
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
                    backgroundColor: referrer.status == 'active' 
                        ? Colors.green.shade100 
                        : Colors.grey.shade200,
                    child: Text(
                      referrer.name.isNotEmpty ? referrer.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: referrer.status == 'active' ? Colors.green.shade700 : Colors.grey,
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
  
  String _commissionType = 'all_orders';
  String _status = 'active';
  bool _isLoading = false;

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
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.referrer != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                              labelText: 'Số điện thoại',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.phone,
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
                              labelText: 'Tỷ lệ hoa hồng (%)',
                              prefixIcon: const Icon(Icons.percent),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
          .delete()
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
