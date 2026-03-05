import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

enum CelebrationType { questComplete, levelUp, achievementUnlock, dailyCombo }

class QuestCelebrationOverlay extends StatefulWidget {
  final CelebrationType type;
  final String title;
  final String? subtitle;
  final int? xpEarned;
  final int? newLevel;
  final int? tokenEarned;
  final VoidCallback? onDismiss;

  QuestCelebrationOverlay({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.xpEarned,
    this.newLevel,
    this.tokenEarned,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required CelebrationType type,
    required String title,
    String? subtitle,
    int? xpEarned,
    int? newLevel,
    int? tokenEarned,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Theme.of(context).colorScheme.onSurface54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return QuestCelebrationOverlay(
          type: type,
          title: title,
          subtitle: subtitle,
          xpEarned: xpEarned,
          newLevel: newLevel,
          tokenEarned: tokenEarned,
          onDismiss: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  @override
  State<QuestCelebrationOverlay> createState() => _QuestCelebrationOverlayState();
}

class _QuestCelebrationOverlayState extends State<QuestCelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    Future.delayed(Duration(seconds: 4), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: _confettiColors,
            ),
          ),
          // Content card
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    _headerText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _accentColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.xpEarned != null)
                        _rewardPill('⚡ +${widget.xpEarned} XP', AppColors.warning),
                      if (widget.tokenEarned != null && widget.tokenEarned! > 0) ...[
                        const SizedBox(width: 8),
                        _rewardPill('🪙 +${widget.tokenEarned} SABO', Color(0xFFFF8F00)),
                      ],
                      if (widget.newLevel != null) ...[
                        const SizedBox(width: 8),
                        _rewardPill('🎉 Level ${widget.newLevel}', AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chạm để đóng',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardPill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
      ),
    );
  }

  String get _emoji {
    switch (widget.type) {
      case CelebrationType.questComplete:
        return '⚔️';
      case CelebrationType.levelUp:
        return '🎉';
      case CelebrationType.achievementUnlock:
        return '🏆';
      case CelebrationType.dailyCombo:
        return '🔥';
    }
  }

  String get _headerText {
    switch (widget.type) {
      case CelebrationType.questComplete:
        return 'QUEST HOÀN THÀNH';
      case CelebrationType.levelUp:
        return 'LEVEL UP!';
      case CelebrationType.achievementUnlock:
        return 'THÀNH TỰU MỚI';
      case CelebrationType.dailyCombo:
        return 'DAILY COMBO!';
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case CelebrationType.questComplete:
        return AppColors.success;
      case CelebrationType.levelUp:
        return AppColors.primary;
      case CelebrationType.achievementUnlock:
        return Color(0xFFFF8F00);
      case CelebrationType.dailyCombo:
        return Color(0xFFFF6D00);
    }
  }

  List<Color> get _confettiColors {
    switch (widget.type) {
      case CelebrationType.levelUp:
        return [AppColors.primary, Color(0xFF7C4DFF), Color(0xFFE040FB), Theme.of(context).colorScheme.surface];
      case CelebrationType.achievementUnlock:
        return [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6F00), Theme.of(context).colorScheme.surface];
      case CelebrationType.dailyCombo:
        return [Color(0xFFFF6D00), Color(0xFFFF9100), Color(0xFFFFAB40), Theme.of(context).colorScheme.surface];
      default:
        return [AppColors.success, Color(0xFF66BB6A), Color(0xFF81C784), Theme.of(context).colorScheme.surface];
    }
  }
}
