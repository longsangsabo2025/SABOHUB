import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/manufacturing_service.dart';
import '../../models/manufacturing_models.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final _service = ManufacturingService();
  List<Supplier> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    try {
      final suppliers = await _service.getSuppliers();
      setState(() {
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải nhà cung cấp: $e')),
        );
      }
    }
  }

  Future<void> _deleteSupplier(String id) async {
    try {
      await _service.deleteSupplier(id);
      await _loadSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhà cung cấp')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà Cung Cấp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Chưa có nhà cung cấp'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showSupplierDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nhà cung cấp'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _suppliers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(supplier.name[0]),
                        ),
                        title: Text(supplier.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.contactPerson != null)
                              Text('📞 ${supplier.contactPerson}'),
                            if (supplier.phone != null)
                              Text('☎️ ${supplier.phone}'),
                            if (supplier.email != null)
                              Text('📧 ${supplier.email}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showSupplierDialog(supplier: supplier);
                            } else if (value == 'delete') {
                              _confirmDelete(supplier);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactNameController = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final notesController = TextEditingController(text: supplier?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'Thêm Nhà Cung Cấp' : 'Sửa Nhà Cung Cấp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên nhà cung cấp *'),
              ),
              TextField(
                controller: contactNameController,
                decoration: const InputDecoration(labelText: 'Tên liên hệ'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                maxLines: 2,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên nhà cung cấp')),
                );
                return;
              }

              try {
                if (supplier == null) {
                  await _service.createSupplier(Supplier(
                    id: '',
                    companyId: '',
                    supplierCode: '',
                    name: nameController.text,
                    contactPerson: contactNameController.text.isEmpty ? null : contactNameController.text,
                    phone: phoneController.text.isEmpty ? null : phoneController.text,
                    email: emailController.text.isEmpty ? null : emailController.text,
                    address: addressController.text.isEmpty ? null : addressController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  ));
                } else {
                  await _service.updateSupplier(supplier.id, {
                    'name': nameController.text,
                    'contact_person': contactNameController.text.isEmpty ? null : contactNameController.text,
                    'phone': phoneController.text.isEmpty ? null : phoneController.text,
                    'email': emailController.text.isEmpty ? null : emailController.text,
                    'address': addressController.text.isEmpty ? null : addressController.text,
                    'notes': notesController.text.isEmpty ? null : notesController.text,
                  });
                }
                Navigator.pop(context);
                await _loadSuppliers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(supplier == null ? 'Đã thêm nhà cung cấp' : 'Đã cập nhật nhà cung cấp')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: Text(supplier == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhà cung cấp "${supplier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(supplier.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
