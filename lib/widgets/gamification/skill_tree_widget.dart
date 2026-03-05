import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class SkillTreeWidget extends ConsumerWidget {
  const SkillTreeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(ceoProfileProvider);
    final skillDefs = ref.watch(skillDefinitionsProvider);
    final profile = profileState.profile;

    if (profile == null) return const SizedBox();

    final isLocked = profile.level < 20;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'CEO Skill Tree',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (profile.skillPoints > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${profile.skillPoints} pts',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          if (isLocked)
            _buildLockedState(profile.level)
          else
            skillDefs.when(
              data: (skills) => _buildSkillBranches(context, ref, skills, profile),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Lỗi: $e'),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedState(int currentLevel) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 32, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mở khóa ở Level 20',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.info),
                ),
                const SizedBox(height: 2),
                Text(
                  'Còn ${20 - currentLevel} level nữa',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentLevel / 20,
                    minHeight: 6,
                    backgroundColor: AppColors.info.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBranches(
    BuildContext context,
    WidgetRef ref,
    List<SkillDefinition> allSkills,
    CeoProfile profile,
  ) {
    final branches = ['leader', 'merchant', 'strategist'];
    final branchColors = {
      'leader': Color(0xFF43A047),
      'merchant': Color(0xFF1E88E5),
      'strategist': Color(0xFFFF8F00),
    };
    final branchNames = {
      'leader': '👥 Leader (Con Người)',
      'merchant': '💰 Merchant (Kinh Doanh)',
      'strategist': '📊 Strategist (Tài Chính)',
    };

    return Column(
      children: branches.map((branch) {
        final skills = allSkills.where((s) => s.branch == branch).toList()
          ..sort((a, b) => a.tier.compareTo(b.tier));
        final color = branchColors[branch]!;
        final branchLevel = _getBranchLevel(profile.skillTree, branch);

        return Container(
          margin: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    branchNames[branch]!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '$branchLevel / ${skills.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: Row(
                  children: skills.map((skill) {
                    final isUnlocked = skill.tier <= branchLevel;
                    final isNext = skill.tier == branchLevel + 1;
                    final canAllocate = isNext && profile.skillPoints > 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: canAllocate
                            ? () => _onAllocate(context, ref, skill)
                            : () => _showSkillInfo(context, skill, isUnlocked),
                        child: _buildSkillNode(context, skill, isUnlocked, isNext, canAllocate, color),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillNode(
    BuildContext context,
    SkillDefinition skill,
    bool isUnlocked,
    bool isNext,
    bool canAllocate,
    Color branchColor,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? branchColor
                : canAllocate
                    ? branchColor.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
            border: Border.all(
              color: canAllocate ? branchColor : Colors.transparent,
              width: canAllocate ? 2 : 0,
            ),
            boxShadow: canAllocate
                ? [BoxShadow(color: branchColor.withValues(alpha: 0.3), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: isUnlocked
                ? Text(skill.iconEmoji, style: TextStyle(fontSize: 18))
                : canAllocate
                    ? Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.surface70)
                    : Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'T${skill.tier}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isUnlocked ? branchColor : AppColors.textSecondary,
          ),
        ),
        Text(
          skill.name,
          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _getBranchLevel(SkillTree tree, String branch) {
    switch (branch) {
      case 'leader': return tree.leader;
      case 'merchant': return tree.merchant;
      case 'strategist': return tree.strategist;
      default: return 0;
    }
  }

  Future<void> _onAllocate(BuildContext context, WidgetRef ref, SkillDefinition skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(skill.iconEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(skill.name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (skill.description != null)
              Text(skill.description!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '${skill.branchName} Tier ${skill.tier}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chi 1 Skill Point để mở khóa?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Mở khóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(gamificationActionsProvider).allocateSkillPoint(skill.code);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSkillInfo(BuildContext context, SkillDefinition skill, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(skill.iconEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(skill.name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (skill.description != null)
              Text(skill.description!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '${skill.branchName} Tier ${skill.tier}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked ? '✅ Đã mở khóa' : '🔒 Chưa mở khóa',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
