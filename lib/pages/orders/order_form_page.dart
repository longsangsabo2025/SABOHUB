import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/odori_customer.dart';
import '../../models/odori_product.dart';
import '../../providers/odori_providers.dart';
import '../../providers/auth_provider.dart';

class OrderFormPage extends ConsumerStatefulWidget {
  final OdoriCustomer? preselectedCustomer;
  
  const OrderFormPage({super.key, this.preselectedCustomer});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  
  OdoriCustomer? _selectedCustomer;
  final List<_OrderLineItem> _orderItems = [];
  bool _isLoading = false;
  
  // Discount settings
  String _discountType = 'percent'; // 'percent' or 'fixed'
  double _discountValue = 0;
  
  // Warehouse selection
  List<Map<String, dynamic>> _warehouses = [];
  String? _selectedWarehouseId;
  String? _selectedWarehouseName;
  bool _isLoadingWarehouses = true;
  
  // Formatters
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Pre-select customer if provided
    if (widget.preselectedCustomer != null) {
      _selectedCustomer = widget.preselectedCustomer;
    }
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      if (companyId == null) return;
      
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('warehouses')
          .select('id, name, is_primary')
          .eq('company_id', companyId)
          .order('is_primary', ascending: false)
          .order('name', ascending: true);
      
      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(data);
        // Auto-select primary warehouse if exists
        final primaryWarehouse = _warehouses.firstWhere(
          (w) => w['is_primary'] == true,
          orElse: () => _warehouses.isNotEmpty ? _warehouses.first : {},
        );
        if (primaryWarehouse.isNotEmpty) {
          _selectedWarehouseId = primaryWarehouse['id'];
          _selectedWarehouseName = primaryWarehouse['name'];
        }
        _isLoadingWarehouses = false;
      });
    } catch (e) {
      setState(() => _isLoadingWarehouses = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn hàng mới'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submitOrder,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('TẠO ĐƠN'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerSection(),
                    const SizedBox(height: 16),
                    _buildWarehouseSection(),
                    const SizedBox(height: 16),
                    _buildItemsSection(),
                    const SizedBox(height: 16),
                    _buildTotalsSection(),
                    const SizedBox(height: 16),
                     TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Ghi chú đơn hàng...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Khách hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_selectedCustomer != null)
                  TextButton(
                    onPressed: _showSelectCustomerSheet,
                    child: const Text('Thay đổi'),
                  )
                else
                  ElevatedButton(
                    onPressed: _showSelectCustomerSheet,
                    child: const Text('Chọn khách hàng'),
                  ),
              ],
            ),
            if (_selectedCustomer != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedCustomer!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_selectedCustomer!.phone ?? 'Chưa có SĐT'),
                trailing: Chip(
                  label: Text(_selectedCustomer!.type == 'distributor' ? 'NPP' : 'Đại lý'),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warehouse, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Kho xuất hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingWarehouses)
              const Center(child: CircularProgressIndicator())
            else if (_warehouses.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Chưa có kho nào. Vui lòng tạo kho trước.'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedWarehouseId,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.inventory_2, color: Colors.orange.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _warehouses.map((warehouse) {
                  final isPrimary = warehouse['is_primary'] == true;
                  return DropdownMenuItem<String>(
                    value: warehouse['id'],
                    child: Row(
                      children: [
                        Text(warehouse['name'] ?? 'Kho'),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Chính',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWarehouseId = value;
                    _selectedWarehouseName = _warehouses
                        .firstWhere((w) => w['id'] == value)['name'];
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn kho';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    if (_orderItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Chưa có sản phẩm nào'),
                const Text('Bấm "Thêm sản phẩm" để bắt đầu', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Danh sách sản phẩm (${_orderItems.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _orderItems[index];
              return ListTile(
                title: Text(item.product.name),
                subtitle: Text('${_currencyFormat.format(item.price)} / ${item.product.unit}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _updateQuantity(index, item.quantity - 1),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.quantity.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () => _updateQuantity(index, item.quantity + 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final subtotal = _orderItems.fold<double>(0, (sum, item) => sum + item.total);
    
    // Calculate discount amount
    double discountAmount = 0;
    if (_discountValue > 0) {
      if (_discountType == 'percent') {
        discountAmount = subtotal * (_discountValue / 100);
      } else {
        discountAmount = _discountValue;
      }
    }
    // Ensure discount doesn't exceed subtotal
    if (discountAmount > subtotal) discountAmount = subtotal;
    
    final total = subtotal - discountAmount;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền hàng:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(subtotal),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Discount input section
            Row(
              children: [
                const Icon(Icons.discount_outlined, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Chiết khấu:', style: TextStyle(fontSize: 14)),
                const Spacer(),
                // Toggle between % and VND
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDiscountTypeButton('%', 'percent'),
                      _buildDiscountTypeButton('VNĐ', 'fixed'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: _discountType == 'percent' ? '0%' : '0đ',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _discountValue = double.tryParse(value.replaceAll(',', '').replaceAll('.', '')) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giảm giá (${_discountType == 'percent' ? '${_discountValue.toStringAsFixed(0)}%' : ''}):',
                    style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                  ),
                  Text(
                    '-${_currencyFormat.format(discountAmount)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KHÁCH PHẢI TRẢ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormat.format(total),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTypeButton(String label, String type) {
    final isSelected = _discountType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _discountType = type;
          _discountController.clear();
          _discountValue = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  void _updateQuantity(int index, double newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _orderItems.removeAt(index);
      } else {
        _orderItems[index].quantity = newQuantity;
      }
    });
  }

  void _showSelectCustomerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CustomerSelectionSheet(
        onSelect: (customer) {
          setState(() => _selectedCustomer = customer);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ProductSelectionSheet(
        onSelect: (product) {
          setState(() {
            final existingIndex = _orderItems.indexWhere((i) => i.product.id == product.id);
            if (existingIndex >= 0) {
              _orderItems[existingIndex].quantity += 1;
            } else {
              _orderItems.add(_OrderLineItem(product: product, quantity: 1));
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khách hàng')));
      return;
    }
    if (_selectedWarehouseId == null || _selectedWarehouseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn kho xuất hàng')));
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm sản phẩm')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) throw Exception('Không tìm thấy thông tin công ty');

      final orderId = const Uuid().v4();
      final orderNumber = 'SO-${DateFormat('yyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      final subtotal = _orderItems.fold<double>(0, (sum, item) => sum + item.total);

      // Calculate discount
      double discountPercent = 0;
      double discountAmount = 0;
      if (_discountValue > 0) {
        if (_discountType == 'percent') {
          discountPercent = _discountValue;
          discountAmount = subtotal * (_discountValue / 100);
        } else {
          discountAmount = _discountValue;
          // Calculate percent for record keeping
          discountPercent = subtotal > 0 ? (discountAmount / subtotal * 100) : 0;
        }
      }
      // Ensure discount doesn't exceed subtotal
      if (discountAmount > subtotal) discountAmount = subtotal;
      
      final total = subtotal - discountAmount;

      // 1. Create Sales Order
      await supabase.from('sales_orders').insert({
        'id': orderId,
        'company_id': companyId,
        'order_number': orderNumber,
        'customer_id': _selectedCustomer!.id,
        'sale_id': authState.user?.id, // Employee who creates the order
        'warehouse_id': _selectedWarehouseId,
        'order_date': DateTime.now().toIso8601String().split('T')[0], // date only
        'status': 'pending_approval', 
        'payment_status': 'unpaid',
        'subtotal': subtotal,
        'discount_percent': discountPercent,
        'discount_amount': discountAmount,
        'total': total,
        'notes': _notesController.text,
      });

      // 2. Create Order Items
      final orderItemsData = _orderItems.map((item) => {
        'id': const Uuid().v4(),
        'order_id': orderId,
        'product_id': item.product.id,
        'product_name': item.product.name,
        'product_sku': item.product.sku,
        'quantity': item.quantity.toInt(), // Must be integer for database
        'unit': item.product.unit,
        'unit_price': item.price,
        'line_total': item.total,
      }).toList();

      await supabase.from('sales_order_items').insert(orderItemsData);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tạo đơn hàng thành công!'),
          backgroundColor: Colors.green,
        ));
        // Refresh orders list
        ref.invalidate(salesOrdersProvider);
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

class _OrderLineItem {
  final OdoriProduct product;
  double quantity;

  _OrderLineItem({required this.product, required this.quantity});

  double get price => product.sellingPrice;
  double get total => price * quantity;
}

// ============================================================================
// TEMPORARY SELECTION SHEETS (Should be separate widgets usually)
// ============================================================================

class _CustomerSelectionSheet extends ConsumerStatefulWidget {
  final Function(OdoriCustomer) onSelect;

  const _CustomerSelectionSheet({required this.onSelect});

  @override
  ConsumerState<_CustomerSelectionSheet> createState() => _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState extends ConsumerState<_CustomerSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchText = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use simple provider instead of filtered one
    final customersAsync = ref.watch(allCustomersProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm khách hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
              autofocus: true,
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Lỗi: $err', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allCustomersProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (allCustomers) {
                // Local filter
                final customers = _searchText.isEmpty 
                    ? allCustomers 
                    : allCustomers.where((c) => 
                        c.name.toLowerCase().contains(_searchText) ||
                        (c.phone?.toLowerCase().contains(_searchText) ?? false) ||
                        c.code.toLowerCase().contains(_searchText)
                      ).toList();
                      
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          _searchText.isEmpty 
                              ? 'Chưa có khách hàng nào' 
                              : 'Không tìm thấy "$_searchText"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerListTile(
                      customer: customer,
                      onTap: () => widget.onSelect(customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Customer List Tile with more information
class _CustomerListTile extends StatelessWidget {
  final OdoriCustomer customer;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.customer,
    required this.onTap,
  });

  /// Build full address from structured fields (same as customers_page.dart)
  String _buildFullAddress() {
    final parts = <String>[];
    if (customer.streetNumber != null && customer.streetNumber!.isNotEmpty) {
      parts.add(customer.streetNumber!);
    }
    if (customer.street != null && customer.street!.isNotEmpty) {
      parts.add(customer.street!);
    }
    if (customer.ward != null && customer.ward!.isNotEmpty) {
      // Add "Phường" prefix if it's a number
      final isNumber = int.tryParse(customer.ward!) != null;
      parts.add(isNumber ? 'Phường ${customer.ward}' : customer.ward!);
    }
    if (customer.district != null && customer.district!.isNotEmpty) {
      // Add "Quận" prefix if it's a number
      final isNumber = int.tryParse(customer.district!) != null;
      parts.add(isNumber ? 'Quận ${customer.district}' : customer.district!);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Build address display using standard format
    final addressDisplay = _buildFullAddress();
    final hasAddress = addressDisplay.isNotEmpty;

    // Customer type label and color
    String typeLabel = '';
    Color typeColor = Colors.grey;
    if (customer.type != null) {
      switch (customer.type) {
        case 'distributor':
          typeLabel = 'NPP';
          typeColor = Colors.purple;
          break;
        case 'agent':
          typeLabel = 'ĐL';
          typeColor = Colors.blue;
          break;
        case 'direct':
          typeLabel = 'TT';
          typeColor = Colors.green;
          break;
        default:
          typeLabel = customer.type!.toUpperCase();
          typeColor = Colors.grey;
      }
    }

    // Channel display
    String? channelLabel;
    if (customer.channel != null) {
      switch (customer.channel) {
        case 'horeca':
          channelLabel = 'HoReCa';
          break;
        case 'retail':
          channelLabel = 'Bán lẻ';
          break;
        case 'wholesale':
          channelLabel = 'Sỉ';
          break;
        default:
          channelLabel = customer.channel;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Avatar with type indicator
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  radius: 24,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (customer.hasLocation)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.location_on, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Customer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and code
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer.code.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer.code,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phone
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (customer.phone2 != null && customer.phone2!.isNotEmpty)
                          Text(
                            ' • ${customer.phone2}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  // Address
                  if (hasAddress)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              addressDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Tags row: Type, Channel, Payment Terms
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (typeLabel.isNotEmpty)
                          _buildTag(typeLabel, typeColor),
                        if (channelLabel != null)
                          _buildTag(channelLabel, Colors.orange),
                        if (customer.paymentTerms > 0)
                          _buildTag('${customer.paymentTerms} ngày', Colors.teal),
                        if (customer.assignedSaleName != null)
                          _buildTag('NV: ${customer.assignedSaleName}', Colors.indigo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProductSelectionSheet extends ConsumerStatefulWidget {
  final Function(OdoriProduct) onSelect;

  const _ProductSelectionSheet({required this.onSelect});

  @override
  ConsumerState<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends ConsumerState<_ProductSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchText = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use simple provider instead of filtered one
    final productsAsync = ref.watch(allProductsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
              autofocus: true,
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Lỗi: $err', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allProductsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (allProducts) {
                // Local filter
                final products = _searchText.isEmpty 
                    ? allProducts 
                    : allProducts.where((p) => 
                        p.name.toLowerCase().contains(_searchText) ||
                        p.sku.toLowerCase().contains(_searchText) ||
                        (p.barcode?.toLowerCase().contains(_searchText) ?? false)
                      ).toList();
                      
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          _searchText.isEmpty 
                              ? 'Chưa có sản phẩm nào' 
                              : 'Không tìm thấy "$_searchText"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: product.imageUrl != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl!, 
                              width: 48, 
                              height: 48, 
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.inventory_2, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.inventory_2, color: Colors.blue.shade300),
                          ),
                      title: Text(product.name),
                      subtitle: Text('SKU: ${product.sku} • ${product.unit}'),
                      trailing: Text(
                        currencyFormat.format(product.sellingPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      onTap: () => widget.onSelect(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
