import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer_address.dart';
import '../business_types/distribution/models/odori_customer.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

/// Widget to manage customer delivery addresses
class CustomerAddressesSheet extends ConsumerStatefulWidget {
  final OdoriCustomer customer;
  final VoidCallback? onChanged;

  const CustomerAddressesSheet({
    super.key,
    required this.customer,
    this.onChanged,
  });

  @override
  ConsumerState<CustomerAddressesSheet> createState() => _CustomerAddressesSheetState();
}

class _CustomerAddressesSheetState extends ConsumerState<CustomerAddressesSheet> {
  List<CustomerAddress> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await supabase
          .from('customer_addresses')
          .select()
          .eq('customer_id', widget.customer.id)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('name');

      final addresses = (response as List)
          .map((json) => CustomerAddress.fromJson(json))
          .toList();

      setState(() {
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
    final companyId = ref.read(authProvider).user?.companyId;
    if (companyId == null) return;

    try {
      await supabase.from('customer_addresses').insert({
        'customer_id': widget.customer.id,
        'company_id': companyId,
        'name': 'Địa chỉ chính',
        'address': widget.customer.address ?? '',
        'street_number': widget.customer.streetNumber,
        'street': widget.customer.street,
        'ward': widget.customer.ward,
        'district': widget.customer.district,
        'city': widget.customer.city,
        'lat': widget.customer.lat,
        'lng': widget.customer.lng,
        'phone': widget.customer.phone,
        'contact_person': widget.customer.contactPerson,
        'is_default': true,
        'is_active': true,
      });

      _loadAddresses();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo địa chỉ mặc định từ thông tin khách hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditAddressDialog({CustomerAddress? address}) {
    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        customerId: widget.customer.id,
        companyId: ref.read(authProvider).user?.companyId ?? '',
        address: address,
        onSaved: () {
          _loadAddresses();
          widget.onChanged?.call();
        },
      ),
    );
  }

  Future<void> _setAsDefault(CustomerAddress address) async {
    try {
      // First, unset all defaults for this customer
      await supabase
          .from('customer_addresses')
          .update({'is_default': false})
          .eq('customer_id', widget.customer.id);

      // Then set this one as default
      await supabase
          .from('customer_addresses')
          .update({'is_default': true})
          .eq('id', address.id);

      _loadAddresses();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã đặt "${address.name}" làm địa chỉ mặc định'),
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

  Future<void> _deleteAddress(CustomerAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa địa chỉ "${address.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('customer_addresses')
          .update({'is_active': false})
          .eq('id', address.id);

      _loadAddresses();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa địa chỉ "${address.name}"'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(16),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Địa chỉ giao hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.customer.name,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
          const SizedBox(height: 16),

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
                            const SizedBox(height: 8),
                            Text('Lỗi: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAddresses,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _addresses.isEmpty
                        ? _buildEmptyState()
                        : _buildAddressList(),
          ),

          const SizedBox(height: 16),

          // Add new address button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditAddressDialog(),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Thêm địa chỉ mới'),
              style: ElevatedButton.styleFrom(
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có địa chỉ giao hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm địa chỉ giao hàng để tạo đơn nhanh hơn',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          if (widget.customer.address != null && widget.customer.address!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _createDefaultFromCustomer,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Tạo từ địa chỉ khách hàng'),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final addr = _addresses[index];
        return _buildAddressCard(addr);
      },
    );
  }

  Widget _buildAddressCard(CustomerAddress addr) {
    return Container(
      decoration: BoxDecoration(
        color: addr.isDefault ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: addr.isDefault ? Colors.blue.shade300 : Colors.grey.shade200,
          width: addr.isDefault ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAddEditAddressDialog(address: addr),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: addr.isDefault ? Colors.blue.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      addr.isDefault ? Icons.star : Icons.location_on_outlined,
                      size: 20,
                      color: addr.isDefault ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              addr.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: addr.isDefault ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Mặc định',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          addr.fullAddress,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditAddressDialog(address: addr);
                          break;
                        case 'default':
                          _setAsDefault(addr);
                          break;
                        case 'delete':
                          _deleteAddress(addr);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      if (!addr.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 18),
                              SizedBox(width: 8),
                              Text('Đặt mặc định'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (addr.phone != null || addr.contactPerson != null) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    if (addr.contactPerson != null) ...[
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        addr.contactPerson!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (addr.phone != null) ...[
                      Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        addr.phone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

/// Dialog form to add/edit a customer address
class AddressFormDialog extends StatefulWidget {
  final String customerId;
  final String companyId;
  final CustomerAddress? address;
  final VoidCallback onSaved;

  const AddressFormDialog({
    super.key,
    required this.customerId,
    required this.companyId,
    this.address,
    required this.onSaved,
  });

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final a = widget.address!;
      _nameController.text = a.name;
      _addressController.text = a.address;
      _streetNumberController.text = a.streetNumber ?? '';
      _streetController.text = a.street ?? '';
      _wardController.text = a.ward ?? '';
      _districtController.text = a.district ?? '';
      _cityController.text = a.city ?? '';
      _phoneController.text = a.phone ?? '';
      _contactPersonController.text = a.contactPerson ?? '';
      _notesController.text = a.notes ?? '';
      _isDefault = a.isDefault;
    } else {
      _cityController.text = 'Thành phố Hồ Chí Minh';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _streetNumberController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build full address
      final parts = <String>[];
      if (_streetNumberController.text.isNotEmpty) parts.add(_streetNumberController.text);
      if (_streetController.text.isNotEmpty) parts.add(_streetController.text);
      if (_wardController.text.isNotEmpty) parts.add(_wardController.text);
      if (_districtController.text.isNotEmpty) parts.add(_districtController.text);
      if (_cityController.text.isNotEmpty) parts.add(_cityController.text);

      final fullAddress = parts.isNotEmpty ? parts.join(', ') : _addressController.text;

      final data = {
        'customer_id': widget.customerId,
        'company_id': widget.companyId,
        'name': _nameController.text.trim(),
        'address': fullAddress,
        'street_number': _streetNumberController.text.isNotEmpty ? _streetNumberController.text.trim() : null,
        'street': _streetController.text.isNotEmpty ? _streetController.text.trim() : null,
        'ward': _wardController.text.isNotEmpty ? _wardController.text.trim() : null,
        'district': _districtController.text.isNotEmpty ? _districtController.text.trim() : null,
        'city': _cityController.text.isNotEmpty ? _cityController.text.trim() : null,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
        'contact_person': _contactPersonController.text.isNotEmpty ? _contactPersonController.text.trim() : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        'is_default': _isDefault,
        'is_active': true,
      };

      if (_isDefault) {
        // Unset other defaults first
        await supabase
            .from('customer_addresses')
            .update({'is_default': false})
            .eq('customer_id', widget.customerId);
      }

      if (widget.address != null) {
        // Update
        await supabase
            .from('customer_addresses')
            .update(data)
            .eq('id', widget.address!.id);
      } else {
        // Insert
        await supabase.from('customer_addresses').insert(data);
      }

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address != null ? '✅ Đã cập nhật địa chỉ' : '✅ Đã thêm địa chỉ mới'),
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
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.address != null ? Icons.edit_location : Icons.add_location,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.address != null ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên địa chỉ *',
                          hintText: 'VD: Kho chính, Chi nhánh Q7, Cơ sở 2...',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _streetNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Số nhà',
                                prefixIcon: Icon(Icons.pin),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Đường',
                                prefixIcon: Icon(Icons.route),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _wardController,
                        decoration: const InputDecoration(
                          labelText: 'Phường/Xã',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(
                                labelText: 'Quận/Huyện',
                                prefixIcon: Icon(Icons.map),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'Tỉnh/Thành phố',
                                prefixIcon: Icon(Icons.apartment),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ đầy đủ (nếu khác)',
                          hintText: 'Để trống để tự động tạo từ các trường trên',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      const Divider(),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactPersonController,
                              decoration: const InputDecoration(
                                labelText: 'Người liên hệ',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          hintText: 'VD: Gọi trước 30 phút, Giao trong giờ hành chính...',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      CheckboxListTile(
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v ?? false),
                        title: const Text('Đặt làm địa chỉ mặc định'),
                        subtitle: const Text('Sử dụng địa chỉ này khi tạo đơn hàng'),
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
              padding: const EdgeInsets.all(16),
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
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.address != null ? 'Lưu thay đổi' : 'Thêm địa chỉ'),
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
