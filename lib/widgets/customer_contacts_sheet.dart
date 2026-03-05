import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer_contact.dart';
import '../../utils/app_logger.dart';
import '../../models/customer_address.dart';
import '../business_types/distribution/models/odori_customer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/customer_avatar.dart';
import '../core/theme/app_spacing.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

final supabase = Supabase.instance.client;

/// Widget to manage customer contacts
class CustomerContactsSheet extends ConsumerStatefulWidget {
  final OdoriCustomer customer;
  final VoidCallback? onChanged;

  const CustomerContactsSheet({
    super.key,
    required this.customer,
    this.onChanged,
  });

  @override
  ConsumerState<CustomerContactsSheet> createState() => _CustomerContactsSheetState();
}

class _CustomerContactsSheetState extends ConsumerState<CustomerContactsSheet> {
  List<CustomerContact> _contacts = [];
  List<CustomerAddress> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load contacts with address info
      final contactsResponse = await supabase
          .from('customer_contacts')
          .select('*, customer_addresses(name)')
          .eq('customer_id', widget.customer.id)
          .eq('is_active', true)
          .order('is_primary', ascending: false)
          .order('name');

      // Load addresses for dropdown
      final addressesResponse = await supabase
          .from('customer_addresses')
          .select()
          .eq('customer_id', widget.customer.id)
          .eq('is_active', true)
          .order('name');

      final contacts = (contactsResponse as List)
          .map((json) => CustomerContact.fromJson(json))
          .toList();

      final addresses = (addressesResponse as List)
          .map((json) => CustomerAddress.fromJson(json))
          .toList();

      setState(() {
        _contacts = contacts;
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultFromCustomer() async {
    final companyId = ref.read(currentUserProvider)?.companyId;
    if (companyId == null) return;

    try {
      await supabase.from('customer_contacts').insert({
        'customer_id': widget.customer.id,
        'company_id': companyId,
        'name': widget.customer.contactPerson ?? widget.customer.name,
        'position': 'Chủ cửa hàng',
        'phone': widget.customer.phone,
        'email': widget.customer.email,
        'is_primary': true,
        'is_active': true,
      });

      _loadData();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo cơ sở chính từ thông tin khách hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditContactDialog({CustomerContact? contact}) {
    showDialog(
      context: context,
      builder: (context) => ContactFormDialog(
        customerId: widget.customer.id,
        companyId: ref.read(currentUserProvider)?.companyId ?? '',
        addresses: _addresses,
        contact: contact,
        onSaved: () {
          _loadData();
          widget.onChanged?.call();
        },
      ),
    );
  }

  Future<void> _setAsPrimary(CustomerContact contact) async {
    try {
      // First, unset all primaries
      await supabase
          .from('customer_contacts')
          .update({'is_primary': false})
          .eq('customer_id', widget.customer.id);

      // Then set this one as primary
      await supabase
          .from('customer_contacts')
          .update({'is_primary': true})
          .eq('id', contact.id);

      _loadData();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã đặt "${contact.name}" làm cơ sở chính'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteContact(CustomerContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cơ sở "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('customer_contacts')
          .update({'is_active': false})
          .eq('id', contact.id);

      _loadData();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa cơ sở "${contact.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại'), backgroundColor: Colors.orange),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      AppLogger.error('Error making call', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.contacts, color: Colors.purple.shade600, size: 24),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách cơ sở / chi nhánh',
                      style: AppTextStyles.title,
                    ),
                    Text(
                      widget.customer.name,
                      style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
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
          AppSpacing.gapLG,

          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                            AppSpacing.gapSM,
                            Text('Lỗi: $_error'),
                            AppSpacing.gapLG,
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _contacts.isEmpty
                        ? _buildEmptyState()
                        : _buildContactList(),
          ),

          AppSpacing.gapLG,

          // Add new contact button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditContactDialog(),
              icon: Icon(Icons.add_business),
              label: Text('Thêm cơ sở mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppSpacing.paddingXXL,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
          ),
          AppSpacing.gapLG,
          Text(
            'Chưa có cơ sở nào',
            style: AppTextStyles.subtitle.copyWith(color: Colors.grey.shade600),
          ),
          AppSpacing.gapSM,
          Text(
            'Thêm cơ sở để quản lý liên hệ tại mỗi địa điểm',
            style: AppTextStyles.body.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLG,
          if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _createDefaultFromCustomer,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Tạo từ thông tin KH'),
            ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _contacts.length,
      separatorBuilder: (_, __) => AppSpacing.gapMD,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(CustomerContact contact) {
    return Container(
      decoration: BoxDecoration(
        color: contact.isPrimary ? Colors.purple.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isPrimary ? Colors.purple.shade300 : Colors.grey.shade200,
          width: contact.isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAddEditContactDialog(contact: contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CustomerAvatar(
                    seed: contact.name,
                    radius: 22,
                  ),
                  AppSpacing.hGapMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                contact.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: contact.isPrimary ? Colors.purple.shade700 : Theme.of(context).colorScheme.onSurface87,
                                ),
                              ),
                            ),
                            if (contact.isPrimary)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Chính',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.surface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (contact.position != null) ...[
                          AppSpacing.gapXXXS,
                          Text(
                            contact.position!,
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                        if (contact.addressName != null) ...[
                          AppSpacing.gapXXXS,
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.teal.shade400),
                              AppSpacing.hGapXXS,
                              Text(
                                contact.addressName!,
                                style: AppTextStyles.caption.copyWith(color: Colors.teal.shade600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Quick call button
                  if (contact.phone != null && contact.phone!.isNotEmpty)
                    IconButton(
                      onPressed: () => _makePhoneCall(contact.phone),
                      icon: const Icon(Icons.phone, color: Colors.green),
                      tooltip: 'Gọi ${contact.phone}',
                    ),
                  // Menu button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditContactDialog(contact: contact);
                          break;
                        case 'primary':
                          _setAsPrimary(contact);
                          break;
                        case 'delete':
                          _deleteContact(contact);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            AppSpacing.hGapSM,
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      if (!contact.isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 18),
                              AppSpacing.hGapSM,
                              Text('Đặt cơ sở chính'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            AppSpacing.hGapSM,
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Contact info row
              if (contact.phone != null || contact.email != null) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    if (contact.phone != null) ...[
                      Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade500),
                      AppSpacing.hGapXXS,
                      Text(
                        contact.phone!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      AppSpacing.hGapLG,
                    ],
                    if (contact.email != null) ...[
                      Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade500),
                      AppSpacing.hGapXXS,
                      Expanded(
                        child: Text(
                          contact.email!,
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog form to add/edit a customer contact
class ContactFormDialog extends StatefulWidget {
  final String customerId;
  final String companyId;
  final List<CustomerAddress> addresses;
  final CustomerContact? contact;
  final VoidCallback onSaved;

  const ContactFormDialog({
    super.key,
    required this.customerId,
    required this.companyId,
    required this.addresses,
    this.contact,
    required this.onSaved,
  });

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPosition;
  String? _selectedAddressId;
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      final c = widget.contact!;
      _nameController.text = c.name;
      _phoneController.text = c.phone ?? '';
      _emailController.text = c.email ?? '';
      _notesController.text = c.notes ?? '';
      _selectedPosition = c.position;
      _selectedAddressId = c.addressId;
      _isPrimary = c.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'customer_id': widget.customerId,
        'company_id': widget.companyId,
        'name': _nameController.text.trim(),
        'position': _selectedPosition,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
        'email': _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
        'address_id': _selectedAddressId,
        'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        'is_primary': _isPrimary,
        'is_active': true,
      };

      if (_isPrimary) {
        // Unset other primaries first
        await supabase
            .from('customer_contacts')
            .update({'is_primary': false})
            .eq('customer_id', widget.customerId);
      }

      if (widget.contact != null) {
        // Update
        await supabase
            .from('customer_contacts')
            .update(data)
            .eq('id', widget.contact!.id);
      } else {
        // Insert
        await supabase.from('customer_contacts').insert(data);
      }

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contact != null ? '✅ Đã cập nhật cơ sở' : '✅ Đã thêm cơ sở mới'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: AppSpacing.paddingLG,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.contact != null ? Icons.edit : Icons.person_add,
                    color: Colors.purple.shade700,
                  ),
                  AppSpacing.hGapMD,
                  Text(
                    widget.contact != null ? 'Sửa cơ sở' : 'Thêm cơ sở mới',
                    style: AppTextStyles.title,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLG,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên cơ sở *',
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên cơ sở' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      AppSpacing.gapLG,

                      // Position dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Chức vụ',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: ContactPositions.common.map((pos) {
                          return DropdownMenuItem(value: pos, child: Text(pos));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPosition = v),
                      ),
                      AppSpacing.gapLG,

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      AppSpacing.gapLG,

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      AppSpacing.gapLG,

                      // Address dropdown (optional)
                      if (widget.addresses.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedAddressId,
                          decoration: const InputDecoration(
                            labelText: 'Liên kết với địa chỉ (tùy chọn)',
                            prefixIcon: Icon(Icons.location_on),
                            helperText: 'Chọn cơ sở/chi nhánh mà người này phụ trách',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('-- Không liên kết --'),
                            ),
                            ...widget.addresses.map((addr) {
                              return DropdownMenuItem<String>(
                                value: addr.id,
                                child: Text(addr.name),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() => _selectedAddressId = v),
                        ),
                        AppSpacing.gapLG,
                      ],

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'VD: Gọi vào buổi sáng, Zalo: ...',
                        ),
                        maxLines: 2,
                      ),
                      AppSpacing.gapLG,

                      CheckboxListTile(
                        value: _isPrimary,
                        onChanged: (v) => setState(() => _isPrimary = v ?? false),
                        title: const Text('Đặt làm cơ sở chính'),
                        subtitle: const Text('Hiển thị đầu tiên khi tra cứu'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: AppSpacing.paddingLG,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy'),
                  ),
                  AppSpacing.hGapMD,
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface),
                          )
                        : Text(widget.contact != null ? 'Lưu thay đổi' : 'Thêm cơ sở'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
