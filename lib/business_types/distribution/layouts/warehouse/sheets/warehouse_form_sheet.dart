import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sheet thêm/sửa thông tin kho
class WarehouseFormSheet extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic>? warehouse;
  final VoidCallback onSaved;

  const WarehouseFormSheet({
    super.key,
    required this.companyId,
    this.warehouse,
    required this.onSaved,
  });

  @override
  State<WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<WarehouseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedType = 'main';
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _warehouseTypes = [
    {'value': 'main', 'label': 'Kho chính', 'icon': Icons.home_work, 'color': Colors.blue},
    {'value': 'transit', 'label': 'Trung chuyển', 'icon': Icons.local_shipping, 'color': Colors.orange},
    {'value': 'vehicle', 'label': 'Xe tải', 'icon': Icons.local_shipping_outlined, 'color': Colors.green},
    {'value': 'virtual', 'label': 'Ảo', 'icon': Icons.cloud_outlined, 'color': Colors.purple},
  ];

  bool get _isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _nameController.text = widget.warehouse!['name'] ?? '';
      _codeController.text = widget.warehouse!['code'] ?? '';
      _addressController.text = widget.warehouse!['address'] ?? '';
      _selectedType = widget.warehouse!['type'] ?? 'main';
      _isActive = widget.warehouse!['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit : Icons.add_business,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Sửa thông tin kho' : 'Thêm kho mới',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEditing ? 'Cập nhật thông tin kho' : 'Điền thông tin kho cần tạo',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warehouse Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên kho *',
                        hintText: 'VD: Kho Bình Thạnh',
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên kho' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Warehouse Code
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Mã kho',
                        hintText: 'VD: KHO-BT-01',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warehouse Type
                    const Text(
                      'Loại kho',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _warehouseTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return InkWell(
                          onTap: () => setState(() => _selectedType = type['value']),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? (type['color'] as Color).withOpacity(0.1) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? type['color'] as Color : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? type['color'] as Color : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? type['color'] as Color : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        hintText: 'Nhập địa chỉ kho',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.location_on_outlined),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Active Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isActive ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle : Icons.block,
                            color: _isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  _isActive 
                                    ? 'Kho này có thể nhận và xuất hàng' 
                                    : 'Kho này không còn hoạt động',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isActive ? Colors.green.shade600 : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Submit Button
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWarehouse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Cập nhật kho' : 'Tạo kho mới',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      // Auto-generate code if empty (required NOT NULL field)
      final warehouseCode = _codeController.text.trim().isNotEmpty 
          ? _codeController.text.trim()
          : 'KHO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final data = {
        'name': _nameController.text.trim(),
        'code': warehouseCode,
        'type': _selectedType,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'is_active': _isActive,
      };

      if (_isEditing) {
        // Update existing warehouse
        await supabase
            .from('warehouses')
            .update(data)
            .eq('id', widget.warehouse!['id']);
      } else {
        // Insert new warehouse with company_id
        data['company_id'] = widget.companyId;
        await supabase.from('warehouses').insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật kho' : 'Đã tạo kho mới'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
