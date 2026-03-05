import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../providers/auth_provider.dart';
import '../../../../../utils/app_logger.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class SampleManagementPage extends ConsumerStatefulWidget {
  const SampleManagementPage({super.key});

  @override
  ConsumerState<SampleManagementPage> createState() => _SampleManagementPageState();
}

class _SampleManagementPageState extends ConsumerState<SampleManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<Map<String, dynamic>> _pendingSamples = [];
  List<Map<String, dynamic>> _shippedSamples = [];
  List<Map<String, dynamic>> _receivedSamples = [];
  List<Map<String, dynamic>> _feedbackSamples = [];
  List<Map<String, dynamic>> _convertedSamples = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllSamples();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSamples() async {
    setState(() => _isLoading = true);
    try {
      final companyId = ref.read(currentUserProvider)?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('product_samples')
          .select('''
            *,
            products(id, name, sku, unit, image_url, selling_price),
            customers(id, name, phone, address, contact_person)
          ''')
          .eq('company_id', companyId)
          .order('sent_date', ascending: false);

      final samples = List<Map<String, dynamic>>.from(data);

      setState(() {
        _pendingSamples = samples.where((s) => s['status'] == 'pending').toList();
        _shippedSamples = samples.where((s) => s['status'] == 'delivered').toList();
        _receivedSamples = samples.where((s) => s['status'] == 'received').toList();
        _feedbackSamples = samples.where((s) => s['status'] == 'feedback_received').toList();
        _convertedSamples = samples.where((s) => s['status'] == 'converted' || s['converted_to_order'] == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading samples: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSampleStatus(Map<String, dynamic> sample, String newStatus, {String? notes, int? rating}) async {
    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific fields
      if (newStatus == 'delivered') {
        updateData['shipped_date'] = DateTime.now().toIso8601String();
        updateData['shipped_by_id'] = userId;
      } else if (newStatus == 'received') {
        updateData['received_date'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'feedback_received') {
        updateData['feedback_date'] = DateTime.now().toIso8601String();
        if (rating != null) updateData['feedback_rating'] = rating;
        if (notes != null && notes.isNotEmpty) updateData['feedback_notes'] = notes;
      } else if (newStatus == 'converted') {
        updateData['converted_to_order'] = true;
        updateData['converted_date'] = DateTime.now().toIso8601String();
        
        // Convert linked order from 'sample' to 'regular'
        final orderId = sample['order_id'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          await supabase
              .from('sales_orders')
              .update({
                'order_type': 'regular', // Change from sample to regular order
                'status': 'confirmed', // Auto-confirm when sample converts
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', orderId);
        }
      }

      await supabase
          .from('product_samples')
          .update(updateData)
          .eq('id', sample['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Cập nhật trạng thái thành "${_getStatusLabel(newStatus)}"'), backgroundColor: Colors.green),
        );
        _loadAllSamples();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getStatusLabel(String status) {
    const labels = {
      'pending': 'Chờ gửi',
      'delivered': 'Đã giao',
      'received': 'Đã nhận',
      'feedback_received': 'Có phản hồi',
      'converted': 'Đã chuyển đơn',
    };
    return labels[status] ?? status;
  }

  Color _getStatusColor(String status) {
    const colors = {
      'pending': AppColors.warning,
      'delivered': AppColors.info,
      'received': AppColors.success,
      'feedback_received': AppColors.primary,
      'converted': Color(0xFF14B8A6),
    };
    return colors[status] ?? Colors.grey;
  }

  void _showMarkShippedDialog(Map<String, dynamic> sample) {
    final customerName = (sample['customers'] as Map?)?['name'] ?? 'Khách hàng';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu đã giao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác nhận rằng mẫu đã được giao cho:'),
            const SizedBox(height: 8),
            Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Sản phẩm: ${sample['product_name']} (x${sample['quantity']} ${sample['unit']})',
              style: const TextStyle(fontSize: 13),
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
              Navigator.pop(context);
              _updateSampleStatus(sample, 'delivered');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Đã giao'),
          ),
        ],
      ),
    );
  }

  void _showRequestFeedbackDialog(Map<String, dynamic> sample) {
    final customerName = (sample['customers'] as Map?)?['name'] ?? 'Khách hàng';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu phản hồi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác nhận mẫu được gửi cho $customerName đã nhận được phản hồi?'),
            const SizedBox(height: 16),
            Text(
              'Sản phẩm: ${sample['product_name']}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
              Navigator.pop(context);
              _updateSampleStatus(sample, 'received');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Đã nhận phản hồi'),
          ),
        ],
      ),
    );
  }

  void _showConvertToOrderDialog(Map<String, dynamic> sample) {
    final customerName = (sample['customers'] as Map?)?['name'] ?? 'Khách hàng';
    final productName = sample['product_name'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển thành đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chuyển mẫu thành đơn hàng từ $customerName?'),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sản phẩm: $productName', style: const TextStyle(fontSize: 13)),
                Text('Khách hàng: $customerName', style: const TextStyle(fontSize: 13)),
                if (sample['feedback_notes'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phản hồi khách:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(sample['feedback_notes'], style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
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
              Navigator.pop(context);
              _updateSampleStatus(sample, 'converted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Chuyển thành đơn'),
          ),
        ],
      ),
    );
  }

  void _showSampleDetail(Map<String, dynamic> sample) {
    final product = sample['products'] as Map?;
    final customer = sample['customers'] as Map?;
    final status = sample['status'] as String? ?? 'pending';
    final feedbackRating = sample['feedback_rating'] as int?;
    final feedbackNotes = sample['feedback_notes'] as String?;
    final shippedDate = sample['shipped_date'] != null ? DateTime.parse(sample['shipped_date']) : null;
    final receivedDate = sample['received_date'] != null ? DateTime.parse(sample['received_date']) : null;
    final feedbackDate = sample['feedback_date'] != null ? DateTime.parse(sample['feedback_date']) : null;
    final convertedDate = sample['converted_date'] != null ? DateTime.parse(sample['converted_date']) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.card_giftcard, color: _getStatusColor(status), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?['name'] ?? 'Sản phẩm',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Product Info
                  _buildDetailSection('Thông tin sản phẩm', [
                    _buildDetailRow('SKU', product?['sku'] ?? 'N/A'),
                    _buildDetailRow('Đơn vị', sample['unit'] ?? 'cái'),
                    _buildDetailRow('Số lượng', '${sample['quantity']} ${sample['unit']}'),
                    if (product?['selling_price'] != null)
                      _buildDetailRow('Giá lẻ', '${sample['quantity'] * (product?['selling_price'] as num? ?? 0)} đ'),
                  ]),

                  const SizedBox(height: 16),

                  // Customer Info
                  _buildDetailSection('Thông tin khách hàng', [
                    _buildDetailRow('Tên', customer?['name'] ?? 'N/A'),
                    _buildDetailRow('SĐT', customer?['phone'] ?? 'N/A'),
                    _buildDetailRow('Người liên hệ', customer?['contact_person'] ?? 'N/A'),
                    _buildDetailRow('Địa chỉ', customer?['address'] ?? 'N/A'),
                  ]),

                  const SizedBox(height: 16),

                  // Timeline
                  _buildDetailSection('Quá trình xử lý', [
                    _buildTimelineItem('Gửi mẫu', sample['sent_date'], '📤'),
                    if (shippedDate != null) _buildTimelineItem('Đã giao', dateFormat.format(shippedDate), '🚚'),
                    if (receivedDate != null) _buildTimelineItem('Đã nhận', dateFormat.format(receivedDate), '✅'),
                    if (feedbackDate != null) _buildTimelineItem('Phản hồi', dateFormat.format(feedbackDate), '💬'),
                    if (convertedDate != null) _buildTimelineItem('Chuyển đơn', dateFormat.format(convertedDate), '🛒'),
                  ]),

                  const SizedBox(height: 16),

                  // Feedback
                  if (feedbackRating != null || feedbackNotes != null) ...[
                    _buildDetailSection('Phản hồi khách hàng', [
                      if (feedbackRating != null)
                        Row(
                          children: [
                            Text('Đánh giá: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            ...List.generate(5, (index) =>
                              Icon(
                                index < feedbackRating ? Icons.star : Icons.star_border,
                                size: 18,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('($feedbackRating/5)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      if (feedbackNotes != null && feedbackNotes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feedbackNotes,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  if (sample['notes'] != null && (sample['notes'] as String).isNotEmpty)
                    _buildDetailSection('Ghi chú từ nhân viên', [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sample['notes'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ]),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(sample, status),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String? date, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (date != null) Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> sample, String status) {
    if (status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showMarkShippedDialog(sample),
          icon: const Icon(Icons.local_shipping),
          label: Text('Đánh dấu đã giao'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (status == 'delivered') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showRequestFeedbackDialog(sample),
          icon: const Icon(Icons.check_circle),
          label: Text('Xác nhận đã nhận'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (status == 'received' || status == 'feedback_received') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showConvertToOrderDialog(sample),
          icon: const Icon(Icons.shopping_cart),
          label: Text('Chuyển thành đơn hàng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildSampleTab(String title, List<Map<String, dynamic>> samples) {
    if (samples.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có $title nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: samples.length,
      itemBuilder: (context, index) {
        final sample = samples[index];
        final product = sample['products'] as Map?;
        final customer = sample['customers'] as Map?;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSampleDetail(sample),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getStatusColor(sample['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: _getStatusColor(sample['status']),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?['name'] ?? 'Sản phẩm',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khách: ${customer?['name'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SL: ${sample['quantity']} ${sample['unit']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý mẫu sản phẩm'),
        backgroundColor: Colors.teal,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.surface,
          unselectedLabelColor: Theme.of(context).colorScheme.surface70,
          indicatorColor: Theme.of(context).colorScheme.surface,
          tabs: [
            Tab(text: 'Chờ gửi (${_pendingSamples.length})'),
            Tab(text: 'Đã giao (${_shippedSamples.length})'),
            Tab(text: 'Đã nhận (${_receivedSamples.length})'),
            Tab(text: 'Phản hồi (${_feedbackSamples.length})'),
            Tab(text: 'Đơn hàng (${_convertedSamples.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSampleTab('chờ gửi', _pendingSamples),
                _buildSampleTab('đã giao', _shippedSamples),
                _buildSampleTab('đã nhận', _receivedSamples),
                _buildSampleTab('phản hồi', _feedbackSamples),
                _buildSampleTab('đơn hàng', _convertedSamples),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _loadAllSamples,
        child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }
}
