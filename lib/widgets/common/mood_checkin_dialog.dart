import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Enum cho trạng thái cảm xúc khi điểm danh
enum StaffMood {
  great('😊', 'Tuyệt vời', AppColors.success),
  okay('😐', 'Bình thường', AppColors.warning),
  tired('😩', 'Mệt mỏi', AppColors.error);

  const StaffMood(this.emoji, this.label, this.color);
  final String emoji;
  final String label;
  final Color color;
}

/// Mood Check-in Dialog — Wisey inspired
/// Shown after successful check-in. Captures staff mood for manager insight.
class MoodCheckinDialog extends StatefulWidget {
  const MoodCheckinDialog({super.key});

  /// Opens dialog and returns selected mood (or null if dismissed)
  static Future<StaffMood?> show(BuildContext context) {
    return showDialog<StaffMood>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MoodCheckinDialog(),
    );
  }

  @override
  State<MoodCheckinDialog> createState() => _MoodCheckinDialogState();
}

class _MoodCheckinDialogState extends State<MoodCheckinDialog> {
  StaffMood? _selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Text('🌟', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn cảm thấy thế nào?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hôm nay ${DateTime.now().day}/${DateTime.now().month}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            // Mood options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: StaffMood.values.map((mood) {
                final isSelected = _selected == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selected = mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.color.withAlpha(30)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? mood.color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mood.emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? mood.color : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected?.color ?? Colors.grey,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selected == null ? 'Chọn trạng thái' : 'Xác nhận',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Skip
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Bỏ qua',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
