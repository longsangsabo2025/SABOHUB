import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/task_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class TaskFormPage extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormPage({super.key, this.task});

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.operations;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskRecurrence _selectedRecurrence = TaskRecurrence.none;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedAssigneeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.task != null) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _notesController.text = task.notes ?? '';
      _selectedCategory = task.category;
      _selectedPriority = task.priority;
      _selectedRecurrence = task.recurrence;
      _selectedDueDate = task.dueDate;
      _selectedAssigneeId = task.assigneeId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Đang kiểm tra đăng nhập...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Tạo nhiệm vụ mới' : 'Chỉnh sửa nhiệm vụ'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveTask,
            icon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
            label: Text(_isLoading ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
      body: _buildBody(currentUser),
    );
  }

  Widget _buildBody(User currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildCategoryPrioritySection(),
            const SizedBox(height: 24),
            _buildAssignmentSection(currentUser),
            const SizedBox(height: 24),
            _buildDueDateSection(),
            const SizedBox(height: 24),
            _buildRecurrenceSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Thông tin cơ bản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên nhiệm vụ *',
                hintText: 'Nhập tên nhiệm vụ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Vui lòng nhập tên nhiệm vụ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                hintText: 'Mô tả chi tiết về nhiệm vụ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPrioritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Phân loại & Ưu tiên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category selection
            DropdownButtonFormField<TaskCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: TaskCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(category.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Priority selection
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Mức độ ưu tiên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: priority.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(priority.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSection(User currentUser) {
    // Only show assignment if user has company
    if (currentUser.companyId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Phân công',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Employee dropdown
            Consumer(
              builder: (context, ref, child) {
                final employeesAsync = ref.watch(companyEmployeesProvider(currentUser.companyId!));
                
                return employeesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) => Text('Lỗi: $error'),
                  data: (employees) {
                    return DropdownButtonFormField<String>(
                      value: _selectedAssigneeId,
                      decoration: const InputDecoration(
                        labelText: 'Giao cho nhân viên',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment_ind),
                      ),
                      hint: const Text('Chọn nhân viên thực hiện'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Tự thực hiện --'),
                        ),
                        ...employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: _getRoleColor(employee.role),
                                  child: Text(
                                    (employee.name ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(employee.name ?? 'Unknown'),
                                      Text(
                                        _getRoleDisplayName(employee.role),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedAssigneeId = value);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Thời hạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hạn chót',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatDate(_selectedDueDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.repeat, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  'Lặp lại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<TaskRecurrence>(
              value: _selectedRecurrence,
              decoration: const InputDecoration(
                labelText: 'Tần suất lặp lại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: TaskRecurrence.values.map((recurrence) {
                return DropdownMenuItem(
                  value: recurrence,
                  child: Row(
                    children: [
                      Icon(recurrence.icon, color: recurrence.color, size: 20),
                      const SizedBox(width: 12),
                      Text(recurrence.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRecurrence = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm',
                hintText: 'Thêm ghi chú hoặc hướng dẫn chi tiết...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy bỏ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveTask,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
            label: Text(widget.task == null ? 'Tạo nhiệm vụ' : 'Cập nhật'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final currentUser = authState.user!;
      
      // Get assignee name if assigned to someone
      String? assigneeName;
      if (_selectedAssigneeId != null) {
        final employeesAsync = ref.read(companyEmployeesProvider(currentUser.companyId!));
        final employees = employeesAsync.asData?.value ?? [];
        final assignee = employees.firstWhere(
          (emp) => emp.id == _selectedAssigneeId,
          orElse: () => currentUser, 
        );
        assigneeName = assignee.name;
      }

      final task = Task(
        id: widget.task?.id ?? '',
        companyId: currentUser.companyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        status: widget.task?.status ?? TaskStatus.todo,
        recurrence: _selectedRecurrence,
        assigneeId: _selectedAssigneeId ?? currentUser.id,
        assignedToName: assigneeName ?? currentUser.name,
        dueDate: _selectedDueDate,
        createdBy: currentUser.id,
        createdByName: currentUser.name ?? 'Unknown',
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      );

      final taskService = ref.read(taskServiceProvider);
      
      if (widget.task == null) {
        // Create new task
        await taskService.createTask(task);
        _showSnackBar('Tạo nhiệm vụ thành công!', Colors.green);
      } else {
        // Update existing task
        await taskService.updateTask(task.id, {
          'title': task.title,
          'description': task.description,
          'category': task.category.name,
          'priority': task.priority.name,
          'recurrence': task.recurrence.name,
          'assigned_to': task.assigneeId,
          'assigned_to_name': task.assignedToName,
          'due_date': task.dueDate.toIso8601String(),
          'notes': task.notes,
        });
        _showSnackBar('Cập nhật nhiệm vụ thành công!', Colors.green);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }

    } catch (e) {
      _showSnackBar('Lỗi: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.shiftLeader:
        return Colors.orange;
      case UserRole.staff:
        return Colors.green;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return 'Giám đốc';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.shiftLeader:
        return 'Trưởng ca';
      case UserRole.staff:
        return 'Nhân viên';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    final formattedDate = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} lúc ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    
    if (difference.inDays == 0) {
      return 'Hôm nay - $formattedDate';
    } else if (difference.inDays == 1) {
      return 'Ngày mai - $formattedDate';
    } else if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày - $formattedDate';
    } else {
      return 'Quá hạn ${difference.inDays.abs()} ngày - $formattedDate';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
