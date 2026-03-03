import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_channel.dart';
import '../services/media_channel_service.dart';

final mediaChannelServiceProvider = Provider((ref) => MediaChannelService());

/// All channels for a company
final mediaChannelsProvider =
    FutureProvider.autoDispose.family<List<MediaChannel>, String>(
  (ref, companyId) async {
    final service = ref.read(mediaChannelServiceProvider);
    return service.getChannels(companyId);
  },
);

/// Channel aggregate stats
final mediaChannelStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    final service = ref.read(mediaChannelServiceProvider);
    return service.getChannelStats(companyId);
  },
);

/// Actions for media channels
class MediaChannelActions {
  final Ref _ref;
  final MediaChannelService _service;

  MediaChannelActions(this._ref)
      : _service = _ref.read(mediaChannelServiceProvider);

  Future<MediaChannel> createChannel(MediaChannel channel) async {
    final created = await _service.createChannel(channel);
    _ref.invalidate(mediaChannelsProvider);
    _ref.invalidate(mediaChannelStatsProvider);
    return created;
  }

  Future<MediaChannel> updateChannel(
      String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateChannel(id, updates);
    _ref.invalidate(mediaChannelsProvider);
    _ref.invalidate(mediaChannelStatsProvider);
    return updated;
  }

  Future<void> updateMetrics(String id, {
    int? followersCount,
    int? videosCount,
    int? viewsCount,
    double? revenue,
  }) async {
    await _service.updateMetrics(id,
        followersCount: followersCount,
        videosCount: videosCount,
        viewsCount: viewsCount,
        revenue: revenue);
    _ref.invalidate(mediaChannelsProvider);
    _ref.invalidate(mediaChannelStatsProvider);
  }

  Future<void> deleteChannel(String id) async {
    await _service.deleteChannel(id);
    _ref.invalidate(mediaChannelsProvider);
    _ref.invalidate(mediaChannelStatsProvider);
  }
}

final mediaChannelActionsProvider = Provider((ref) => MediaChannelActions(ref));
