import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/token_provider.dart';
import '../../models/daily_cashflow.dart';
import '../../services/daily_cashflow_service.dart';

/// Staff daily report page - Nhân viên báo cáo doanh thu cuối ca
class StaffDailyReportPage extends ConsumerStatefulWidget {
  const StaffDailyReportPage({super.key});

  @override
  ConsumerState<StaffDailyReportPage> createState() => _StaffDailyReportPageState();
}

class _StaffDailyReportPageState extends ConsumerState<StaffDailyReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = DailyCashflowService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSubmitting = false;
  DailyCashflow? _existingReport;
  String? _errorMessage;

  // Controllers
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();
  final _cardController = TextEditingController();
  final _ewalletController = TextEditingController();
  final _ordersController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingReport();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _transferController.dispose();
    _cardController.dispose();
    _ewalletController.dispose();
    _ordersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReport() async {
    final user = ref.read(currentUserProvider);
    if (user?.companyId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _service.getCashflowByDate(
        companyId: user!.companyId!,
        date: _selectedDate,
      );

      setState(() {
        _existingReport = report;
        if (report != null) {
          _cashController.text = report.cashAmount.toStringAsFixed(0);
          _transferController.text = report.transferAmount.toStringAsFixed(0);
          _cardController.text = report.cardAmount.toStringAsFixed(0);
          _ewalletController.text = report.ewalletAmount.toStringAsFixed(0);
          _ordersController.text = report.totalOrders.toString();
          _notesController.text = report.notes ?? '';
        } else {
          _clearForm();
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi tải báo cáo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _cashController.clear();
    _transferController.clear();
    _cardController.clear();
    _ewalletController.clear();
    _ordersController.clear();
    _notesController.clear();
  }

  double _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  double get _totalRevenue {
    return _parseAmount(_cashController.text) +
        _parseAmount(_transferController.text) +
        _parseAmount(_cardController.text) +
        _parseAmount(_ewalletController.text);
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user?.companyId == null || user?.id == null) {
      _showSnackBar('Không tìm thấy thông tin người dùng', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = await _service.createDraftReport(
        companyId: user!.companyId!,
        userId: user.id,
        reportDate: _selectedDate,
        cashAmount: _parseAmount(_cashController.text),
        transferAmount: _parseAmount(_transferController.text),
        cardAmount: _parseAmount(_cardController.text),
        ewalletAmount: _parseAmount(_ewalletController.text),
        totalRevenue: _totalRevenue,
        totalOrders: int.tryParse(_ordersController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      setState(() => _existingReport = report);
      _showSnackBar('Đã lưu nháp báo cáo');
    } catch (e) {
      _showSnackBar('Lỗi lưu báo cáo: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitForReview() async {
    if (_existingReport == null) {
      await _saveDraft();
      if (_existingReport == null) return;
    }

    final user = ref.read(currentUserProvider);
    if (user?.id == null) return;

    setState(() => _isSubmitting = true);

    try {
      final report = await _service.submitReport(
        reportId: _existingReport!.id,
        userId: user!.id,
      );

      setState(() => _existingReport = report);

      // 🪙 SABO Token: Thưởng token khi gửi báo cáo doanh thu
      try {
        await ref.read(tokenWalletProvider.notifier).earnTokens(
          15,
          sourceType: 'daily_report',
          sourceId: _existingReport?.id,
          description: 'Gửi báo cáo doanh thu ngày ${DateFormat('dd/MM').format(_selectedDate)}',
        );
      } catch (_) {
        // Token reward is non-critical
      }

      _showSnackBar('Đã gửi báo cáo cho quản lý duyệt');
    } catch (e) {
      _showSnackBar('Lỗi gửi báo cáo: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExistingReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date selector
                      _buildDateSelector(),
                      const SizedBox(height: 16),

                      // Status banner
                      if (_existingReport != null) _buildStatusBanner(),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Revenue form
                      _buildRevenueForm(),
                      const SizedBox(height: 16),

                      // Total summary
                      _buildTotalSummary(),
                      const SizedBox(height: 16),

                      // Notes
                      _buildNotesField(),
                      const SizedBox(height: 24),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.teal),
        title: Text(
          DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Ngày báo cáo'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 7)),
            lastDate: DateTime.now(),
            locale: const Locale('vi'),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
              _existingReport = null;
            });
            _loadExistingReport();
          }
        },
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _existingReport!.status;
    final color = Color(status.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(status), color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái: ${status.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (status == ReportStatus.rejected &&
                    _existingReport!.rejectionReason != null)
                  Text(
                    'Lý do: ${_existingReport!.rejectionReason}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Icons.edit_note;
      case ReportStatus.pending:
        return Icons.hourglass_empty;
      case ReportStatus.approved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
    }
  }

  Widget _buildRevenueForm() {
    final isEditable = _existingReport == null ||
        _existingReport!.status == ReportStatus.draft ||
        _existingReport!.status == ReportStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Doanh thu theo hình thức',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isEditable) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Chỉ xem', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildAmountField(
              controller: _cashController,
              label: 'Tiền mặt',
              icon: Icons.money,
              enabled: isEditable,
            ),
            const SizedBox(height: 12),
            _buildAmountField(
              controller: _transferController,
              label: 'Chuyển khoản',
              icon: Icons.account_balance,
              enabled: isEditable,
            ),
            const SizedBox(height: 12),
            _buildAmountField(
              controller: _cardController,
              label: 'Thẻ',
              icon: Icons.credit_card,
              enabled: isEditable,
            ),
            const SizedBox(height: 12),
            _buildAmountField(
              controller: _ewalletController,
              label: 'Ví điện tử',
              icon: Icons.phone_iphone,
              enabled: isEditable,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ordersController,
              enabled: isEditable,
              decoration: const InputDecoration(
                labelText: 'Số đơn hàng',
                prefixIcon: Icon(Icons.receipt_long),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: '₫',
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.isEmpty) return null; // Optional
        return null;
      },
    );
  }

  Widget _buildTotalSummary() {
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.summarize, color: Colors.teal, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng doanh thu',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    _currencyFormat.format(_totalRevenue),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final isEditable = _existingReport == null ||
        _existingReport!.status == ReportStatus.draft ||
        _existingReport!.status == ReportStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          enabled: isEditable,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (nếu có)',
            prefixIcon: Icon(Icons.note_alt),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _existingReport?.status;
    final isEditable = status == null ||
        status == ReportStatus.draft ||
        status == ReportStatus.rejected;

    if (!isEditable) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Save draft
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu nháp'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Submit for review
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitForReview,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text('Gửi cho quản lý duyệt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
