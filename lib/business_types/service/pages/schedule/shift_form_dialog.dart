import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/shift_schedule.dart';
import '../../providers/shift_scheduling_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Bottom sheet form — thêm / sửa ca làm việc
class ShiftFormDialog extends ConsumerStatefulWidget {
  /// Nếu đang edit
  final StaffShiftSchedule? existingShift;

  /// Pre-fill cho trường hợp tap vào ô trống
  final String? preselectedEmployeeId;
  final String? preselectedEmployeeName;
  final DateTime? preselectedDate;
  final DateTime? weekStart;

  /// Callback sau khi lưu thành công
  final VoidCallback? onSaved;

  const ShiftFormDialog({
    super.key,
    this.existingShift,
    this.preselectedEmployeeId,
    this.preselectedEmployeeName,
    this.preselectedDate,
    this.weekStart,
    this.onSaved,
  });

  @override
  ConsumerState<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends ConsumerState<ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEmployeeId;
  DateTime? _selectedDate;
  ScheduleShiftType _selectedShiftType = ScheduleShiftType.morning;
  String _startTime = '07:00';
  String _endTime = '14:00';
  final _notesController = TextEditingController();
  bool _isSaving = false;
  List<StaffShiftSchedule> _conflicts = [];

  bool get _isEditing => widget.existingShift != null;

  @override
  void initState() {
    super.initState();
    final shift = widget.existingShift;
    if (shift != null) {
      _selectedEmployeeId = shift.employeeId;
      _selectedDate = shift.date;
      _selectedShiftType = shift.shiftType;
      _startTime = shift.startTime;
      _endTime = shift.endTime;
      _notesController.text = shift.notes ?? '';
    } else {
      _selectedEmployeeId = widget.preselectedEmployeeId;
      _selectedDate = widget.preselectedDate ?? DateTime.now();
      _applyShiftDefaults(_selectedShiftType);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _applyShiftDefaults(ScheduleShiftType type) {
    _startTime = StaffShiftSchedule.formatTimeOfDay(type.defaultStart);
    _endTime = StaffShiftSchedule.formatTimeOfDay(type.defaultEnd);
  }

  Future<void> _checkConflicts() async {
    if (_selectedEmployeeId == null || _selectedDate == null) {
      setState(() => _conflicts = []);
      return;
    }

    try {
      final service = ref.read(shiftSchedulingServiceProvider);
      final result = await service.checkConflicts(
        employeeId: _selectedEmployeeId!,
        date: _selectedDate!,
        excludeShiftId: widget.existingShift?.id,
      );
      if (mounted) setState(() => _conflicts = result);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkConflicts();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final current = StaffShiftSchedule.parseTimeOfDay(
        isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = StaffShiftSchedule.formatTimeOfDay(picked);
        } else {
          _endTime = StaffShiftSchedule.formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhân viên và ngày')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(weeklyShiftDataProvider.notifier);
    bool ok;

    if (_isEditing) {
      ok = await notifier.updateShift(
        shiftId: widget.existingShift!.id,
        shiftType: _selectedShiftType,
        startTime: _startTime,
        endTime: _endTime,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    } else {
      ok = await notifier.createShift(
        employeeId: _selectedEmployeeId!,
        date: _selectedDate!,
        shiftType: _selectedShiftType,
        startTime: _startTime,
        endTime: _endTime,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      widget.onSaved?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Đã cập nhật ca' : 'Đã thêm ca thành công'),
        backgroundColor: AppColors.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lỗi khi lưu ca. Vui lòng thử lại.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(shiftEmployeesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Title ──
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_calendar : Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Sửa ca làm việc' : 'Thêm ca làm việc',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Employee Dropdown ──
              if (!_isEditing) ...[
                const Text('Nhân viên',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                employeesAsync.when(
                  data: (employees) {
                    return DropdownButtonFormField<String>(
                      value: _selectedEmployeeId,
                      decoration: InputDecoration(
                        hintText: 'Chọn nhân viên',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: employees.map((emp) {
                        final id = emp['id'] as String;
                        final name = emp['full_name'] as String? ?? 'N/A';
                        final role = emp['role'] as String? ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('$name${role.isNotEmpty ? ' ($role)' : ''}',
                              style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedEmployeeId = val);
                        _checkConflicts();
                      },
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn nhân viên' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Lỗi: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],

              // ── Date Picker ──
              const Text('Ngày làm việc',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _isEditing ? null : _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, dd/MM/yyyy', 'vi')
                                .format(_selectedDate!)
                            : 'Chọn ngày',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? Theme.of(context).colorScheme.onSurface87
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Shift Type Selector ──
              const Text('Loại ca',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ScheduleShiftType.values.map((type) {
                  final selected = _selectedShiftType == type;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Text(type.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Theme.of(context).colorScheme.surface : type.color,
                            )),
                      ],
                    ),
                    selected: selected,
                    selectedColor: type.color,
                    backgroundColor: type.bgColor,
                    onSelected: (_) {
                      setState(() {
                        _selectedShiftType = type;
                        _applyShiftDefaults(type);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Custom Time Override ──
              const Text('Thời gian (tuỳ chỉnh)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Bắt đầu',
                      value: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('→',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
                  Expanded(
                    child: _TimeTile(
                      label: 'Kết thúc',
                      value: _endTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Conflict Warning ──
              if (_conflicts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warningDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhân viên đã có ${_conflicts.length} ca trong ngày này: '
                          '${_conflicts.map((c) => c.shiftType.label).join(', ')}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warningDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Notes ──
              const Text('Ghi chú',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (không bắt buộc)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Theme.of(context).colorScheme.surface),
                            )
                          : Icon(Icons.check, size: 18),
                      label: Text(_isEditing ? 'Cập nhật' : 'Lưu ca'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Time Tile Widget ─────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
