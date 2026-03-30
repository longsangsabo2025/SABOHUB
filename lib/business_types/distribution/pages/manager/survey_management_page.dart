import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../services/sales_features_service.dart';

/// Survey Management Page — Manager tạo, quản lý, xem kết quả khảo sát
class SurveyManagementPage extends ConsumerStatefulWidget {
  const SurveyManagementPage({super.key});

  @override
  ConsumerState<SurveyManagementPage> createState() => _SurveyManagementPageState();
}

class _SurveyManagementPageState extends ConsumerState<SurveyManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Survey> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSurveys();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSurveys() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final surveys = await ref.read(surveyServiceProvider).getAllSurveys(companyId);
      if (mounted) setState(() => _surveys = surveys);
    } catch (e) {
      AppLogger.error('Failed to load surveys', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSurveys = _surveys.where((s) => s.isActive).toList();
    final inactiveSurveys = _surveys.where((s) => !s.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khảo sát'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Đang hoạt động (${activeSurveys.length})'),
            Tab(text: 'Đã tắt (${inactiveSurveys.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSurveys,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSurveyList(activeSurveys, isEmpty: 'Chưa có khảo sát nào đang hoạt động'),
                _buildSurveyList(inactiveSurveys, isEmpty: 'Không có khảo sát nào đã tắt'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSurveySheet,
        icon: const Icon(Icons.add),
        label: const Text('Tạo khảo sát'),
      ),
    );
  }

  Widget _buildSurveyList(List<Survey> surveys, {required String isEmpty}) {
    if (surveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.poll_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(isEmpty, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSurveys,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surveys.length,
        itemBuilder: (context, index) => _buildSurveyCard(surveys[index]),
      ),
    );
  }

  Widget _buildSurveyCard(Survey survey) {
    final progress = survey.targetResponses > 0
        ? survey.currentResponses / survey.targetResponses
        : 0.0;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSurveyDetail(survey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      survey.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildSurveyMenu(survey),
                ],
              ),
              if (survey.description != null && survey.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(survey.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.quiz, '${survey.questions.length} câu hỏi'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.people, '${survey.currentResponses} phản hồi'),
                  if (survey.targetResponses > 0) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.flag, 'Mục tiêu: ${survey.targetResponses}'),
                  ],
                ],
              ),
              if (survey.targetResponses > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0 ? Colors.green : Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).round()}% hoàn thành',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (survey.startDate != null || survey.endDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      [
                        if (survey.startDate != null) 'Từ ${dateFormat.format(survey.startDate!)}',
                        if (survey.endDate != null) 'Đến ${dateFormat.format(survey.endDate!)}',
                      ].join(' — '),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSurveyMenu(Survey survey) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'toggle':
            await ref.read(surveyServiceProvider).toggleSurveyActive(survey.id, !survey.isActive);
            _loadSurveys();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(survey.isActive ? 'Đã tắt khảo sát' : 'Đã bật khảo sát'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          case 'results':
            _showSurveyResults(survey);
            break;
          case 'edit':
            _showEditSurveySheet(survey);
            break;
          case 'delete':
            _confirmDelete(survey);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'results',
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Xem kết quả'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Sửa'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(survey.isActive ? Icons.pause : Icons.play_arrow,
                  size: 20, color: survey.isActive ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              Text(survey.isActive ? 'Tắt khảo sát' : 'Bật khảo sát'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Xóa', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Survey survey) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khảo sát?'),
        content: Text('Xóa "${survey.title}" và tất cả phản hồi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(surveyServiceProvider).deleteSurvey(survey.id);
                _loadSurveys();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa khảo sát'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // SURVEY DETAIL (bottom sheet)
  // ──────────────────────────────────────────────────────────────────────

  void _showSurveyDetail(Survey survey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(survey.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showSurveyResults(survey);
                      },
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('Kết quả'),
                    ),
                  ],
                ),
              ),
              if (survey.description != null && survey.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(survey.description!, style: TextStyle(color: Colors.grey.shade600)),
                ),
              const Divider(),
              // Questions preview
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: survey.questions.length,
                  itemBuilder: (_, index) {
                    final q = survey.questions[index];
                    return _buildQuestionPreview(q, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPreview(Map<String, dynamic> q, int index) {
    final type = q['type'] ?? 'text';
    final options = List<String>.from(q['options'] ?? []);
    final required = q['required'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${q['question']}${required ? ' *' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _questionTypeLabel(type),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Row(
                      children: [
                        Icon(
                          type == 'multiple_choice' ? Icons.check_box_outline_blank : Icons.radio_button_unchecked,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(opt, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'single_choice':
        return '○ Chọn một';
      case 'multiple_choice':
        return '☐ Chọn nhiều';
      case 'rating':
        return '★ Đánh giá';
      case 'yes_no':
        return '✓/✗ Có/Không';
      default:
        return '✎ Tự nhập';
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // CREATE SURVEY (bottom sheet)
  // ──────────────────────────────────────────────────────────────────────

  void _showCreateSurveySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SurveyEditorSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _loadSurveys();
        },
      ),
    );
  }

  void _showEditSurveySheet(Survey survey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SurveyEditorSheet(
        existingSurvey: survey,
        onSaved: () {
          Navigator.pop(ctx);
          _loadSurveys();
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // SURVEY RESULTS
  // ──────────────────────────────────────────────────────────────────────

  void _showSurveyResults(Survey survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SurveyResultsPage(survey: survey),
      ),
    );
  }
}

// ============================================================================
// SURVEY EDITOR SHEET — Tạo / Sửa khảo sát
// ============================================================================

class _SurveyEditorSheet extends ConsumerStatefulWidget {
  final Survey? existingSurvey;
  final VoidCallback onSaved;

  const _SurveyEditorSheet({this.existingSurvey, required this.onSaved});

  @override
  ConsumerState<_SurveyEditorSheet> createState() => _SurveyEditorSheetState();
}

class _SurveyEditorSheetState extends ConsumerState<_SurveyEditorSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  final List<_QuestionDraft> _questions = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingSurvey != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.existingSurvey!;
      _titleController.text = s.title;
      _descController.text = s.description ?? '';
      _targetController.text = s.targetResponses > 0 ? s.targetResponses.toString() : '';
      for (final q in s.questions) {
        _questions.add(_QuestionDraft(
          question: q['question'] ?? '',
          type: q['type'] ?? 'single_choice',
          options: List<String>.from(q['options'] ?? []),
          required: q['required'] == true,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề khảo sát'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 câu hỏi'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.question.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Câu hỏi ${i + 1} chưa có nội dung'), backgroundColor: Colors.orange),
        );
        return;
      }
      if (['single_choice', 'multiple_choice'].contains(q.type) && q.options.where((o) => o.trim().isNotEmpty).length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Câu hỏi ${i + 1} cần ít nhất 2 lựa chọn'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final questionsJson = _questions.map((q) => q.toJson()).toList();
      final target = int.tryParse(_targetController.text.trim()) ?? 0;
      final service = ref.read(surveyServiceProvider);

      if (_isEditing) {
        await service.updateSurvey(
          surveyId: widget.existingSurvey!.id,
          title: title,
          description: _descController.text.trim(),
          questions: questionsJson,
          targetResponses: target,
        );
      } else {
        await service.createSurvey(
          companyId: companyId,
          title: title,
          description: _descController.text.trim(),
          questions: questionsJson,
          createdBy: user?.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật khảo sát' : 'Đã tạo khảo sát mới'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
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

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft(
        question: '',
        type: 'single_choice',
        options: ['', ''],
        required: true,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle + header
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Sửa khảo sát' : 'Tạo khảo sát mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEditing ? 'Cập nhật' : 'Lưu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề khảo sát *',
                      hintText: 'VD: Khảo sát nước giặt tiệm giặt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (tùy chọn)',
                      hintText: 'VD: Thu thập thông tin về thói quen sử dụng nước giặt...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Target
                  TextField(
                    controller: _targetController,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu phản hồi (tùy chọn)',
                      hintText: 'VD: 100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Questions header
                  Row(
                    children: [
                      const Text('CÂU HỎI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const Spacer(),
                      Text('${_questions.length} câu', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Questions list
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    return _buildQuestionEditor(q, index);
                  }),

                  // Add question button
                  OutlinedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm câu hỏi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.teal, style: BorderStyle.solid),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(_QuestionDraft q, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Câu ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 12)),
                ),
                const Spacer(),
                // Move up/down
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed: () {
                      setState(() {
                        final item = _questions.removeAt(index);
                        _questions.insert(index - 1, item);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (index < _questions.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    onPressed: () {
                      setState(() {
                        final item = _questions.removeAt(index);
                        _questions.insert(index + 1, item);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
                  onPressed: () => setState(() => _questions.removeAt(index)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question text
            TextField(
              controller: TextEditingController(text: q.question)
                ..selection = TextSelection.collapsed(offset: q.question.length),
              decoration: const InputDecoration(
                hintText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => q.question = v,
            ),
            const SizedBox(height: 8),

            // Type selector + required
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: q.type,
                    decoration: const InputDecoration(
                      labelText: 'Loại',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'single_choice', child: Text('Chọn một')),
                      DropdownMenuItem(value: 'multiple_choice', child: Text('Chọn nhiều')),
                      DropdownMenuItem(value: 'text', child: Text('Tự nhập')),
                      DropdownMenuItem(value: 'rating', child: Text('Đánh giá (1-5)')),
                      DropdownMenuItem(value: 'yes_no', child: Text('Có / Không')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        q.type = v;
                        if (['single_choice', 'multiple_choice'].contains(v) && q.options.isEmpty) {
                          q.options = ['', ''];
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Checkbox(
                      value: q.required,
                      onChanged: (v) => setState(() => q.required = v ?? true),
                    ),
                    const Text('Bắt buộc', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),

            // Options (for choice types)
            if (['single_choice', 'multiple_choice'].contains(q.type)) ...[
              const SizedBox(height: 12),
              ...q.options.asMap().entries.map((optEntry) {
                final optIndex = optEntry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        q.type == 'multiple_choice'
                            ? Icons.check_box_outline_blank
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: optEntry.value)
                            ..selection = TextSelection.collapsed(offset: optEntry.value.length),
                          decoration: InputDecoration(
                            hintText: 'Lựa chọn ${optIndex + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (v) => q.options[optIndex] = v,
                        ),
                      ),
                      if (q.options.length > 2)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red.shade400),
                          onPressed: () => setState(() => q.options.removeAt(optIndex)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => q.options.add('')),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm lựa chọn', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  String question;
  String type;
  List<String> options;
  bool required;

  _QuestionDraft({
    required this.question,
    required this.type,
    required this.options,
    required this.required,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': 'q_${DateTime.now().millisecondsSinceEpoch}_${question.hashCode.abs()}',
      'question': question.trim(),
      'type': type,
      'required': required,
    };
    if (['single_choice', 'multiple_choice'].contains(type)) {
      json['options'] = options.where((o) => o.trim().isNotEmpty).toList();
    }
    if (type == 'rating') {
      json['max_rating'] = 5;
    }
    return json;
  }
}

// ============================================================================
// SURVEY RESULTS PAGE — Xem kết quả khảo sát chi tiết
// ============================================================================

class _SurveyResultsPage extends ConsumerStatefulWidget {
  final Survey survey;

  const _SurveyResultsPage({required this.survey});

  @override
  ConsumerState<_SurveyResultsPage> createState() => _SurveyResultsPageState();
}

class _SurveyResultsPageState extends ConsumerState<_SurveyResultsPage> {
  List<Map<String, dynamic>> _responses = [];
  Map<String, Map<String, int>> _aggregation = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(surveyServiceProvider);
      final responses = await service.getSurveyResponses(widget.survey.id);
      final aggregation = await service.getAnswerAggregation(widget.survey.id);
      if (mounted) {
        setState(() {
          _responses = responses;
          _aggregation = aggregation;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load survey results', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey.title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResults),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Chưa có phản hồi nào', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    // Per-question breakdown
                    ...widget.survey.questions.asMap().entries.map((entry) {
                      return _buildQuestionResult(entry.value, entry.key);
                    }),
                    const SizedBox(height: 16),
                    // Individual responses
                    _buildResponsesList(),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard() {
    final avgDuration = _responses.isNotEmpty
        ? _responses
                .map((r) => (r['duration_seconds'] as num?)?.toInt() ?? 0)
                .reduce((a, b) => a + b) ~/
            _responses.length
        : 0;

    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Phản hồi', '${_responses.length}', Icons.people, Colors.blue),
                _buildStatItem('Câu hỏi', '${widget.survey.questions.length}', Icons.quiz, Colors.teal),
                _buildStatItem('TB thời gian', '${avgDuration}s', Icons.timer, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQuestionResult(Map<String, dynamic> q, int index) {
    final questionId = q['id'] ?? 'q$index';
    final type = q['type'] ?? 'text';
    final answers = _aggregation[questionId] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${q['question']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (['single_choice', 'multiple_choice', 'yes_no'].contains(type))
              _buildBarChart(answers)
            else if (type == 'rating')
              _buildRatingResult(answers)
            else
              _buildTextResponses(questionId),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) return Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey.shade500));

    final total = data.values.fold(0, (a, b) => a + b);
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final pct = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13))),
                  Text('${entry.value} (${(pct * 100).round()}%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Colors.teal.shade400),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingResult(Map<String, int> data) {
    if (data.isEmpty) return Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey.shade500));

    final total = data.values.fold(0, (a, b) => a + b);
    double weightedSum = 0;
    for (final e in data.entries) {
      weightedSum += (int.tryParse(e.key) ?? 0) * e.value;
    }
    final avg = total > 0 ? weightedSum / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Row(
              children: List.generate(5, (i) => Icon(
                i < avg.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              )),
            ),
            const SizedBox(width: 8),
            Text('($total phản hồi)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        _buildBarChart(data),
      ],
    );
  }

  Widget _buildTextResponses(String questionId) {
    final textAnswers = _responses
        .where((r) {
          final answers = Map<String, dynamic>.from(r['answers'] ?? {});
          return answers[questionId] != null && answers[questionId].toString().trim().isNotEmpty;
        })
        .map((r) => Map<String, dynamic>.from(r['answers'] ?? {})[questionId].toString())
        .toList();

    if (textAnswers.isEmpty) return Text('Chưa có câu trả lời', style: TextStyle(color: Colors.grey.shade500));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textAnswers.take(10).map((answer) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(answer, style: const TextStyle(fontSize: 13)),
          )).toList(),
    );
  }

  Widget _buildResponsesList() {
    final dateFormat = DateFormat('dd/MM HH:mm');
    return ExpansionTile(
      title: Text('Phản hồi chi tiết (${_responses.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
      children: _responses.take(50).map((r) {
        final customerName = r['customers']?['name'] ?? 'Không rõ';
        final respondentName = r['employees']?['full_name'] ?? '';
        final completedAt = r['completed_at'] != null ? dateFormat.format(DateTime.parse(r['completed_at'])) : '';
        final duration = r['duration_seconds'] ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal.shade50,
            child: Text(customerName.isNotEmpty ? customerName[0] : '?',
                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
          ),
          title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
            '${respondentName.isNotEmpty ? 'Bởi: $respondentName • ' : ''}$completedAt • ${duration}s',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResponseDetail(r),
        );
      }).toList(),
    );
  }

  void _showResponseDetail(Map<String, dynamic> response) {
    final answers = Map<String, dynamic>.from(response['answers'] ?? {});
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                'Phản hồi: ${response['customers']?['name'] ?? 'Không rõ'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...widget.survey.questions.map((q) {
                final questionId = q['id'] ?? '';
                final answer = answers[questionId];
                return ListTile(
                  title: Text(q['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  subtitle: Text(
                    answer is List ? answer.join(', ') : (answer?.toString() ?? '—'),
                    style: TextStyle(color: Colors.teal.shade700),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
