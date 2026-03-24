import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/odori_product.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../utils/app_logger.dart';
import 'inventory_constants.dart';

/// An item in the sample list: product + quantity
class _SampleItem {
  OdoriProduct? product;
  final TextEditingController quantityController;

  _SampleItem({String quantity = '1'})
      : quantityController = TextEditingController(text: quantity);

  void dispose() => quantityController.dispose();
}

// ==================== ADD SAMPLE SHEET ====================
class AddSampleSheet extends ConsumerStatefulWidget {
  final List<OdoriProduct> products;
  final VoidCallback onSaved;
  final String? preselectedCustomerId;
  final String? preselectedCustomerName;

  const AddSampleSheet({
    super.key,
    required this.products,
    required this.onSaved,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
  });

  @override
  ConsumerState<AddSampleSheet> createState() => _AddSampleSheetState();
}

class _AddSampleSheetState extends ConsumerState<AddSampleSheet> {
  // Multi-product sample list
  final List<_SampleItem> _sampleItems = [];

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  final _notesController = TextEditingController();
  String _customerSearchQuery = '';
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = false;
  bool _isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    // Start with one empty sample row
    _sampleItems.add(_SampleItem());
    // Pre-select customer if provided (e.g. from journey stop)
    if (widget.preselectedCustomerId != null) {
      _selectedCustomerId = widget.preselectedCustomerId;
      _selectedCustomerName = widget.preselectedCustomerName;
    }
    _loadCustomers();
  }

  @override
  void dispose() {
    for (final item in _sampleItems) {
      item.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _addSampleRow() {
    setState(() => _sampleItems.add(_SampleItem()));
  }

  void _removeSampleRow(int index) {
    if (_sampleItems.length <= 1) return;
    setState(() {
      _sampleItems[index].dispose();
      _sampleItems.removeAt(index);
    });
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
      final companyId = ref.read(currentUserProvider)?.companyId ?? '';
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
      AppLogger.error('Error loading customers: $e');
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
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? Colors.purple.shade50 : Theme.of(context).colorScheme.surface,
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
    // Validate: at least one product selected
    final validItems = _sampleItems.where((item) => item.product != null).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')),
      );
      return;
    }

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
      return;
    }

    // Validate quantities
    for (int i = 0; i < validItems.length; i++) {
      final qty = int.tryParse(validItems[i].quantityController.text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Số lượng ${validItems[i].product!.name} phải lớn hơn 0')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final companyId = ref.read(currentUserProvider)?.companyId ?? '';
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final userName = ref.read(currentUserProvider)?.displayName ?? '';

      // Calculate totals
      double subtotal = 0;
      for (final item in validItems) {
        final qty = int.tryParse(item.quantityController.text) ?? 0;
        subtotal += qty * item.product!.sellingPrice;
      }

      // Step 1: Create Sales Order with source = 'sample'
      final orderNumber = 'SM-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      final notesText = _notesController.text.trim();
      final orderResponse = await supabase.from('sales_orders').insert({
        'company_id': companyId,
        'customer_id': _selectedCustomerId,
        'order_number': orderNumber,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
        'order_type': 'sample',
        'status': 'pending_approval',
        'payment_status': 'unpaid',
        'delivery_status': 'pending',
        'source': 'app',
        'subtotal': subtotal,
        'total': subtotal,
        'sale_id': userId,
        'created_by': userId,
        'customer_name': _selectedCustomerName,
        'notes': '[MẪU SP] Gửi mẫu ${validItems.length} sản phẩm${notesText.isNotEmpty ? ' - $notesText' : ''}',
      }).select().single();

      final orderId = orderResponse['id'];

      // Step 2: Create Sales Order Items (batch)
      final orderItems = validItems.map((item) {
        final qty = int.tryParse(item.quantityController.text) ?? 0;
        return {
          'order_id': orderId,
          'product_id': item.product!.id,
          'product_sku': item.product!.sku,
          'product_name': item.product!.name,
          'unit': item.product!.unit,
          'quantity': qty,
          'unit_price': item.product!.sellingPrice,
          'line_total': qty * item.product!.sellingPrice,
        };
      }).toList();
      await supabase.from('sales_order_items').insert(orderItems);

      // Step 3: Create Product Sample records (batch)
      final sampleRecords = validItems.map((item) {
        final qty = int.tryParse(item.quantityController.text) ?? 0;
        return {
          'company_id': companyId,
          'order_id': orderId,
          'product_id': item.product!.id,
          'customer_id': _selectedCustomerId,
          'quantity': qty,
          'unit': item.product!.unit,
          'product_name': item.product!.name,
          'product_sku': item.product!.sku,
          'sent_by_id': userId,
          'sent_by_name': userName,
          'notes': notesText.isNotEmpty ? notesText : null,
          'status': 'pending',
          'sent_date': DateTime.now().toIso8601String(),
        };
      }).toList();
      await supabase.from('product_samples').insert(sampleRecords);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Đã gửi ${validItems.length} mẫu SP (đơn #$orderNumber)')),
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
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.card_giftcard, color: Colors.deepOrange.shade700, size: 20),
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

                // Customer Selector
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
                                child: Text(
                                  _selectedCustomerName ?? 'Chọn khách hàng...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedCustomerName != null ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 20),

                // Product list header
                Row(
                  children: [
                    const Text(
                      'Sản phẩm mẫu *',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${_sampleItems.where((i) => i.product != null).length} SP',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepOrange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sample item rows
                ...List.generate(_sampleItems.length, (index) {
                  return _buildSampleItemRow(index);
                }),

                // Add more button
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addSampleRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm sản phẩm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange.shade700,
                    side: BorderSide(color: Colors.deepOrange.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú...',
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
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveSample,
                        icon: _isLoading
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                              )
                            : Icon(Icons.send, size: 18),
                        label: Text('Gửi ${_sampleItems.where((i) => i.product != null).length} mẫu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  Widget _buildSampleItemRow(int index) {
    final item = _sampleItems[index];
    // Filter out already-selected products (except current)
    final usedProductIds = _sampleItems
        .where((s) => s != item && s.product != null)
        .map((s) => s.product!.id)
        .toSet();
    final availableProducts = widget.products
        .where((p) => !usedProductIds.contains(p.id) || p.id == item.product?.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: item.product != null ? Colors.deepOrange.shade200 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: item.product != null ? Colors.deepOrange.shade50.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Index badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Product dropdown
              Expanded(
                child: DropdownButtonFormField<OdoriProduct>(
                  value: item.product,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Chọn sản phẩm...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  items: availableProducts.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => item.product = value),
                ),
              ),
              // Remove button
              if (_sampleItems.length > 1) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _removeSampleRow(index),
                  icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Xóa',
                ),
              ],
            ],
          ),
          if (item.product != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 32),
                // Quantity
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'SL',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.product!.unit,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const Spacer(),
                // Price info
                Text(
                  '${_formatNumber(item.product!.sellingPrice)} đ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
