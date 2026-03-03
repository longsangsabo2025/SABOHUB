import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/daily_cashflow_service.dart';
import '../../models/daily_cashflow.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Page nhập báo cáo cuối ngày — 2 chế độ:
/// 1. Import File Excel (KiotViet / POS)
/// 2. Nhập thủ công (cho ngày trước hoặc không có file)
class DailyCashflowImportPage extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;
  final String? branchId;

  const DailyCashflowImportPage({
    super.key,
    required this.companyId,
    required this.companyName,
    this.branchId,
  });

  @override
  ConsumerState<DailyCashflowImportPage> createState() =>
      _DailyCashflowImportPageState();
}

class _DailyCashflowImportPageState
    extends ConsumerState<DailyCashflowImportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabC;
  final _service = DailyCashflowService();
  final _notesC = TextEditingController();

  // ── Shared state ──
  ParsedCashflowData? _parsed;
  bool _saving = false;
  String? _error;
  DailyCashflow? _saved;

  // ── Import File state ──
  String? _fileName;
  bool _loading = false;

  // ── Manual Entry state ──
  final _formKey = GlobalKey<FormState>();
  DateTime _manualDate = DateTime.now();
  final _branchNameC = TextEditingController();
  final _cashAmountC = TextEditingController();
  final _transferAmountC = TextEditingController();
  final _cardAmountC = TextEditingController();
  final _ewalletAmountC = TextEditingController();
  final _pointsAmountC = TextEditingController();
  final _totalOrdersC = TextEditingController();
  final _cashOrdersC = TextEditingController();
  final _transferOrdersC = TextEditingController();
  final _cardOrdersC = TextEditingController();
  final _ewalletOrdersC = TextEditingController();
  final _pointsOrdersC = TextEditingController();
  final _uniqueItemsC = TextEditingController();
  final _totalQuantityC = TextEditingController();

  // ── History ──
  List<DailyCashflow>? _history;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 2, vsync: this);
    _tabC.addListener(() {
      if (!_tabC.indexIsChanging) {
        setState(() {
          _error = null;
          _parsed = null;
          _saved = null;
        });
      }
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _tabC.dispose();
    _notesC.dispose();
    _branchNameC.dispose();
    _cashAmountC.dispose();
    _transferAmountC.dispose();
    _cardAmountC.dispose();
    _ewalletAmountC.dispose();
    _pointsAmountC.dispose();
    _totalOrdersC.dispose();
    _cashOrdersC.dispose();
    _transferOrdersC.dispose();
    _cardOrdersC.dispose();
    _ewalletOrdersC.dispose();
    _pointsOrdersC.dispose();
    _uniqueItemsC.dispose();
    _totalQuantityC.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadHistory() async {
    try {
      final list = await _service.getCashflowHistory(
        companyId: widget.companyId,
        branchId: widget.branchId,
        limit: 14,
      );
      if (mounted) setState(() { _history = list; _loadingHistory = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  // ── Import file ──
  Future<void> _pickFile() async {
    setState(() { _error = null; _parsed = null; _saved = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      setState(() => _error = 'Không đọc được file.');
      return;
    }

    setState(() { _loading = true; _fileName = file.name; });

    try {
      final parsed = _service.parseExcelFile(file.bytes!, file.name);
      setState(() { _parsed = parsed; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Manual entry → ParsedCashflowData ──
  void _submitManual() {
    if (!_formKey.currentState!.validate()) return;

    final cash = _parseAmount(_cashAmountC.text);
    final transfer = _parseAmount(_transferAmountC.text);
    final card = _parseAmount(_cardAmountC.text);
    final ewallet = _parseAmount(_ewalletAmountC.text);
    final points = _parseAmount(_pointsAmountC.text);
    final total = cash + transfer + card + ewallet + points;

    if (total <= 0) {
      setState(() => _error = 'Vui lòng nhập ít nhất 1 khoản doanh thu.');
      return;
    }

    final totalOrders = int.tryParse(_totalOrdersC.text.trim()) ?? 0;

    setState(() {
      _parsed = ParsedCashflowData(
        reportDate: _manualDate,
        branchName: _branchNameC.text.trim().isEmpty
            ? null
            : _branchNameC.text.trim(),
        cashAmount: cash,
        transferAmount: transfer,
        cardAmount: card,
        ewalletAmount: ewallet,
        pointsAmount: points,
        totalRevenue: total,
        totalOrders: totalOrders,
        cashOrders: int.tryParse(_cashOrdersC.text.trim()) ?? 0,
        transferOrders: int.tryParse(_transferOrdersC.text.trim()) ?? 0,
        cardOrders: int.tryParse(_cardOrdersC.text.trim()) ?? 0,
        ewalletOrders: int.tryParse(_ewalletOrdersC.text.trim()) ?? 0,
        pointsOrders: int.tryParse(_pointsOrdersC.text.trim()) ?? 0,
        uniqueItems: int.tryParse(_uniqueItemsC.text.trim()) ?? 0,
        totalQuantity: int.tryParse(_totalQuantityC.text.trim()) ?? 0,
        sourceFile: 'manual_entry',
      );
      _error = null;
    });
  }

  double _parseAmount(String text) {
    final cleaned = text.trim().replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  // ── Save (shared) ──
  Future<void> _save() async {
    if (_parsed == null) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() => _error = 'Chưa đăng nhập.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final saved = await _service.saveCashflow(
        companyId: widget.companyId,
        userId: user.id,
        parsed: _parsed!,
        branchId: widget.branchId,
        notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
      );
      setState(() { _saved = saved; _saving = false; });
      _loadHistory();
      if (mounted) HapticFeedback.heavyImpact();
    } catch (e) {
      setState(() {
        _error = 'Lỗi lưu: ${e.toString().replaceAll('Exception: ', '')}';
        _saving = false;
      });
    }
  }

  // ── Date picker ──
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
      helpText: 'Chọn ngày báo cáo',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) setState(() => _manualDate = picked);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Báo Cáo Cuối Ngày',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.companyName,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        bottom: TabBar(
          controller: _tabC,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.upload_file, size: 18), text: 'Import File'),
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Nhập thủ công'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabC,
        children: [
          _buildImportTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // TAB 1: IMPORT FILE
  // ─────────────────────────────────────────────────

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUploadSection(),
          const SizedBox(height: 16),
          if (_error != null && _tabC.index == 0) _buildError(),
          if (_parsed != null && _saved == null && _tabC.index == 0) ...[
            _buildPreview(_parsed!),
            const SizedBox(height: 12),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildSaveButton(),
          ],
          if (_saved != null && _tabC.index == 0) _buildSuccess(),
          const SizedBox(height: 24),
          _buildHistory(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // TAB 2: MANUAL ENTRY
  // ─────────────────────────────────────────────────

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show preview + save if manual data was submitted
          if (_parsed != null && _saved == null && _tabC.index == 1) ...[
            _buildPreview(_parsed!),
            const SizedBox(height: 12),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildSaveButton(),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() { _parsed = null; _error = null; }),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Sửa lại'),
              ),
            ),
          ] else if (_saved != null && _tabC.index == 1)
            _buildSuccess()
          else ...[
            _buildManualForm(),
          ],

          if (_error != null && _tabC.index == 1) ...[
            const SizedBox(height: 12),
            _buildError(),
          ],

          const SizedBox(height: 24),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date picker ──
          _sectionCard(
            icon: Icons.calendar_today,
            title: 'Ngày báo cáo',
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withValues(alpha: 0.04),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_manualDate),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Branch ──
          _sectionCard(
            icon: Icons.store,
            title: 'Chi nhánh',
            child: TextFormField(
              controller: _branchNameC,
              decoration: const InputDecoration(
                hintText: 'VD: Chi nhánh trung tâm',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Revenue ──
          _sectionCard(
            icon: Icons.payments,
            title: 'Doanh thu (₫)',
            child: Column(
              children: [
                _amountField(_cashAmountC, 'Tiền mặt', Colors.green),
                const SizedBox(height: 8),
                _amountField(_transferAmountC, 'Chuyển khoản', Colors.blue),
                const SizedBox(height: 8),
                _amountField(_cardAmountC, 'Thẻ', Colors.purple),
                const SizedBox(height: 8),
                _amountField(_ewalletAmountC, 'Ví điện tử', Colors.orange),
                const SizedBox(height: 8),
                _amountField(_pointsAmountC, 'Điểm', Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Orders ──
          _sectionCard(
            icon: Icons.receipt_long,
            title: 'Số giao dịch',
            child: Column(
              children: [
                _intField(_totalOrdersC, 'Tổng hóa đơn'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _intField(_cashOrdersC, 'TM')),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(_transferOrdersC, 'CK')),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(_cardOrdersC, 'Thẻ')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _intField(_ewalletOrdersC, 'Ví ĐT')),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(_pointsOrdersC, 'Điểm')),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Products ──
          _sectionCard(
            icon: Icons.inventory_2,
            title: 'Hàng hóa',
            child: Row(
              children: [
                Expanded(child: _intField(_uniqueItemsC, 'Số mặt hàng')),
                const SizedBox(width: 10),
                Expanded(child: _intField(_totalQuantityC, 'Tổng SL bán')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit ──
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _submitManual,
              icon: const Icon(Icons.preview),
              label: const Text('Xem trước & Kiểm tra'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED UI BUILDERS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _intField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        hintText: '0',
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _loading ? null : _pickFile,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _parsed != null ? AppColors.success : Colors.grey.shade300,
            width: _parsed != null ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (_loading)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Icon(
                _parsed != null ? Icons.check_circle : Icons.upload_file,
                size: 48,
                color: _parsed != null ? AppColors.success : AppColors.primary,
              ),
            const SizedBox(height: 12),
            Text(
              _parsed != null
                  ? '✅ Đã đọc: $_fileName'
                  : 'Chọn file Excel báo cáo cuối ngày',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    _parsed != null ? AppColors.success : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _parsed != null
                  ? 'Nhấn để chọn file khác'
                  : 'Hỗ trợ .xls và .xlsx từ KiotViet / POS',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
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
    );
  }

  Widget _buildPreview(ParsedCashflowData p) {
    final fmt = NumberFormat('#,###', 'vi');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              const Icon(Icons.preview, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Xem trước dữ liệu',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // Date & Branch
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _infoChip(Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(p.reportDate)),
                if (p.branchName != null) ...[
                  const SizedBox(width: 12),
                  Flexible(child: _infoChip(Icons.store, p.branchName!)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Revenue
          const Text('Doanh thu theo phương thức',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _revenueRow('Tiền mặt', p.cashAmount, p.cashOrders, Colors.green),
          _revenueRow(
              'Chuyển khoản', p.transferAmount, p.transferOrders, Colors.blue),
          _revenueRow('Thẻ', p.cardAmount, p.cardOrders, Colors.purple),
          _revenueRow(
              'Ví điện tử', p.ewalletAmount, p.ewalletOrders, Colors.orange),
          _revenueRow('Điểm', p.pointsAmount, p.pointsOrders, Colors.teal),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('TỔNG THỰC THU',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Text(
                '${fmt.format(p.totalRevenue)} ₫',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Orders & Products
          Row(
            children: [
              _metricCard('Hóa đơn', '${p.totalOrders}',
                  Icons.receipt_long, Colors.blue),
              const SizedBox(width: 8),
              _metricCard('Mặt hàng', '${p.uniqueItems}',
                  Icons.inventory_2, Colors.orange),
              const SizedBox(width: 8),
              _metricCard('SL SP', '${p.totalQuantity}',
                  Icons.shopping_bag, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueRow(String label, double amount, int orders, Color color) {
    final fmt = NumberFormat('#,###', 'vi');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          if (orders > 0)
            Text('$orders GD  ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          Text(
            amount > 0 ? '${fmt.format(amount)} ₫' : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  amount > 0 ? Colors.grey.shade800 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _notesC,
        decoration: const InputDecoration(
          labelText: 'Ghi chú (tùy chọn)',
          hintText: 'VD: Ca tối, quán đông...',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.cloud_upload),
        label: Text(_saving ? 'Đang lưu...' : 'Xác nhận & Lưu dữ liệu'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final s = _saved!;
    final fmt = NumberFormat('#,###', 'vi');
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 56, color: AppColors.success),
          const SizedBox(height: 12),
          const Text('Đã lưu thành công!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success)),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd/MM/yyyy').format(s.reportDate)} — ${fmt.format(s.totalRevenue)} ₫',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.add),
            label: const Text('Nhập thêm'),
          ),
        ],
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _parsed = null;
      _saved = null;
      _fileName = null;
      _error = null;
      _notesC.clear();
      _branchNameC.clear();
      _cashAmountC.clear();
      _transferAmountC.clear();
      _cardAmountC.clear();
      _ewalletAmountC.clear();
      _pointsAmountC.clear();
      _totalOrdersC.clear();
      _cashOrdersC.clear();
      _transferOrdersC.clear();
      _cardOrdersC.clear();
      _ewalletOrdersC.clear();
      _pointsOrdersC.clear();
      _uniqueItemsC.clear();
      _totalQuantityC.clear();
      _manualDate = DateTime.now();
    });
  }

  // ─────────────────────────────────────────────────
  // HISTORY
  // ─────────────────────────────────────────────────

  Widget _buildHistory() {
    final fmt = NumberFormat('#,###', 'vi');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            const Text('Lịch sử nhập liệu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_history != null)
              Text('${_history!.length} bản ghi',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingHistory)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_history == null || _history!.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có dữ liệu nào',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...(_history!.map((cf) => _buildHistoryCard(cf, fmt))),
      ],
    );
  }

  Widget _buildHistoryCard(DailyCashflow cf, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(DateFormat('dd').format(cf.reportDate),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text(DateFormat('MM/yy').format(cf.reportDate),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fmt.format(cf.totalRevenue)} ₫',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _miniTag('${cf.totalOrders} HĐ', Colors.blue),
                    const SizedBox(width: 4),
                    _miniTag(
                        'TM: ${fmt.format(cf.cashAmount)}', Colors.green),
                    if (cf.transferAmount > 0) ...[
                      const SizedBox(width: 4),
                      _miniTag(
                          'CK: ${fmt.format(cf.transferAmount)}',
                          Colors.indigo),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cf.sourceFile == 'manual_entry'
                      ? '✏️ Nhập thủ công'
                      : '📄 ${cf.sourceFile ?? 'Import'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          if (cf.branchName != null)
            Text(cf.branchName!,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
