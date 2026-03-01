import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';

/// Modern Smart Task Creation Page with Stepper
/// Features: Multi-step wizard, AI suggestions, smart defaults, animations
class SmartTaskCreationPage extends ConsumerStatefulWidget {
  const SmartTaskCreationPage({super.key});

  @override
  ConsumerState<SmartTaskCreationPage> createState() =>
      _SmartTaskCreationPageState();
}

class _SmartTaskCreationPageState extends ConsumerState<SmartTaskCreationPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedManagerId;
  String? _selectedCompanyId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.general;
  String _selectedRecurrence = 'none';
  final List<String> _checklistItems = [];
  final _checklistItemController = TextEditingController();
  DateTime? _selectedDueDate;

  // Form keys for validation
  final _formKey = GlobalKey<FormState>();

  // Data lists
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistItemController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = ref.read(managementTaskServiceProvider);
    try {
      final results = await Future.wait([
        service.getManagers(),
        service.getCompanies(),
      ]);

      if (mounted) {
        setState(() {
          _managers = results[0];
          _companies = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Tạo nhiệm vụ mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStepperForm(),
            ),
    );
  }

  Widget _buildStepperForm() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(0, '🏢', 'Chọn công ty'),
          _buildStepLine(0),
          _buildStepIndicator(1, '�', 'Thông tin công việc'),
          _buildStepLine(1),
          _buildStepIndicator(2, '👤', 'Phân công'),
          _buildStepLine(2),
          _buildStepIndicator(3, '✅', 'Xác nhận'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String icon, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : isActive
                      ? AppColors.info
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                isCompleted ? '✓' : icon,
                style: TextStyle(
                  fontSize: 20,
                  color: isActive || isCompleted
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.info : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCompanySelectionStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _buildAssignmentStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Company Selection
  Widget _buildCompanySelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏢 Chọn công ty',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn công ty mà bạn muốn giao nhiệm vụ cho',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        if (_companies.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.business_center,
                    size: 48, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                Text(
                  '⚠️ Chưa có công ty nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn cần tạo ít nhất 1 công ty trước khi giao việc',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: _companies.map((company) {
              final isSelected = _selectedCompanyId == company['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCompanyId = company['id'] as String;
                      // Reset manager selection when company changes
                      _selectedManagerId = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.info
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.info
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.info
                                : Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            color: isSelected
                                ? Colors.white
                                : Colors.purple.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company['name'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.info
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),

        // Category selector
        Text(
          '📂 Phân loại mảng',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: TaskCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              selectedColor: AppColors.info.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? AppColors.info : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.info : Colors.grey.shade700,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 Sau khi chọn công ty, bạn chỉ có thể phân công cho managers thuộc công ty đó',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Basic Info (Task Details)
  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Thông tin công việc',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập chi tiết về nhiệm vụ cần thực hiện',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),

        // Task Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Tên nhiệm vụ *',
            hintText: 'VD: Mở rộng thị trường miền Bắc',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên nhiệm vụ';
            }
            if (value.length < 5) {
              return 'Tên nhiệm vụ phải có ít nhất 5 ký tự';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 24),

        // Task Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Mô tả chi tiết',
            hintText: 'Mô tả rõ ràng các yêu cầu và kỳ vọng...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          maxLines: 5,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 32),

        // Priority Selection
        Text(
          'Mức độ ưu tiên *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ...TaskPriority.values.map((priority) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() => _selectedPriority = priority);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedPriority == priority
                      ? _getPriorityColor(priority).withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPriority == priority
                        ? _getPriorityColor(priority)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                      child: _selectedPriority == priority
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priority.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                          Text(
                            _getPriorityDescription(priority),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Due Date Selection
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate ??
                  DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.info,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDueDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hạn hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                            : 'Chọn ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedDueDate != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Recurrence
        Text(
          '🔄 Lặp lại',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ('none', 'Không lặp'),
            ('daily', 'Hằng ngày'),
            ('weekly', 'Hằng tuần'),
            ('monthly', 'Hằng tháng'),
          ].map((e) {
            final isSelected = _selectedRecurrence == e.$1;
            return ChoiceChip(
              label: Text(e.$2),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedRecurrence = e.$1),
              selectedColor: Colors.orange.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Checklist builder
        Text(
          '✅ Checklist (các bước thực hiện)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _checklistItemController,
                decoration: InputDecoration(
                  hintText: 'VD: Tạo account, Thiết kế logo...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _addChecklistItemToForm(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addChecklistItemToForm,
              icon: const Icon(Icons.add_circle),
              color: Colors.blue,
              tooltip: 'Thêm bước',
            ),
          ],
        ),
        if (_checklistItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_checklistItems.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_checklistItems[i]),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _checklistItems.removeAt(i));
                    },
                    icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _addChecklistItemToForm() {
    final text = _checklistItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(text);
    });
    _checklistItemController.clear();
  }

  // Step 3: Assignment (Manager Selection)
  Widget _buildAssignmentStep() {
    // Filter managers by selected company
    final filteredManagers = _selectedCompanyId != null
        ? _managers.where((m) => m['company_id'] == _selectedCompanyId).toList()
        : _managers;

    final selectedCompany = _companies.firstWhere(
      (c) => c['id'] == _selectedCompanyId,
      orElse: () => {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👤 Phân công nhiệm vụ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn Manager để thực hiện nhiệm vụ tại ${selectedCompany['name'] ?? 'công ty'}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        if (filteredManagers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.person_off, size: 48, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                Text(
                  '⚠️ Chưa có Manager nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Công ty này chưa có Manager. Hãy tạo tài khoản Manager trước!',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: filteredManagers.map((manager) {
              final isSelected = _selectedManagerId == manager['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(
                        () => _selectedManagerId = manager['id'] as String);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.info
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.info
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isSelected
                              ? AppColors.info
                              : Colors.blue.shade100,
                          child: Text(
                            (manager['full_name'] as String)[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                manager['full_name'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.info
                                      : Colors.black,
                                ),
                              ),
                              if (manager['company_name'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      manager['company_name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Step 4: Confirmation
  Widget _buildConfirmationStep() {
    final selectedManager = _managers.firstWhere(
      (m) => m['id'] == _selectedManagerId,
      orElse: () => {},
    );
    final selectedCompany = _selectedCompanyId != null
        ? _companies.firstWhere(
            (c) => c['id'] == _selectedCompanyId,
            orElse: () => {},
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅ Xác nhận thông tin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kiểm tra lại thông tin trước khi tạo nhiệm vụ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),

        // Summary Card
        _buildSummaryItem(
          '📝 Nhiệm vụ',
          _titleController.text.isEmpty ? 'Chưa nhập' : _titleController.text,
          subtitle: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        ),

        _buildSummaryItem(
          '👤 Người thực hiện',
          selectedManager['full_name'] ?? 'Chưa chọn',
          subtitle: selectedManager['company_name'],
        ),

        if (selectedCompany != null)
          _buildSummaryItem(
            '🏢 Công ty',
            selectedCompany['name'] ?? '',
          ),

        _buildSummaryItem(
          '📂 Mảng',
          _selectedCategory.displayName,
        ),

        _buildSummaryItem(
          '⚡ Mức độ ưu tiên',
          _selectedPriority.label,
          color: _getPriorityColor(_selectedPriority),
        ),

        if (_selectedDueDate != null)
          _buildSummaryItem(
            '📅 Hạn hoàn thành',
            DateFormat('dd/MM/yyyy').format(_selectedDueDate!),
          ),

        if (_selectedRecurrence != 'none')
          _buildSummaryItem(
            '🔄 Lặp lại',
            _selectedRecurrence == 'daily'
                ? 'Hằng ngày'
                : _selectedRecurrence == 'weekly'
                    ? 'Hằng tuần'
                    : 'Hằng tháng',
          ),

        if (_checklistItems.isNotEmpty)
          _buildSummaryItem(
            '✅ Checklist',
            '${_checklistItems.length} bước',
            subtitle: _checklistItems.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n'),
          ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mọi thông tin đã sẵn sàng! Nhấn "Tạo nhiệm vụ" để hoàn tất.',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value,
      {String? subtitle, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ?? Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentStep--);
                  _animationController.reset();
                  _animationController.forward();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == 3 ? _createTask : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 3 ? 'Tạo nhiệm vụ' : 'Tiếp tục',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_currentStep == 3 ? Icons.check : Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // Validate current step
    if (_currentStep == 0) {
      // Step 1: Company selection
      if (_selectedCompanyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng chọn công ty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Step 2: Task info (title, description, priority, due date)
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentStep == 2) {
      // Step 3: Manager assignment
      if (_selectedManagerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng chọn người thực hiện'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _createTask() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final service = ref.read(managementTaskServiceProvider);

      await service.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority.value,
        assignedTo: _selectedManagerId!,
        companyId: _selectedCompanyId,
        dueDate: _selectedDueDate,
        category: _selectedCategory.value,
        recurrence: _selectedRecurrence,
        checklist: _checklistItems.isNotEmpty
            ? _checklistItems
                .asMap()
                .entries
                .map((e) => {
                      'id': '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
                      'title': e.value,
                      'is_done': false,
                    })
                .toList()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close page

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tạo nhiệm vụ thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red.shade700;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }

  String _getPriorityDescription(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Không gấp, có thể hoàn thành trong thời gian dài';
      case TaskPriority.medium:
        return 'Mức độ bình thường, cần hoàn thành đúng hạn';
      case TaskPriority.high:
        return 'Quan trọng và khẩn cấp, cần ưu tiên thực hiện ngay';
      case TaskPriority.critical:
        return 'Cực kỳ nghiêm trọng, ảnh hưởng toàn hệ thống';
    }
  }
}
