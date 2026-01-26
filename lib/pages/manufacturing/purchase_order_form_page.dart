import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/manufacturing_service.dart';
import '../../models/manufacturing_models.dart';

class PurchaseOrderFormPage extends ConsumerStatefulWidget {
  const PurchaseOrderFormPage({super.key});

  @override
  ConsumerState<PurchaseOrderFormPage> createState() => _PurchaseOrderFormPageState();
}

class _PurchaseOrderFormPageState extends ConsumerState<PurchaseOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _service = ManufacturingService();

  String? _selectedSupplierId;
  DateTime _orderDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  
  // Items to purchase (simplified: product_id -> quantity)
  final List<Map<String, dynamic>> _items = [];

  bool _isLoading = false;
  List<Supplier> _suppliers = [];
  List<Map<String, dynamic>> _materials = []; // Raw materials from manufacturing

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final suppliers = await _service.getSuppliers();
      final db = Supabase.instance.client;
      // Load materials (raw materials for manufacturing)
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      final materials = await db
          .from('manufacturing_materials')
          .select('id, name, unit, current_stock')
          .eq('company_id', companyId ?? '');

      setState(() {
        _suppliers = suppliers;
        _materials = List<Map<String, dynamic>>.from(materials);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nguyên vật liệu để chọn')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? selectedMaterialId;
        final qtyController = TextEditingController(text: '1');

        return AlertDialog(
          title: const Text('Thêm mặt hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Nguyên vật liệu'),
                items: _materials.map((m) => DropdownMenuItem(
                  value: m['id'] as String,
                  child: Text('${m['name']} (${m['unit']})'),
                )).toList(),
                onChanged: (val) => selectedMaterialId = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMaterialId != null) {
                  final material = _materials.firstWhere((m) => m['id'] == selectedMaterialId);
                  setState(() {
                    _items.add({
                      'material_id': selectedMaterialId,
                      'material_name': material['name'],
                      'unit': material['unit'],
                      'quantity': int.tryParse(qtyController.text) ?? 1,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhà cung cấp')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 mặt hàng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      if (companyId == null) throw Exception('User context not found');

      final db = Supabase.instance.client;

      // 1. Create PO Header
      final poData = {
        'company_id': companyId,
        'supplier_id': _selectedSupplierId,
        'order_number': 'PO-${DateTime.now().millisecondsSinceEpoch}',
        'order_date': _orderDate.toIso8601String(),
        'expected_date': _expectedDate.toIso8601String(),
        'status': 'pending',
        'notes': _notesController.text,
        'created_by': userId,
      };

      final poRes = await db.from('manufacturing_purchase_orders').insert(poData).select().single();
      final poId = poRes['id'];

      // 2. Create PO Items
      final itemsData = _items.map((item) => {
        'company_id': companyId,
        'purchase_order_id': poId,
        'material_id': item['material_id'],
        'quantity': item['quantity'],
        'received_quantity': 0,
      }).toList();

      await db.from('manufacturing_purchase_order_items').insert(itemsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo đơn mua hàng thành công')),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Đơn Mua Hàng (PO)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Nhà cung cấp *'),
                value: _selectedSupplierId,
                items: _suppliers.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedSupplierId = val),
                validator: (val) => val == null ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),

              // Date Pickers
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày đặt'),
                      subtitle: Text('${_orderDate.day}/${_orderDate.month}/${_orderDate.year}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _orderDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) setState(() => _orderDate = picked);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày nhận dự kiến'),
                      subtitle: Text('${_expectedDate.day}/${_expectedDate.month}/${_expectedDate.year}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) setState(() => _expectedDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Danh sách mặt hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có mặt hàng nào', style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['material_name']),
                        subtitle: Text('${item['quantity']} ${item['unit']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _items.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Tạo Đơn Mua Hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
