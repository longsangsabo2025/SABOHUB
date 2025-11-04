import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/employee_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/task_service.dart';

/// Dialog for editing an existing task
class EditTaskDialog extends ConsumerStatefulWidget {
  final Task task;

  const EditTaskDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late TaskPriority _selectedPriority;
  late TaskStatus _selectedStatus;
  late DateTime _selectedDueDate;
  String? _selectedAssigneeId;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;
    _selectedDueDate = widget.task.dueDate;
    _selectedAssigneeId = widget.task.assignedTo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get assignee name if selected
      String? assigneeName;
      if (_selectedAssigneeId != null) {
        final employeesAsync = ref.read(companyEmployeesProvider(widget.task.branchId));
        final employees = employeesAsync.when(
          data: (data) => data,
          loading: () => <User>[],
          error: (_, __) => <User>[],
        );
        if (employees.isNotEmpty) {
          try {
            final assignee = employees.firstWhere((e) => e.id == _selectedAssigneeId);
            assigneeName = assignee.name ?? assignee.email;
          } catch (_) {}
        }
      }

      final taskService = TaskService();
      await taskService.updateTask(widget.task.id, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority.name,
        'status': _selectedStatus.name,
        'due_date': _selectedDueDate.toIso8601String(),
        'assigned_to': _selectedAssigneeId,
        'assigned_to_name': assigneeName,
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật công việc thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(companyEmployeesProvider(widget.task.branchId));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Chỉnh sửa công việc',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề công việc *',
                          hintText: 'Nhập tên công việc...',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả chi tiết...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<TaskPriority>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Độ ưu tiên',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  size: 16,
                                  color: priority.color,
                                ),
                                const SizedBox(width: 8),
                                Text(priority.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<TaskStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          prefixIcon: const Icon(Icons.info),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: TaskStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: status.color,
                                ),
                                const SizedBox(width: 8),
                                Text(status.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Due Date
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Hạn hoàn thành',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateFormat.format(_selectedDueDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assignee
                      employeesAsync.when(
                        data: (employees) {
                          return DropdownButtonFormField<String>(
                            value: _selectedAssigneeId,
                            decoration: InputDecoration(
                              labelText: 'Giao cho',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            hint: const Text('Chọn nhân viên (tùy chọn)'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Không giao'),
                              ),
                              ...employees.map((employee) {
                                return DropdownMenuItem(
                                  value: employee.id,
                                  child: Text(employee.name ?? employee.email),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAssigneeId = value;
                              });
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text(
                          'Không thể tải danh sách nhân viên',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateTask,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Đang lưu...' : 'Lưu thay đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
}
