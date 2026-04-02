import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════
// TOOL MENU DATA
// ═══════════════════════════════════════════════════════════════

/// A single tool entry in the tool menu.
class TravisTool {
  final String id;
  final String label;
  final String specialist;

  const TravisTool({
    required this.id,
    required this.label,
    required this.specialist,
  });
}

/// A group of tools belonging to one specialist.
class TravisToolGroup {
  final String specialist;
  final String emoji;
  final String label;
  final Color color;
  final List<TravisTool> tools;

  const TravisToolGroup({
    required this.specialist,
    required this.emoji,
    required this.label,
    required this.color,
    required this.tools,
  });
}

/// All 29 tools grouped by specialist — single source of truth.
const _toolGroups = <TravisToolGroup>[
  TravisToolGroup(
    specialist: 'ops',
    emoji: '⚙️',
    label: 'Ops',
    color: AppColors.error,
    tools: [
      TravisTool(id: 'get_empire_status', label: 'Empire Status', specialist: 'ops'),
      TravisTool(id: 'check_service_health', label: 'Health Check', specialist: 'ops'),
      TravisTool(id: 'restart_service', label: 'Restart', specialist: 'ops'),
      TravisTool(id: 'run_database_query', label: 'DB Query', specialist: 'ops'),
      TravisTool(id: 'read_service_logs', label: 'Logs', specialist: 'ops'),
    ],
  ),
  TravisToolGroup(
    specialist: 'life',
    emoji: '📝',
    label: 'Life OS',
    color: AppColors.success,
    tools: [
      TravisTool(id: 'daily_briefing', label: 'Briefing', specialist: 'life'),
      TravisTool(id: 'quick_note', label: 'Ghi chú', specialist: 'life'),
      TravisTool(id: 'get_notes', label: 'Xem notes', specialist: 'life'),
      TravisTool(id: 'set_reminder', label: 'Nhắc nhở', specialist: 'life'),
      TravisTool(id: 'track_habit', label: 'Habit ✓', specialist: 'life'),
      TravisTool(id: 'get_habits', label: 'Habits', specialist: 'life'),
      TravisTool(id: 'log_expense', label: 'Chi tiêu', specialist: 'life'),
      TravisTool(id: 'get_expenses', label: 'Xem \$', specialist: 'life'),
    ],
  ),
  TravisToolGroup(
    specialist: 'ceo',
    emoji: '📊',
    label: 'CEO',
    color: AppColors.warning,
    tools: [
      TravisTool(id: 'get_revenue_dashboard', label: 'Revenue', specialist: 'ceo'),
      TravisTool(id: 'log_revenue', label: 'Log \$', specialist: 'ceo'),
      TravisTool(id: 'set_daily_goals', label: 'Goals', specialist: 'ceo'),
      TravisTool(id: 'complete_goal', label: 'Done ✓', specialist: 'ceo'),
      TravisTool(id: 'log_ceo_decision', label: 'Decision', specialist: 'ceo'),
      TravisTool(id: 'get_accountability_report', label: 'Report', specialist: 'ceo'),
    ],
  ),
  TravisToolGroup(
    specialist: 'comms',
    emoji: '📡',
    label: 'Comms',
    color: AppColors.info,
    tools: [
      TravisTool(id: 'send_telegram_message', label: 'Telegram', specialist: 'comms'),
      TravisTool(id: 'save_to_memory', label: 'Lưu nhớ', specialist: 'comms'),
      TravisTool(id: 'search_memory', label: 'Tìm nhớ', specialist: 'comms'),
    ],
  ),
  TravisToolGroup(
    specialist: 'utility',
    emoji: '🔍',
    label: 'Tiện ích',
    color: AppColors.secondary,
    tools: [
      TravisTool(id: 'web_search', label: 'Tìm web', specialist: 'utility'),
      TravisTool(id: 'get_weather', label: 'Thời tiết', specialist: 'utility'),
      TravisTool(id: 'calculate', label: 'Tính', specialist: 'utility'),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
// SELECTED TOOL INDICATOR (shows above input when tool selected)
// ═══════════════════════════════════════════════════════════════

/// Chip showing the currently forced tool + clear button.
class TravisToolIndicator extends StatelessWidget {
  final TravisTool tool;
  final VoidCallback onClear;

  const TravisToolIndicator({
    super.key,
    required this.tool,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final group = _toolGroups.firstWhere(
      (g) => g.specialist == tool.specialist,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: group.color),
          const SizedBox(width: 4),
          Text(
            '${group.emoji} ${tool.label}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: group.color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOOL MENU BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

/// Shows a bottom sheet with all 29 tools grouped by specialist.
///
/// Returns the selected [TravisTool] or null if dismissed.
Future<TravisTool?> showTravisToolMenu(BuildContext context) {
  return showModalBottomSheet<TravisTool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _TravisToolMenuSheet(),
  );
}

class _TravisToolMenuSheet extends StatelessWidget {
  const _TravisToolMenuSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'Chọn tool',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '29 tools',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tool groups
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              itemCount: _toolGroups.length,
              itemBuilder: (ctx, i) => _ToolGroupSection(
                group: _toolGroups[i],
                onSelect: (tool) => Navigator.of(ctx).pop(tool),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolGroupSection extends StatelessWidget {
  final TravisToolGroup group;
  final ValueChanged<TravisTool> onSelect;

  const _ToolGroupSection({
    required this.group,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Text(
                '${group.emoji} ${group.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: group.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${group.tools.length})',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tool chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: group.tools.map((tool) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(tool),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: group.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: group.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      tool.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: group.color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
