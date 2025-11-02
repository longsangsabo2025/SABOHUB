import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_provider.dart';
import '../../models/store.dart';
import '../../providers/company_provider_cached.dart';
import '../../services/store_service.dart';

/// Store Service Provider (for mutations)
final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

/// CEO Stores Management Page
/// Manages all branches in the enterprise
class CEOStoresPage extends ConsumerStatefulWidget {
  const CEOStoresPage({super.key});

  @override
  ConsumerState<CEOStoresPage> createState() => _CEOStoresPageState();
}

class _CEOStoresPageState extends ConsumerState<CEOStoresPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use cached provider - persists across tab switches
    final storesAsync = ref.watch(cachedStoresProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        // ✅ Pull-to-refresh support
        onRefresh: () async {
          await ref.read(cachedStoresProvider.notifier).refresh();
        },
        child: Column(
          children: [
            _buildHeader(storesAsync),
            Expanded(
              child: storesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(cachedStoresProvider.notifier).refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (cachedData) {
                  // Unwrap cached data
                  final stores = cachedData.data;
                  return _buildStoreList(stores);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStoreDialog(),
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm cửa hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<CachedData<List<Store>>> storesAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý cửa hàng',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quản lý tất cả cửa hàng trong hệ thống',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              storesAsync.when(
                data: (cachedData) => _buildStoreCount(cachedData.data.length),
                loading: () => _buildStoreCount(0),
                error: (_, __) => _buildStoreCount(0),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildStoreCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count cửa hàng',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cửa hàng...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStoreList(List<Store> stores) {
    final filteredStores = stores
        .where((store) =>
            store.name.toLowerCase().contains(_searchQuery) ||
            (store.address?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();

    if (filteredStores.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy cửa hàng nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStores.length,
      itemBuilder: (context, index) {
        final store = filteredStores[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (store.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          store.address!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: store.status == 'ACTIVE'
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    store.status == 'ACTIVE' ? 'Hoạt động' : 'Không hoạt động',
                    style: TextStyle(
                      color: store.status == 'ACTIVE'
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (store.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    store.phone!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showStoreDetails(store),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Xem chi tiết'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showEditStoreDialog(store),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteStore(store),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => _StoreFormDialog(),
    );
  }

  void _showEditStoreDialog(Store store) {
    showDialog(
      context: context,
      builder: (context) => _StoreFormDialog(store: store),
    );
  }

  void _showStoreDetails(Store store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.address != null) Text('Địa chỉ: ${store.address}'),
            if (store.phone != null) Text('Điện thoại: ${store.phone}'),
            Text('Trạng thái: ${store.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStore(Store store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa cửa hàng "${store.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(storeServiceProvider);
                await service.deleteStore(store.id);

                // ✅ Refresh cached provider
                refreshStores(ref);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa cửa hàng thành công')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StoreFormDialog extends ConsumerStatefulWidget {
  final Store? store;

  const _StoreFormDialog({this.store});

  @override
  ConsumerState<_StoreFormDialog> createState() => _StoreFormDialogState();
}

class _StoreFormDialogState extends ConsumerState<_StoreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store?.name ?? '');
    _addressController =
        TextEditingController(text: widget.store?.address ?? '');
    _phoneController = TextEditingController(text: widget.store?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.store == null ? 'Thêm cửa hàng mới' : 'Sửa cửa hàng'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên cửa hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Điện thoại',
                border: OutlineInputBorder(),
              ),
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
          onPressed: _handleSubmit,
          child: Text(widget.store == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final service = ref.read(storeServiceProvider);

      if (widget.store == null) {
        // Create new store
        await service.createStore(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      } else {
        // Update existing store
        await service.updateStore(widget.store!.id, {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        });
      }

      // ✅ Refresh cached provider
      refreshStores(ref);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.store == null
                ? 'Đã thêm cửa hàng thành công'
                : 'Đã cập nhật cửa hàng thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
