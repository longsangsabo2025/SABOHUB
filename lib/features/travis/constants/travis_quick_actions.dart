// Centralized quick action definitions for Travis AI chat.
//
// Used by TravisChatPage, TravisChatTab, and TravisFloatingChat
// to avoid duplicating action lists across files.

/// A quick action item for Travis AI chat.
class TravisQuickAction {
  final String emoji;
  final String label;

  const TravisQuickAction(this.emoji, this.label);

  String get displayText => '$emoji $label';
}

/// All Travis AI quick actions — single source of truth.
///
/// Aligned with 29-tool phone-first set.
class TravisQuickActions {
  TravisQuickActions._();

  /// Full set for main chat page (6 actions).
  static const full = [
    TravisQuickAction('📊', 'Empire status nhanh'),
    TravisQuickAction('📈', 'Báo cáo doanh thu hôm nay'),
    TravisQuickAction('🔔', 'Có alert nào pending không?'),
    TravisQuickAction('🎯', 'Goals hôm nay?'),
    TravisQuickAction('💡', 'Gợi ý content hôm nay'),
    TravisQuickAction('🏋️', 'Gym xong rồi'),
  ];

  /// Compact set for floating chat (4 actions).
  static const compact = [
    TravisQuickAction('📊', 'Empire status'),
    TravisQuickAction('📈', 'Revenue'),
    TravisQuickAction('🎯', 'Goals'),
    TravisQuickAction('📝', 'Ghi chú nhanh'),
  ];
}
