import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../viewmodels/gym_coach_view_model.dart';
import '../pages/gym_coach_chat_page.dart';

/// Embeddable Gym Coach AI Chat — dùng bên trong TabBarView (không Scaffold/AppBar).
///
/// Tương tự [TravisChatTab] nhưng cho Gym Coach AI.
class GymCoachTab extends ConsumerWidget {
  const GymCoachTab({super.key});

  static const _gymColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(gymCoachViewModelProvider);

    return Column(
      children: [
        // Mini action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _gymColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '🏋️ Gym Coach AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _gymColor,
                ),
              ),
              chatState.when(
                data: (data) => data.isSending
                    ? const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.error, size: 14, color: Colors.red),
                ),
              ),
              const Spacer(),
              // New chat
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                tooltip: 'Chat mới',
                onPressed: () {
                  ref.read(gymCoachViewModelProvider.notifier).clearChat();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Open full page
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Mở Gym Coach',
                onPressed: () => context.push(AppRoutes.gymCoach),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        // Chat content
        const Expanded(child: GymCoachChatPage()),
      ],
    );
  }
}
