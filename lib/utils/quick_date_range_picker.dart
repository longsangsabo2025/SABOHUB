import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==========================================================
// Quick Date Range Picker - Shared helper
// ==========================================================
/// Returns a DateTimeRange, or a special sentinel range (year=1970) to clear filter, or null for no change.
Future<DateTimeRange?> showQuickDateRangePicker(BuildContext context, {DateTimeRange? current}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  
  final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
  
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = (now.month > 1) 
      ? DateTime(now.year, now.month - 1, 1) 
      : DateTime(now.year - 1, 12, 1);
  final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

  // Sentinel value meaning "open custom picker"
  final customSentinel = DateTimeRange(start: DateTime(1999), end: DateTime(1999));
  // Sentinel value meaning "clear filter"
  final clearSentinel = DateTimeRange(start: DateTime(1970), end: DateTime(1970));

  final presets = <Map<String, dynamic>>[
    {'label': 'Hôm nay', 'icon': Icons.today, 'range': DateTimeRange(start: today, end: today)},
    {'label': 'Hôm qua', 'icon': Icons.history, 'range': DateTimeRange(start: yesterday, end: yesterday)},
    {'label': 'Tuần này', 'icon': Icons.view_week, 'range': DateTimeRange(start: thisWeekStart, end: today)},
    {'label': 'Tuần trước', 'icon': Icons.calendar_view_week, 'range': DateTimeRange(start: lastWeekStart, end: lastWeekEnd)},
    {'label': 'Tháng này', 'icon': Icons.calendar_month, 'range': DateTimeRange(start: thisMonthStart, end: today)},
    {'label': 'Tháng trước', 'icon': Icons.calendar_today, 'range': DateTimeRange(start: lastMonthStart, end: lastMonthEnd)},
  ];

  String? activeLabel;
  if (current != null) {
    for (final p in presets) {
      final r = p['range'] as DateTimeRange;
      if (r.start == current.start && r.end == current.end) {
        activeLabel = p['label'] as String;
        break;
      }
    }
  }

  final result = await showModalBottomSheet<DateTimeRange>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Colors.indigo.shade600, size: 22),
                const SizedBox(width: 8),
                const Text('Chọn khoảng thời gian', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (current != null)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, clearSentinel),
                    child: Text('Bỏ lọc', style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final label = p['label'] as String;
                final icon = p['icon'] as IconData;
                final range = p['range'] as DateTimeRange;
                final isActive = label == activeLabel;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, range),
                  child: Container(
                    width: (MediaQuery.of(ctx).size.width - 56) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.indigo.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isActive ? Colors.indigo.shade400 : Colors.grey.shade200, width: isActive ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, size: 20, color: isActive ? Colors.indigo.shade600 : Colors.grey.shade600),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? Colors.indigo.shade700 : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, customSentinel),
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: const Text('Chọn khoảng tùy chỉnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          if (current != null && activeLabel == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.indigo.shade600),
                    const SizedBox(width: 8),
                    Text('${DateFormat('dd/MM/yyyy').format(current.start)} - ${DateFormat('dd/MM/yyyy').format(current.end)}',
                      style: TextStyle(fontSize: 13, color: Colors.indigo.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ],
      ),
    ),
  );

  if (result == null) return null; // dismissed
  
  // Clear sentinel
  if (result.start.year == 1970) return clearSentinel;
  
  // Custom range sentinel → open system date range picker
  if (result.start.year == 1999) {
    if (!context.mounted) return null;
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: current,
      locale: const Locale('vi'),
    );
  }
  
  return result;
}

/// Helper to get display label for a date range (matches presets or shows dates)
String getDateRangeLabel(DateTimeRange range) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = (now.month > 1) ? DateTime(now.year, now.month - 1, 1) : DateTime(now.year - 1, 12, 1);
  final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

  if (range.start == today && range.end == today) return 'Hôm nay';
  if (range.start == yesterday && range.end == yesterday) return 'Hôm qua';
  if (range.start == thisWeekStart && range.end == today) return 'Tuần này';
  if (range.start == lastWeekStart && range.end == lastWeekEnd) return 'Tuần trước';
  if (range.start == thisMonthStart && range.end == today) return 'Tháng này';
  if (range.start == lastMonthStart && range.end == lastMonthEnd) return 'Tháng trước';
  return '${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}';
}
