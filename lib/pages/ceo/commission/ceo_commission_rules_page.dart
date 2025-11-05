import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commission_rule.dart';
import '../../../services/commission_rule_service.dart';
import '../../../providers/auth_provider.dart';

/// CEO Commission Rules Management Page
class CeoCommissionRulesPage extends ConsumerStatefulWidget {
  const CeoCommissionRulesPage({super.key});

  @override
  ConsumerState<CeoCommissionRulesPage> createState() =>
      _CeoCommissionRulesPageState();
}

class _CeoCommissionRulesPageState
    extends ConsumerState<CeoCommissionRulesPage> {
  final _ruleService = CommissionRuleService();
  List<CommissionRule> _rules = [];
  bool _isLoading = true;
  bool _showInactiveRules = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authProvider);
      final companyId = user.user?.companyId;

      if (companyId != null) {
        final rules = await _ruleService.getRulesByCompany(
          companyId,
          isActive: _showInactiveRules ? null : true,
        );
        setState(() {
          _rules = rules;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateRuleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateRuleDialog(),
    );

    if (result == true) {
      _loadRules();
    }
  }

  Future<void> _toggleRuleActive(CommissionRule rule) async {
    try {
      if (rule.isActive) {
        await _ruleService.deactivateRule(rule.id);
      } else {
        await _ruleService.reactivateRule(rule.id);
      }
      _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Quy Tắc Hoa Hồng'),
        actions: [
          IconButton(
            icon: Icon(
              _showInactiveRules ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _showInactiveRules
                ? 'Ẩn quy tắc đã tắt'
                : 'Hiện quy tắc đã tắt',
            onPressed: () {
              setState(() {
                _showInactiveRules = !_showInactiveRules;
              });
              _loadRules();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(
                  child: Text('Chưa có quy tắc nào.\nTạo quy tắc đầu tiên!'),
                )
              : RefreshIndicator(
                  onRefresh: _loadRules,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return _buildRuleCard(rule);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRuleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo Quy Tắc'),
      ),
    );
  }

  Widget _buildRuleCard(CommissionRule rule) {
    final appliesTo = AppliesTo.fromString(rule.appliesTo);
    Color priorityColor = rule.priority > 5
        ? Colors.red
        : rule.priority > 2
            ? Colors.orange
            : Colors.grey;

    return Card(
      elevation: rule.isActive ? 2 : 0,
      color: rule.isActive ? null : Colors.grey[200],
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: rule.isActive
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey[300],
          child: Text(
            appliesTo.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          rule.ruleName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rule.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${rule.commissionPercentage}% hoa hồng',
              style: TextStyle(
                color: rule.isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              appliesTo.label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rule.priority > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'P${rule.priority}',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Switch(
              value: rule.isActive,
              onChanged: (_) => _toggleRuleActive(rule),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rule.description != null) ...[
                  Text(
                    rule.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Divider(height: 24),
                ],
                _buildInfoRow('Áp dụng cho', appliesTo.label),
                if (rule.role != null)
                  _buildInfoRow('Vai trò', rule.role!.toUpperCase()),
                if (rule.minBillAmount > 0)
                  _buildInfoRow(
                    'Bill tối thiểu',
                    '${rule.minBillAmount.toStringAsFixed(0)}₫',
                  ),
                if (rule.maxBillAmount != null)
                  _buildInfoRow(
                    'Bill tối đa',
                    '${rule.maxBillAmount!.toStringAsFixed(0)}₫',
                  ),
                _buildInfoRow(
                  'Hiệu lực',
                  '${rule.effectiveFrom.day}/${rule.effectiveFrom.month}/${rule.effectiveFrom.year}${rule.effectiveTo != null ? ' - ${rule.effectiveTo!.day}/${rule.effectiveTo!.month}/${rule.effectiveTo!.year}' : ' - Vô thời hạn'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to create new commission rule
class _CreateRuleDialog extends ConsumerStatefulWidget {
  const _CreateRuleDialog();

  @override
  ConsumerState<_CreateRuleDialog> createState() => _CreateRuleDialogState();
}

class _CreateRuleDialogState extends ConsumerState<_CreateRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ruleService = CommissionRuleService();

  final _ruleNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController(text: '5');
  final _minAmountController = TextEditingController(text: '0');
  final _priorityController = TextEditingController(text: '0');

  String _appliesTo = 'all';
  bool _isCreating = false;

  @override
  void dispose() {
    _ruleNameController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _minAmountController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _createRule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final user = ref.read(authProvider);
      final companyId = user.user?.companyId;

      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await _ruleService.createRule(
        companyId: companyId,
        ruleName: _ruleNameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        appliesTo: _appliesTo,
        commissionPercentage: double.parse(_percentageController.text),
        minBillAmount: double.parse(_minAmountController.text),
        priority: int.parse(_priorityController.text),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tạo quy tắc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo Quy Tắc Hoa Hồng'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _ruleNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Quy Tắc *',
                  hintText: 'Hoa hồng nhân viên',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô Tả',
                  hintText: 'Mô tả ngắn về quy tắc',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _appliesTo,
                decoration: const InputDecoration(
                  labelText: 'Áp Dụng Cho',
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('👥 Tất cả')),
                  DropdownMenuItem(
                      value: 'role', child: Text('🎭 Theo vai trò')),
                  DropdownMenuItem(
                      value: 'individual', child: Text('👤 Cá nhân')),
                ],
                onChanged: (value) {
                  setState(() {
                    _appliesTo = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _percentageController,
                decoration: const InputDecoration(
                  labelText: 'Phần Trăm Hoa Hồng *',
                  hintText: '5',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập phần trăm';
                  final val = double.tryParse(value!);
                  if (val == null || val < 0 || val > 100) {
                    return 'Phải từ 0-100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Bill Tối Thiểu',
                  hintText: '0',
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(
                  labelText: 'Độ Ưu Tiên',
                  hintText: '0',
                  helperText: 'Số càng lớn càng ưu tiên',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createRule,
          child: _isCreating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tạo'),
        ),
      ],
    );
  }
}
