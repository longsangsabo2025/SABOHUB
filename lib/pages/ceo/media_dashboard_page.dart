import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/media_channel.dart';
import '../../services/media_channel_service.dart';

final _mediaServiceProvider = Provider((ref) => MediaChannelService(ref));

final _mediaChannelsProvider = FutureProvider<List<MediaChannel>>((ref) {
  return ref.read(_mediaServiceProvider).getChannels();
});

class MediaDashboardPage extends ConsumerStatefulWidget {
  const MediaDashboardPage({super.key});

  @override
  ConsumerState<MediaDashboardPage> createState() => _MediaDashboardPageState();
}

class _MediaDashboardPageState extends ConsumerState<MediaDashboardPage> {
  final _nf = NumberFormat('#,###', 'vi_VN');
  String _filterPlatform = 'all';

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(_mediaChannelsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('SABO Media'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddChannelDialog,
          ),
        ],
      ),
      body: channelsAsync.when(
        data: (channels) => _buildBody(channels),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildBody(List<MediaChannel> channels) {
    final filtered = _filterPlatform == 'all'
        ? channels
        : channels.where((c) => c.platform == _filterPlatform).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_mediaChannelsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(channels),
            const SizedBox(height: 20),
            _buildPlatformFilter(channels),
            const SizedBox(height: 16),
            ...filtered.map(_buildChannelCard),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(List<MediaChannel> channels) {
    final totalFollowers = channels.fold<int>(0, (s, c) => s + c.followersCount);
    final totalViews = channels.fold<int>(0, (s, c) => s + c.viewsCount);
    final totalVideos = channels.fold<int>(0, (s, c) => s + c.videosCount);
    final activeCount = channels.where((c) => c.isActive).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('Kênh hoạt động', '$activeCount/${channels.length}',
            Icons.play_circle, Colors.green),
        _buildStatCard('Tổng followers', _formatNumber(totalFollowers),
            Icons.people, Colors.blue),
        _buildStatCard('Tổng lượt xem', _formatNumber(totalViews),
            Icons.visibility, Colors.purple),
        _buildStatCard('Tổng video', _nf.format(totalVideos),
            Icons.video_library, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildPlatformFilter(List<MediaChannel> channels) {
    final platforms = {'all', ...channels.map((c) => c.platform)};
    final labels = {
      'all': 'Tất cả',
      'youtube': '▶ YouTube',
      'tiktok': '♪ TikTok',
      'instagram': '📷 Instagram',
      'facebook': 'f Facebook',
      'twitter': '𝕏 Twitter',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: platforms.map((p) {
          final isSelected = _filterPlatform == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[p] ?? p),
              selected: isSelected,
              onSelected: (_) => setState(() => _filterPlatform = p),
              selectedColor: Colors.blue.shade100,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChannelCard(MediaChannel channel) {
    final followerPct = (channel.followerProgress * 100).clamp(0, 100).toInt();
    final videoPct = (channel.videoProgress * 100).clamp(0, 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlatformAvatar(channel.platform),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(channel.platform.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _buildStatusChip(channel.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildMetric(Icons.people, _formatNumber(channel.followersCount),
                  'Followers'),
              _buildMetric(Icons.visibility, _formatNumber(channel.viewsCount),
                  'Views'),
              _buildMetric(Icons.video_library,
                  _nf.format(channel.videosCount), 'Videos'),
            ],
          ),
          if (channel.targetFollowers > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildProgressBar(
                      'Followers', followerPct, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      _buildProgressBar('Videos', videoPct, Colors.orange),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Cập nhật'),
                onPressed: () => _showUpdateStatsDialog(channel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformAvatar(String platform) {
    final colors = {
      'youtube': Colors.red,
      'tiktok': Colors.black,
      'instagram': Colors.purple,
      'facebook': Colors.blue.shade800,
      'twitter': Colors.lightBlue,
    };
    final icons = {
      'youtube': Icons.play_arrow,
      'tiktok': Icons.music_note,
      'instagram': Icons.camera_alt,
      'facebook': Icons.facebook,
      'twitter': Icons.tag,
    };

    return CircleAvatar(
      radius: 22,
      backgroundColor:
          (colors[platform] ?? Colors.grey).withValues(alpha: 0.1),
      child: Icon(icons[platform] ?? Icons.language,
          color: colors[platform] ?? Colors.grey, size: 22),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'planning'
            ? Colors.orange
            : Colors.grey;
    final label = status == 'active'
        ? 'Active'
        : status == 'planning'
            ? 'Planning'
            : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text('$pct%',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct / 100,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return _nf.format(n);
  }

  void _showAddChannelDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final targetFollowersCtrl = TextEditingController(text: '10000');
    final targetVideosCtrl = TextEditingController(text: '100');
    String selectedPlatform = 'youtube';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm kênh Media'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên kênh'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPlatform,
                  decoration: const InputDecoration(labelText: 'Nền tảng'),
                  items: const [
                    DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                    DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                    DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                    DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                    DropdownMenuItem(value: 'twitter', child: Text('Twitter/X')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedPlatform = v ?? 'youtube'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL kênh (tùy chọn)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetFollowersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mục tiêu followers'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: targetVideosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mục tiêu videos'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await ref.read(_mediaServiceProvider).createChannel(
                        name: nameCtrl.text,
                        platform: selectedPlatform,
                        channelUrl: urlCtrl.text.isNotEmpty ? urlCtrl.text : null,
                        targetFollowers:
                            int.tryParse(targetFollowersCtrl.text) ?? 10000,
                        targetVideos:
                            int.tryParse(targetVideosCtrl.text) ?? 100,
                      );
                  ref.invalidate(_mediaChannelsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm kênh mới')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatsDialog(MediaChannel channel) {
    final followersCtrl =
        TextEditingController(text: channel.followersCount.toString());
    final viewsCtrl =
        TextEditingController(text: channel.viewsCount.toString());
    final videosCtrl =
        TextEditingController(text: channel.videosCount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cập nhật ${channel.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: followersCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Followers'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: viewsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Views'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: videosCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Videos'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(_mediaServiceProvider).updateStats(
                      channel.id,
                      followers: int.tryParse(followersCtrl.text),
                      videos: int.tryParse(videosCtrl.text),
                      views: int.tryParse(viewsCtrl.text),
                    );
                ref.invalidate(_mediaChannelsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
