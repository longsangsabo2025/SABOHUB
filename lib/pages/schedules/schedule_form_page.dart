import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';

class ScheduleFormPage extends ConsumerStatefulWidget {
  final Schedule? schedule;

  const ScheduleFormPage({super.key, this.schedule});

  @override
  ConsumerState<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends ConsumerState<ScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeNameController = TextEditingController();
  final _employeeEmailController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ShiftType _selectedShiftType = ShiftType.morning;
  TimeOfDay? _customStartTime;
  TimeOfDay? _customEndTime;
  ScheduleStatus _selectedStatus = ScheduleStatus.scheduled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.schedule != null) {
      final schedule = widget.schedule!;
      _employeeNameController.text = schedule.employeeName;
      _employeeEmailController.text = schedule.employeeEmail ?? '';
      _employeePhoneController.text = schedule.employeePhone ?? '';
      _notesController.text = schedule.notes ?? '';
      _selectedDate = schedule.date;
      _selectedShiftType = schedule.shiftType;
      _customStartTime = schedule.customStartTime;
      _customEndTime = schedule.customEndTime;
      _selectedStatus = schedule.status;
    }
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeePhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Thêm Lịch Làm Việc' : 'Sửa Lịch Làm Việc'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Employee name
                      TextFormField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên nhân viên *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên nhân viên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Employee email
                      TextFormField(
                        controller: _employeeEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email nhân viên',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Employee phone
                      TextFormField(
                        controller: _employeePhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại nhân viên',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Schedule Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin lịch làm việc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Ngày làm việc'),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _selectDate,
                      ),
                      const Divider(),
                      
                      // Shift type selection
                      const Text('Ca làm việc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ShiftType.values.map((type) => FilterChip(
                          label: Text(type.label),
                          selected: _selectedShiftType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedShiftType = type;
                                // Reset custom times when changing shift type
                                _customStartTime = null;
                                _customEndTime = null;
                              });
                            }
                          },
                          selectedColor: type.color.withOpacity(0.3),
                          checkmarkColor: type.color,
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Custom time selection
                      if (_selectedShiftType == ShiftType.full) ...[
                        const Text('Giờ làm việc tùy chỉnh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: const Icon(Icons.access_time),
                                title: const Text('Giờ bắt đầu'),
                                subtitle: Text(
                                  _customStartTime?.format(context) ?? _selectedShiftType.startTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onTap: () => _selectTime(true),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                leading: const Icon(Icons.access_time_filled),
                                title: const Text('Giờ kết thúc'),
                                subtitle: Text(
                                  _customEndTime?.format(context) ?? _selectedShiftType.endTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onTap: () => _selectTime(false),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                      
                      // Status selection
                      const Text('Trạng thái', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ScheduleStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                        items: ScheduleStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.label),
                            ],
                          ),
                        )).toList(),
                        onChanged: (status) {
                          if (status != null) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghi chú',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú (tùy chọn)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.schedule == null ? 'Thêm' : 'Cập nhật'),
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final currentTime = isStartTime 
        ? (_customStartTime ?? _selectedShiftType.startTime)
        : (_customEndTime ?? _selectedShiftType.endTime);
        
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (time != null) {
      setState(() {
        if (isStartTime) {
          _customStartTime = time;
        } else {
          _customEndTime = time;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authProvider);
    if (user.user?.companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin công ty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final schedule = Schedule(
        id: widget.schedule?.id ?? '',
        employeeId: widget.schedule?.employeeId ?? 'temp_${now.millisecondsSinceEpoch}',
        employeeName: _employeeNameController.text.trim(),
        employeeEmail: _employeeEmailController.text.trim().isEmpty 
            ? null 
            : _employeeEmailController.text.trim(),
        employeePhone: _employeePhoneController.text.trim().isEmpty 
            ? null 
            : _employeePhoneController.text.trim(),
        companyId: user.user!.companyId!,
        date: _selectedDate,
        shiftType: _selectedShiftType,
        customStartTime: _customStartTime,
        customEndTime: _customEndTime,
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.schedule?.createdAt ?? now,
        updatedAt: now,
        createdBy: widget.schedule?.createdBy ?? user.user!.id,
        updatedBy: user.user!.id,
      );

      final scheduleActions = ref.read(scheduleActionsProvider);
      
      if (widget.schedule == null) {
        await scheduleActions.createSchedule(schedule);
      } else {
        await scheduleActions.updateSchedule(schedule);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.schedule == null 
                  ? 'Đã thêm lịch làm việc thành công'
                  : 'Đã cập nhật lịch làm việc thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}