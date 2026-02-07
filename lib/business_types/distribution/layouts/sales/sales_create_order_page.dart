import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../widgets/sales_features_widgets.dart';
import '../../widgets/sales_features_widgets_2.dart';
import '../../../../widgets/customer_avatar.dart';

/// Create Order Page - Modern UI for Sales
class SalesCreateOrderPage extends ConsumerStatefulWidget {
  const SalesCreateOrderPage({super.key});

  @override
  ConsumerState<SalesCreateOrderPage> createState() => _SalesCreateOrderPageState();
}

class _SalesCreateOrderPageState extends ConsumerState<SalesCreateOrderPage> {
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = true;
  
  final _notesController = TextEditingController();
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomersAndProducts();
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
        SnackBar(
          content: const Row(
            children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 12), Text('Vui lòng chọn khách hàng')],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 12), Text('Vui lòng thêm ít nhất 1 sản phẩm')],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // === Check overdue receivables & credit limit before allowing order ===
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId != null && _selectedCustomer != null) {
        final cf = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

        // 1. Check credit limit
        final custData = await Supabase.instance.client
            .from('customers')
            .select('credit_limit, total_debt')
            .eq('id', _selectedCustomer!['id'])
            .maybeSingle();
        if (custData != null) {
          final creditLimit = ((custData['credit_limit'] ?? 0) as num).toDouble();
          final totalDebt = ((custData['total_debt'] ?? 0) as num).toDouble();
          if (creditLimit > 0 && (totalDebt + _orderTotal) > creditLimit) {
            if (!mounted) return;
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(children: [
                  Icon(Icons.credit_card_off, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text('Vượt hạn mức'),
                ]),
                content: Text(
                  'Đơn hàng sẽ vượt hạn mức tín dụng:\n\n'
                  '• Hạn mức: ${cf.format(creditLimit)}\n'
                  '• Nợ hiện tại: ${cf.format(totalDebt)}\n'
                  '• Đơn mới: ${cf.format(_orderTotal)}\n'
                  '• Tổng sau đơn: ${cf.format(totalDebt + _orderTotal)}\n\n'
                  'Vượt: ${cf.format(totalDebt + _orderTotal - creditLimit)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Vẫn tạo đơn', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (proceed != true) return;
          }
        }

        // 2. Check overdue receivables
        final overdueCheck = await Supabase.instance.client
            .from('receivables')
            .select('id, original_amount, paid_amount, due_date')
            .eq('company_id', companyId)
            .eq('customer_id', _selectedCustomer!['id'])
            .eq('status', 'overdue')
            .limit(5);
        if (overdueCheck is List && overdueCheck.isNotEmpty) {
          final totalOverdue = (overdueCheck as List).fold<double>(
              0, (s, r) => s + (((r['original_amount'] ?? 0) as num).toDouble() - ((r['paid_amount'] ?? 0) as num).toDouble()));
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text('Khách hàng quá hạn'),
              ]),
              content: Text(
                'Khách hàng này có ${overdueCheck.length} khoản nợ quá hạn '
                'với tổng ${cf.format(totalOverdue)}.\n\n'
                'Bạn có chắc muốn tiếp tục tạo đơn?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Vẫn tạo đơn', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }
    } catch (_) {
      // Non-blocking: if check fails, allow order to proceed
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) throw Exception('Missing company or user ID');

      final supabase = Supabase.instance.client;
      final orderNumber = 'SO-${DateTime.now().millisecondsSinceEpoch}';

      final orderData = await supabase
          .from('sales_orders')
          .insert({
            'company_id': companyId,
            'customer_id': _selectedCustomer!['id'],
            'sale_id': userId,
            'order_number': orderNumber,
            'order_date': DateTime.now().toIso8601String().split('T')[0],
            'status': 'pending_approval',
            'delivery_status': 'pending',
            'subtotal': _orderTotal,
            'total': _orderTotal,
            'notes': _notesController.text,
          })
          .select()
          .single();

      final orderId = orderData['id'];
      for (var item in _orderItems) {
        await supabase.from('sales_order_items').insert({
          'order_id': orderId,
          'product_id': item['product']['id'],
          'product_name': item['product']['name'],
          'product_sku': item['product']['sku'],
          'unit': item['product']['unit'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'line_total': item['line_total'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Text('✅ Đã tạo đơn hàng $orderNumber')],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        setState(() {
          _selectedCustomer = null;
          _orderItems.clear();
          _notesController.clear();
          _expectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
        });
      }
    } catch (e) {
      AppLogger.error('Failed to create order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tạo đơn: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.add_shopping_cart, color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tạo đơn hàng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Chọn khách hàng và sản phẩm', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer selector
                    _buildSectionTitle('Khách hàng', Icons.person),
                    const SizedBox(height: 8),
                    _buildCustomerSelector(),

                    // Active Promotions
                    const SizedBox(height: 16),
                    const ActivePromotionsList(),

                    // Product recommendations for selected customer
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 16),
                      ProductRecommendations(
                        customerId: _selectedCustomer!['id'],
                        onProductSelected: (product) => _addProduct(product),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Product selector
                    _buildSectionTitle('Sản phẩm', Icons.inventory_2),
                    const SizedBox(height: 8),
                    _buildProductSelector(),

                    const SizedBox(height: 16),

                    // Order items
                    if (_orderItems.isNotEmpty) ...[
                      _buildSectionTitle('Giỏ hàng (${_orderItems.length})', Icons.shopping_cart),
                      const SizedBox(height: 8),
                      ..._orderItems.asMap().entries.map((entry) => _buildOrderItemCard(entry.key, entry.value)),

                      // Order total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG CỘNG:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            Text(currencyFormat.format(_orderTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Delivery info
                    _buildSectionTitle('Giao hàng', Icons.local_shipping),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ngày giao dự kiến', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _expectedDeliveryDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (picked != null) setState(() => _expectedDeliveryDate = picked);
                                },
                                child: const Text('Đổi'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú',
                              hintText: 'Ghi chú cho đơn hàng...',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Đang tạo...' : 'TẠO ĐƠN HÀNG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    if (_isLoadingCustomers) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      onTap: _showCustomerPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _selectedCustomer != null ? Colors.green : Colors.grey.shade300, width: _selectedCustomer != null ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _selectedCustomer != null ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_selectedCustomer != null ? Icons.check_circle : Icons.person_add, color: _selectedCustomer != null ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCustomer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedCustomer!['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_selectedCustomer!['phone'] ?? ''} • ${_selectedCustomer!['code'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                  : Text('Nhấn để chọn khách hàng', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredCustomers = _customers.where((c) {
            if (searchQuery.isEmpty) return true;
            final name = (c['name'] ?? '').toString().toLowerCase();
            final phone = (c['phone'] ?? '').toString().toLowerCase();
            final code = (c['code'] ?? '').toString().toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query) || phone.contains(query) || code.contains(query);
          }).toList();
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Chọn khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredCustomers.length}',
                              style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) => setModalState(() => searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm khách hàng...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Không tìm thấy khách hàng', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected = _selectedCustomer?['id'] == customer['id'];
                            return _buildCustomerPickerCard(customer, isSelected, () {
                              setState(() => _selectedCustomer = customer);
                              Navigator.pop(context);
                            });
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerPickerCard(Map<String, dynamic> customer, bool isSelected, VoidCallback onTap) {
    final name = customer['name'] ?? 'N/A';
    final phone = customer['phone'] ?? '';
    final district = customer['district'] ?? '';
    final channel = customer['channel'] as String?;
    final status = customer['status'] ?? 'active';
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    final paymentTerms = customer['payment_terms'] ?? 0;
    final lastOrderDate = customer['last_order_date'] != null 
        ? DateTime.tryParse(customer['last_order_date'].toString()) 
        : null;
    
    final lastOrderColor = _getLastOrderColorStatic(lastOrderDate);
    final isVIP = creditLimit > 10000000;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CustomerAvatar(
                        seed: name,
                        radius: 22,
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isVIP) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (channel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getChannelColorStatic(channel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  channel,
                                  style: TextStyle(fontSize: 10, color: _getChannelColorStatic(channel)),
                                ),
                              ),
                            if (district.toString().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  district.toString(),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (phone.toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            phone.toString(),
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
              
              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildPickerKPIItem(
                      '📅',
                      _formatLastOrderStatic(lastOrderDate),
                      'Lần mua',
                      lastOrderColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      '💳',
                      creditLimit > 0 
                          ? NumberFormat.compact(locale: 'vi').format(creditLimit)
                          : '0',
                      'Hạn mức',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      '⏱️',
                      '$paymentTerms',
                      'Ngày TT',
                      Colors.purple,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildPickerKPIItem(
                      status == 'active' ? '✅' : '⛔',
                      status == 'active' ? 'Hoạt động' : 'Ngưng',
                      'Trạng thái',
                      status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerKPIItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  static Color _getChannelColorStatic(String? channel) {
    switch (channel) {
      case 'Horeca': return Colors.purple;
      case 'GT Sỉ': return Colors.blue;
      case 'GT Lẻ': return Colors.green;
      default: return Colors.indigo;
    }
  }

  static Color _getLastOrderColorStatic(DateTime? lastOrderDate) {
    if (lastOrderDate == null) return Colors.grey;
    final days = DateTime.now().difference(lastOrderDate).inDays;
    if (days <= 7) return Colors.green;
    if (days <= 14) return Colors.orange;
    return Colors.red;
  }

  static String _formatLastOrderStatic(DateTime? date) {
    if (date == null) return 'Chưa mua';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${days ~/ 7} tuần';
    return '${days ~/ 30} tháng';
  }

  Widget _buildProductSelector() {
    if (_isLoadingProducts) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      onTap: _showProductPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text('Nhấn để thêm sản phẩm', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
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
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Chọn sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${filteredProducts.length}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                Divider(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: filteredProducts.isEmpty
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
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final price = (product['selling_price'] ?? 0).toDouble();
                            final inCart = _orderItems.any((item) => item['product']['id'] == product['id']);
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
                              ),
                              title: Text(product['name'] ?? 'N/A'),
                              subtitle: Text('${product['sku'] ?? ''} • ${product['unit'] ?? ''}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(currencyFormat.format(price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (inCart) Text('Đã thêm', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                                ],
                              ),
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
          );
        },
      ),
    );
  }

  Widget _buildOrderItemCard(int index, Map<String, dynamic> item) {
    final product = item['product'] as Map<String, dynamic>;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${currencyFormat.format(item['unit_price'])} / ${product['unit'] ?? 'đơn vị'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQuantity(index, -1), color: Colors.red, iconSize: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQuantity(index, 1), color: Colors.green, iconSize: 28),
            ],
          ),
          SizedBox(
            width: 90,
            child: Text(currencyFormat.format(item['line_total']), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
