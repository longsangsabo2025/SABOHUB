import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../business_types/service/models/event.dart';
import '../../../business_types/service/providers/event_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Event Create/Edit Form — SABO Events
class EventFormPage extends ConsumerStatefulWidget {
  final Event? event; // null = create mode

  const EventFormPage({super.key, this.event});

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueNameCtrl;
  late final TextEditingController _venueAddressCtrl;
  late final TextEditingController _onlineUrlCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _expectedAttendeesCtrl;
  late final TextEditingController _bannerUrlCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagsCtrl;

  late EventType _eventType;
  late EventStatus _status;
  bool _isOnline = false;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _venueNameCtrl = TextEditingController(text: e?.venueName ?? '');
    _venueAddressCtrl = TextEditingController(text: e?.venueAddress ?? '');
    _onlineUrlCtrl = TextEditingController(text: e?.onlineUrl ?? '');
    _budgetCtrl = TextEditingController(text: '${e?.budget ?? 0}');
    _expectedAttendeesCtrl =
        TextEditingController(text: '${e?.expectedAttendees ?? 0}');
    _bannerUrlCtrl = TextEditingController(text: e?.bannerUrl ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _tagsCtrl = TextEditingController(text: e?.tags?.join(', ') ?? '');

    _eventType = e?.eventType ?? EventType.tournament;
    _status = e?.status ?? EventStatus.planning;
    _isOnline = e?.isOnline ?? false;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _onlineUrlCtrl.dispose();
    _budgetCtrl.dispose();
    _expectedAttendeesCtrl.dispose();
    _bannerUrlCtrl.dispose();
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
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId ?? '';
      final actions = ref.read(eventActionsProvider);

      if (_isEdit) {
        await actions.updateEvent(widget.event!.id, {
          'title': _titleCtrl.text.trim(),
          'description':
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          'event_type': _eventType.value,
          'status': _status.value,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'venue_name': _venueNameCtrl.text.trim().isEmpty
              ? null
              : _venueNameCtrl.text.trim(),
          'venue_address': _venueAddressCtrl.text.trim().isEmpty
              ? null
              : _venueAddressCtrl.text.trim(),
          'is_online': _isOnline,
          'online_url': _onlineUrlCtrl.text.trim().isEmpty
              ? null
              : _onlineUrlCtrl.text.trim(),
          'budget': double.tryParse(_budgetCtrl.text) ?? 0,
          'expected_attendees':
              int.tryParse(_expectedAttendeesCtrl.text) ?? 0,
          'banner_url': _bannerUrlCtrl.text.trim().isEmpty
              ? null
              : _bannerUrlCtrl.text.trim(),
          'notes':
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'tags': _parseTags(),
        });
      } else {
        final event = Event(
          id: '',
          companyId: companyId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          eventType: _eventType,
          status: _status,
          startDate: _startDate,
          endDate: _endDate,
          venueName: _venueNameCtrl.text.trim().isEmpty
              ? null
              : _venueNameCtrl.text.trim(),
          venueAddress: _venueAddressCtrl.text.trim().isEmpty
              ? null
              : _venueAddressCtrl.text.trim(),
          isOnline: _isOnline,
          onlineUrl: _onlineUrlCtrl.text.trim().isEmpty
              ? null
              : _onlineUrlCtrl.text.trim(),
          budget: double.tryParse(_budgetCtrl.text) ?? 0,
          expectedAttendees:
              int.tryParse(_expectedAttendeesCtrl.text) ?? 0,
          bannerUrl: _bannerUrlCtrl.text.trim().isEmpty
              ? null
              : _bannerUrlCtrl.text.trim(),
          notes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          tags: _parseTags(),
          managerId: user?.id,
        );
        await actions.createEvent(event);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Đã cập nhật sự kiện' : 'Đã tạo sự kiện mới'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa sự kiện' : 'Tạo sự kiện mới'),
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
                      decoration: _inputDeco('Tên sự kiện *', Icons.event),
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

                    // Type & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<EventType>(
                            value: _eventType,
                            decoration:
                                _inputDeco('Loại sự kiện', Icons.category),
                            items: EventType.values
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.label)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _eventType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<EventStatus>(
                            value: _status,
                            decoration:
                                _inputDeco('Trạng thái', Icons.flag),
                            items: EventStatus.values
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

                    // ── Schedule ──
                    _sectionHeader('Lịch trình'),
                    Row(
                      children: [
                        Expanded(
                            child: _dateTile('Ngày bắt đầu', _startDate,
                                (d) => setState(() => _startDate = d))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dateTile('Ngày kết thúc', _endDate,
                                (d) => setState(() => _endDate = d))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Venue ──
                    _sectionHeader('Địa điểm'),
                    SwitchListTile(
                      title: const Text('Sự kiện online'),
                      value: _isOnline,
                      onChanged: (v) => setState(() => _isOnline = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isOnline) ...[
                      TextFormField(
                        controller: _onlineUrlCtrl,
                        decoration:
                            _inputDeco('Online URL', Icons.link),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _venueNameCtrl,
                        decoration:
                            _inputDeco('Tên địa điểm', Icons.location_on),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _venueAddressCtrl,
                        decoration: _inputDeco('Địa chỉ', Icons.map),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── Budget & Capacity ──
                    _sectionHeader('Ngân sách & Quy mô'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetCtrl,
                            decoration:
                                _inputDeco('Ngân sách (VNĐ)', Icons.paid),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _expectedAttendeesCtrl,
                            decoration: _inputDeco(
                                'Dự kiến người tham dự', Icons.people),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Media & Notes ──
                    _sectionHeader('Media & Ghi chú'),
                    TextFormField(
                      controller: _bannerUrlCtrl,
                      decoration: _inputDeco('Banner URL', Icons.image),
                    ),
                    const SizedBox(height: 12),
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
                        label:
                            Text(_isEdit ? 'Lưu thay đổi' : 'Tạo sự kiện'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
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
        title: const Text('Xóa sự kiện?'),
        content: Text(
            'Bạn có chắc chắn muốn xóa "${widget.event!.title}"? Hành động này không thể hoàn tác.'),
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
        await ref.read(eventActionsProvider).deleteEvent(widget.event!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã xóa sự kiện'),
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
