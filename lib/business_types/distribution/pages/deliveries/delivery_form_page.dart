import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/odori_delivery.dart';
import '../../../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';

class DeliveryFormPage extends ConsumerStatefulWidget {
  final OdoriDelivery? delivery;

  const DeliveryFormPage({super.key, this.delivery});

  @override
  ConsumerState<DeliveryFormPage> createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends ConsumerState<DeliveryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryNumberController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDriverId;
  DateTime _deliveryDate = DateTime.now();
  
  // List of selected Order IDs to be delivered in this trip
  final Set<String> _selectedOrderIds = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.delivery != null) {
      // Edit mode logic here if needed, usually complex for deliveries
      // allowing edit of header info mainly
      _deliveryNumberController.text = widget.delivery!.deliveryNumber;
      _vehicleController.text = widget.delivery!.vehicle ?? '';
      _vehiclePlateController.text = widget.delivery!.vehiclePlate ?? '';
      _notesController.text = widget.delivery!.notes ?? '';
      _selectedDriverId = widget.delivery!.driverId;
      _deliveryDate = widget.delivery!.deliveryDate;
    } else {
      // Generate temp number or leave blank
      _deliveryNumberController.text = 'DEL-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _deliveryNumberController.dispose();
    _vehicleController.dispose();
    _vehiclePlateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitFormat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tài xế')),
      );
      return;
    }
    if (_selectedOrderIds.isEmpty && widget.delivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 đơn hàng để giao')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) throw Exception('User context not found');

      final db = Supabase.instance.client;

      // 1. Create/Update Delivery Header
      final deliveryData = {
        'company_id': companyId,
        'delivery_number': _deliveryNumberController.text,
        'delivery_date': _deliveryDate.toIso8601String(),
        'driver_id': _selectedDriverId,
        'vehicle': _vehicleController.text,
        'vehicle_plate': _vehiclePlateController.text,
        'notes': _notesController.text,
        'status': widget.delivery?.status ?? 'planned', // Default to planned
        'planned_stops': _selectedOrderIds.length,
      };

      String deliveryId;
      if (widget.delivery != null) {
         await db.from('deliveries').update(deliveryData).eq('id', widget.delivery!.id);
         deliveryId = widget.delivery!.id;
      } else {
         final res = await db.from('deliveries').insert(deliveryData).select().single();
         deliveryId = res['id'];
         
         // 2. Insert Delivery Items (Orders) for new delivery
         if (_selectedOrderIds.isNotEmpty) {
           final itemsData = _selectedOrderIds.map((orderId) => {
             'company_id': companyId,
             'delivery_id': deliveryId,
             'sales_order_id': orderId,
             'status': 'pending', 
             'sequence': 0, // Simplified
           }).toList();
           
           await db.from('delivery_items').insert(itemsData);
           
           // Optional: Update sales orders status to 'shipping' or similar if business logic requires
           await db.from('sales_orders')
               .update({'status': 'shipping'})
               .inFilter('id', _selectedOrderIds.toList());
         }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu chuyến giao hàng')),
        );
        ref.invalidate(deliveriesProvider);
        ref.invalidate(activeDeliveriesProvider);
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
    // Only fetch orders that are 'approved' or 'ready_to_ship' and not yet in a delivery. 
    // Simplified: Fetch all pending/approved orders.
    final ordersAsync = ref.watch(salesOrdersProvider(const OrderFilters(status: 'approved'))); 
    
    // We assume there's a provider for drivers (employees)
    // If not, we might need to fetch employees with role 'driver' or just all employees
    // For now, let's use a hypothetical 'driversProvider' or query employees manually.
    // Reusing productsProvider structure to create a quick query for employees directly here or use existing provider.
    // Let's assume we can watch a list of employees.
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.delivery != null ? 'Sửa Chuyến Giao' : 'Tạo Chuyến Giao Mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _deliveryNumberController,
                        decoration: const InputDecoration(labelText: 'Mã chuyến'),
                        readOnly: true, // Auto-generated usually
                      ),
                      const SizedBox(height: 16),
                      // Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngày giao hàng'),
                        subtitle: Text('${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deliveryDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _deliveryDate = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Driver & Vehicle Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Tài xế & Phương tiện', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Driver Dropdown (Using FutureBuilder for simplicity if no specific provider exists)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: Supabase.instance.client
                            .from('employees')
                            .select('id, full_name')
                            .eq('status', 'active'), // Assuming status column
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final drivers = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Tài xế *'),
                            value: _selectedDriverId,
                            items: drivers.map((d) => DropdownMenuItem(
                              value: d['id'] as String,
                              child: Text(d['full_name'] as String),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedDriverId = val),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleController,
                        decoration: const InputDecoration(labelText: 'Phương tiện (Xe máy, Xe tải)'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehiclePlateController,
                        decoration: const InputDecoration(labelText: 'Biển số xe'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Orders Selection Card (Only show when creating new)
              if (widget.delivery == null) ...[
                const Text('Chọn đơn hàng cần giao', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 300, 
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: ordersAsync.when(
                    data: (orders) {
                      if (orders.isEmpty) {
                        return const Center(child: Text('Không có đơn hàng nào chờ giao (Status: Approved)'));
                      }
                      return ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final isSelected = _selectedOrderIds.contains(order.id);
                          return CheckboxListTile(
                            title: Text('${order.orderNumber} - ${order.customerName}'),
                            subtitle: Text('${order.total}đ - ${order.status}'),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedOrderIds.add(order.id);
                                } else {
                                  _selectedOrderIds.remove(order.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Lỗi tải đơn hàng: $e')),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú chuyến đi'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitFormat,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Tạo Chuyến Giao Hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
