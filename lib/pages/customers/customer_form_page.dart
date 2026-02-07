import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;

import '../../business_types/distribution/providers/odori_providers.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key});

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  // Vietnamese Address Selection
  dvhcvn.Level1? _selectedCity;
  dvhcvn.Level2? _selectedDistrict;
  dvhcvn.Level3? _selectedWard;
  List<dvhcvn.Level2> _districts = [];
  List<dvhcvn.Level3> _wards = [];
  
  // State
  String _customerType = 'direct'; // direct, distributor, agent
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAddress();
  }
  
  void _initializeAddress() {
    // Default to Ho Chi Minh City
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      _selectedCity = hcm;
      _districts = hcm.children;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetNumberController.dispose();
    _streetController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm khách hàng mới'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('LƯU'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralInfoSection(),
              const SizedBox(height: 16),
              _buildAddressSection(),
              const SizedBox(height: 16),
              _buildContactInfoSection(),
              const SizedBox(height: 16),
              _buildAdditionalInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chung',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng / NPP *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên khách hàng';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _customerType,
              decoration: const InputDecoration(
                labelText: 'Loại khách hàng',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'direct', child: Text('Khách lẻ (Direct)')),
                DropdownMenuItem(value: 'distributor', child: Text('Nhà Phân Phối (NPP)')),
                DropdownMenuItem(value: 'agent', child: Text('Đại lý')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _customerType = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Địa chỉ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Số nhà + Tên đường
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _streetNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số nhà',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đường',
                      border: OutlineInputBorder(),
                      hintText: 'VD: Lê Văn Thọ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quận/Huyện dropdown
            DropdownButtonFormField<dvhcvn.Level2>(
              value: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'Quận/Huyện *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _districts.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                  _selectedWard = null;
                  _wards = value?.children ?? [];
                });
              },
              validator: (value) => value == null ? 'Vui lòng chọn Quận/Huyện' : null,
            ),
            const SizedBox(height: 16),
            
            // Phường/Xã dropdown
            DropdownButtonFormField<dvhcvn.Level3>(
              value: _selectedWard,
              decoration: const InputDecoration(
                labelText: 'Phường/Xã *',
                prefixIcon: Icon(Icons.house),
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _wards.map((w) => DropdownMenuItem(
                value: w,
                child: Text(w.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) => setState(() => _selectedWard = value),
              validator: (value) => value == null ? 'Vui lòng chọn Phường/Xã' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liên hệ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin khác',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'Mã số thuế',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) throw Exception('Không tìm thấy thông tin công ty');

      final customerId = const Uuid().v4();
      
      // Auto generate code: KH + Timestamp (simple logic)
      final customerCode = 'KH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      // Build full address from structured fields
      final addressParts = <String>[];
      if (_streetNumberController.text.trim().isNotEmpty) {
        addressParts.add(_streetNumberController.text.trim());
      }
      if (_streetController.text.trim().isNotEmpty) {
        addressParts.add(_streetController.text.trim());
      }
      if (_selectedWard != null) {
        addressParts.add(_selectedWard!.name);
      }
      if (_selectedDistrict != null) {
        addressParts.add(_selectedDistrict!.name);
      }
      if (_selectedCity != null) {
        addressParts.add(_selectedCity!.name);
      }
      final fullAddress = addressParts.join(', ');

      await supabase.from('customers').insert({
        'id': customerId,
        'company_id': companyId,
        'code': customerCode,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        // Structured address fields
        'street_number': _streetNumberController.text.trim().isNotEmpty ? _streetNumberController.text.trim() : null,
        'street': _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
        'ward': _selectedWard?.name.replaceAll('Phường ', '').replaceAll('Xã ', '').replaceAll('Thị trấn ', ''),
        'district': _selectedDistrict?.name.replaceAll('Quận ', '').replaceAll('Huyện ', '').replaceAll('Thành phố ', '').replaceAll('Thị xã ', ''),
        'city': _selectedCity?.name.replaceAll('Thành phố ', '').replaceAll('Tỉnh ', ''),
        'address': fullAddress.isNotEmpty ? fullAddress : null,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'tax_code': _taxIdController.text.trim().isNotEmpty ? _taxIdController.text.trim() : null,
        'type': _customerType,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thêm khách hàng thành công!'),
          backgroundColor: Colors.green,
        ));
         // Refresh customer list
        ref.invalidate(customersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
