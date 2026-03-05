import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../business_types/service/models/content.dart';
import '../../../business_types/service/providers/content_provider.dart';
import '../../../business_types/service/providers/media_channel_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Content Calendar Create/Edit Form — SABO Media Production
class ContentFormPage extends ConsumerStatefulWidget {
  final ContentCalendar? content; // null = create mode

  const ContentFormPage({super.key, this.content});

  @override
  ConsumerState<ContentFormPage> createState() => _ContentFormPageState();
}

class _ContentFormPageState extends ConsumerState<ContentFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _platformCtrl;
  late final TextEditingController _thumbnailUrlCtrl;
  late final TextEditingController _contentUrlCtrl;
  late final TextEditingController _scriptUrlCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagsCtrl;

  late ContentType _contentType;
  late ContentStatus _status;
  String? _channelId;
  DateTime? _plannedDate;
  DateTime? _deadline;

  bool get _isEdit => widget.content != null;

  @override
  void initState() {
    super.initState();
    final c = widget.content;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _platformCtrl = TextEditingController(text: c?.platform ?? '');
    _thumbnailUrlCtrl = TextEditingController(text: c?.thumbnailUrl ?? '');
    _contentUrlCtrl = TextEditingController(text: c?.contentUrl ?? '');
    _scriptUrlCtrl = TextEditingController(text: c?.scriptUrl ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _tagsCtrl = TextEditingController(text: c?.tags?.join(', ') ?? '');

    _contentType = c?.contentType ?? ContentType.video;
    _status = c?.status ?? ContentStatus.idea;
    _channelId = c?.channelId;
    _plannedDate = c?.plannedDate;
    _deadline = c?.deadline;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _platformCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _contentUrlCtrl.dispose();
    _scriptUrlCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String label, DateTime? current,
      ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: label,
    );
    if (picked != null) onPicked(picked);
  }

  List<String>? _parseTags() {
    final raw = _tagsCtrl.text.trim();
    if (raw.isEmpty) return null;
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId ?? '';
      final actions = ref.read(contentActionsProvider);

      if (_isEdit) {
        await actions.updateContent(widget.content!.id, {
          'title': _titleCtrl.text.trim(),
          'description':
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          'content_type': _contentType.value,
          'status': _status.value,
          'channel_id': _channelId,
          'platform': _platformCtrl.text.trim().isEmpty
              ? null
              : _platformCtrl.text.trim(),
          'planned_date': _plannedDate?.toIso8601String().split('T').first,
          'deadline': _deadline?.toIso8601String().split('T').first,
          'thumbnail_url': _thumbnailUrlCtrl.text.trim().isEmpty
              ? null
              : _thumbnailUrlCtrl.text.trim(),
          'content_url': _contentUrlCtrl.text.trim().isEmpty
              ? null
              : _contentUrlCtrl.text.trim(),
          'script_url': _scriptUrlCtrl.text.trim().isEmpty
              ? null
              : _scriptUrlCtrl.text.trim(),
          'notes':
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'tags': _parseTags(),
        });
      } else {
        final content = ContentCalendar(
          id: '',
          companyId: companyId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          contentType: _contentType,
          status: _status,
          channelId: _channelId,
          platform: _platformCtrl.text.trim().isEmpty
              ? null
              : _platformCtrl.text.trim(),
          plannedDate: _plannedDate ?? DateTime.now(),
          deadline: _deadline,
          thumbnailUrl: _thumbnailUrlCtrl.text.trim().isEmpty
              ? null
              : _thumbnailUrlCtrl.text.trim(),
          contentUrl: _contentUrlCtrl.text.trim().isEmpty
              ? null
              : _contentUrlCtrl.text.trim(),
          scriptUrl: _scriptUrlCtrl.text.trim().isEmpty
              ? null
              : _scriptUrlCtrl.text.trim(),
          notes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          tags: _parseTags(),
          assignedTo: user?.id,
        );
        await actions.createContent(content);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Đã cập nhật content' : 'Đã tạo content mới'),
            backgroundColor: Colors.green,
          ),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final channelsAsync = ref.watch(mediaChannelsProvider(companyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa content' : 'Tạo content mới'),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ──
                    _sectionHeader('Thông tin cơ bản'),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration:
                          _inputDeco('Tiêu đề content *', Icons.title),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDeco('Mô tả', Icons.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Content Type & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ContentType>(
                            value: _contentType,
                            decoration:
                                _inputDeco('Loại content', Icons.video_library),
                            items: ContentType.values
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.label)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _contentType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<ContentStatus>(
                            value: _status,
                            decoration:
                                _inputDeco('Trạng thái', Icons.flag),
                            items: ContentStatus.values
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.label)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Channel & Platform ──
                    _sectionHeader('Kênh & Nền tảng'),
                    channelsAsync.when(
                      data: (channels) {
                        return DropdownButtonFormField<String?>(
                          value: _channelId,
                          decoration:
                              _inputDeco('Kênh phát hành', Icons.tv),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Chưa chọn')),
                            ...channels.map((ch) => DropdownMenuItem(
                                value: ch.id,
                                child: Text(
                                    '${ch.platformIcon} ${ch.name}'))),
                          ],
                          onChanged: (v) =>
                              setState(() => _channelId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => TextFormField(
                        controller: _platformCtrl,
                        decoration:
                            _inputDeco('Nền tảng', Icons.language),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _platformCtrl,
                      decoration: _inputDeco(
                          'Platform (youtube, tiktok...)', Icons.language),
                    ),
                    const SizedBox(height: 16),

                    // ── Schedule ──
                    _sectionHeader('Lịch trình'),
                    Row(
                      children: [
                        Expanded(
                            child: _dateTile(
                                'Ngày dự kiến *',
                                _plannedDate,
                                (d) =>
                                    setState(() => _plannedDate = d))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dateTile('Deadline', _deadline,
                                (d) => setState(() => _deadline = d))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Media URLs ──
                    _sectionHeader('Tài nguyên'),
                    TextFormField(
                      controller: _thumbnailUrlCtrl,
                      decoration:
                          _inputDeco('Thumbnail URL', Icons.image),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentUrlCtrl,
                      decoration:
                          _inputDeco('Content URL', Icons.link),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scriptUrlCtrl,
                      decoration:
                          _inputDeco('Script/Kịch bản URL', Icons.article),
                    ),
                    const SizedBox(height: 16),

                    // ── Notes & Tags ──
                    _sectionHeader('Ghi chú'),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: _inputDeco('Ghi chú', Icons.note),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsCtrl,
                      decoration: _inputDeco(
                          'Tags (cách nhau bằng dấu phẩy)', Icons.tag),
                    ),
                    const SizedBox(height: 24),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: Icon(_isEdit ? Icons.save : Icons.add),
                        label: Text(
                            _isEdit ? 'Lưu thay đổi' : 'Tạo content'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.backgroundDark,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _dateTile(
      String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => _pickDate(label, value, onPicked),
      child: InputDecorator(
        decoration: _inputDeco(label, Icons.calendar_today),
        child: Text(
          value != null ? fmt.format(value) : 'Chọn ngày',
          style: TextStyle(
            color: value != null ? Theme.of(context).colorScheme.onSurface87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa content?'),
        content: Text(
            'Bạn có chắc chắn muốn xóa "${widget.content!.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(contentActionsProvider)
            .deleteContent(widget.content!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã xóa content'),
                backgroundColor: Colors.orange),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
