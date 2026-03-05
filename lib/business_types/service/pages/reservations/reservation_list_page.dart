import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import 'reservation_form_page.dart';

/// ═══════════════════════════════════════════════════════════════
/// RESERVATION LIST PAGE — Danh sách đặt bàn
/// ═══════════════════════════════════════════════════════════════
///
/// - Date picker at top (default: today)
/// - List grouped by time slot
/// - Status chips (color-coded)
/// - FAB to create new reservation
/// - Slide actions: confirm, seat, cancel
class ReservationListPage extends ConsumerStatefulWidget {
  const ReservationListPage({super.key});

  @override
  ConsumerState<ReservationListPage> createState() =>
      _ReservationListPageState();
}

class _ReservationListPageState extends ConsumerState<ReservationListPage> {
  DateTime _selectedDate = DateTime.now();
  Timer? _noShowTimer;

  @override
  void initState() {
    super.initState();
    // Auto-mark no-show every 5 minutes
    _noShowTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.read(reservationActionsProvider).autoMarkNoShow();
    });
    // Run once on init
    Future.microtask(
        () => ref.read(reservationActionsProvider).autoMarkNoShow());
  }

  @override
  void dispose() {
    _noShowTimer?.cancel();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _refresh() {
    ref.invalidate(reservationListProvider(_selectedDate));
    ref.invalidate(reservationStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationListProvider(_selectedDate));
    final statsAsync = ref.watch(reservationStatsProvider);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt bàn'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ──
          _buildStatsBar(context, statsAsync),

          // ── Date picker bar ──
          _buildDateBar(context, isToday),

          // ── Reservation list ──
          Expanded(
            child: reservationsAsync.when(
              data: (list) => list.isEmpty
                  ? _buildEmpty()
                  : _buildGroupedList(context, list),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        icon: const Icon(Icons.add),
        label: const Text('Đặt bàn mới'),
      ),
    );
  }

  // ─── Stats bar ────────────────────────────────────────
  Widget _buildStatsBar(BuildContext context, AsyncValue<ReservationStats> statsAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statChip('Hôm nay', '${stats.todayTotal}', Theme.of(context).colorScheme.surface),
            _statChip('Chờ', '${stats.todayPending}', AppColors.warningLight),
            _statChip(
                'Đã xác nhận', '${stats.todayConfirmed}', AppColors.infoLight),
            _statChip(
                'Đã đến', '${stats.todayCheckedIn}', AppColors.successLight),
          ],
        ),
        loading: () => const SizedBox(height: 30),
        error: (_, __) => const SizedBox(height: 30),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  // ─── Date bar ─────────────────────────────────────────
  Widget _buildDateBar(BuildContext context, bool isToday) {
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => _selectedDate =
                  _selectedDate.subtract(const Duration(days: 1)));
            },
            icon: const Icon(Icons.chevron_left, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isToday ? AppColors.primary : AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      isToday ? 'Hôm nay — $dateStr' : dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.normal,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() =>
                  _selectedDate = _selectedDate.add(const Duration(days: 1)));
            },
            icon: const Icon(Icons.chevron_right, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (!isToday)
            TextButton(
              onPressed: () =>
                  setState(() => _selectedDate = DateTime.now()),
              child: const Text('Hôm nay',
                  style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Chưa có đặt bàn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Nhấn + để tạo đặt bàn mới',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Lỗi tải dữ liệu',
              style: TextStyle(fontSize: 16, color: AppColors.error)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ─── Grouped list ─────────────────────────────────────
  Widget _buildGroupedList(BuildContext context, List<Reservation> reservations) {
    // Group by hour slot
    final grouped = <String, List<Reservation>>{};
    for (final r in reservations) {
      final hour = r.startTime.hour;
      final key = '${hour.toString().padLeft(2, '0')}:00';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final slot = sortedKeys[index];
          final items = grouped[slot]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slot header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                color: AppColors.surfaceVariant,
                child: Text(
                  '🕐 $slot',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // Items
              ...items.map((r) => _buildReservationTile(context, r)),
            ],
          );
        },
      ),
    );
  }

  // ─── Single reservation tile ──────────────────────────
  Widget _buildReservationTile(BuildContext context, Reservation r) {
    return Dismissible(
      key: ValueKey(r.id),
      background: Container(
        color: AppColors.info,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surface),
            SizedBox(height: 2),
            Text('Xác nhận',
                style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 10)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Theme.of(context).colorScheme.surface),
            SizedBox(height: 2),
            Text('Hủy',
                style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 10)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → confirm or check-in
          return await _handleSwipeConfirm(r);
        } else {
          // Swipe left → cancel
          return await _handleSwipeCancel(r);
        }
      },
      child: InkWell(
        onTap: () => _showReservationDetail(context, r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Text(
                      r.startTimeFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      r.durationFormatted,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _statusChip(r.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(r.customerPhone,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('${r.guestCount} khách',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (r.tableOrRoomName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(r.type.icon,
                              size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(r.tableOrRoomName!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                    if (r.note != null && r.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('📝 ${r.note}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(ReservationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: status.color),
      ),
    );
  }

  // ─── Swipe handlers ───────────────────────────────────
  Future<bool> _handleSwipeConfirm(Reservation r) async {
    if (r.status == ReservationStatus.pending) {
      try {
        await ref.read(reservationActionsProvider).confirm(r.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xác nhận đặt bàn'),
              backgroundColor: AppColors.info,
            ),
          );
        }
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    } else if (r.status == ReservationStatus.confirmed) {
      try {
        await ref.read(reservationActionsProvider).checkIn(r.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Khách đã đến'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
    return false; // Don't actually dismiss
  }

  Future<bool> _handleSwipeCancel(Reservation r) async {
    if (!r.isCancellable) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đặt bàn'),
        content: Text('Hủy đặt bàn của "${r.customerName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hủy đặt bàn'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(reservationActionsProvider)
            .cancel(r.id, reason: 'Hủy bởi quản lý');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Đã hủy đặt bàn'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
    return false;
  }

  // ─── Detail dialog ────────────────────────────────────
  void _showReservationDetail(BuildContext context, Reservation r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReservationDetailSheet(
        reservation: r,
        onAction: (action) async {
          Navigator.pop(ctx);
          final actions = ref.read(reservationActionsProvider);
          try {
            switch (action) {
              case 'confirm':
                await actions.confirm(r.id);
                break;
              case 'check_in':
                await actions.checkIn(r.id);
                break;
              case 'complete':
                await actions.complete(r.id);
                break;
              case 'cancel':
                await actions.cancel(r.id);
                break;
            }
            _refresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Cập nhật thành công'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: AppColors.error),
              );
            }
          }
        },
      ),
    );
  }

  // ─── Open form ────────────────────────────────────────
  void _openForm([Reservation? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationFormPage(
          initialDate: _selectedDate,
          existingReservation: existing,
        ),
      ),
    );
    if (result == true) _refresh();
  }
}

// ═══════════════════════════════════════════════════════════════
// DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
class _ReservationDetailSheet extends StatelessWidget {
  final Reservation reservation;
  final void Function(String action) onAction;

  const _ReservationDetailSheet({
    required this.reservation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(r.customerName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(r.status.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.status.color)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info rows
          _infoRow(Icons.phone, r.customerPhone),
          _infoRow(Icons.people, '${r.guestCount} khách'),
          _infoRow(Icons.access_time, r.timeRangeFormatted),
          _infoRow(Icons.timer, 'Thời lượng: ${r.durationFormatted}'),
          _infoRow(r.type.icon, r.type.label),
          if (r.tableOrRoomName != null)
            _infoRow(Icons.table_restaurant, r.tableOrRoomName!),
          if (r.note != null && r.note!.isNotEmpty)
            _infoRow(Icons.notes, r.note!),
          if (r.cancelReason != null)
            _infoRow(Icons.info_outline, 'Lý do hủy: ${r.cancelReason}'),

          const SizedBox(height: 20),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (r.status == ReservationStatus.pending)
                _actionButton(context, 'Xác nhận', Icons.check, AppColors.info,
                    () => onAction('confirm')),
              if (r.status == ReservationStatus.confirmed)
                _actionButton(context, 'Đã đến', Icons.login, AppColors.success,
                    () => onAction('check_in')),
              if (r.status == ReservationStatus.checkedIn)
                _actionButton(context, 'Hoàn thành', Icons.done_all, Colors.teal,
                    () => onAction('complete')),
              if (r.isCancellable)
                _actionButton(context, 'Hủy', Icons.cancel, AppColors.error,
                    () => onAction('cancel')),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
