import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/invoice_scan_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Trang scan hóa đơn AI
/// Flow: 📸 Chụp / chọn ảnh → 🤖 AI phân tích → 📋 Xác nhận → 💾 Lưu
class InvoiceScanPage extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const InvoiceScanPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  ConsumerState<InvoiceScanPage> createState() => _InvoiceScanPageState();
}

class _InvoiceScanPageState extends ConsumerState<InvoiceScanPage>
    with SingleTickerProviderStateMixin {
  final _service = InvoiceScanService();
  final _imagePicker = ImagePicker();
  late TabController _tabController;

  // ── Scan state ──
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _analyzing = false;
  InvoiceAnalysisResult? _result;

  // ── Transactions state ──
  List<ExpenseTransaction> _pendingTx = [];
  List<ExpenseTransaction> _confirmedTx = [];
  bool _loadingTx = false;
  bool _applying = false;

  // ── Edit state for corrections ──
  final _editAmountController = TextEditingController();
  String? _editCategory;

  final _currencyFmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editAmountController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // DATA LOADING
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadTransactions() async {
    setState(() => _loadingTx = true);
    try {
      final pending =
          await _service.getTransactions(companyId: widget.companyId, status: 'pending');
      final confirmed =
          await _service.getTransactions(companyId: widget.companyId, status: 'confirmed');
      if (mounted) {
        setState(() {
          _pendingTx = pending;
          _confirmedTx = confirmed;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi tải dữ liệu: $e');
      }
    } finally {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // IMAGE PICKING
  // ══════════════════════════════════════════════════════════════

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? _guessMimeType(image.name);

      setState(() {
        _imageBytes = bytes;
        _imageMimeType = mime;
        _result = null; // Reset previous result
      });
    } catch (e) {
      _showError('Lỗi chọn ảnh: $e');
    }
  }

  String _guessMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // AI ANALYSIS
  // ══════════════════════════════════════════════════════════════

  Future<void> _analyzeInvoice() async {
    if (_imageBytes == null) return;

    final employeeId = ref.read(currentUserProvider)?.id;

    setState(() {
      _analyzing = true;
      _result = null;
    });

    try {
      final result = await _service.analyzeInvoice(
        imageBytes: _imageBytes!,
        mimeType: _imageMimeType ?? 'image/jpeg',
        companyId: widget.companyId,
        employeeId: employeeId,
      );

      if (mounted) {
        setState(() => _result = result);
        if (result.success && result.saved) {
          _loadTransactions(); // Refresh pending list
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _result = InvoiceAnalysisResult.error('$e'));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // TRANSACTION ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> _confirmTransaction(ExpenseTransaction tx) async {
    try {
      await _service.confirmTransaction(tx.id);
      _showSuccess('Đã xác nhận: ${tx.categoryLabel} - ${_fmtMoney(tx.amount)}');
      _loadTransactions();
    } catch (e) {
      _showError('Lỗi xác nhận: $e');
    }
  }

  Future<void> _confirmWithEdits(ExpenseTransaction tx) async {
    _editAmountController.text = tx.amount.toStringAsFixed(0);
    _editCategory = tx.category;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Sửa & Xác nhận'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editAmountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VND)',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _editCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category),
                ),
                items: InvoiceAnalysisResult.categoryLabelMap.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setDialogState(() => _editCategory = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final correctedAmount = double.tryParse(
            _editAmountController.text.replaceAll(RegExp(r'[^\d.]'), ''));
        await _service.confirmTransaction(
          tx.id,
          correctedAmount: correctedAmount,
          correctedCategory: _editCategory,
        );
        _showSuccess('Đã xác nhận (đã sửa)');
        _loadTransactions();
      } catch (e) {
        _showError('Lỗi: $e');
      }
    }
  }

  Future<void> _rejectTransaction(ExpenseTransaction tx) async {
    try {
      await _service.rejectTransaction(tx.id);
      _showSuccess('Đã từ chối');
      _loadTransactions();
    } catch (e) {
      _showError('Lỗi: $e');
    }
  }

  Future<void> _applyConfirmedToMonth(String targetMonth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Áp dụng vào P&L?'),
        content: Text(
          'Tổng hợp tất cả chi phí đã xác nhận cho tháng $targetMonth '
          'và cập nhật vào báo cáo lãi lỗ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _applying = true);
    try {
      final result = await _service.applyExpensesToPnl(
        companyId: widget.companyId,
        targetMonth: targetMonth,
      );
      if (result['success'] == true) {
        _showSuccess('Đã cập nhật P&L tháng $targetMonth! ✅');
        _loadTransactions();
      } else {
        _showError('Lỗi: ${result['error']}');
      }
    } catch (e) {
      _showError('Lỗi áp dụng: $e');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📸 Scan Hóa Đơn AI', style: TextStyle(fontSize: 16)),
            Text(widget.companyName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.document_scanner, size: 18),
                  const SizedBox(width: 6),
                  const Text('Scan mới'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long, size: 18),
                  const SizedBox(width: 6),
                  Text('Chờ duyệt (${_pendingTx.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScanTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  // ── TAB 1: SCAN ──────────────────────────────────────────────

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image picker area ──
          _buildImagePickerArea(),
          const SizedBox(height: 16),

          // ── Analyze button ──
          if (_imageBytes != null && _result == null && !_analyzing)
            ElevatedButton.icon(
              onPressed: _analyzeInvoice,
              icon: const Icon(Icons.auto_awesome),
              label: Text('🤖 Phân tích bằng AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          // ── Loading indicator ──
          if (_analyzing) _buildAnalyzingIndicator(),

          // ── AI Result ──
          if (_result != null) _buildAnalysisResult(),
        ],
      ),
    );
  }

  Widget _buildImagePickerArea() {
    if (_imageBytes != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _imageBytes!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _imageBytes = null;
                  _result = null;
                }),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Xóa'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Chọn lại'),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Chụp hoặc chọn ảnh hóa đơn',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text('Chụp ảnh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Thư viện'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 16),
          Text('🤖 AI đang phân tích hóa đơn...',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Gemini Vision đang đọc và phân loại',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final r = _result!;
    if (!r.success) {
      return Card(
        color: AppColors.errorLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 36),
              const SizedBox(height: 8),
              Text('Phân tích thất bại', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(r.error ?? 'Lỗi không xác định', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _analyzeInvoice,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text('Kết quả phân tích AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildConfidenceBadge(r.confidence),
              ],
            ),
            const Divider(height: 20),

            // Category
            _resultRow('Loại chứng từ', r.documentTypeLabel, Icons.file_present, Colors.indigo),
            _resultRow('Phân loại', r.categoryLabel, Icons.category, AppColors.primary),
            _resultRow('Số tiền', _fmtMoney(r.amount), Icons.money, AppColors.success),
            if (r.vendor != null)
              _resultRow('Nhà cung cấp', r.vendor!, Icons.store, Colors.blue),
            if (r.invoiceDate != null)
              _resultRow('Ngày hóa đơn', r.invoiceDate!, Icons.calendar_today, Colors.orange),
            if (r.invoiceNumber != null)
              _resultRow('Số hóa đơn', r.invoiceNumber!, Icons.tag, Colors.grey),
            if (r.description != null)
              _resultRow('Mô tả', r.description!, Icons.description, Colors.teal),

            // Items detail
            if (r.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Chi tiết mặt hàng:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              ...r.items.map((item) => Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      '• ${item['name']} x${item['quantity']} = ${_fmtMoney((item['total'] as num?)?.toDouble() ?? 0)}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface87),
                    ),
                  )),
            ],

            const SizedBox(height: 16),

            // Status
            if (r.saved)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã lưu vào danh sách chờ duyệt (tháng ${r.targetMonth?.substring(0, 7) ?? '?'})',
                        style: const TextStyle(fontSize: 13, color: AppColors.successDark),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageBytes = null;
                        _result = null;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: Text('Scan tiếp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: Text('Xem DS (${_pendingTx.length})'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final pct = (confidence * 100).toInt();
    Color bg;
    if (confidence >= 0.8) {
      bg = AppColors.success;
    } else if (confidence >= 0.5) {
      bg = AppColors.warning;
    } else {
      bg = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg, width: 1),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: bg),
      ),
    );
  }

  // ── TAB 2: TRANSACTIONS ─────────────────────────────────────

  Widget _buildTransactionsTab() {
    if (_loadingTx) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final allTx = [..._pendingTx, ..._confirmedTx];

    if (allTx.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Chưa có chi phí nào',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Scan hóa đơn để bắt đầu',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    // Group by target_month
    final byMonth = <String, List<ExpenseTransaction>>{};
    for (final tx in allTx) {
      final monthKey = tx.targetMonth.substring(0, 7); // YYYY-MM
      byMonth.putIfAbsent(monthKey, () => []);
      byMonth[monthKey]!.add(tx);
    }

    final sortedMonths = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedMonths.length,
        itemBuilder: (context, idx) {
          final month = sortedMonths[idx];
          final txList = byMonth[month]!;
          final pendingCount = txList.where((t) => t.isPending).length;
          final confirmedCount = txList.where((t) => t.isConfirmed).length;
          final totalAmount = txList
              .where((t) => !t.isRejected)
              .fold<double>(0, (s, t) => s + t.amount);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 8),
                      Text('Tháng $month',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Text(_fmtMoney(totalAmount),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red.shade700)),
                    ],
                  ),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _statusChip('Chờ duyệt', pendingCount, AppColors.warning),
                      const SizedBox(width: 8),
                      _statusChip('Đã duyệt', confirmedCount, AppColors.success),
                      const Spacer(),
                      if (confirmedCount > 0)
                        TextButton.icon(
                          onPressed: _applying
                              ? null
                              : () => _applyConfirmedToMonth('$month-01'),
                          icon: _applying
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.publish, size: 16),
                          label: const Text('Áp dụng P&L',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),

                // Transaction list
                ...txList.map((tx) => _buildTransactionTile(tx)),

                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildTransactionTile(ExpenseTransaction tx) {
    final statusColor = tx.isPending
        ? AppColors.warning
        : tx.isConfirmed
            ? AppColors.success
            : tx.isRejected
                ? AppColors.error
                : Colors.grey;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(_categoryIcon(tx.category), size: 18, color: statusColor),
      ),
      title: Text(tx.categoryLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tx.vendor != null)
            Text(tx.vendor!, style: const TextStyle(fontSize: 11)),
          if (tx.description != null)
            Text(tx.description!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtMoney(tx.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red.shade700)),
              _buildConfidenceBadge(tx.confidence),
            ],
          ),
          if (tx.isPending) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 20,
              onSelected: (action) {
                switch (action) {
                  case 'confirm':
                    _confirmTransaction(tx);
                    break;
                  case 'edit':
                    _confirmWithEdits(tx);
                    break;
                  case 'reject':
                    _rejectTransaction(tx);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'confirm',
                    child: ListTile(
                        dense: true,
                        leading: Icon(Icons.check, color: AppColors.success),
                        title: Text('Xác nhận'))),
                const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit, color: AppColors.info),
                        title: Text('Sửa & Xác nhận'))),
                const PopupMenuItem(
                    value: 'reject',
                    child: ListTile(
                        dense: true,
                        leading: Icon(Icons.close, color: AppColors.error),
                        title: Text('Từ chối'))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'salary':
        return Icons.people;
      case 'rent':
        return Icons.house;
      case 'electricity':
        return Icons.bolt;
      case 'advertising':
        return Icons.campaign;
      case 'invoiced_purchases':
        return Icons.inventory;
      case 'equipment_maintenance':
        return Icons.build;
      case 'other_purchases':
        return Icons.shopping_cart;
      default:
        return Icons.receipt;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  String _fmtMoney(double value) {
    return '${_currencyFmt.format(value)} đ';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }
}
