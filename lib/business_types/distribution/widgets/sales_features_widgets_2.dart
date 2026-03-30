import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/sales_features_service.dart';
import '../../../providers/auth_provider.dart';

// ============================================================================
// STOCK CHECK FORM - Kiểm tồn kho tại điểm bán
// ============================================================================
class StockCheckForm extends ConsumerStatefulWidget {
  final String visitId;
  final VoidCallback? onSaved;

  const StockCheckForm({
    super.key,
    required this.visitId,
    this.onSaved,
  });

  @override
  ConsumerState<StockCheckForm> createState() => _StockCheckFormState();
}

class _StockCheckFormState extends ConsumerState<StockCheckForm> {
  List<Map<String, dynamic>> _products = [];
  final Map<String, Map<String, dynamic>> _stockData = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final response = await supabase
          .from('products')
          .select('id, name, sku, unit')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name')
          .limit(50);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAll() async {
    if (_stockData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có dữ liệu để lưu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(storeInventoryCheckServiceProvider);

      for (final entry in _stockData.entries) {
        final data = entry.value;
        await service.saveCheck(
          visitId: widget.visitId,
          productId: entry.key,
          shelfStock: data['shelf_stock'] ?? 0,
          backStock: data['back_stock'] ?? 0,
          isOutOfStock: data['is_out_of_stock'] ?? false,
          isLowStock: data['is_low_stock'] ?? false,
          currentPrice: data['current_price'],
          notes: data['notes'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kiểm tồn'), backgroundColor: Colors.green),
        );
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tồn kho'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAll,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final productId = product['id'];
                final data = _stockData[productId] ?? {};

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${product['sku'] ?? ''} • ${product['unit'] ?? ''}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (data['is_out_of_stock'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Hết hàng', style: TextStyle(color: Colors.red.shade700, fontSize: 11)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Tồn kệ',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: (data['shelf_stock'] ?? 0).toString(),
                                onChanged: (v) {
                                  _stockData[productId] = {
                                    ...data,
                                    'shelf_stock': int.tryParse(v) ?? 0,
                                    'is_out_of_stock': (int.tryParse(v) ?? 0) == 0,
                                  };
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Tồn kho sau',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: (data['back_stock'] ?? 0).toString(),
                                onChanged: (v) {
                                  _stockData[productId] = {
                                    ...data,
                                    'back_stock': int.tryParse(v) ?? 0,
                                  };
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilterChip(
                              label: const Text('Sắp hết'),
                              selected: data['is_low_stock'] == true,
                              onSelected: (v) {
                                _stockData[productId] = {...data, 'is_low_stock': v};
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Có KM'),
                              selected: data['on_promotion'] == true,
                              onSelected: (v) {
                                _stockData[productId] = {...data, 'on_promotion': v};
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// SURVEY FORM - Form khảo sát
// ============================================================================
class SurveyFormWidget extends ConsumerStatefulWidget {
  final Survey survey;
  final String? customerId;
  final String? visitId;
  final VoidCallback? onCompleted;

  const SurveyFormWidget({
    super.key,
    required this.survey,
    this.customerId,
    this.visitId,
    this.onCompleted,
  });

  @override
  ConsumerState<SurveyFormWidget> createState() => _SurveyFormWidgetState();
}

class _SurveyFormWidgetState extends ConsumerState<SurveyFormWidget> {
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _submit() async {
    // Validate required questions
    for (final q in widget.survey.questions) {
      if (q['required'] == true && _answers[q['id']] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng trả lời: ${q['question']}'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      final userId = user?.id;

      if (companyId == null || userId == null) return;

      final duration = DateTime.now().difference(_startTime!).inSeconds;

      await ref.read(surveyServiceProvider).submitResponse(
        surveyId: widget.survey.id,
        companyId: companyId,
        customerId: widget.customerId,
        visitId: widget.visitId,
        respondentId: userId,
        answers: _answers,
        durationSeconds: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi khảo sát'), backgroundColor: Colors.green),
        );
        widget.onCompleted?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey.title),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Gửi'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.survey.questions.length,
        itemBuilder: (context, index) {
          final question = widget.survey.questions[index];
          return _buildQuestion(question, index);
        },
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> q, int index) {
    final questionId = q['id'] ?? 'q$index';
    final type = q['type'] ?? 'text';
    final required = q['required'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${index + 1}. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                Expanded(
                  child: Text(
                    '${q['question']}${required ? ' *' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAnswerWidget(type, questionId, q),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(String type, String questionId, Map<String, dynamic> q) {
    switch (type) {
      case 'rating':
        final maxRating = q['max_rating'] ?? 5;
        return Row(
          children: List.generate(maxRating, (i) {
            final value = i + 1;
            final selected = _answers[questionId] == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => setState(() => _answers[questionId] = value),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? Theme.of(context).colorScheme.surface : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );

      case 'single_choice':
        final options = List<String>.from(q['options'] ?? []);
        return Column(
          children: options.map((opt) => RadioListTile<String>(
            value: opt,
            groupValue: _answers[questionId],
            title: Text(opt),
            onChanged: (v) => setState(() => _answers[questionId] = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          )).toList(),
        );

      case 'multiple_choice':
        final options = List<String>.from(q['options'] ?? []);
        final selected = List<String>.from(_answers[questionId] ?? []);
        return Column(
          children: options.map((opt) => CheckboxListTile(
            value: selected.contains(opt),
            title: Text(opt),
            onChanged: (v) {
              if (v == true) {
                selected.add(opt);
              } else {
                selected.remove(opt);
              }
              setState(() => _answers[questionId] = selected);
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          )).toList(),
        );

      case 'yes_no':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _answers[questionId] = true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _answers[questionId] == true ? Colors.green.shade100 : null,
                  side: BorderSide(color: _answers[questionId] == true ? Colors.green : Colors.grey.shade300),
                ),
                child: Text('Có', style: TextStyle(color: _answers[questionId] == true ? Colors.green : null)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _answers[questionId] = false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _answers[questionId] == false ? Colors.red.shade100 : null,
                  side: BorderSide(color: _answers[questionId] == false ? Colors.red : Colors.grey.shade300),
                ),
                child: Text('Không', style: TextStyle(color: _answers[questionId] == false ? Colors.red : null)),
              ),
            ),
          ],
        );

      default: // text
        return TextFormField(
          decoration: InputDecoration(
            hintText: q['placeholder'] ?? 'Nhập câu trả lời...',
            border: const OutlineInputBorder(),
          ),
          maxLines: q['multiline'] == true ? 3 : 1,
          onChanged: (v) => _answers[questionId] = v,
        );
    }
  }
}

// ============================================================================
// PRODUCT RECOMMENDATIONS - Đề xuất sản phẩm
// ============================================================================
class ProductRecommendations extends ConsumerStatefulWidget {
  final String customerId;
  final Function(Map<String, dynamic>)? onProductSelected;

  const ProductRecommendations({
    super.key,
    required this.customerId,
    this.onProductSelected,
  });

  @override
  ConsumerState<ProductRecommendations> createState() => _ProductRecommendationsState();
}

class _ProductRecommendationsState extends ConsumerState<ProductRecommendations> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      // Get customer's frequently bought products
      final products = await ref.read(customerHistoryServiceProvider).getFrequentProducts(widget.customerId);
      
      // If no history, get popular products for company
      if (products.isEmpty) {
        final user = ref.read(currentUserProvider);
        final companyId = user?.companyId;
        if (companyId != null) {
          final response = await supabase
              .from('products')
              .select('id, name, sku, unit, selling_price')
              .eq('company_id', companyId)
              .eq('status', 'active')
              .order('name')
              .limit(10);
          setState(() => _products = List<Map<String, dynamic>>.from(response));
        }
      } else {
        setState(() => _products = products);
      }
    } catch (e) {
      // Silent fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            const Text('Đề xuất cho khách hàng này', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return GestureDetector(
                onTap: () => widget.onProductSelected?.call(product),
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(right: index < _products.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _currencyFormat.format(product['selling_price'] ?? 0),
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (product['order_count'] != null)
                        Text(
                          'Đã mua ${product['order_count']} lần',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SURVEYS LIST - Danh sách khảo sát
// ============================================================================
class SurveysList extends ConsumerStatefulWidget {
  final String? customerId;
  final String? visitId;

  const SurveysList({
    super.key,
    this.customerId,
    this.visitId,
  });

  @override
  ConsumerState<SurveysList> createState() => _SurveysListState();
}

class _SurveysListState extends ConsumerState<SurveysList> {
  List<Survey> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final user = ref.read(currentUserProvider);
    final companyId = user?.companyId;
    if (companyId == null) return;

    final surveys = await ref.read(surveyServiceProvider).getActiveSurveys(companyId);
    if (mounted) {
      setState(() {
        _surveys = surveys;
        _isLoading = false;
      });
    }
  }

  void _openCreateSurvey() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateQuickSurveyForm()),
    );
    if (created == true) _loadSurveys();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_surveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.poll_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Không có khảo sát', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openCreateSurvey,
              icon: const Icon(Icons.add),
              label: const Text('Tạo khảo sát'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _surveys.length,
            itemBuilder: (context, index) {
              final survey = _surveys[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Icon(Icons.poll, color: Colors.purple.shade700),
                  ),
                  title: Text(survey.title),
                  subtitle: Text(
                    '${survey.questions.length} câu hỏi • ${survey.currentResponses}/${survey.targetResponses} phản hồi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurveyFormWidget(
                          survey: survey,
                          customerId: widget.customerId,
                          visitId: widget.visitId,
                          onCompleted: () => _loadSurveys(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: _openCreateSurvey,
            icon: const Icon(Icons.add),
            label: const Text('Tạo khảo sát mới'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CREATE QUICK SURVEY FORM - Tạo nhanh khảo sát
// ============================================================================
class CreateQuickSurveyForm extends ConsumerStatefulWidget {
  const CreateQuickSurveyForm({super.key});

  @override
  ConsumerState<CreateQuickSurveyForm> createState() => _CreateQuickSurveyFormState();
}

class _CreateQuickSurveyFormState extends ConsumerState<CreateQuickSurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_QuestionItem> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addQuestion(); // Start with 1 question
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionItem());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      final userId = user?.id;
      if (companyId == null) return;

      final questions = <Map<String, dynamic>>[];
      for (var i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final questionText = q.questionController.text.trim();
        if (questionText.isEmpty) continue;

        final map = <String, dynamic>{
          'id': 'q${i + 1}',
          'question': questionText,
          'type': q.type,
          'required': q.isRequired,
        };

        if (q.type == 'single_choice' || q.type == 'multiple_choice') {
          final options = q.optionsController.text
              .split('\n')
              .map((o) => o.trim())
              .where((o) => o.isNotEmpty)
              .toList();
          if (options.isNotEmpty) map['options'] = options;
        }

        if (q.type == 'rating') {
          map['max_rating'] = q.maxRating;
        }

        questions.add(map);
      }

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần ít nhất 1 câu hỏi')),
        );
        setState(() => _isSaving = false);
        return;
      }

      await ref.read(surveyServiceProvider).createSurvey(
        companyId: companyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        questions: questions,
        createdBy: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo khảo sát'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo khảo sát nhanh'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _addQuestion,
        child: const Icon(Icons.add),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề khảo sát *',
                hintText: 'VD: Khảo sát chất lượng dịch vụ',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.quiz, size: 20),
                const SizedBox(width: 8),
                Text('Câu hỏi (${_questions.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              return _buildQuestionCard(q, index);
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Thêm câu hỏi'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(_QuestionItem q, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade100,
                  child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: q.questionController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập câu hỏi' : null,
                  ),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeQuestion(index),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: q.type,
                    decoration: const InputDecoration(
                      labelText: 'Loại',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Văn bản')),
                      DropdownMenuItem(value: 'yes_no', child: Text('Có / Không')),
                      DropdownMenuItem(value: 'rating', child: Text('Đánh giá (1-5)')),
                      DropdownMenuItem(value: 'single_choice', child: Text('Chọn 1')),
                      DropdownMenuItem(value: 'multiple_choice', child: Text('Chọn nhiều')),
                    ],
                    onChanged: (v) {
                      setState(() => q.type = v ?? 'text');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Bắt buộc'),
                  selected: q.isRequired,
                  onSelected: (v) => setState(() => q.isRequired = v),
                ),
              ],
            ),
            if (q.type == 'single_choice' || q.type == 'multiple_choice') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: q.optionsController,
                decoration: const InputDecoration(
                  labelText: 'Các lựa chọn (mỗi dòng 1 lựa chọn)',
                  hintText: 'Tốt\nBình thường\nKém',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nhập ít nhất 2 lựa chọn';
                  final lines = v.split('\n').where((l) => l.trim().isNotEmpty).toList();
                  if (lines.length < 2) return 'Cần ít nhất 2 lựa chọn';
                  return null;
                },
              ),
            ],
            if (q.type == 'rating') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Thang điểm tối đa: '),
                  ...List.generate(4, (i) {
                    final val = i + 3; // 3,4,5,6
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text('$val'),
                        selected: q.maxRating == val,
                        onSelected: (s) {
                          if (s) setState(() => q.maxRating = val);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionItem {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionsController = TextEditingController();
  String type = 'text';
  bool isRequired = false;
  int maxRating = 5;

  void dispose() {
    questionController.dispose();
    optionsController.dispose();
  }
}
