/// SABO Corporation — Media Channel Model
/// Connects to `media_channels` table (already has 5 channels!)
class MediaChannel {
  final String id;
  final String companyId;
  final String name;
  final String platform; // youtube, tiktok, facebook, instagram
  final String? channelUrl;
  final String status; // active, paused, archived
  final String? assignedTo;
  final String? managerName;
  final int followersCount;
  final int videosCount;
  final int viewsCount;
  final double revenue;
  final int? targetFollowers;
  final int? targetVideos;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MediaChannel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.platform,
    this.channelUrl,
    this.status = 'active',
    this.assignedTo,
    this.managerName,
    this.followersCount = 0,
    this.videosCount = 0,
    this.viewsCount = 0,
    this.revenue = 0,
    this.targetFollowers,
    this.targetVideos,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory MediaChannel.fromJson(Map<String, dynamic> json) {
    return MediaChannel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      platform: json['platform'] ?? 'other',
      channelUrl: json['channel_url'],
      status: json['status'] ?? 'active',
      assignedTo: json['assigned_to'],
      managerName: json['manager_name'],
      followersCount: json['followers_count'] ?? 0,
      videosCount: json['videos_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      targetFollowers: json['target_followers'],
      targetVideos: json['target_videos'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'name': name,
        'platform': platform,
        'channel_url': channelUrl,
        'status': status,
        'assigned_to': assignedTo,
        'manager_name': managerName,
        'followers_count': followersCount,
        'videos_count': videosCount,
        'views_count': viewsCount,
        'revenue': revenue,
        'target_followers': targetFollowers,
        'target_videos': targetVideos,
        'notes': notes,
      };

  /// Platform icon
  String get platformIcon {
    switch (platform) {
      case 'youtube':
        return '📺';
      case 'tiktok':
        return '🎵';
      case 'facebook':
        return '📘';
      case 'instagram':
        return '📸';
      case 'twitter':
        return '🐦';
      case 'linkedin':
        return '💼';
      default:
        return '📱';
    }
  }

  /// Follower progress (0.0 - 1.0)
  double get followerProgress {
    if (targetFollowers == null || targetFollowers == 0) return 0;
    return (followersCount / targetFollowers!).clamp(0.0, 1.0);
  }

  /// Video progress (0.0 - 1.0)
  double get videoProgress {
    if (targetVideos == null || targetVideos == 0) return 0;
    return (videosCount / targetVideos!).clamp(0.0, 1.0);
  }

  MediaChannel copyWith({
    String? name,
    String? platform,
    String? channelUrl,
    String? status,
    String? managerName,
    int? followersCount,
    int? videosCount,
    int? viewsCount,
    double? revenue,
    int? targetFollowers,
    int? targetVideos,
    String? notes,
  }) {
    return MediaChannel(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      channelUrl: channelUrl ?? this.channelUrl,
      status: status ?? this.status,
      assignedTo: assignedTo,
      managerName: managerName ?? this.managerName,
      followersCount: followersCount ?? this.followersCount,
      videosCount: videosCount ?? this.videosCount,
      viewsCount: viewsCount ?? this.viewsCount,
      revenue: revenue ?? this.revenue,
      targetFollowers: targetFollowers ?? this.targetFollowers,
      targetVideos: targetVideos ?? this.targetVideos,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
