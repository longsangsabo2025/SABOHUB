/// Quick Actions for Gym Coach AI chat.
///
/// Follows the same pattern as TravisQuickActions.
class GymQuickAction {
  final String emoji;
  final String label;

  const GymQuickAction(this.emoji, this.label);

  String get displayText => '$emoji $label';
}

class GymQuickActions {
  GymQuickActions._();

  /// Full set for main gym chat page (6 actions).
  static const full = [
    GymQuickAction('💪', 'Tạo chương trình tập hôm nay'),
    GymQuickAction('🍗', 'Tính macro cho mục tiêu tăng cơ'),
    GymQuickAction('📊', 'Phân tích tiến độ tập luyện'),
    GymQuickAction('🏋️', 'Hướng dẫn form Squat đúng'),
    GymQuickAction('🔥', 'Bài tập cardio 20 phút hiệu quả'),
    GymQuickAction('😴', 'Tư vấn recovery và nghỉ ngơi'),
  ];

  /// Compact set for floating/embedded mode (4 actions).
  static const compact = [
    GymQuickAction('💪', 'Tập hôm nay'),
    GymQuickAction('🍗', 'Dinh dưỡng'),
    GymQuickAction('📊', 'Tiến độ'),
    GymQuickAction('🏋️', 'Form check'),
  ];
}
