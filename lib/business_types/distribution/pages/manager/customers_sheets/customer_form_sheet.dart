import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;

import '../../../models/odori_customer.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../providers/odori_providers.dart';

final _supabase = Supabase.instance.client;

// ==================== CUSTOMER FORM SHEET ====================
class CustomerFormSheet extends ConsumerStatefulWidget {
  final OdoriCustomer? customer;
  final Function(OdoriCustomer) onSaved;

  const CustomerFormSheet({
    super.key,
    this.customer,
    required this.onSaved,
  });

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
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
  String _selectedStatus = 'active';
  String _selectedTier = 'bronze';
  String? _selectedReferrerId;
  bool _isLoading = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _initializeAddress();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _codeController.text = widget.customer!.code;
      _phoneController.text = widget.customer!.phone ?? '';
      _streetNumberController.text = widget.customer!.streetNumber ?? '';
      _streetController.text = widget.customer!.street ?? '';
      _creditLimitController.text = widget.customer!.creditLimit.toString();
      _paymentTermsController.text = widget.customer!.paymentTerms.toString();
      _selectedChannel = widget.customer!.channel ?? 'GT Sỉ';
      _selectedStatus = widget.customer!.status;
      _selectedTier = widget.customer!.tier;
      _selectedReferrerId = widget.customer!.referrerId;
      
      // Try to match existing address to dropdowns
      _matchExistingAddress();
    } else {
      _creditLimitController.text = '0';
      _paymentTermsController.text = '0';
      // Tự động tạo mã KH cho khách hàng mới
      _generateCustomerCode();
    }
  }
  
  /// Tự động tạo mã KH theo format KH-XXXX (số tự tăng)
  Future<void> _generateCustomerCode() async {
    setState(() => _isGeneratingCode = true);
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;
      
      // Lấy mã KH lớn nhất hiện có với format KH-XXXX
      final response = await _supabase
          .from('customers')
          .select('code')
          .eq('company_id', companyId)
          .like('code', 'KH-%')
          .order('code', ascending: false)
          .limit(1);
      
      int nextNumber = 1;
      if ((response as List).isNotEmpty) {
        final lastCode = response[0]['code'] as String?;
        if (lastCode != null && lastCode.startsWith('KH-')) {
          final numberPart = lastCode.substring(3);
          final parsed = int.tryParse(numberPart);
          if (parsed != null) {
            nextNumber = parsed + 1;
          }
        }
      }
      
      final newCode = 'KH-${nextNumber.toString().padLeft(4, '0')}';
      if (mounted) {
        setState(() {
          _codeController.text = newCode;
          _isGeneratingCode = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error generating customer code: $e');
      // Fallback to timestamp-based code
      if (mounted) {
        setState(() {
          _codeController.text = 'KH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
          _isGeneratingCode = false;
        });
      }
    }
  }
  
  void _initializeAddress() {
    // Default to Ho Chi Minh City
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      _selectedCity = hcm;
      _districts = hcm.children;
    }
  }
  
  void _matchExistingAddress() {
    if (widget.customer == null) return;
    
    final customer = widget.customer!;
    
    // Try to match district
    if (customer.district != null && _selectedCity != null) {
      for (var d in _districts) {
        if (d.name.contains(customer.district!) || 
            customer.district!.contains(d.name.replaceAll('Quận ', '').replaceAll('Huyện ', ''))) {
          _selectedDistrict = d;
          _wards = d.children;
          break;
        }
      }
    }
    
    // Try to match ward
    if (customer.ward != null && _selectedDistrict != null) {
      for (var w in _wards) {
        if (w.name.contains(customer.ward!) ||
            customer.ward!.contains(w.name.replaceAll('Phường ', '').replaceAll('Xã ', ''))) {
          _selectedWard = w;
          break;
        }
      }
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

      final customerData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().isEmpty 
            ? 'KH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
            : _codeController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'street_number': _streetNumberController.text.trim().isEmpty ? null : _streetNumberController.text.trim(),
        'street': _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        'ward': _selectedWard?.name.replaceAll('Phường ', '').replaceAll('Xã ', '').replaceAll('Thị trấn ', ''),
        'district': _selectedDistrict?.name.replaceAll('Quận ', '').replaceAll('Huyện ', '').replaceAll('Thành phố ', '').replaceAll('Thị xã ', ''),
        'city': _selectedCity?.name.replaceAll('Thành phố ', '').replaceAll('Tỉnh ', ''),
        'address': fullAddress.isEmpty ? null : fullAddress,
        'channel': _selectedChannel,
        'status': _selectedStatus,
        'tier': _selectedTier,
        'referrer_id': _selectedReferrerId,
        'credit_limit': double.tryParse(_creditLimitController.text) ?? 0,
        'payment_terms': int.tryParse(_paymentTermsController.text) ?? 0,
        'company_id': companyId,
      };

      if (widget.customer != null) {
        await _supabase
            .from('customers')
            .update(customerData)
            .eq('id', widget.customer!.id);
      } else {
        await _supabase.from('customers').insert(customerData);
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
        widget.onSaved(widget.customer ?? OdoriCustomer(
          id: '', 
          code: customerData['code'] as String, 
          name: customerData['name'] as String,
          companyId: companyId,
          status: _selectedStatus,
          createdAt: DateTime.now(),
        ));
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
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.person_add,
                    color: Colors.teal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách hàng *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
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
                        prefixIcon: _isGeneratingCode 
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.tag),
                        border: const OutlineInputBorder(),
                        hintText: 'Tự động tạo',
                        suffixIcon: widget.customer == null
                            ? IconButton(
                                icon: Icon(Icons.refresh, color: Colors.teal.shade400),
                                onPressed: _isGeneratingCode ? null : _generateCustomerCode,
                                tooltip: 'Tạo mã mới',
                              )
                            : null,
                      ),
                      readOnly: widget.customer == null && _isGeneratingCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        hintText: '0903xxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final phone = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (phone.length < 10 || phone.length > 11) {
                          return 'SĐT phải có 10-11 số';
                        }
                        if (!phone.startsWith('0')) {
                          return 'SĐT phải bắt đầu bằng 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // === ĐỊA CHỈ VIỆT NAM ===
              const Text(
                '📍 Địa chỉ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              
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
              const SizedBox(height: 12),
              
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
              const SizedBox(height: 12),
              
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
              const SizedBox(height: 16),
              
              // === THÔNG TIN KINH DOANH ===
              const Text(
                '💼 Thông tin kinh doanh',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              
              // Kênh bán hàng
              DropdownButtonFormField<String>(
                value: _selectedChannel,
                decoration: const InputDecoration(
                  labelText: 'Kênh',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Horeca', child: Text('Horeca')),
                  DropdownMenuItem(value: 'GT Sỉ', child: Text('GT Sỉ')),
                  DropdownMenuItem(value: 'GT Lẻ', child: Text('GT Lẻ')),
                ],
                onChanged: (value) => setState(() => _selectedChannel = value!),
              ),
              const SizedBox(height: 12),
              
              // Phân loại khách hàng
              DropdownButtonFormField<String>(
                value: _selectedTier,
                decoration: const InputDecoration(
                  labelText: 'Phân loại khách hàng',
                  prefixIcon: Icon(Icons.star),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'diamond',
                    child: Row(
                      children: [
                        Icon(Icons.diamond, color: Colors.blue[300], size: 20),
                        const SizedBox(width: 8),
                        const Text('💎 Kim cương'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'gold',
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.amber[600], size: 20),
                        const SizedBox(width: 8),
                        const Text('🥇 Vàng'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'silver',
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        const Text('🥈 Bạc'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bronze',
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.brown[300], size: 20),
                        const SizedBox(width: 8),
                        const Text('🥉 Đồng'),
                      ],
                    ),
                  ),
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
                        decoration: const InputDecoration(
                          labelText: 'Người giới thiệu',
                          prefixIcon: Icon(Icons.person_add_alt_1),
                          border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Hạn mức (VNĐ)',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentTermsController,
                      decoration: const InputDecoration(
                        labelText: 'Ngày thanh toán',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.toggle_on),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('🟢 Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('🔴 Ngưng hoạt động')),
                  DropdownMenuItem(value: 'archived', child: Text('📦 Lưu trữ')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
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
