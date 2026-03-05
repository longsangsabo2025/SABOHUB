import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/auth_provider.dart';

class AiQuestConfigPage extends ConsumerStatefulWidget {
  AiQuestConfigPage({super.key});

  @override
  ConsumerState<AiQuestConfigPage> createState() => _AiQuestConfigPageState();
}

class _AiQuestConfigPageState extends ConsumerState<AiQuestConfigPage> {
  bool _generating = false;
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(businessConfigProvider);
    final aiConfigAsync = ref.watch(aiConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quest Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(businessConfigProvider);
              ref.invalidate(aiConfigProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildCurrentConfig(theme, configAsync),
            const SizedBox(height: 24),
            _buildAiSection(theme, aiConfigAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), AppColors.paymentRefunded],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.surface, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Quest Config',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'AI tự động tạo quest & config phù hợp loại hình kinh doanh của bạn',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConfig(ThemeData theme, AsyncValue<BusinessConfig> configAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cấu Hình Hiện Tại', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi: $e', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          ),
          data: (config) {
            if (config.mappings.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text('Chưa có config cho loại "${config.businessType}"',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text('Nhấn "Tạo bằng AI" để auto-generate!',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            }
            return _buildConfigGrid(theme, config);
          },
        ),
      ],
    );
  }

  Widget _buildConfigGrid(ThemeData theme, BusinessConfig config) {
    final concepts = config.mappings.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: concepts.map((e) => _buildConfigChip(theme, e.value)).toList(),
    );
  }

  Widget _buildConfigChip(ThemeData theme, BusinessTypeMapping mapping) {
    final iconMap = <String, IconData>{
      'package': Icons.inventory,
      'payments': Icons.payment,
      'inventory': Icons.inventory_2,
      'people': Icons.people,
      'truck': Icons.local_shipping,
      'warehouse': Icons.warehouse,
      'clock': Icons.access_time,
      'target': Icons.gps_fixed,
      'sports_bar': Icons.sports_bar,
      'menu_book': Icons.menu_book,
      'table_bar': Icons.table_bar,
      'coffee': Icons.coffee,
      'restaurant': Icons.restaurant,
      'hotel': Icons.hotel,
      'store': Icons.store,
      'factory': Icons.factory,
      'domain': Icons.domain,
      'business': Icons.business,
      'local_cafe': Icons.local_cafe,
      'room_service': Icons.room_service,
      'meeting_room': Icons.meeting_room,
      'category': Icons.category,
      'storefront': Icons.storefront,
      'inventory_2': Icons.inventory_2,
      'table_restaurant': Icons.table_restaurant,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconMap[mapping.icon] ?? Icons.star, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mapping.concept,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                Text(mapping.displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (mapping.tableName != null)
                  Text(mapping.tableName!, style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection(ThemeData theme, AsyncValue<AiGeneratedConfig?> aiAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Generator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildGenerateButton(theme),
        const SizedBox(height: 16),
        aiAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (config) => config != null ? _buildAiConfigCard(theme, config) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _generating ? null : _onGenerate,
        icon: _generating
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? 'Đang tạo...' : 'Tạo Config bằng AI'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildAiConfigCard(ThemeData theme, AiGeneratedConfig config) {
    final statusColor = switch (config.status) {
      'pending' => Colors.orange,
      'approved' => Colors.blue,
      'applied' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('AI Config — ${config.businessType}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(config.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statBox(theme, '${config.configCount}', 'Configs'),
                const SizedBox(width: 16),
                _statBox(theme, '${config.questCount}', 'Quests'),
                const SizedBox(width: 16),
                _statBox(theme, config.aiModel, 'Model'),
              ],
            ),
            if (config.configCount > 0) ...[
              const SizedBox(height: 12),
              Text('Preview:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              ...config.generatedConfig.take(3).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6),
                        const SizedBox(width: 8),
                        Text('${c['concept']} → ${c['display_name']}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )),
              if (config.configCount > 3) Text('... +${config.configCount - 3} more', style: theme.textTheme.labelSmall),
            ],
            if (config.questCount > 0) ...[
              const SizedBox(height: 8),
              ...config.generatedQuests.take(3).map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, size: 14, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${q['name']} (+${q['xp_reward']} XP)',
                            style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
            if (config.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onReject(config.id),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text('Từ chối'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _applying ? null : () => _onApply(config.id),
                      icon: _applying
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
                          : const Icon(Icons.check, size: 18),
                      label: Text(_applying ? 'Đang áp dụng...' : 'Áp Dụng'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }

  Future<void> _onGenerate() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.companyId == null) return;

    setState(() => _generating = true);
    try {
      final service = ref.read(gamificationServiceProvider);
      final btype = await service.getCompanyBusinessType(user.companyId!) ?? 'billiards';
      await service.generateAiConfig(user.companyId!, btype);
      ref.invalidate(aiConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI đã tạo config! Kiểm tra và duyệt bên dưới.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _onApply(String configId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _applying = true);
    try {
      final service = ref.read(gamificationServiceProvider);
      final result = await service.applyAiConfig(configId, user.id);

      ref.invalidate(businessConfigProvider);
      ref.invalidate(aiConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _onReject(String configId) async {
    try {
      final service = ref.read(gamificationServiceProvider);
      await service.rejectAiConfig(configId);
      ref.invalidate(aiConfigProvider);
    } catch (e) {
      debugPrint('AiQuestConfigPage._onReject error: $e');
    }
  }
}
