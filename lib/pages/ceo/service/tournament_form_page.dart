import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../business_types/service/models/tournament.dart';
import '../../../business_types/service/providers/tournament_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Tournament Create/Edit Form — SABO Billiard Tournaments
class TournamentFormPage extends ConsumerStatefulWidget {
  final Tournament? tournament; // null = create mode

  const TournamentFormPage({super.key, this.tournament});

  @override
  ConsumerState<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends ConsumerState<TournamentFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueNameCtrl;
  late final TextEditingController _venueAddressCtrl;
  late final TextEditingController _maxParticipantsCtrl;
  late final TextEditingController _entryFeeCtrl;
  late final TextEditingController _prizePoolCtrl;
  late final TextEditingController _sponsorNameCtrl;
  late final TextEditingController _sponsorAmountCtrl;
  late final TextEditingController _rulesCtrl;
  late final TextEditingController _tableCountCtrl;
  late final TextEditingController _bannerUrlCtrl;
  late final TextEditingController _livestreamUrlCtrl;

  // Enum values
  late TournamentType _tournamentType;
  late GameType _gameType;
  late TournamentStatus _status;

  // Dates
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;

  bool get _isEdit => widget.tournament != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _venueNameCtrl = TextEditingController(text: t?.venueName ?? '');
    _venueAddressCtrl = TextEditingController(text: t?.venueAddress ?? '');
    _maxParticipantsCtrl =
        TextEditingController(text: '${t?.maxParticipants ?? 32}');
    _entryFeeCtrl = TextEditingController(text: '${t?.entryFee ?? 0}');
    _prizePoolCtrl = TextEditingController(text: '${t?.prizePool ?? 0}');
    _sponsorNameCtrl = TextEditingController(text: t?.sponsorName ?? '');
    _sponsorAmountCtrl =
        TextEditingController(text: '${t?.sponsorAmount ?? 0}');
    _rulesCtrl = TextEditingController(text: t?.rulesText ?? '');
    _tableCountCtrl = TextEditingController(text: '${t?.tableCount ?? 1}');
    _bannerUrlCtrl = TextEditingController(text: t?.bannerUrl ?? '');
    _livestreamUrlCtrl = TextEditingController(text: t?.livestreamUrl ?? '');

    _tournamentType = t?.tournamentType ?? TournamentType.singleElimination;
    _gameType = t?.gameType ?? GameType.pool;
    _status = t?.status ?? TournamentStatus.draft;

    _startDate = t?.startDate;
    _endDate = t?.endDate;
    _registrationDeadline = t?.registrationDeadline;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizePoolCtrl.dispose();
    _sponsorNameCtrl.dispose();
    _sponsorAmountCtrl.dispose();
    _rulesCtrl.dispose();
    _tableCountCtrl.dispose();
    _bannerUrlCtrl.dispose();
    _livestreamUrlCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId ?? '';
      final actions = ref.read(tournamentActionsProvider);

      if (_isEdit) {
        await actions.updateTournament(widget.tournament!.id, {
          'name': _nameCtrl.text.trim(),
          'description':
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          'tournament_type': _tournamentType.value,
          'game_type': _gameType.value,
          'status': _status.value,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'registration_deadline': _registrationDeadline?.toIso8601String(),
          'venue_name': _venueNameCtrl.text.trim().isEmpty
              ? null
              : _venueNameCtrl.text.trim(),
          'venue_address': _venueAddressCtrl.text.trim().isEmpty
              ? null
              : _venueAddressCtrl.text.trim(),
          'max_participants':
              int.tryParse(_maxParticipantsCtrl.text) ?? 32,
          'entry_fee': double.tryParse(_entryFeeCtrl.text) ?? 0,
          'prize_pool': double.tryParse(_prizePoolCtrl.text) ?? 0,
          'sponsor_name': _sponsorNameCtrl.text.trim().isEmpty
              ? null
              : _sponsorNameCtrl.text.trim(),
          'sponsor_amount': double.tryParse(_sponsorAmountCtrl.text) ?? 0,
          'rules_text':
              _rulesCtrl.text.trim().isEmpty ? null : _rulesCtrl.text.trim(),
          'table_count': int.tryParse(_tableCountCtrl.text) ?? 1,
          'banner_url': _bannerUrlCtrl.text.trim().isEmpty
              ? null
              : _bannerUrlCtrl.text.trim(),
          'livestream_url': _livestreamUrlCtrl.text.trim().isEmpty
              ? null
              : _livestreamUrlCtrl.text.trim(),
        });
      } else {
        final tournament = Tournament(
          id: '',
          companyId: companyId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          tournamentType: _tournamentType,
          gameType: _gameType,
          status: _status,
          startDate: _startDate,
          endDate: _endDate,
          registrationDeadline: _registrationDeadline,
          venueName: _venueNameCtrl.text.trim().isEmpty
              ? null
              : _venueNameCtrl.text.trim(),
          venueAddress: _venueAddressCtrl.text.trim().isEmpty
              ? null
              : _venueAddressCtrl.text.trim(),
          maxParticipants:
              int.tryParse(_maxParticipantsCtrl.text) ?? 32,
          entryFee: double.tryParse(_entryFeeCtrl.text) ?? 0,
          prizePool: double.tryParse(_prizePoolCtrl.text) ?? 0,
          sponsorName: _sponsorNameCtrl.text.trim().isEmpty
              ? null
              : _sponsorNameCtrl.text.trim(),
          sponsorAmount: double.tryParse(_sponsorAmountCtrl.text) ?? 0,
          rulesText: _rulesCtrl.text.trim().isEmpty
              ? null
              : _rulesCtrl.text.trim(),
          tableCount: int.tryParse(_tableCountCtrl.text) ?? 1,
          bannerUrl: _bannerUrlCtrl.text.trim().isEmpty
              ? null
              : _bannerUrlCtrl.text.trim(),
          livestreamUrl: _livestreamUrlCtrl.text.trim().isEmpty
              ? null
              : _livestreamUrlCtrl.text.trim(),
          organizerId: user?.id,
        );
        await actions.createTournament(tournament);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Đã cập nhật giải đấu' : 'Đã tạo giải đấu mới'),
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
        title: Text(_isEdit ? 'Sửa giải đấu' : 'Tạo giải đấu mới'),
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
                      controller: _nameCtrl,
                      decoration:
                          _inputDeco('Tên giải đấu *', Icons.emoji_events),
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

                    // Tournament Type & Game Type
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TournamentType>(
                            value: _tournamentType,
                            decoration: _inputDeco('Thể thức', Icons.category),
                            items: TournamentType.values
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.label)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _tournamentType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<GameType>(
                            value: _gameType,
                            decoration:
                                _inputDeco('Loại game', Icons.sports),
                            items: GameType.values
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.label)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _gameType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status (for edit mode)
                    if (_isEdit)
                      DropdownButtonFormField<TournamentStatus>(
                        value: _status,
                        decoration: _inputDeco('Trạng thái', Icons.flag),
                        items: TournamentStatus.values
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    if (_isEdit) const SizedBox(height: 16),

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
                    const SizedBox(height: 8),
                    _dateTile('Hạn đăng ký', _registrationDeadline,
                        (d) => setState(() => _registrationDeadline = d)),
                    const SizedBox(height: 16),

                    // ── Venue ──
                    _sectionHeader('Địa điểm'),
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
                    const SizedBox(height: 16),

                    // ── Capacity & Financials ──
                    _sectionHeader('Quy mô & Tài chính'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxParticipantsCtrl,
                            decoration: _inputDeco('Số VĐV tối đa', Icons.people),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tableCountCtrl,
                            decoration: _inputDeco('Số bàn', Icons.table_bar),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _entryFeeCtrl,
                            decoration: _inputDeco('Phí tham gia (VNĐ)',
                                Icons.attach_money),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _prizePoolCtrl,
                            decoration: _inputDeco(
                                'Tổng giải thưởng (VNĐ)', Icons.monetization_on),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Sponsor ──
                    _sectionHeader('Nhà tài trợ'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sponsorNameCtrl,
                            decoration:
                                _inputDeco('Tên NTT', Icons.handshake),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _sponsorAmountCtrl,
                            decoration: _inputDeco(
                                'Số tiền tài trợ', Icons.paid),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Rules ──
                    _sectionHeader('Luật thi đấu & Media'),
                    TextFormField(
                      controller: _rulesCtrl,
                      decoration: _inputDeco('Nội quy / Luật', Icons.rule),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bannerUrlCtrl,
                      decoration: _inputDeco('Banner URL', Icons.image),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _livestreamUrlCtrl,
                      decoration:
                          _inputDeco('Livestream URL', Icons.live_tv),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: Icon(_isEdit ? Icons.save : Icons.add),
                        label: Text(_isEdit ? 'Lưu thay đổi' : 'Tạo giải đấu'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
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
        title: const Text('Xóa giải đấu?'),
        content: Text(
            'Bạn có chắc chắn muốn xóa "${widget.tournament!.name}"? Hành động này không thể hoàn tác.'),
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
            .read(tournamentActionsProvider)
            .deleteTournament(widget.tournament!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã xóa giải đấu'),
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
