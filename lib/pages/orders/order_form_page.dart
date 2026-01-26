import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  
  OdoriCustomer? _selectedCustomer;
  final List<_OrderLineItem> _orderItems = [];
  bool _isLoading = false;
  
  // Formatters
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Pre-select customer if provided
    if (widget.preselectedCustomer != null) {
      _selectedCustomer = widget.preselectedCustomer;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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
            // TODO: Add discount/tax logic here if needed
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KHÁCH PHẢI TRẢ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormat.format(subtotal),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ],
            ),
          ],
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

      // 1. Create Sales Order
      await supabase.from('sales_orders').insert({
        'id': orderId,
        'company_id': companyId,
        'order_number': orderNumber,
        'customer_id': _selectedCustomer!.id,
        'sale_id': authState.user?.id, // Employee who creates the order
        'order_date': DateTime.now().toIso8601String().split('T')[0], // date only
        'status': 'pending_approval', 
        'payment_status': 'unpaid',
        'subtotal': subtotal,
        'total': subtotal, // Match schema column name
        'notes': _notesController.text,
      });

      // 2. Create Order Items
      final orderItemsData = _orderItems.map((item) => {
        'id': const Uuid().v4(),
        'order_id': orderId,
        'product_id': item.product.id,
        'product_name': item.product.name,
        'product_sku': item.product.sku,
        'quantity': item.quantity,
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
                        (c.code?.toLowerCase().contains(_searchText) ?? false)
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone ?? customer.address ?? 'Không có thông tin'),
                      trailing: customer.type != null 
                          ? Chip(
                              label: Text(
                                customer.type == 'distributor' ? 'NPP' : 'ĐL',
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
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
                        (p.sku?.toLowerCase().contains(_searchText) ?? false) ||
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
