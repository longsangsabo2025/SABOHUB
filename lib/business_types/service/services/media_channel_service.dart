import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/app_logger.dart';
import '../models/media_channel.dart';

/// Service for managing media channels (YouTube, TikTok, etc.)
/// Connects to `media_channels` table — already has 5 channels!
class MediaChannelService {
  final _supabase = Supabase.instance.client;

  /// Get all channels for a company
  Future<List<MediaChannel>> getChannels(String companyId) async {
    try {
      final data = await _supabase
          .from('media_channels')
          .select()
          .eq('company_id', companyId)
          .order('created_at');
      return data.map((e) => MediaChannel.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('MediaChannelService.getChannels', e);
      rethrow;
    }
  }

  /// Get channel by ID
  Future<MediaChannel> getChannel(String id) async {
    try {
      final data = await _supabase
          .from('media_channels')
          .select()
          .eq('id', id)
          .single();
      return MediaChannel.fromJson(data);
    } catch (e) {
      AppLogger.error('MediaChannelService.getChannel', e);
      rethrow;
    }
  }

  /// Create new channel
  Future<MediaChannel> createChannel(MediaChannel channel) async {
    try {
      final data = await _supabase
          .from('media_channels')
          .insert(channel.toJson())
          .select()
          .single();
      return MediaChannel.fromJson(data);
    } catch (e) {
      AppLogger.error('MediaChannelService.createChannel', e);
      rethrow;
    }
  }

  /// Update channel
  Future<MediaChannel> updateChannel(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('media_channels')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return MediaChannel.fromJson(data);
    } catch (e) {
      AppLogger.error('MediaChannelService.updateChannel', e);
      rethrow;
    }
  }

  /// Update channel metrics (followers, views, videos, revenue)
  Future<void> updateMetrics(String id, {
    int? followersCount,
    int? videosCount,
    int? viewsCount,
    double? revenue,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (followersCount != null) updates['followers_count'] = followersCount;
      if (videosCount != null) updates['videos_count'] = videosCount;
      if (viewsCount != null) updates['views_count'] = viewsCount;
      if (revenue != null) updates['revenue'] = revenue;

      await _supabase
          .from('media_channels')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      AppLogger.error('MediaChannelService.updateMetrics', e);
      rethrow;
    }
  }

  /// Get aggregate stats for all channels in a company
  Future<Map<String, dynamic>> getChannelStats(String companyId) async {
    try {
      final channels = await getChannels(companyId);
      
      int totalFollowers = 0;
      int totalVideos = 0;
      int totalViews = 0;
      double totalRevenue = 0;
      int activeChannels = 0;

      for (final ch in channels) {
        totalFollowers += ch.followersCount;
        totalVideos += ch.videosCount;
        totalViews += ch.viewsCount;
        totalRevenue += ch.revenue;
        if (ch.status == 'active') activeChannels++;
      }

      return {
        'total_channels': channels.length,
        'active_channels': activeChannels,
        'total_followers': totalFollowers,
        'total_videos': totalVideos,
        'total_views': totalViews,
        'total_revenue': totalRevenue,
        'channels': channels,
      };
    } catch (e) {
      AppLogger.error('MediaChannelService.getChannelStats', e);
      rethrow;
    }
  }

  /// Delete channel (soft delete via status)
  Future<void> deleteChannel(String id) async {
    try {
      await _supabase
          .from('media_channels')
          .update({
            'status': 'archived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('MediaChannelService.deleteChannel', e);
      rethrow;
    }
  }
}
