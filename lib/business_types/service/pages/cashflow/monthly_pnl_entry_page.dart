import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/monthly_pnl_service.dart';
import '../../models/monthly_pnl.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Page nhập / chỉnh sửa chi phí hàng tháng + đính kèm hóa đơn, chứng từ
class MonthlyPnlEntryPage extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;
  final MonthlyPnl? existingRecord; // null = create new

  const MonthlyPnlEntryPage({
    super.key,
    required this.companyId,
    required this.companyName,
    this.existingRecord,
  });

  @override
  ConsumerState<MonthlyPnlEntryPage> createState() =>
      _MonthlyPnlEntryPageState();
}

class _MonthlyPnlEntryPageState extends ConsumerState<MonthlyPnlEntryPage> {
  final _service = MonthlyPnlService();
  final _formKey = GlobalKey<FormState>();

  // ── Month selector ──
  late int _selectedYear;
  late int _selectedMonth;

  // ── Revenue Controllers ──
  final _grossRevenueC = TextEditingController();
  final _netRevenueC = TextEditingController();
  final _cogsC = TextEditingController();

  // ── Expense Category Controllers ──
  final _salaryC = TextEditingController();
  final _rentC = TextEditingController();
  final _electricityC = TextEditingController();
  final _advertisingC = TextEditingController();
  final _invoicedPurchasesC = TextEditingController();
  final _otherPurchasesC = TextEditingController();

  // ── Other ──
  final _otherIncomeC = TextEditingController();
  final _otherExpensesC = TextEditingController();
  final _notesC = TextEditingController();

  // ── State ──
  bool _saving = false;
  String? _error;
  bool _saved = false;

  // ── Attachments ──
  List<Map<String, dynamic>> _attachments = [];
  bool _loadingAttachments = false;
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.existingRecord != null) {
      final r = widget.existingRecord!;
      _selectedYear = r.reportMonth.year;
      _selectedMonth = r.reportMonth.month;
      _populateFromRecord(r);
      _loadAttachments();
    } else {
      // Default to current month
      _selectedYear = now.year;
      _selectedMonth = now.month;
    }
  }

  void _populateFromRecord(MonthlyPnl r) {
    _grossRevenueC.text = _fmtNumber(r.grossRevenue);
    _netRevenueC.text = _fmtNumber(r.netRevenue);
    _cogsC.text = _fmtNumber(r.cogs);
    _salaryC.text = _fmtNumber(r.salaryExpenses);
    _rentC.text = _fmtNumber(r.rentExpense);
    _electricityC.text = _fmtNumber(r.electricityExpense);
    _advertisingC.text = _fmtNumber(r.advertisingExpense);
    _invoicedPurchasesC.text = _fmtNumber(r.invoicedPurchases);
    _otherPurchasesC.text = _fmtNumber(r.otherPurchases);
    _otherIncomeC.text = _fmtNumber(r.otherIncome);
    _otherExpensesC.text = _fmtNumber(r.otherExpenses);
    _notesC.text = r.notes ?? '';
  }

  String _fmtNumber(double v) => v > 0 ? v.toStringAsFixed(0) : '';

  Future<void> _loadAttachments() async {
    if (widget.existingRecord == null) return;
    setState(() => _loadingAttachments = true);
    try {
      final list = await _service.getPnlAttachments(widget.existingRecord!.id);
      if (mounted) setState(() { _attachments = list; _loadingAttachments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAttachments = false);
    }
  }

  @override
  void dispose() {
    _grossRevenueC.dispose();
    _netRevenueC.dispose();
    _cogsC.dispose();
    _salaryC.dispose();
    _rentC.dispose();
    _electricityC.dispose();
    _advertisingC.dispose();
    _invoicedPurchasesC.dispose();
    _otherPurchasesC.dispose();
    _otherIncomeC.dispose();
    _otherExpensesC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  double _parseAmt(String text) {
    final cleaned = text.trim().replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _error = 'Chưa đăng nhập.');
      return;
    }

    // Parse values
    final grossRevenue = _parseAmt(_grossRevenueC.text);
    final netRevenue = _parseAmt(_netRevenueC.text);
    final cogs = _parseAmt(_cogsC.text);
    final salary = _parseAmt(_salaryC.text);
    final rent = _parseAmt(_rentC.text);
    final electricity = _parseAmt(_electricityC.text);
    final advertising = _parseAmt(_advertisingC.text);
    final invoicedPurch = _parseAmt(_invoicedPurchasesC.text);
    final otherPurch = _parseAmt(_otherPurchasesC.text);
    final otherIncome = _parseAmt(_otherIncomeC.text);
    final otherExpenses = _parseAmt(_otherExpensesC.text);

    // Calculate derived values
    final grossProfit = netRevenue - cogs;
    final totalExpenses = salary + rent + electricity + advertising +
        invoicedPurch + otherPurch + otherExpenses;
    final operatingProfit = grossProfit - totalExpenses;
    final netProfit = operatingProfit + otherIncome;

    setState(() { _saving = true; _error = null; });

    try {
      await _service.upsertMonthlyPnl(
        companyId: widget.companyId,
        reportMonth: DateTime(_selectedYear, _selectedMonth, 1),
        grossRevenue: grossRevenue,
        netRevenue: netRevenue,
        cogs: cogs,
        grossProfit: grossProfit,
        totalExpenses: totalExpenses,
        salaryExpenses: salary,
        operatingProfit: operatingProfit,
        rentExpense: rent,
        electricityExpense: electricity,
        advertisingExpense: advertising,
        invoicedPurchases: invoicedPurch,
        otherPurchases: otherPurch,
        otherIncome: otherIncome,
        otherExpenses: otherExpenses,
        netProfit: netProfit,
        notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
        importedBy: user.id,
      );

      setState(() { _saved = true; _saving = false; });
      if (mounted) HapticFeedback.heavyImpact();
    } catch (e) {
      setState(() {
        _error = 'Lỗi lưu: ${e.toString().replaceAll('Exception: ', '')}';
        _saving = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE UPLOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> _pickAndUploadFile() async {
    // Need an existing record to attach files
    if (widget.existingRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng lưu báo cáo trước khi đính kèm file.'),
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'xls', 'xlsx', 'doc', 'docx'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể đọc file')),
          );
        }
        return;
      }

      setState(() => _uploadingFile = true);

      final user = ref.read(currentUserProvider);

      final attachment = await _service.uploadPnlAttachment(
        pnlRecordId: widget.existingRecord!.id,
        companyId: widget.companyId,
        fileName: file.name,
        fileBytes: file.bytes!,
        category: null,
        uploadedBy: user?.id,
      );

      setState(() {
        _attachments.insert(0, attachment);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã tải file lên thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _deleteAttachment(String attachmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa file?'),
        content: const Text('Bạn có chắc muốn xóa file đính kèm này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deletePnlAttachment(attachmentId);
      setState(() {
        _attachments.removeWhere((a) => a['id'] == attachmentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa file.')),
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

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRecord != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Sửa Chi Phí Tháng' : 'Nhập Chi Phí Tháng',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(widget.companyName,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.surface54)),
          ],
        ),
      ),
      body: _saved ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Month Picker ──
            _sectionCard(
              icon: Icons.calendar_month,
              title: 'Tháng báo cáo',
              child: Row(
                children: [
                  // Month
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Tháng',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('Tháng $m'),
                              ))
                          .toList(),
                      onChanged: widget.existingRecord != null
                          ? null  // can't change month when editing
                          : (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Year
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Năm',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: List.generate(5, (i) => DateTime.now().year - i)
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y'),
                              ))
                          .toList(),
                      onChanged: widget.existingRecord != null
                          ? null
                          : (v) => setState(() => _selectedYear = v ?? _selectedYear),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Revenue Section ──
            _sectionCard(
              icon: Icons.trending_up,
              title: 'Doanh thu (₫)',
              child: Column(
                children: [
                  _amountField(_grossRevenueC, 'Doanh thu gộp', Colors.blue),
                  const SizedBox(height: 8),
                  _amountField(_netRevenueC, 'Doanh thu thuần', Colors.green),
                  const SizedBox(height: 8),
                  _amountField(_cogsC, 'Giá vốn (COGS)', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ══════════════════════════════════════════════
            // EXPENSE CATEGORIES — 6 hạng mục chi phí
            // ══════════════════════════════════════════════
            _sectionCard(
              icon: Icons.receipt_long,
              title: 'Chi phí hàng tháng (₫)',
              subtitle: '6 hạng mục chính',
              child: Column(
                children: [
                  _amountField(_salaryC, '💰 Lương nhân viên', Colors.indigo),
                  const SizedBox(height: 8),
                  _amountField(_rentC, '🏠 Mặt bằng', Colors.brown),
                  const SizedBox(height: 8),
                  _amountField(_electricityC, '⚡ Điện', Colors.amber.shade700),
                  const SizedBox(height: 8),
                  _amountField(_advertisingC, '📢 Quảng cáo', Colors.pink),
                  const SizedBox(height: 8),
                  _amountField(_invoicedPurchasesC, '🧾 Nhập hàng (có hóa đơn)', Colors.teal),
                  const SizedBox(height: 8),
                  _amountField(_otherPurchasesC, '🛒 Mua vật dụng/hàng hóa khác', Colors.grey.shade700),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Other income/expenses ──
            _sectionCard(
              icon: Icons.more_horiz,
              title: 'Khác',
              child: Column(
                children: [
                  _amountField(_otherIncomeC, 'Thu nhập khác', Colors.green.shade600),
                  const SizedBox(height: 8),
                  _amountField(_otherExpensesC, 'Chi phí khác', Colors.red.shade400),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Notes ──
            _sectionCard(
              icon: Icons.notes,
              title: 'Ghi chú',
              child: TextFormField(
                controller: _notesC,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'VD: Tháng cao điểm, sửa chữa quán...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ══════════════════════════════════════════════
            // FILE ATTACHMENTS — Hóa đơn / Chứng từ
            // ══════════════════════════════════════════════
            _buildAttachmentsSection(),
            const SizedBox(height: 16),

            // ── Summary ──
            _buildExpenseSummary(),
            const SizedBox(height: 16),

            // ── Error ──
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),

            // ── Save Button ──
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
                    : const Icon(Icons.save),
                label: Text(_saving
                    ? 'Đang lưu...'
                    : widget.existingRecord != null
                        ? 'Cập nhật báo cáo'
                        : 'Lưu báo cáo tháng'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EXPENSE SUMMARY (real-time)
  // ─────────────────────────────────────────────────

  Widget _buildExpenseSummary() {
    final fmt = NumberFormat('#,###', 'vi');
    final salary = _parseAmt(_salaryC.text);
    final rent = _parseAmt(_rentC.text);
    final elec = _parseAmt(_electricityC.text);
    final adv = _parseAmt(_advertisingC.text);
    final invPurch = _parseAmt(_invoicedPurchasesC.text);
    final otherPurch = _parseAmt(_otherPurchasesC.text);
    final otherExp = _parseAmt(_otherExpensesC.text);

    final totalExp = salary + rent + elec + adv + invPurch + otherPurch + otherExp;
    final netRev = _parseAmt(_netRevenueC.text);
    final cogs = _parseAmt(_cogsC.text);
    final grossProfit = netRev - cogs;
    final otherIncome = _parseAmt(_otherIncomeC.text);
    final netProfit = grossProfit - totalExp + otherIncome;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: netProfit >= 0
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: netProfit >= 0
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 16,
                  color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700),
              const SizedBox(width: 6),
              Text('Tổng kết tạm tính',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('Lợi nhuận gộp', grossProfit, fmt),
          _summaryRow('Tổng chi phí', -totalExp, fmt),
          _summaryRow('Thu nhập khác', otherIncome, fmt),
          const Divider(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('LỢI NHUẬN RÒNG',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Text(
                '${netProfit >= 0 ? '+' : ''}${fmt.format(netProfit)} ₫',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Text(
            '${value >= 0 ? '' : '-'}${fmt.format(value.abs())} ₫',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: value >= 0 ? Colors.green.shade700 : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // ATTACHMENTS SECTION
  // ─────────────────────────────────────────────────

  Widget _buildAttachmentsSection() {
    return _sectionCard(
      icon: Icons.attach_file,
      title: 'Hóa đơn / Chứng từ đính kèm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload button
          OutlinedButton.icon(
            onPressed: _uploadingFile ? null : _pickAndUploadFile,
            icon: _uploadingFile
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file, size: 18),
            label: Text(_uploadingFile ? 'Đang tải...' : 'Chọn file đính kèm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hỗ trợ: JPG, PNG, PDF, Excel, Word',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),

          if (widget.existingRecord == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu báo cáo trước → quay lại sửa để đính kèm file.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Loading
          if (_loadingAttachments)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          // Attachment list
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${_attachments.length} file đính kèm',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ..._attachments.map((a) => _buildAttachmentCard(a)),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    final fileName = attachment['file_name'] as String? ?? 'file';
    final fileUrl = attachment['file_url'] as String?;
    final fileSize = attachment['file_size'] as int? ?? 0;
    final createdAt = attachment['created_at'] as String?;
    final id = attachment['id'] as String;

    IconData icon;
    Color iconColor;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        icon = Icons.image;
        iconColor = Colors.green;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        iconColor = Colors.green.shade700;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.blue;
    }

    final sizeStr = fileSize > 1024 * 1024
        ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(fileSize / 1024).toStringAsFixed(0)} KB';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '$sizeStr${createdAt != null ? ' • ${DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(createdAt))}' : ''}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // View
          if (fileUrl != null)
            IconButton(
              onPressed: () => _openUrl(fileUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Mở file',
              color: Colors.blue,
              visualDensity: VisualDensity.compact,
            ),
          // Delete
          IconButton(
            onPressed: () => _deleteAttachment(id),
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Xóa',
            color: Colors.red.shade400,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────
  // SUCCESS
  // ─────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('Đã lưu thành công!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success)),
            const SizedBox(height: 8),
            Text(
              'Báo cáo tháng $_selectedMonth/$_selectedYear',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _saved = false;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nhập thêm tháng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _amountField(TextEditingController c, String label, Color color) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}), // rebuild summary
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        prefixIconConstraints: const BoxConstraints(maxWidth: 40),
        suffixText: '₫',
        border: const OutlineInputBorder(),
        isDense: true,
        hintText: '0',
      ),
    );
  }
}
