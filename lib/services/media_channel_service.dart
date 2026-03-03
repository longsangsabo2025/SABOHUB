import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../models/media_channel.dart';
import '../providers/auth_provider.dart';

class MediaChannelService {
  final _supabase = supabase.client;
  final Ref _ref;

  MediaChannelService(this._ref);

  Future<List<MediaChannel>> getChannels() async {
    try {
      final user = _ref.read(authProvider).user;
      final companyId = user?.companyId;

      var query = _supabase.from('media_channels').select('*');
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => MediaChannel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch media channels: $e');
    }
  }

  Future<MediaChannel> createChannel({
    required String name,
    required String platform,
    String? channelUrl,
    int targetFollowers = 0,
    int targetVideos = 0,
    String? notes,
  }) async {
    try {
      final user = _ref.read(authProvider).user;
      final companyId = user?.companyId;

      final data = {
        'name': name,
        'platform': platform,
        'channel_url': channelUrl,
        'status': 'planning',
        'target_followers': targetFollowers,
        'target_videos': targetVideos,
        'notes': notes,
        if (companyId != null) 'company_id': companyId,
      };

      final response =
          await _supabase.from('media_channels').insert(data).select().single();
      return MediaChannel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create media channel: $e');
    }
  }

  Future<void> updateChannel(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('media_channels').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update media channel: $e');
    }
  }

  Future<void> updateStats(
    String id, {
    int? followers,
    int? videos,
    int? views,
    double? revenue,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (followers != null) updates['followers_count'] = followers;
      if (videos != null) updates['videos_count'] = videos;
      if (views != null) updates['views_count'] = views;
      if (revenue != null) updates['revenue'] = revenue;

      await _supabase.from('media_channels').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update channel stats: $e');
    }
  }

  Future<void> deleteChannel(String id) async {
    try {
      await _supabase.from('media_channels').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete media channel: $e');
    }
  }

  Future<Map<String, dynamic>> getMediaStats() async {
    try {
      final channels = await getChannels();
      final active = channels.where((c) => c.isActive).toList();

      return {
        'total_channels': channels.length,
        'active_channels': active.length,
        'total_followers': channels.fold<int>(0, (sum, c) => sum + c.followersCount),
        'total_views': channels.fold<int>(0, (sum, c) => sum + c.viewsCount),
        'total_videos': channels.fold<int>(0, (sum, c) => sum + c.videosCount),
        'total_revenue': channels.fold<double>(0, (sum, c) => sum + c.revenue),
        'platforms': _groupByPlatform(channels),
      };
    } catch (e) {
      return {};
    }
  }

  Map<String, int> _groupByPlatform(List<MediaChannel> channels) {
    final map = <String, int>{};
    for (final c in channels) {
      map[c.platform] = (map[c.platform] ?? 0) + 1;
    }
    return map;
  }
}
