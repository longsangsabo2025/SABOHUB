import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../../providers/auth_provider.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../widgets/customer_avatar.dart';

/// Form tạo/sửa đơn hàng với customer đã chọn sẵn
class SalesCreateOrderFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? preselectedCustomer;
  final Map<String, dynamic>? existingOrder;

  const SalesCreateOrderFormPage({super.key, this.preselectedCustomer, this.existingOrder});

  @override
  ConsumerState<SalesCreateOrderFormPage> createState() => _SalesCreateOrderFormPageState();
}

class _SalesCreateOrderFormPageState extends ConsumerState<SalesCreateOrderFormPage> {
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = true;
  
  final _notesController = TextEditingController();
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
    _loadCustomersAndProducts();
    
    if (widget.existingOrder != null) {
      _notesController.text = widget.existingOrder!['notes'] ?? '';
      _loadExistingOrderItems();
    }
  }
  
  Future<void> _loadExistingOrderItems() async {
    try {
      final orderId = widget.existingOrder!['id'];
      final supabase = Supabase.instance.client;
      
      final itemsData = await supabase
          .from('sales_order_items')
          .select('*, products:product_id(id, name, sku, unit, selling_price)')
          .eq('order_id', orderId);
      
      setState(() {
        _orderItems = List<Map<String, dynamic>>.from(itemsData).map((item) {
          final product = item['products'] as Map<String, dynamic>?;
          return {
            'product': product ?? {'id': item['product_id'], 'name': item['product_name'], 'sku': item['product_sku'], 'unit': item['unit']},
            'quantity': item['quantity'],
            'unit_price': (item['unit_price'] ?? 0).toDouble(),
            'line_total': (item['line_total'] ?? 0).toDouble(),
          };
        }).toList();
      });
      
      if (widget.existingOrder!['customers'] != null) {
        _selectedCustomer = widget.existingOrder!['customers'];
      }
    } catch (e) {
      AppLogger.error('Failed to load order items', e);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomersAndProducts() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final customersData = await supabase
          .from('customers')
          .select('id, name, code, phone, address')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      final productsData = await supabase
          .from('products')
          .select('id, name, sku, unit, selling_price')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(customersData);
        _products = List<Map<String, dynamic>>.from(productsData);
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers/products', e);
      setState(() {
        _isLoadingCustomers = false;
        _isLoadingProducts = false;
      });
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final existingIndex = _orderItems.indexWhere((item) => item['product']['id'] == product['id']);

    if (existingIndex >= 0) {
      setState(() {
        _orderItems[existingIndex]['quantity']++;
        _orderItems[existingIndex]['line_total'] =
            _orderItems[existingIndex]['quantity'] * _orderItems[existingIndex]['unit_price'];
      });
    } else {
      setState(() {
        _orderItems.add({
          'product': product,
          'quantity': 1,
          'unit_price': (product['selling_price'] ?? 0).toDouble(),
          'line_total': (product['selling_price'] ?? 0).toDouble(),
        });
      });
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _orderItems[index]['quantity'] + delta;
      if (newQty <= 0) {
        _orderItems.removeAt(index);
      } else {
        _orderItems[index]['quantity'] = newQty;
        _orderItems[index]['line_total'] = newQty * _orderItems[index]['unit_price'];
      }
    });
  }

  double get _orderTotal {
    return _orderItems.fold(0.0, (sum, item) => sum + (item['line_total'] ?? 0));
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      final companyId = authState.user?.companyId;

      if (userId == null || companyId == null) {
        throw Exception('User not authenticated');
      }

      final supabase = Supabase.instance.client;
      
      String orderId;
      String orderNumber;
      
      if (_isEditing) {
        orderId = widget.existingOrder!['id'];
        orderNumber = widget.existingOrder!['order_number'];
        
        await supabase
            .from('sales_orders')
            .update({
              'customer_id': _selectedCustomer!['id'],
              'customer_name': _selectedCustomer!['name'],
              'total': _orderTotal,
              'subtotal': _orderTotal,
              'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);
        
        await supabase.from('sales_order_items').delete().eq('order_id', orderId);
      } else {
        orderNumber = 'SO${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        
        final orderResponse = await supabase
            .from('sales_orders')
            .insert({
              'company_id': companyId,
              'customer_id': _selectedCustomer!['id'],
              'customer_name': _selectedCustomer!['name'],
              'order_number': orderNumber,
              'order_date': DateTime.now().toIso8601String().split('T')[0],
              'total': _orderTotal,
              'subtotal': _orderTotal,
              'status': 'pending_approval',
              'payment_status': 'unpaid',
              'delivery_status': 'pending',
              'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
              'created_by': userId,
              'sale_id': userId,
            })
            .select('id')
            .single();
        
        orderId = orderResponse['id'];
      }

      final orderItemsData = _orderItems.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        return {
          'order_id': orderId,
          'product_id': product['id'],
          'product_name': product['name'],
          'product_sku': product['sku'],
          'unit': product['unit'] ?? 'cái',
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'line_total': item['line_total'],
        };
      }).toList();

      await supabase.from('sales_order_items').insert(orderItemsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Đơn hàng $orderNumber đã được cập nhật' 
                : 'Đơn hàng $orderNumber đã được tạo thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error(_isEditing ? 'Failed to update order' : 'Failed to create order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Lỗi cập nhật đơn: $e' : 'Lỗi tạo đơn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa đơn hàng' : 'Tạo đơn hàng'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submitOrder,
            icon: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(_isEditing ? 'Lưu' : 'Tạo đơn'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Khách hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (widget.preselectedCustomer != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Đã chọn sẵn', style: TextStyle(fontSize: 10, color: Colors.green)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _selectedCustomer != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                CustomerAvatar(
                                  seed: _selectedCustomer!['name'] ?? '?',
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedCustomer!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (_selectedCustomer!['phone'] != null)
                                        Text(_selectedCustomer!['phone'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => setState(() => _selectedCustomer = null),
                                ),
                              ],
                            ),
                          )
                        : _isLoadingCustomers
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<Map<String, dynamic>>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Chọn khách hàng',
                                ),
                                items: _customers.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c['name'] ?? ''),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedCustomer = value),
                              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showProductPicker,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_orderItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Chưa có sản phẩm', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _orderItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _orderItems[index];
                          final product = item['product'] as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                            ),
                            title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(currencyFormat.format(item['unit_price'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateQuantity(index, -1),
                                ),
                                Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes and delivery date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Ghi chú & Giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Ghi chú cho đơn hàng...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.teal),
                      title: const Text('Ngày giao dự kiến'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDeliveryDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng cộng', style: TextStyle(color: Colors.grey.shade600)),
                    Text(
                      currencyFormat.format(_orderTotal),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Tạo đơn hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductPicker() {
    final searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filteredProducts = query.isEmpty 
              ? _products 
              : _products.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  final sku = (p['sku'] ?? '').toString().toLowerCase();
                  return name.contains(query) || sku.contains(query);
                }).toList();
          
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text('Chọn sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${filteredProducts.length}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên hoặc SKU...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                      onPressed: () {
                                        searchController.clear();
                                        setModalState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _isLoadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Không tìm thấy sản phẩm', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final existingQty = _orderItems
                                      .where((item) => item['product']['id'] == product['id'])
                                      .fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
                                  
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                                    ),
                                    title: Text(product['name'] ?? ''),
                                    subtitle: Text(
                                      '${product['sku'] ?? ''} - ${currencyFormat.format(product['selling_price'] ?? 0)}',
                                    ),
                                    trailing: existingQty > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text('x$existingQty', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          )
                                        : const Icon(Icons.add_circle_outline, color: Colors.teal),
                                    onTap: () {
                                      _addProduct(product);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expectedDeliveryDate = picked);
    }
  }
}
