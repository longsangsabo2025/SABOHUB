import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_sample.dart';
import '../../models/odori_product.dart';
import '../../models/odori_customer.dart';
import '../../providers/odori_providers.dart';
import '../../../../providers/auth_provider.dart';

class ProductSamplesPage extends ConsumerStatefulWidget {
  const ProductSamplesPage({super.key});

  @override
  ConsumerState<ProductSamplesPage> createState() => _ProductSamplesPageState();
}

class _ProductSamplesPageState extends ConsumerState<ProductSamplesPage> {
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(productSamplesProvider(ProductSampleFilters(
      status: _statusFilter,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    )));

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm mẫu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chờ gửi', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã gửi', 'delivered'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã nhận', 'received'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Có phản hồi', 'feedback_received'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã mua', 'converted'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Sample list
          Expanded(
            child: samplesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(productSamplesProvider(const ProductSampleFilters())),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (samples) {
                if (samples.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Chưa có sản phẩm mẫu nào'),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn + để tạo sản phẩm mẫu mới',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productSamplesProvider(ProductSampleFilters(
                    status: _statusFilter,
                    search: _searchController.text.isEmpty ? null : _searchController.text,
                  )).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: samples.length,
                    itemBuilder: (context, index) {
                      final sample = samples[index];
                      return _SampleCard(
                        sample: sample,
                        onTap: () => _showSampleDetail(sample),
                        onStatusChange: () => _updateSampleStatus(sample),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSampleSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bộ lọc',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tất cả'),
              trailing: _statusFilter == null ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_outlined, color: Colors.orange),
              title: const Text('Chờ gửi'),
              trailing: _statusFilter == 'pending' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = 'pending');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined, color: Colors.blue),
              title: const Text('Đã gửi'),
              trailing: _statusFilter == 'delivered' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = 'delivered');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('Đã nhận'),
              trailing: _statusFilter == 'received' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = 'received');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined, color: Colors.purple),
              title: const Text('Có phản hồi'),
              trailing: _statusFilter == 'feedback_received' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = 'feedback_received');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_checkout, color: Colors.teal),
              title: const Text('Đã mua hàng'),
              trailing: _statusFilter == 'converted' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _statusFilter = 'converted');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddSampleSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AddSamplePage()),
    ).then((result) {
      if (result == true) {
        ref.invalidate(productSamplesProvider);
      }
    });
  }

  void _showSampleDetail(ProductSample sample) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, size: 32, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sample.productName ?? 'Sản phẩm mẫu',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (sample.productSku != null)
                          Text(
                            sample.productSku!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(sample.status),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              _buildDetailRow('Khách hàng', sample.customerName ?? 'Không xác định'),
              _buildDetailRow('Số lượng', '${sample.quantity} ${sample.unit}'),
              _buildDetailRow('Ngày gửi', dateFormat.format(sample.sentDate)),
              _buildDetailRow('Người gửi', sample.sentByName ?? 'Không xác định'),
              if (sample.receivedDate != null)
                _buildDetailRow('Ngày nhận', dateFormat.format(sample.receivedDate!)),
              if (sample.receivedBy != null)
                _buildDetailRow('Người nhận', sample.receivedBy!),
              if (sample.feedbackRating != null) ...[
                const SizedBox(height: 16),
                const Text('Đánh giá:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < sample.feedbackRating! ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
              ],
              if (sample.feedbackNotes != null && sample.feedbackNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Phản hồi: ${sample.feedbackNotes}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
              if (sample.notes != null && sample.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ghi chú:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(sample.notes!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateSampleStatus(sample);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Cập nhật'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSample(sample);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      label: const Text('Xóa', style: TextStyle(color: Colors.white)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Chờ gửi';
        break;
      case 'delivered':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = 'Đã gửi';
        break;
      case 'received':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Đã nhận';
        break;
      case 'feedback_received':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        text = 'Có phản hồi';
        break;
      case 'converted':
        bgColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        text = 'Đã mua';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Future<void> _updateSampleStatus(ProductSample sample) async {
    final statuses = ['pending', 'delivered', 'received', 'feedback_received', 'converted'];
    final statusLabels = ['Chờ gửi', 'Đã gửi', 'Đã nhận', 'Có phản hồi', 'Đã mua hàng'];

    String? selectedStatus = sample.status;
    int? feedbackRating = sample.feedbackRating;
    final feedbackController = TextEditingController(text: sample.feedbackNotes);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật trạng thái'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trạng thái:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ...List.generate(statuses.length, (index) {
                  return RadioListTile<String>(
                    title: Text(statusLabels[index]),
                    value: statuses[index],
                    groupValue: selectedStatus,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setDialogState(() => selectedStatus = value);
                    },
                  );
                }),
                if (selectedStatus == 'feedback_received' || selectedStatus == 'converted') ...[
                  const SizedBox(height: 16),
                  const Text('Đánh giá:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < (feedbackRating ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => feedbackRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      labelText: 'Phản hồi của khách',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': selectedStatus,
                  'feedbackRating': feedbackRating,
                  'feedbackNotes': feedbackController.text,
                });
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final updateData = <String, dynamic>{
        'status': result['status'],
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (result['status'] == 'delivered') {
        updateData['sent_date'] = DateTime.now().toIso8601String();
      } else if (result['status'] == 'received') {
        updateData['received_date'] = DateTime.now().toIso8601String();
      } else if (result['status'] == 'feedback_received' || result['status'] == 'converted') {
        if (result['feedbackRating'] != null) {
          updateData['feedback_rating'] = result['feedbackRating'];
          updateData['feedback_date'] = DateTime.now().toIso8601String();
        }
        if (result['feedbackNotes']?.isNotEmpty == true) {
          updateData['feedback_notes'] = result['feedbackNotes'];
        }
        if (result['status'] == 'converted') {
          updateData['converted_to_order'] = true;
        }
      }

      await Supabase.instance.client
          .from('product_samples')
          .update(updateData)
          .eq('id', sample.id);

      ref.invalidate(productSamplesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSample(ProductSample sample) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mẫu "${sample.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('product_samples')
          .delete()
          .eq('id', sample.id);

      ref.invalidate(productSamplesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _SampleCard extends StatelessWidget {
  final ProductSample sample;
  final VoidCallback onTap;
  final VoidCallback onStatusChange;

  const _SampleCard({
    required this.sample,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sample.productName ?? 'Sản phẩm mẫu',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sample.quantity} ${sample.unit} • ${sample.customerName ?? 'Chưa gán KH'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(sample.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(sample.sentDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    sample.sentByName ?? 'N/A',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (sample.feedbackRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${sample.feedbackRating}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Chờ gửi';
        break;
      case 'delivered':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = 'Đã gửi';
        break;
      case 'received':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Đã nhận';
        break;
      case 'feedback_received':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        text = 'Có phản hồi';
        break;
      case 'converted':
        bgColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        text = 'Đã mua';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

// ============================================================================
// ADD SAMPLE PAGE
// ============================================================================
class _AddSamplePage extends ConsumerStatefulWidget {
  const _AddSamplePage();

  @override
  ConsumerState<_AddSamplePage> createState() => _AddSamplePageState();
}

class _AddSamplePageState extends ConsumerState<_AddSamplePage> {
  final _formKey = GlobalKey<FormState>();
  OdoriProduct? _selectedProduct;
  OdoriCustomer? _selectedCustomer;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  String _unit = 'cái';
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sản phẩm mẫu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product selection
            const Text('Sản phẩm *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            productsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (products) => DropdownButtonFormField<OdoriProduct>(
                value: _selectedProduct,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Chọn sản phẩm',
                ),
                items: products.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (${p.sku})', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProduct = value;
                    if (value != null) {
                      _unit = value.unit;
                    }
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn sản phẩm' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Customer selection
            const Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            customersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (customers) => DropdownButtonFormField<OdoriCustomer>(
                value: _selectedCustomer,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Chọn khách hàng (không bắt buộc)',
                ),
                items: customers.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCustomer = value),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity and unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Số lượng *', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Nhập số lượng';
                          if (int.tryParse(value) == null || int.parse(value) <= 0) {
                            return 'Số không hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đơn vị', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['cái', 'chai', 'hộp', 'gói', 'kg', 'lít', 'thùng']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (value) => setState(() => _unit = value ?? 'cái'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Ghi chú thêm (không bắt buộc)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo sản phẩm mẫu', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      final userName = authState.user?.name;

      if (companyId == null) throw Exception('Không tìm thấy công ty');

      final data = {
        'company_id': companyId,
        'product_id': _selectedProduct!.id,
        'product_name': _selectedProduct!.name,
        'product_sku': _selectedProduct!.sku,
        'customer_id': _selectedCustomer?.id,
        'quantity': int.parse(_quantityController.text),
        'unit': _unit,
        'sent_date': DateTime.now().toIso8601String(),
        'sent_by_id': userId,
        'sent_by_name': userName,
        'status': 'pending',
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      await Supabase.instance.client.from('product_samples').insert(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo sản phẩm mẫu'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
