import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../models/coaching_models.dart';
import '../viewmodels/coaching_view_model.dart';

/// Self-Improvement Coaching Page — program selector + AI chat.
///
/// Left panel: 10 coaching programs as cards.
/// Right area: AI chat within selected program.
class CoachingPage extends ConsumerStatefulWidget {
  const CoachingPage({super.key});

  @override
  ConsumerState<CoachingPage> createState() => _CoachingPageState();
}

class _CoachingPageState extends ConsumerState<CoachingPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _customGoalController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(coachingViewModelProvider.notifier).sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(coachingViewModelProvider);

    return asyncState.when(
      data: (data) {
        if (data.selectedProgram == null) {
          return _buildProgramGrid(data);
        }
        _scrollToBottom();
        return _buildChatView(data);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $e', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(coachingViewModelProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Program Grid ─────────────────────────────────────────────

  Widget _buildProgramGrid(CoachingState data) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA78BFA), Color(0xFF6C63FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Self-Improvement Coach',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'AI coach cá nhân · Gemini + Brain RAG + Memory',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn chương trình để bắt đầu',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: data.programs.length,
            itemBuilder: (context, index) {
              final program = data.programs[index];
              return _ProgramCard(
                program: program,
                onTap: () {
                  ref.read(coachingViewModelProvider.notifier).selectProgram(program);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Chat View ────────────────────────────────────────────────

  Widget _buildChatView(CoachingState data) {
    final program = data.selectedProgram!;
    final programColor = Color(program.colorValue);

    return Column(
      children: [
        // Program header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: programColor.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(color: programColor.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () {
                  ref.read(coachingViewModelProvider.notifier).goBack();
                },
                tooltip: 'Quay lại',
              ),
              Text(program.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: programColor,
                      ),
                    ),
                    Text(
                      program.subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Generate plan button
              _PlanButton(
                color: programColor,
                isLoading: data.isLoadingPlan,
                isCustom: program.isCustom,
                onPressed: () => _showPlanDialog(program, programColor),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: data.messages.length + (data.isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == data.messages.length && data.isSending) {
                return _TypingIndicator(color: programColor);
              }
              return _CoachingBubble(
                message: data.messages[index],
                accentColor: programColor,
              );
            },
          ),
        ),

        // Plan preview
        if (data.currentPlan != null)
          _PlanPreview(
            plan: data.currentPlan!,
            color: programColor,
            onDismiss: () {
              // Clear plan from state
            },
          ),

        // Input
        _ChatInput(
          controller: _controller,
          focusNode: _focusNode,
          isSending: data.isSending,
          accentColor: programColor,
          onSend: _sendMessage,
        ),
      ],
    );
  }

  void _showPlanDialog(CoachingProgram program, Color color) {
    final daysOptions = [7, 14, 21, 30, 60, 90];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        int selectedDays = program.defaultDays;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${program.emoji} Tạo Kế Hoạch — ${program.title}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (program.isCustom) ...[
                    TextField(
                      controller: _customGoalController,
                      decoration: InputDecoration(
                        labelText: 'Mục tiêu của bạn',
                        hintText: 'VD: Học đàn guitar, Giảm 5kg, Viết mỗi ngày...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('Thời gian:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: daysOptions.map((d) {
                      final isSelected = d == selectedDays;
                      return ChoiceChip(
                        label: Text('$d ngày'),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.2),
                        onSelected: (_) => setSheetState(() => selectedDays = d),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(coachingViewModelProvider.notifier).generatePlan(
                              days: selectedDays,
                              customGoal: program.isCustom
                                  ? _customGoalController.text.trim()
                                  : null,
                            );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Tạo Kế Hoạch'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Program Card ───────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  final CoachingProgram program;
  final VoidCallback onTap;

  const _ProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(program.colorValue);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(program.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (program.isCustom)
                            Text(
                              'BONUS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                                letterSpacing: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  program.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Plan Button ────────────────────────────────────────────────

class _PlanButton extends StatelessWidget {
  final Color color;
  final bool isLoading;
  final bool isCustom;
  final VoidCallback onPressed;

  const _PlanButton({
    required this.color,
    required this.isLoading,
    required this.isCustom,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(Icons.auto_awesome, size: 16, color: color),
      label: Text(
        isLoading ? 'Đang tạo...' : 'Tạo kế hoạch',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

// ─── Typing Indicator ───────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Đang suy nghĩ...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Bubble ────────────────────────────────────────────────

class _CoachingBubble extends StatelessWidget {
  final CoachingMessage message;
  final Color accentColor;

  const _CoachingBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isSystem = message.isSystem;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        ),
        child: MarkdownBlock(data: message.content),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? accentColor.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(fontSize: 14),
              )
            : MarkdownBlock(data: message.content),
      ),
    );
  }
}

// ─── Plan Preview ───────────────────────────────────────────────

class _PlanPreview extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Color color;
  final VoidCallback? onDismiss;

  const _PlanPreview({
    required this.plan,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final techniques = plan['techniques'] as List<dynamic>? ?? [];
    final habits = plan['daily_habits'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (techniques.isNotEmpty) ...[
            Text(
              'Top Techniques',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            ...techniques.take(3).map((t) {
              final tech = t as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '⭐ ${tech['effectiveness'] ?? '?'}/5 — ${tech['name'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Daily Habits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            ...habits.take(3).map((h) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $h', style: const TextStyle(fontSize: 12)),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Chat Input ─────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final Color accentColor;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.accentColor,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Hỏi coach AI...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: isSending ? null : onSend,
            icon: Icon(Icons.send_rounded, color: accentColor),
            style: IconButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
