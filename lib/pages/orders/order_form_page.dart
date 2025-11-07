import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../models/menu_item.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class OrderFormPage extends ConsumerStatefulWidget {
  final Order? order;

  const OrderFormPage({super.key, this.order});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _tableNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<OrderItem> _orderItems = [];
  bool _isLoading = false;

  // Sample menu items (in real app, this would come from MenuService)
  final List<MenuItem> _menuItems = [
    MenuItem(
      id: '1',
      name: 'Cà phê đen',
      category: MenuCategory.drink,
      price: 25000,
      description: 'Cà phê đen nguyên chất',
      companyId: '',
    ),
    MenuItem(
      id: '2',
      name: 'Cà phê sữa',
      category: MenuCategory.drink,
      price: 30000,
      description: 'Cà phê sữa truyền thống',
      companyId: '',
    ),
    MenuItem(
      id: '3',
      name: 'Nước cam',
      category: MenuCategory.drink,
      price: 35000,
      description: 'Nước cam tươi nguyên chất',
      companyId: '',
    ),
    MenuItem(
      id: '4',
      name: 'Bánh mì',
      category: MenuCategory.food,
      price: 20000,
      description: 'Bánh mì thịt nướng',
      companyId: '',
    ),
    MenuItem(
      id: '5',
      name: 'Mì tôm',
      category: MenuCategory.food,
      price: 25000,
      description: 'Mì tôm cua',
      companyId: '',
    ),
    MenuItem(
      id: '6',
      name: 'Khoai tây chiên',
      category: MenuCategory.snack,
      price: 30000,
      description: 'Khoai tây chiên giòn',
      companyId: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _initializeFromOrder(widget.order!);
    }
  }

  void _initializeFromOrder(Order order) {
    _customerNameController.text = order.customerName ?? '';
    _tableNameController.text = order.tableName ?? '';
    _notesController.text = order.notes ?? '';
    _orderItems = [...order.items];
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _tableNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Tạo đơn hàng mới' : 'Chi tiết đơn hàng'),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
        actions: [
          if (widget.order == null)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveOrder,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Lưu'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Đang xử lý...')
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderInfoSection(),
                          const SizedBox(height: 24),
                          _buildMenuSection(),
                          const SizedBox(height: 24),
                          if (_orderItems.isNotEmpty) ...[
                            _buildOrderSummarySection(),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (widget.order == null && _orderItems.isNotEmpty)
                    _buildBottomActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng',
                hintText: 'Nhập tên khách hàng (tùy chọn)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tableNameController,
              decoration: const InputDecoration(
                labelText: 'Bàn số',
                hintText: 'Ví dụ: Bàn 1, Bàn VIP',
                prefixIcon: Icon(Icons.table_restaurant),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ghi chú thêm cho đơn hàng',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn món',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...MenuCategory.values.map((category) {
              final categoryItems = _menuItems.where((item) => item.category == category).toList();
              if (categoryItems.isEmpty) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20, color: category.color),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: category.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...categoryItems.map((item) => _buildMenuItemTile(item)),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(MenuItem item) {
    final existingItem = _orderItems.firstWhere(
      (orderItem) => orderItem.menuItemId == item.id,
      orElse: () => const OrderItem(
        menuItemId: '',
        menuItemName: '',
        price: 0,
        quantity: 0,
      ),
    );
    
    final quantity = existingItem.menuItemId.isNotEmpty ? existingItem.quantity : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) Text(item.description!),
            const SizedBox(height: 4),
            Text(
              '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        trailing: quantity > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _updateItemQuantity(item, quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red.shade600,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateItemQuantity(item, quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.green.shade600,
                  ),
                ],
              )
            : IconButton(
                onPressed: () => _updateItemQuantity(item, 1),
                icon: const Icon(Icons.add_circle),
                color: Colors.green.shade600,
              ),
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    final totalAmount = _orderItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tóm tắt đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ..._orderItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.quantity}x ${item.menuItemName}'),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Tạo đơn hàng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateItemQuantity(MenuItem menuItem, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _orderItems.removeWhere((item) => item.menuItemId == menuItem.id);
      } else {
        final existingIndex = _orderItems.indexWhere(
          (item) => item.menuItemId == menuItem.id,
        );
        
        final orderItem = OrderItem(
          menuItemId: menuItem.id,
          menuItemName: menuItem.name,
          price: menuItem.price,
          quantity: newQuantity,
        );
        
        if (existingIndex >= 0) {
          _orderItems[existingIndex] = orderItem;
        } else {
          _orderItems.add(orderItem);
        }
      }
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate() || _orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một món'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(orderActionsProvider);
      
      await actions.createOrder(
        items: _orderItems,
        tableId: _tableNameController.text.isNotEmpty ? 'table-${_tableNameController.text}' : null,
        tableName: _tableNameController.text.isNotEmpty ? _tableNameController.text : null,
        customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}