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
class TravisQuickActions {
  TravisQuickActions._();

  /// Full set for main chat page (6 actions).
  static const full = [
    TravisQuickAction('📊', 'Empire status nhanh'),
    TravisQuickAction('🎬', 'Video Factory queue hiện tại?'),
    TravisQuickAction('🔔', 'Có alert nào pending không?'),
    TravisQuickAction('💻', 'System metrics (CPU, RAM)'),
    TravisQuickAction('💡', 'Gợi ý content hôm nay'),
    TravisQuickAction('📈', 'Báo cáo doanh thu hôm nay'),
  ];

  /// Compact set for floating chat (4 actions).
  static const compact = [
    TravisQuickAction('📊', 'Empire status'),
    TravisQuickAction('🔔', 'Alerts'),
    TravisQuickAction('💻', 'Metrics'),
    TravisQuickAction('💡', 'Content'),
  ];
}
