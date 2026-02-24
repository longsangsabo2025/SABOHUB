import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;

import '../../../../../services/geocoding_service.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../providers/odori_providers.dart';

/// Form tạo/sửa khách hàng cho Sales
class SalesCustomerFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSaved;

  const SalesCustomerFormSheet({
    super.key,
    this.customer,
    required this.onSaved,
  });

  @override
  ConsumerState<SalesCustomerFormSheet> createState() => _SalesCustomerFormSheetState();
}

class _SalesCustomerFormSheetState extends ConsumerState<SalesCustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  
  // Vietnamese Address Selection
  dvhcvn.Level1? _selectedCity;
  dvhcvn.Level2? _selectedDistrict;
  dvhcvn.Level3? _selectedWard;
  List<dvhcvn.Level2> _districts = [];
  List<dvhcvn.Level3> _wards = [];
  
  String _selectedChannel = 'GT Sỉ';
  String _selectedType = 'retail';
  String _selectedStatus = 'active';
  String _selectedTier = 'bronze';
  String? _selectedReferrerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAddress();
    if (widget.customer != null) {
      _nameController.text = widget.customer!['name'] ?? '';
      _codeController.text = widget.customer!['code'] ?? '';
      _phoneController.text = widget.customer!['phone'] ?? '';
      _streetNumberController.text = widget.customer!['street_number'] ?? '';
      _streetController.text = widget.customer!['street'] ?? '';
      _creditLimitController.text = (widget.customer!['credit_limit'] ?? 0).toString();
      _paymentTermsController.text = (widget.customer!['payment_terms'] ?? 0).toString();
      _selectedChannel = widget.customer!['channel'] ?? 'GT Sỉ';
      _selectedType = widget.customer!['type'] ?? 'retail';
      _selectedStatus = widget.customer!['status'] ?? 'active';
      _selectedTier = widget.customer!['tier'] ?? 'bronze';
      _selectedReferrerId = widget.customer!['referrer_id'];
      _matchExistingAddress();
    } else {
      _creditLimitController.text = '0';
      _paymentTermsController.text = '0';
      _generateCustomerCode();
    }
  }
  
  void _initializeAddress() {
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      _selectedCity = hcm;
      _districts = hcm.children;
    }
  }
  
  void _matchExistingAddress() {
    if (widget.customer == null) return;
    final district = widget.customer!['district'] as String?;
    final ward = widget.customer!['ward'] as String?;
    
    if (district != null && district.isNotEmpty) {
      for (final d in _districts) {
        if (d.name.contains(district) || 
            district.contains(d.name.replaceAll(RegExp(r'^(Quận |Huyện |Thành phố |Thị xã )'), ''))) {
          setState(() {
            _selectedDistrict = d;
            _wards = d.children;
          });
          break;
        }
      }
    }
    if (ward != null && ward.isNotEmpty && _selectedDistrict != null) {
      for (final w in _wards) {
        if (w.name.contains(ward) || 
            ward.contains(w.name.replaceAll(RegExp(r'^(Phường |Xã |Thị trấn )'), ''))) {
          setState(() => _selectedWard = w);
          break;
        }
      }
    }
  }

  Future<void> _generateCustomerCode() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('customers')
          .select('code')
          .eq('company_id', companyId)
          .ilike('code', 'KH-%')
          .order('code', ascending: false)
          .limit(1);

      int nextNumber = 1;
      if (data is List && data.isNotEmpty) {
        final lastCode = data[0]['code'] as String?;
        if (lastCode != null && lastCode.startsWith('KH-')) {
          final numPart = lastCode.substring(3);
          nextNumber = (int.tryParse(numPart) ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _codeController.text = 'KH-${nextNumber.toString().padLeft(4, '0')}';
        });
      }
    } catch (e) {
      _codeController.text = 'KH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _streetNumberController.dispose();
    _streetController.dispose();
    _creditLimitController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      if (companyId == null || companyId.isEmpty) {
        throw Exception('Không tìm thấy company_id. Vui lòng đăng nhập lại.');
      }

      final supabase = Supabase.instance.client;

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

      // Auto-geocode address
      double? latitude;
      double? longitude;
      if (_selectedDistrict != null) {
        final coords = await GeocodingService.geocodeFromFields(
          streetNumber: _streetNumberController.text.trim(),
          street: _streetController.text.trim(),
          ward: _selectedWard?.name,
          district: _selectedDistrict?.name,
          city: _selectedCity?.name,
        );
        if (coords != null) {
          latitude = coords.lat;
          longitude = coords.lng;
        }
      }

      final customerData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().isEmpty 
            ? 'KH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
            : _codeController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'street_number': _streetNumberController.text.trim().isEmpty ? null : _streetNumberController.text.trim(),
        'street': _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        'ward': _selectedWard?.name.replaceAll(RegExp(r'^(Phường |Xã |Thị trấn )'), ''),
        'district': _selectedDistrict?.name.replaceAll(RegExp(r'^(Quận |Huyện |Thành phố |Thị xã )'), ''),
        'city': _selectedCity?.name.replaceAll(RegExp(r'^(Thành phố |Tỉnh )'), ''),
        'address': fullAddress.isEmpty ? null : fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'channel': _selectedChannel,
        'type': _selectedType,
        'status': _selectedStatus,
        'tier': _selectedTier,
        'referrer_id': _selectedReferrerId,
        'credit_limit': double.tryParse(_creditLimitController.text) ?? 0,
        'payment_terms': int.tryParse(_paymentTermsController.text) ?? 0,
        'company_id': companyId,
      };

      if (widget.customer != null) {
        await supabase
            .from('customers')
            .update(customerData)
            .eq('id', widget.customer!['id']);
      } else {
        await supabase.from('customers').insert(customerData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customer != null 
                ? 'Đã cập nhật khách hàng' 
                : 'Đã thêm khách hàng mới'),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.person_add,
                      color: Colors.indigo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng mới',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isEditing ? 'Cập nhật thông tin khách hàng' : 'Điền thông tin khách hàng mới',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Form fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên khách hàng *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value?.trim().isEmpty == true 
                    ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Mã KH',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Tự động',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: '0xxx xxx xxx',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final phone = value.trim();
                          if (!RegExp(r'^0\d{9,10}$').hasMatch(phone)) {
                            return 'SĐT phải 10-11 số, bắt đầu bằng 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // === Structured Address Section ===
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _streetNumberController,
                            decoration: InputDecoration(
                              labelText: 'Số',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _streetController,
                            decoration: InputDecoration(
                              labelText: 'Tên đường',
                              hintText: 'VD: Dương Đình Hội',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<dvhcvn.Level2>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'Quận/Huyện *',
                        prefixIcon: const Icon(Icons.location_city, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
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
                      validator: (value) => value == null ? 'Chọn quận/huyện' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<dvhcvn.Level3>(
                      value: _selectedWard,
                      decoration: InputDecoration(
                        labelText: 'Phường/Xã',
                        prefixIcon: const Icon(Icons.house, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      isExpanded: true,
                      items: _wards.map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(w.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedWard = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Kênh
              DropdownButtonFormField<String>(
                value: _selectedChannel,
                decoration: InputDecoration(
                  labelText: 'Kênh',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'Horeca', child: Text('Horeca')),
                  DropdownMenuItem(value: 'GT Sỉ', child: Text('GT Sỉ')),
                  DropdownMenuItem(value: 'GT Lẻ', child: Text('GT Lẻ')),
                ],
                onChanged: (value) => setState(() => _selectedChannel = value!),
              ),
              const SizedBox(height: 12),
              
              // Loại khách hàng
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Loại khách hàng',
                  prefixIcon: Icon(
                    _selectedType == 'distributor' ? Icons.business : 
                    _selectedType == 'wholesale' ? Icons.store :
                    _selectedType == 'horeca' ? Icons.restaurant :
                    _selectedType == 'other' ? Icons.more_horiz :
                    Icons.shopping_bag,
                    color: _selectedType == 'distributor' ? Colors.purple : 
                           _selectedType == 'wholesale' ? Colors.orange :
                           _selectedType == 'horeca' ? Colors.teal :
                           Colors.blue,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'retail', child: Text('🛒 Khách lẻ')),
                  DropdownMenuItem(value: 'wholesale', child: Text('🛍️ Khách sỉ')),
                  DropdownMenuItem(value: 'distributor', child: Text('🏢 Nhà phân phối (NPP)')),
                  DropdownMenuItem(value: 'horeca', child: Text('🍽️ Horeca')),
                  DropdownMenuItem(value: 'other', child: Text('📋 Khác')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),
              
              // Phân loại khách hàng (tier)
              DropdownButtonFormField<String>(
                value: _selectedTier,
                decoration: InputDecoration(
                  labelText: 'Phân loại khách hàng',
                  prefixIcon: Icon(
                    _selectedTier == 'diamond' ? Icons.diamond : Icons.workspace_premium,
                    color: _selectedTier == 'diamond' ? Colors.blue[300] :
                           _selectedTier == 'gold' ? Colors.amber[600] :
                           _selectedTier == 'silver' ? Colors.grey[400] :
                           Colors.brown[300],
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'diamond', child: Text('💎 Kim cương')),
                  DropdownMenuItem(value: 'gold', child: Text('🥇 Vàng')),
                  DropdownMenuItem(value: 'silver', child: Text('🥈 Bạc')),
                  DropdownMenuItem(value: 'bronze', child: Text('🥉 Đồng')),
                ],
                onChanged: (value) => setState(() => _selectedTier = value!),
              ),
              const SizedBox(height: 12),
              
              // Người giới thiệu
              Consumer(
                builder: (context, ref, _) {
                  final referrersAsync = ref.watch(activeReferrersProvider);
                  return referrersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Lỗi: $e'),
                    data: (referrers) {
                      if (referrers.isEmpty) return const SizedBox.shrink();
                      return DropdownButtonFormField<String?>(
                        value: _selectedReferrerId,
                        decoration: InputDecoration(
                          labelText: 'Người giới thiệu',
                          prefixIcon: const Icon(Icons.person_add_alt_1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('-- Không có --'),
                          ),
                          ...referrers.map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('${r.name} (${r.commissionRate}%)'),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedReferrerId = value),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _creditLimitController,
                      decoration: InputDecoration(
                        labelText: 'Hạn mức (VNĐ)',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentTermsController,
                      decoration: InputDecoration(
                        labelText: 'Ngày thanh toán',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: const Icon(Icons.toggle_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Ngưng hoạt động')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isEditing ? Icons.save : Icons.add, size: 20),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
