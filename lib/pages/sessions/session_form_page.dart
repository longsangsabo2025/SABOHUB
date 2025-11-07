import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table.dart';

class SessionFormPage extends ConsumerStatefulWidget {
  const SessionFormPage({super.key});

  @override
  ConsumerState<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends ConsumerState<SessionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedTableId;
  double _hourlyRate = 50000; // Default rate
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableTables = ref.watch(tablesByStatusProvider(TableStatus.available));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bắt đầu phiên chơi'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _startSession,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Bắt đầu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table selection
              Text(
                'Chọn bàn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              availableTables.when(
                data: (tables) => _buildTableSelection(tables),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Lỗi: $error',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hourly rate
              Text(
                'Giá giờ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: (_hourlyRate / 1000).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá giờ (nghìn đồng)',
                  prefixText: '₫ ',
                  suffixText: 'K/giờ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá giờ';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Giá giờ phải là số dương';
                  }
                  return null;
                },
                onSaved: (value) {
                  _hourlyRate = (double.tryParse(value!) ?? 0) * 1000;
                },
              ),
              const SizedBox(height: 24),

              // Customer name
              Text(
                'Tên khách hàng (tuỳ chọn)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách hàng',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              Text(
                'Ghi chú (tuỳ chọn)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 32),

              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _selectedTableId == null ? null : _startSession,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isLoading ? 'Đang bắt đầu...' : 'Bắt đầu phiên chơi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableSelection(List tables) {
    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không có bàn nào đang trống. Vui lòng kiểm tra lại trang quản lý bàn.',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: tables.map<Widget>((table) {
        final isSelected = _selectedTableId == table.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTableId = table.id;
                _hourlyRate = table.hourlyRate; // Set the table's hourly rate
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? Colors.blue.shade50 : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: table.id,
                    groupValue: _selectedTableId,
                    onChanged: (value) {
                      setState(() {
                        _selectedTableId = value;
                        _hourlyRate = table.hourlyRate;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue.shade700 : null,
                          ),
                        ),
                        Text(
                          '${table.type} - ${(table.hourlyRate / 1000).toInt()}K/giờ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue.shade600,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _startSession() async {
    if (!_formKey.currentState!.validate() || _selectedTableId == null) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionActions = ref.read(sessionActionsProvider);
      await sessionActions.startSession(
        tableId: _selectedTableId!,
        hourlyRate: _hourlyRate,
        customerName: _customerNameController.text.trim().isEmpty 
            ? null 
            : _customerNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bắt đầu phiên chơi thành công'),
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