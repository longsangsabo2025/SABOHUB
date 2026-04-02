import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/viewmodels/travis_chat_view_model.dart';
import '../../../models/travis_message.dart';

/// Travis Dashboard — health, stats, tools overview.
class TravisDashboardPage extends ConsumerWidget {
  const TravisDashboardPage({super.key});

  static const _travisColor = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(travisChatViewModelProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(travisChatViewModelProvider.notifier).checkHealth();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Card
          chatState.when(
            data: (data) => _HealthCard(
              isOnline: data.isOnline,
              health: data.health,
            ),
            loading: () => const _HealthCard(isOnline: false, health: null),
            error: (_, __) => const _HealthCard(isOnline: false, health: null),
          ),
          const SizedBox(height: 16),

          // Stats Card
          _StatsCard(ref: ref),
          const SizedBox(height: 16),

          // Capabilities Card
          const _CapabilitiesCard(),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final bool isOnline;
  final TravisHealth? health;

  const _HealthCard({required this.isOnline, required this.health});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOnline ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: isOnline ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (health != null)
                        Text(
                          '${health!.version} • ${health!.totalTools} tools',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (health != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.build,
                    label: 'Tools',
                    value: '${health!.totalTools}',
                  ),
                  _StatItem(
                    icon: Icons.timer,
                    label: 'Uptime',
                    value: health!.uptimeFormatted,
                  ),
                  _StatItem(
                    icon: Icons.memory,
                    label: 'Version',
                    value: health!.version.isNotEmpty ? health!.version : '-',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final WidgetRef ref;

  const _StatsCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: TravisDashboardPage._travisColor),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  icon: Icons.refresh,
                  label: 'Health Check',
                  onTap: () => ref.read(travisChatViewModelProvider.notifier).checkHealth(),
                ),
                _ActionChip(
                  icon: Icons.add_comment,
                  label: 'New Chat',
                  onTap: () => ref.read(travisChatViewModelProvider.notifier).clearChat(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard();

  static const _capabilities = [
    ('🧠', 'Business Insights', 'Revenue, metrics, decisions'),
    ('📊', 'Analytics', 'KPIs, trends, performance'),
    ('📋', 'Task Management', 'Goals, reminders, tracking'),
    ('🔍', 'Research', 'Market, competitors, news'),
    ('✍️', 'Content', 'Blog, social media, SEO'),
    ('🔧', 'System Ops', 'Health checks, monitoring, alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: TravisDashboardPage._travisColor),
                SizedBox(width: 8),
                Text(
                  '6 Specialists',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_capabilities.length, (i) {
              final (emoji, title, desc) = _capabilities[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
