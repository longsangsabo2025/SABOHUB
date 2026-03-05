// Quality Inspection Form Page - Create/Edit QC Inspection
// Date: 2026-03-04

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../models/quality_inspection.dart';
import '../../models/manufacturing_models.dart';
import '../../services/quality_service.dart';

class QualityInspectionFormPage extends ConsumerStatefulWidget {
  final QualityInspection? inspection;

  const QualityInspectionFormPage({super.key, this.inspection});

  @override
  ConsumerState<QualityInspectionFormPage> createState() =>
      _QualityInspectionFormPageState();
}

class _QualityInspectionFormPageState
    extends ConsumerState<QualityInspectionFormPage> {
  late QualityService _service;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _notesController = TextEditingController();
  final _totalQtyController = TextEditingController();
  final _passedQtyController = TextEditingController();
  final _failedQtyController = TextEditingController();

  // State
  List<ProductionOrder> _productionOrders = [];
  ProductionOrder? _selectedOrder;
  String _productName = '';
  String _inspectorName = '';
  InspectionStatus _status = InspectionStatus.pending;
  List<DefectRecord> _defects = [];
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.inspection != null;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _service = QualityService(
      companyId: user?.companyId,
      employeeId: user?.id,
    );
    _inspectorName = user?.name ?? 'Nhân viên';

    if (_isEdit) {
      _populateForm(widget.inspection!);
    }

    _loadProductionOrders();
  }

  void _populateForm(QualityInspection i) {
    _productName = i.productName;
    _notesController.text = i.notes ?? '';
    _totalQtyController.text = i.totalQuantity.toString();
    _passedQtyController.text = i.passedQuantity.toString();
    _failedQtyController.text = i.failedQuantity.toString();
    _status = i.status;
    _defects = List.from(i.defectTypes);
    _inspectorName = i.inspectorName;
  }

  Future<void> _loadProductionOrders() async {
    setState(() => _loading = true);
    try {
      _productionOrders = await _service.getProductionOrders();
      // Nếu edit, tìm selected order
      if (_isEdit && widget.inspection!.productionOrderId != null) {
        _selectedOrder = _productionOrders
            .where((o) => o.id == widget.inspection!.productionOrderId)
            .firstOrNull;
      }
    } catch (e) {
      AppLogger.warn('QC Form: Failed to load production orders', e);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onOrderSelected(ProductionOrder? order) {
    if (order == null) return;
    setState(() {
      _selectedOrder = order;
      _productName = 'MO-${order.orderNumber} (${order.productId})';
      final qty =
          order.producedQuantity > 0 ? order.producedQuantity : order.plannedQuantity;
      _totalQtyController.text = qty.toString();
      _passedQtyController.text = qty.toString();
      _failedQtyController.text = '0';
    });
  }

  void _recalculateStatus() {
    final total = int.tryParse(_totalQtyController.text) ?? 0;
    final failed = int.tryParse(_failedQtyController.text) ?? 0;
    final passed = total - failed;
    if (passed >= 0) {
      _passedQtyController.text = passed.toString();
    }

    if (total == 0) {
      _status = InspectionStatus.pending;
    } else {
      final failRate = failed / total;
      if (failRate > 0.10) {
        _status = InspectionStatus.failed;
      } else if (failRate > 0.05) {
        _status = InspectionStatus.conditional;
      } else {
        _status = InspectionStatus.passed;
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = ref.read(currentUserProvider);
    final total = int.tryParse(_totalQtyController.text) ?? 0;
    final passed = int.tryParse(_passedQtyController.text) ?? 0;
    final failed = int.tryParse(_failedQtyController.text) ?? 0;

    final inspection = QualityInspection(
      id: _isEdit
          ? widget.inspection!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: user?.companyId ?? '',
      productionOrderId: _selectedOrder?.id ?? widget.inspection?.productionOrderId,
      productName: _productName,
      inspectorId: user?.id,
      inspectorName: _inspectorName,
      inspectionDate: _isEdit ? widget.inspection!.inspectionDate : DateTime.now(),
      status: _status,
      totalQuantity: total,
      passedQuantity: passed,
      failedQuantity: failed,
      defectTypes: _defects,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photos: _isEdit ? widget.inspection!.photos : [],
      createdAt: _isEdit ? widget.inspection!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (_isEdit) {
        await _service.updateInspection(inspection.id, inspection);
      } else {
        await _service.createInspection(inspection);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Đã cập nhật kiểm tra'
                : 'Đã tạo kiểm tra chất lượng'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('QC Form: Save failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu kiểm tra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _totalQtyController.dispose();
    _passedQtyController.dispose();
    _failedQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa kiểm tra QC' : 'Tạo kiểm tra QC'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === PRODUCTION ORDER ===
                  _buildOrderSelector(),
                  const SizedBox(height: 16),

                  // === PRODUCT NAME ===
                  TextFormField(
                    initialValue: _productName,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _productName = v,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                  const SizedBox(height: 16),

                  // === INSPECTOR ===
                  TextFormField(
                    initialValue: _inspectorName,
                    decoration: const InputDecoration(
                      labelText: 'Người kiểm tra',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // === QUANTITIES ===
                  _buildQuantitySection(),
                  const SizedBox(height: 16),

                  // === AUTO STATUS ===
                  _buildStatusIndicator(),
                  const SizedBox(height: 16),

                  // === DEFECTS ===
                  _buildDefectsSection(),
                  const SizedBox(height: 16),

                  // === NOTES ===
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      hintText: 'Nhập ghi chú kiểm tra...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // === SAVE BUTTON ===
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving
                          ? 'Đang lưu...'
                          : _isEdit
                              ? 'Cập nhật'
                              : 'Lưu kiểm tra'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ===== ORDER SELECTOR =====
  Widget _buildOrderSelector() {
    return DropdownButtonFormField<ProductionOrder>(
      value: _selectedOrder,
      decoration: const InputDecoration(
        labelText: 'Lệnh sản xuất (tùy chọn)',
        prefixIcon: Icon(Icons.factory),
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<ProductionOrder>(
          value: null,
          child: Text('-- Không chọn --', style: TextStyle(color: Colors.grey)),
        ),
        ..._productionOrders.map((o) => DropdownMenuItem(
              value: o,
              child: Text(
                'MO-${o.orderNumber} (${o.status}) - SL: ${o.plannedQuantity}',
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: _onOrderSelected,
    );
  }

  // ===== QUANTITIES =====
  Widget _buildQuantitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Số lượng kiểm tra',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalQtyController,
                    decoration: const InputDecoration(
                      labelText: 'Tổng SL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalculateStatus(),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _passedQtyController,
                    decoration: const InputDecoration(
                      labelText: 'Đạt',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _failedQtyController,
                    decoration: const InputDecoration(
                      labelText: 'Lỗi',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalculateStatus(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== STATUS INDICATOR =====
  Widget _buildStatusIndicator() {
    final statusText = QCStatusHelper.statusText(_status);
    final color = _statusColor(_status);
    final total = int.tryParse(_totalQtyController.text) ?? 0;
    final failed = int.tryParse(_failedQtyController.text) ?? 0;
    final failRate = total > 0 ? (failed / total * 100) : 0.0;

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(_statusIcon(_status), color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kết quả: $statusText',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Tỉ lệ lỗi: ${failRate.toStringAsFixed(1)}% '
                    '(>10% = Không đạt, 5-10% = Có điều kiện)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DEFECTS SECTION =====
  Widget _buildDefectsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách lỗi',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addDefect,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm lỗi'),
                ),
              ],
            ),
            if (_defects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('Chưa có lỗi nào',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._defects.asMap().entries.map((entry) {
                final idx = entry.key;
                final d = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _severityColor(d.severity),
                    child: Text('${d.count}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(d.type, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${QCStatusHelper.severityText(d.severity)}'
                    '${d.description != null && d.description!.isNotEmpty ? ' - ${d.description}' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() => _defects.removeAt(idx));
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ===== ADD DEFECT DIALOG =====
  Future<void> _addDefect() async {
    String selectedType = QCDefectTypes.all.first;
    DefectSeverity selectedSeverity = DefectSeverity.medium;
    final countController = TextEditingController(text: '1');
    final descController = TextEditingController();

    final result = await showDialog<DefectRecord>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm lỗi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại lỗi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: QCDefectTypes.all
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DefectSeverity>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Mức độ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: DefectSeverity.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(QCStatusHelper.severityText(s)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedSeverity = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: countController,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng lỗi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(countController.text) ?? 1;
                Navigator.pop(
                  ctx,
                  DefectRecord(
                    type: selectedType,
                    count: count,
                    severity: selectedSeverity,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    countController.dispose();
    descController.dispose();

    if (result != null) {
      setState(() => _defects.add(result));
    }
  }

  // ===== DELETE CONFIRMATION =====
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa kiểm tra?'),
        content: const Text('Dữ liệu kiểm tra sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.inspection != null) {
      try {
        await _service.deleteInspection(widget.inspection!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa kiểm tra'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ===== HELPERS =====
  Color _statusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return Colors.orange;
      case InspectionStatus.inProgress:
        return Colors.blue;
      case InspectionStatus.passed:
        return Colors.green;
      case InspectionStatus.failed:
        return Colors.red;
      case InspectionStatus.conditional:
        return Colors.amber.shade700;
    }
  }

  IconData _statusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return Icons.pending;
      case InspectionStatus.inProgress:
        return Icons.play_circle;
      case InspectionStatus.passed:
        return Icons.check_circle;
      case InspectionStatus.failed:
        return Icons.cancel;
      case InspectionStatus.conditional:
        return Icons.warning;
    }
  }

  Color _severityColor(DefectSeverity severity) {
    switch (severity) {
      case DefectSeverity.low:
        return Colors.blue;
      case DefectSeverity.medium:
        return Colors.orange;
      case DefectSeverity.high:
        return Colors.deepOrange;
      case DefectSeverity.critical:
        return Colors.red;
    }
  }
}
