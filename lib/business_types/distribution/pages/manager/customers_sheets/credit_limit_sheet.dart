import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/odori_customer.dart';

/// Bottom sheet for quick credit limit adjustment
class CreditLimitSheet extends StatefulWidget {
  final OdoriCustomer customer;
  final VoidCallback? onChanged;

  const CreditLimitSheet({
    super.key,
    required this.customer,
    this.onChanged,
  });

  @override
  State<CreditLimitSheet> createState() => _CreditLimitSheetState();
}

class _CreditLimitSheetState extends State<CreditLimitSheet> {
  final _controller = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final _compactFormat = NumberFormat.compact(locale: 'vi');
  
  bool _isSaving = false;
  bool _isLoading = true;
  double _currentLimit = 0;
  double _totalDebt = 0;
  double _newLimit = 0;
  String? _errorMessage;

  // Preset amounts in VND
  static const List<double> _presets = [
    5000000,   // 5M
    10000000,  // 10M
    20000000,  // 20M
    50000000,  // 50M
    100000000, // 100M
    200000000, // 200M
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      final data = await Supabase.instance.client
          .from('customers')
          .select('credit_limit, total_debt')
          .eq('id', widget.customer.id)
          .single();
      
      if (!mounted) return;
      setState(() {
        _currentLimit = ((data['credit_limit'] ?? 0) as num).toDouble();
        _totalDebt = ((data['total_debt'] ?? 0) as num).toDouble();
        _newLimit = _currentLimit;
        _controller.text = _currentLimit > 0 ? _currentLimit.toStringAsFixed(0) : '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLimit = widget.customer.creditLimit;
      _totalDebt = 0;
        _newLimit = _currentLimit;
        _controller.text = _currentLimit > 0 ? _currentLimit.toStringAsFixed(0) : '';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_newLimit < 0) {
      setState(() => _errorMessage = 'Hạn mức không được âm');
      return;
    }
    
    if (_newLimit > 0 && _newLimit < _totalDebt) {
      // Show warning but allow saving
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cảnh báo'),
            ],
          ),
          content: Text(
            'Hạn mức mới (${_currencyFormat.format(_newLimit)}) thấp hơn công nợ hiện tại (${_currencyFormat.format(_totalDebt)}).\n\nBạn vẫn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client
          .from('customers')
          .update({'credit_limit': _newLimit})
          .eq('id', widget.customer.id);

      if (!mounted) return;
      
      widget.onChanged?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _newLimit > 0 
                ? 'Đã cập nhật hạn mức: ${_currencyFormat.format(_newLimit)}'
                : 'Đã xóa hạn mức công nợ',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  void _setAmount(double amount) {
    setState(() {
      _newLimit = amount;
      _controller.text = amount.toStringAsFixed(0);
      _errorMessage = null;
    });
  }

  void _clearLimit() {
    setState(() {
      _newLimit = 0;
      _controller.text = '';
      _errorMessage = null;
    });
  }

  double get _debtRatio {
    if (_newLimit <= 0) return 0;
    return (_totalDebt / _newLimit).clamp(0, 1).toDouble();
  }

  Color get _debtRatioColor {
    if (_debtRatio >= 0.9) return Colors.red;
    if (_debtRatio >= 0.7) return Colors.orange;
    if (_debtRatio >= 0.5) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.credit_score, color: Colors.blue.shade700, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Điều chỉnh hạn mức',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.customer.name,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current status cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Hạn mức hiện tại',
                          _currentLimit > 0 
                              ? _currencyFormat.format(_currentLimit)
                              : 'Chưa thiết lập',
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Công nợ hiện tại',
                          _currencyFormat.format(_totalDebt),
                          Icons.money_off,
                          _totalDebt > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Debt ratio indicator
                  if (_newLimit > 0) ...[
                    _buildDebtRatioIndicator(),
                    const SizedBox(height: 12),
                  ],

                  // Available credit
                  if (_newLimit > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _debtRatioColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _debtRatioColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Còn có thể nợ thêm',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            _currencyFormat.format((_newLimit - _totalDebt).clamp(0, double.infinity)),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _debtRatioColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Section: Set new limit
                  Text(
                    'Thiết lập hạn mức mới',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input field
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Hạn mức (VNĐ)',
                      hintText: '0 = Không giới hạn',
                      prefixIcon: const Icon(Icons.credit_card),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearLimit,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      helperText: _newLimit > 0
                          ? 'Tương đương: ${_currencyFormat.format(_newLimit)}'
                          : null,
                      errorText: _errorMessage,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _newLimit = double.tryParse(value) ?? 0;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Preset buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._presets.map((amount) => _buildPresetChip(amount)),
                      // "No limit" option
                      ActionChip(
                        avatar: const Icon(Icons.all_inclusive, size: 16),
                        label: const Text('Không giới hạn'),
                        backgroundColor: _newLimit == 0 
                            ? Colors.grey.shade200
                            : Colors.grey.shade50,
                        side: BorderSide(
                          color: _newLimit == 0 ? Colors.grey.shade400 : Colors.grey.shade300,
                        ),
                        onPressed: _clearLimit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Change summary
                  if (_newLimit != _currentLimit) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thay đổi hạn mức',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_currentLimit > 0 ? _currencyFormat.format(_currentLimit) : "Không giới hạn"}'
                                  ' → '
                                  '${_newLimit > 0 ? _currencyFormat.format(_newLimit) : "Không giới hạn"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving || _newLimit == _currentLimit ? null : _save,
                          icon: _isSaving 
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtRatioIndicator() {
    final percentage = (_debtRatio * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ sử dụng',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _debtRatioColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _debtRatioColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _debtRatio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_debtRatioColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currencyFormat.format(_totalDebt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                _currencyFormat.format(_newLimit),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(double amount) {
    final isSelected = _newLimit == amount;
    final label = amount >= 1000000000
        ? '${(amount / 1000000000).toStringAsFixed(0)} tỷ'
        : amount >= 1000000
            ? '${(amount / 1000000).toStringAsFixed(0)} triệu'
            : _compactFormat.format(amount);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue.shade100,
      backgroundColor: Colors.grey.shade50,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => _setAmount(amount),
    );
  }
}
