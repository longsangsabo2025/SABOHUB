import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// RESERVATION FORM PAGE — Tạo / Sửa đặt bàn
/// ═══════════════════════════════════════════════════════════════
class ReservationFormPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Reservation? existingReservation;

  const ReservationFormPage({
    super.key,
    this.initialDate,
    this.existingReservation,
  });

  @override
  ConsumerState<ReservationFormPage> createState() =>
      _ReservationFormPageState();
}

class _ReservationFormPageState extends ConsumerState<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int _duration = 60;
  int _guestCount = 2;
  ReservationType _type = ReservationType.table;
  String? _selectedTableId;
  String? _selectedTableName;

  List<Map<String, dynamic>> _availableTables = [];
  bool _isLoadingTables = false;
  bool _isSaving = false;
  String? _doubleBookError;

  bool get _isEditing => widget.existingReservation != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    if (_isEditing) {
      final r = widget.existingReservation!;
      _nameCtrl.text = r.customerName;
      _phoneCtrl.text = r.customerPhone;
      _emailCtrl.text = r.customerEmail ?? '';
      _noteCtrl.text = r.note ?? '';
      _selectedDate = r.reservationDate;
      _selectedTime = r.startTime;
      _duration = r.durationMinutes;
      _guestCount = r.guestCount;
      _type = r.type;
      _selectedTableId = r.tableOrRoomId;
      _selectedTableName = r.tableOrRoomName;
    }

    _loadTables();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── Load available tables ──────────────────────────
  Future<void> _loadTables() async {
    final user = ref.read(currentUserProvider);
    if (user?.companyId == null) return;

    setState(() => _isLoadingTables = true);
    try {
      final response = await Supabase.instance.client
          .from('tables')
          .select('id, table_number, table_type, status')
          .eq('company_id', user!.companyId!)
          .order('table_number', ascending: true)
          .limit(100);
      if (mounted) {
        setState(() {
          _availableTables = List<Map<String, dynamic>>.from(response);
          _isLoadingTables = false;
        });
      }
    } catch (e) {
      AppLogger.error('ReservationForm._loadTables', e);
      if (mounted) setState(() => _isLoadingTables = false);
    }
  }

  // ─── Check double booking ──────────────────────────
  Future<void> _checkDoubleBooking() async {
    if (_selectedTableId == null) {
      setState(() => _doubleBookError = null);
      return;
    }
    try {
      final isDouble = await ref
          .read(reservationActionsProvider)
          .isDoubleBooked(
            tableId: _selectedTableId!,
            date: _selectedDate,
            startTime: _selectedTime,
            durationMinutes: _duration,
            excludeReservationId:
                _isEditing ? widget.existingReservation!.id : null,
          );
      if (mounted) {
        setState(() {
          _doubleBookError =
              isDouble ? 'Bàn đã được đặt trong khung giờ này!' : null;
        });
      }
    } catch (e) {
      AppLogger.error('ReservationForm._checkDoubleBooking', e);
    }
  }

  // ─── Save ──────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_doubleBookError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_doubleBookError!),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final actions = ref.read(reservationActionsProvider);

      if (_isEditing) {
        await actions.update(widget.existingReservation!.id, {
          'customer_name': _nameCtrl.text.trim(),
          'customer_phone': _phoneCtrl.text.trim(),
          'customer_email':
              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          'type': _type.value,
          'reservation_date':
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          'start_time':
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'duration_minutes': _duration,
          'guest_count': _guestCount,
          'table_or_room_id': _selectedTableId,
          'table_or_room_name': _selectedTableName,
          'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        });
      } else {
        final reservation = Reservation(
          id: '', // Will be generated
          companyId: user?.companyId,
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          customerEmail:
              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          type: _type,
          status: ReservationStatus.pending,
          reservationDate: _selectedDate,
          startTime: _selectedTime,
          durationMinutes: _duration,
          guestCount: _guestCount,
          tableOrRoomId: _selectedTableId,
          tableOrRoomName: _selectedTableName,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          createdBy: user?.id,
          createdAt: DateTime.now(),
        );
        await actions.create(reservation);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Đã cập nhật đặt bàn'
                : '✅ Đã tạo đặt bàn mới'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('ReservationForm._save', e);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa đặt bàn' : 'Đặt bàn mới'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section: Thông tin khách ──
            _sectionTitle('👤 Thông tin khách hàng'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Tên khách hàng *',
              icon: Icons.person,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Số điện thoại *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập SĐT';
                if (v.trim().length < 9) return 'SĐT không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email (tùy chọn)',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // ── Section: Chi tiết đặt bàn ──
            _sectionTitle('📋 Chi tiết đặt bàn'),
            const SizedBox(height: 8),

            // Reservation type
            _buildDropdown<ReservationType>(
              label: 'Loại',
              icon: Icons.category,
              value: _type,
              items: ReservationType.values
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Row(children: [
                        Icon(t.icon, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ])))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),

            // Date & Time row
            Row(
              children: [
                Expanded(
                  child: _buildDateField(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Duration & Guest count row
            Row(
              children: [
                Expanded(child: _buildDurationField()),
                const SizedBox(width: 12),
                Expanded(child: _buildGuestCountField()),
              ],
            ),
            const SizedBox(height: 12),

            // Table selection
            _buildTableSelector(),
            if (_doubleBookError != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_doubleBookError!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Notes
            _buildTextField(
              controller: _noteCtrl,
              label: 'Ghi chú (tùy chọn)',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Summary card
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.surface),
                      )
                    : Icon(Icons.save),
                label:
                    Text(_isSaving ? 'Đang lưu...' : (_isEditing ? 'Cập nhật' : 'Tạo đặt bàn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          locale: const Locale('vi', 'VN'),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _checkDoubleBooking();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày',
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(dateStr, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildTimeField() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
          _checkDoubleBooking();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Giờ',
          prefixIcon: const Icon(Icons.access_time, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(timeStr, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildDurationField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Thời lượng',
        prefixIcon: const Icon(Icons.timer, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _duration,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 30, child: Text('30 phút')),
            DropdownMenuItem(value: 60, child: Text('1 giờ')),
            DropdownMenuItem(value: 90, child: Text('1.5 giờ')),
            DropdownMenuItem(value: 120, child: Text('2 giờ')),
            DropdownMenuItem(value: 180, child: Text('3 giờ')),
            DropdownMenuItem(value: 240, child: Text('4 giờ')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _duration = v);
              _checkDoubleBooking();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGuestCountField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Số khách',
        prefixIcon: const Icon(Icons.people, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                _guestCount > 1 ? () => setState(() => _guestCount--) : null,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$_guestCount',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            onPressed:
                _guestCount < 50 ? () => setState(() => _guestCount++) : null,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    if (_isLoadingTables) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Đang tải bàn...',
          border: OutlineInputBorder(),
        ),
        child: SizedBox(
            height: 20,
            child: Center(child: LinearProgressIndicator())),
      );
    }

    final tableItems = _availableTables.map((t) {
      final id = t['id'] as String;
      final number = t['table_number'] ?? '?';
      final type = t['table_type'] ?? '';
      final status = t['status'] ?? 'available';
      final isOccupied = status == 'occupied';
      return DropdownMenuItem<String>(
        value: id,
        child: Row(
          children: [
            Icon(
              isOccupied ? Icons.block : Icons.table_restaurant,
              size: 16,
              color: isOccupied ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 8),
            Text('Bàn $number'),
            if (type.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text('($type)',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ],
        ),
      );
    }).toList();

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Chọn bàn (tùy chọn)',
        prefixIcon: const Icon(Icons.table_restaurant, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTableId,
          hint: const Text('Chưa chọn bàn'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text('— Chưa chọn —')),
            ...tableItems,
          ],
          onChanged: (v) {
            setState(() {
              _selectedTableId = v;
              if (v != null) {
                final table = _availableTables.firstWhere(
                    (t) => t['id'] == v,
                    orElse: () => {});
                _selectedTableName =
                    table.isNotEmpty ? 'Bàn ${table['table_number']}' : null;
              } else {
                _selectedTableName = null;
              }
            });
            _checkDoubleBooking();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final endTime = TimeOfDay(
      hour: (_selectedTime.hour + _duration ~/ 60) % 24,
      minute: _selectedTime.minute + _duration % 60,
    );
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'
        ' - '
        '${endTime.hour.toString().padLeft(2, '0')}:${(endTime.minute % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Tóm tắt đặt bàn',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const Divider(height: 16),
          _summaryRow('📅 Ngày',
              DateFormat('dd/MM/yyyy (EEEE)', 'vi').format(_selectedDate)),
          _summaryRow('🕐 Giờ', timeStr),
          _summaryRow('⏱️ Thời lượng', '$_duration phút'),
          _summaryRow('👥 Số khách', '$_guestCount'),
          _summaryRow('📍 Loại', _type.label),
          if (_selectedTableName != null)
            _summaryRow('🪑 Bàn', _selectedTableName!),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
