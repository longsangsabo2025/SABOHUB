import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sales_features_service.dart';
import '../../../providers/auth_provider.dart';

// ============================================================================
// KPI TARGETS CARD - Hiển thị mục tiêu & tiến độ
// ============================================================================
class KpiTargetsCard extends ConsumerStatefulWidget {
  const KpiTargetsCard({super.key});

  @override
  ConsumerState<KpiTargetsCard> createState() => _KpiTargetsCardState();
}

class _KpiTargetsCardState extends ConsumerState<KpiTargetsCard> {
  SalesTarget? _target;
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    final employeeId = authState.user?.id;

    if (companyId == null || employeeId == null) return;

    final target = await ref.read(salesTargetServiceProvider).getCurrentTarget(companyId, employeeId);
    if (mounted) {
      setState(() {
        _target = target;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())));
    }

    if (_target == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Chưa có mục tiêu', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Mục tiêu tháng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _target!.revenueProgress >= 1 ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_target!.revenueProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _target!.revenueProgress >= 1 ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Revenue progress
            _buildProgressItem(
              icon: Icons.attach_money,
              label: 'Doanh số',
              current: _target!.actualRevenue,
              target: _target!.targetRevenue,
              progress: _target!.revenueProgress,
              formatCurrency: true,
            ),
            const SizedBox(height: 12),
            
            // Orders progress
            _buildProgressItem(
              icon: Icons.receipt_long,
              label: 'Đơn hàng',
              current: _target!.actualOrders.toDouble(),
              target: _target!.targetOrders.toDouble(),
              progress: _target!.ordersProgress,
            ),
            const SizedBox(height: 12),
            
            // Visits progress
            _buildProgressItem(
              icon: Icons.store,
              label: 'Viếng thăm',
              current: _target!.actualVisits.toDouble(),
              target: _target!.targetVisits.toDouble(),
              progress: _target!.visitsProgress,
            ),
            const SizedBox(height: 12),
            
            // New customers
            _buildProgressItem(
              icon: Icons.person_add,
              label: 'KH mới',
              current: _target!.actualNewCustomers.toDouble(),
              target: _target!.targetNewCustomers.toDouble(),
              progress: _target!.newCustomersProgress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required double current,
    required double target,
    required double progress,
    bool formatCurrency = false,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final color = safeProgress >= 1 ? Colors.green : (safeProgress >= 0.7 ? Colors.blue : Colors.orange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const Spacer(),
            Text(
              formatCurrency
                  ? '${_currencyFormat.format(current)} / ${_currencyFormat.format(target)}'
                  : '${current.toInt()} / ${target.toInt()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: safeProgress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

// ============================================================================
// CUSTOMER DEBT BADGE - Hiển thị công nợ KH
// ============================================================================
class CustomerDebtBadge extends StatelessWidget {
  final double totalDebt;
  final double creditLimit;
  final bool compact;
  final VoidCallback? onPaymentTap;

  const CustomerDebtBadge({
    super.key,
    required this.totalDebt,
    required this.creditLimit,
    this.compact = false,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final usagePercent = creditLimit > 0 ? (totalDebt / creditLimit * 100) : 0.0;
    
    Color bgColor;
    Color textColor;
    IconData icon;
    
    if (usagePercent >= 100) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.warning;
    } else if (usagePercent >= 80) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      icon = Icons.info;
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              currencyFormat.format(totalDebt),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text('Công nợ', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalDebt),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Hạn mức: ${currencyFormat.format(creditLimit)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (usagePercent / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(textColor),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            'Đã dùng ${usagePercent.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROMOTION BADGE - Hiển thị khuyến mãi
// ============================================================================
class PromotionBadge extends StatelessWidget {
  final String name;
  final String? description;
  final DateTime endDate;
  final VoidCallback? onTap;

  const PromotionBadge({
    super.key,
    required this.name,
    this.description,
    required this.endDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (description != null)
                    Text(
                      description!,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysLeft > 0 ? 'Còn $daysLeft ngày' : 'Hết hạn hôm nay',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ACTIVE PROMOTIONS LIST
// ============================================================================
class ActivePromotionsList extends ConsumerStatefulWidget {
  final bool compact;
  
  const ActivePromotionsList({super.key, this.compact = false});

  @override
  ConsumerState<ActivePromotionsList> createState() => _ActivePromotionsListState();
}

class _ActivePromotionsListState extends ConsumerState<ActivePromotionsList> {
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;

    final promotions = await ref.read(promotionServiceProvider).getActivePromotions(companyId);
    if (mounted) {
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_promotions.isEmpty) {
      if (widget.compact) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('Không có khuyến mãi đang áp dụng', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (widget.compact) {
      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _promotions.length,
          itemBuilder: (context, index) {
            final promo = _promotions[index];
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
              child: SizedBox(
                width: 250,
                child: PromotionBadge(
                  name: promo.name,
                  description: promo.description,
                  endDate: promo.endDate,
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Khuyến mãi đang áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_promotions.length}', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        ..._promotions.map((promo) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PromotionBadge(
            name: promo.name,
            description: promo.description,
            endDate: promo.endDate,
          ),
        )),
      ],
    );
  }
}

// ============================================================================
// CUSTOMER ORDER HISTORY
// ============================================================================
class CustomerOrderHistory extends ConsumerStatefulWidget {
  final String customerId;
  final int limit;

  const CustomerOrderHistory({
    super.key,
    required this.customerId,
    this.limit = 10,
  });

  @override
  ConsumerState<CustomerOrderHistory> createState() => _CustomerOrderHistoryState();
}

class _CustomerOrderHistoryState extends ConsumerState<CustomerOrderHistory> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final orders = await ref.read(customerHistoryServiceProvider).getOrderHistory(
      widget.customerId,
      limit: widget.limit,
    );
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final date = DateTime.tryParse(order['order_date'] ?? '');
        final status = order['status'] ?? 'pending';
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _getStatusColor(status).withOpacity(0.2),
            child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 20),
          ),
          title: Text(order['order_number'] ?? 'N/A'),
          subtitle: Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(order['total'] ?? 0),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(fontSize: 10, color: _getStatusColor(status)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'processing': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'processing': return Icons.autorenew;
      case 'cancelled': return Icons.cancel;
      default: return Icons.schedule;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'processing': return 'Đang xử lý';
      case 'confirmed': return 'Đã duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'pending_approval': return 'Chờ duyệt';
      default: return status;
    }
  }
}

// ============================================================================
// VISIT PHOTO CAPTURE BUTTON
// ============================================================================
class VisitPhotoCaptureButton extends ConsumerStatefulWidget {
  final String visitId;
  final String category;
  final VoidCallback? onPhotoAdded;

  const VisitPhotoCaptureButton({
    super.key,
    required this.visitId,
    this.category = 'other',
    this.onPhotoAdded,
  });

  @override
  ConsumerState<VisitPhotoCaptureButton> createState() => _VisitPhotoCaptureButtonState();
}

class _VisitPhotoCaptureButtonState extends ConsumerState<VisitPhotoCaptureButton> {
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _capturePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
      if (image == null) return;

      setState(() => _isUploading = true);

      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) return;

      // Upload to Supabase Storage
      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final path = 'visit-photos/$companyId/${widget.visitId}/$fileName';

      await Supabase.instance.client.storage.from('uploads').uploadBinary(path, bytes);

      final publicUrl = Supabase.instance.client.storage.from('uploads').getPublicUrl(path);

      // Save to database
      await ref.read(visitPhotoServiceProvider).uploadPhoto(
        visitId: widget.visitId,
        companyId: companyId,
        category: widget.category,
        photoUrl: publicUrl,
        uploadedBy: userId,
      );

      widget.onPhotoAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải ảnh lên'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _capturePhoto,
      icon: _isUploading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.camera_alt),
      label: Text(_isUploading ? 'Đang tải...' : 'Chụp ảnh'),
    );
  }
}

// ============================================================================
// COMPETITOR REPORT FORM
// ============================================================================
class CompetitorReportForm extends ConsumerStatefulWidget {
  final String? customerId;
  final String? visitId;
  final VoidCallback? onSaved;

  const CompetitorReportForm({
    super.key,
    this.customerId,
    this.visitId,
    this.onSaved,
  });

  @override
  ConsumerState<CompetitorReportForm> createState() => _CompetitorReportFormState();
}

class _CompetitorReportFormState extends ConsumerState<CompetitorReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _competitorNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _promotionController = TextEditingController();
  
  String _activityType = 'promotion';
  String _impact = 'medium';
  bool _isSaving = false;

  final _activityTypes = [
    {'value': 'promotion', 'label': 'Khuyến mãi'},
    {'value': 'new_product', 'label': 'Sản phẩm mới'},
    {'value': 'price_change', 'label': 'Thay đổi giá'},
    {'value': 'merchandising', 'label': 'Trưng bày'},
    {'value': 'sampling', 'label': 'Dùng thử'},
    {'value': 'other', 'label': 'Khác'},
  ];

  @override
  void dispose() {
    _competitorNameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _promotionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) return;

      await ref.read(competitorReportServiceProvider).createReport(
        companyId: companyId,
        customerId: widget.customerId,
        visitId: widget.visitId,
        reportedBy: userId,
        competitorName: _competitorNameController.text.trim(),
        competitorBrand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        activityType: _activityType,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        observedPrice: double.tryParse(_priceController.text.replaceAll(RegExp(r'[^\d.]'), '')),
        promotionDetails: _promotionController.text.trim().isNotEmpty ? _promotionController.text.trim() : null,
        estimatedImpact: _impact,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu báo cáo đối thủ'), backgroundColor: Colors.green),
        );
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo đối thủ'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _competitorNameController,
              decoration: const InputDecoration(
                labelText: 'Tên đối thủ *',
                hintText: 'VD: Công ty ABC',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Thương hiệu/Sản phẩm',
                hintText: 'VD: Dầu ăn XYZ',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _activityType,
              decoration: const InputDecoration(
                labelText: 'Loại hoạt động *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _activityTypes.map((t) => DropdownMenuItem(
                value: t['value'],
                child: Text(t['label']!),
              )).toList(),
              onChanged: (v) => setState(() => _activityType = v!),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                hintText: 'Mô tả hoạt động đối thủ...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            if (_activityType == 'price_change')
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá quan sát',
                  prefixIcon: Icon(Icons.attach_money),
                  suffix: Text('₫'),
                ),
                keyboardType: TextInputType.number,
              ),
            
            if (_activityType == 'promotion')
              TextFormField(
                controller: _promotionController,
                decoration: const InputDecoration(
                  labelText: 'Chi tiết khuyến mãi',
                  hintText: 'VD: Mua 2 tặng 1',
                  prefixIcon: Icon(Icons.local_offer),
                ),
              ),
            
            const SizedBox(height: 16),
            const Text('Mức độ ảnh hưởng:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Thấp')),
                ButtonSegment(value: 'medium', label: Text('Trung bình')),
                ButtonSegment(value: 'high', label: Text('Cao')),
              ],
              selected: {_impact},
              onSelectionChanged: (s) => setState(() => _impact = s.first),
            ),
          ],
        ),
      ),
    );
  }
}
