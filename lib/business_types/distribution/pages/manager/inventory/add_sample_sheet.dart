import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/odori_product.dart';
import '../../../../../providers/auth_provider.dart';
import 'inventory_constants.dart';

// ==================== ADD SAMPLE SHEET ====================
class AddSampleSheet extends ConsumerStatefulWidget {
  final List<OdoriProduct> products;
  final VoidCallback onSaved;

  const AddSampleSheet({
    super.key,
    required this.products,
    required this.onSaved,
  });

  @override
  ConsumerState<AddSampleSheet> createState() => _AddSampleSheetState();
}

class _AddSampleSheetState extends ConsumerState<AddSampleSheet> {
  OdoriProduct? _selectedProduct;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  String _customerSearchQuery = '';
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = false;
  bool _isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _filterCustomers(String query) {
    setState(() {
      _customerSearchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = (customer['name'] as String? ?? '').toLowerCase();
          final phone = (customer['phone'] as String? ?? '').toLowerCase();
          final address = (customer['address'] as String? ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower) || address.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('customers')
          .select('id, name, phone, address, contact_person, type')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        final customers = List<Map<String, dynamic>>.from(data);
        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  void _showCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chọn khách hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Search TextField
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên, SĐT, địa chỉ...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) => setState(() => _filterCustomers(value)),
              ),
              const SizedBox(height: 12),

              // Customer List
              Expanded(
                child: _filteredCustomers.isEmpty
                    ? Center(
                        child: Text(
                          _customerSearchQuery.isEmpty ? 'Chưa có khách hàng' : 'Không tìm thấy khách hàng',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final isSelected = customer['id'] == _selectedCustomerId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? Colors.purple.shade50 : Colors.white,
                            ),
                            child: ListTile(
                              onTap: () {
                                this.setState(() {
                                  _selectedCustomerId = customer['id'] as String;
                                  _selectedCustomerName = customer['name'] as String;
                                });
                                Navigator.pop(ctx);
                              },
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                customer['name'] as String? ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  if (customer['phone'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            customer['phone'] as String,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['address'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              customer['address'] as String,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['contact_person'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            customer['contact_person'] as String,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['type'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              customer['type'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected ? Icon(Icons.check, color: Colors.purple.shade700) : null,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSample() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm')),
      );
      return;
    }

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng phải lớn hơn 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final userId = ref.read(authProvider).user?.id ?? '';
      final userName = ref.read(authProvider).user?.displayName ?? '';

      // Step 1: Create Sales Order with order_type: 'sample'
      final orderNumber = 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final subtotal = quantity * (_selectedProduct!.sellingPrice ?? 0);
      
      final orderResponse = await supabase.from('sales_orders').insert({
        'company_id': companyId,
        'customer_id': _selectedCustomerId,
        'order_number': orderNumber,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'pending_approval',
        'payment_status': 'unpaid',
        'delivery_status': 'pending',
        'order_type': 'sample', // Mark as sample order
        'subtotal': subtotal,
        'total': subtotal,
        'sale_id': userId,
        'notes': 'Mẫu sản phẩm - ${_notesController.text.trim()}',
      }).select().single();

      final orderId = orderResponse['id'];

      // Step 2: Create Sales Order Item
      await supabase.from('sales_order_items').insert({
        'order_id': orderId,
        'product_id': _selectedProduct!.id,
        'product_sku': _selectedProduct!.sku,
        'product_name': _selectedProduct!.name,
        'unit': _selectedProduct!.unit,
        'quantity': quantity,
        'unit_price': _selectedProduct!.sellingPrice ?? 0,
        'line_total': subtotal,
      });

      // Step 3: Create Product Sample record with order link
      await supabase.from('product_samples').insert({
        'company_id': companyId,
        'order_id': orderId, // Link to sales order
        'product_id': _selectedProduct!.id,
        'customer_id': _selectedCustomerId,
        'quantity': quantity,
        'unit': _selectedProduct!.unit,
        'product_name': _selectedProduct!.name,
        'product_sku': _selectedProduct!.sku,
        'sent_by_id': userId,
        'sent_by_name': userName,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'status': 'pending',
        'sent_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Đã ghi nhận gửi mẫu (tạo đơn hàng #$orderNumber)')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.content_copy, color: Colors.purple.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gửi sản phẩm mẫu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Product Dropdown
                const Text(
                  'Sản phẩm *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<OdoriProduct>(
                  value: _selectedProduct,
                  decoration: InputDecoration(
                    hintText: 'Chọn sản phẩm...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProduct = value),
                ),

                const SizedBox(height: 16),

                // Customer Selector with Search
                const Text(
                  'Khách hàng *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _isLoadingCustomers
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: () => _showCustomerSelector(context),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedCustomerName ?? 'Chọn khách hàng...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedCustomerName != null ? Colors.black : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 16),

                // Quantity
                const Text(
                  'Số lượng *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nhập số lượng',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixText: _selectedProduct?.unit ?? 'cái',
                  ),
                ),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Ghi chú',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú về mẫu này...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSample,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Gửi mẫu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
