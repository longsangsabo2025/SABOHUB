class MediaChannel {
  final String id;
  final String? companyId;
  final String name;
  final String platform;
  final String? channelUrl;
  final String status;
  final String? assignedTo;
  final String? managerName;
  final int followersCount;
  final int videosCount;
  final int viewsCount;
  final double revenue;
  final int targetFollowers;
  final int targetVideos;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaChannel({
    required this.id,
    this.companyId,
    required this.name,
    required this.platform,
    this.channelUrl,
    required this.status,
    this.assignedTo,
    this.managerName,
    this.followersCount = 0,
    this.videosCount = 0,
    this.viewsCount = 0,
    this.revenue = 0,
    this.targetFollowers = 0,
    this.targetVideos = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaChannel.fromJson(Map<String, dynamic> json) {
    return MediaChannel(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      name: json['name'] as String,
      platform: json['platform'] as String? ?? 'youtube',
      channelUrl: json['channel_url'] as String?,
      status: json['status'] as String? ?? 'planning',
      assignedTo: json['assigned_to'] as String?,
      managerName: json['manager_name'] as String?,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      videosCount: (json['videos_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      targetFollowers: (json['target_followers'] as num?)?.toInt() ?? 0,
      targetVideos: (json['target_videos'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
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
        if (companyId != null) 'company_id': companyId,
      };

  double get followerProgress =>
      targetFollowers > 0 ? followersCount / targetFollowers : 0;

  double get videoProgress =>
      targetVideos > 0 ? videosCount / targetVideos : 0;

  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return '▶';
      case 'tiktok':
        return '♪';
      case 'instagram':
        return '📷';
      case 'facebook':
        return 'f';
      case 'twitter':
      case 'x':
        return '𝕏';
      default:
        return '🌐';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'planning':
        return 'Đang lên kế hoạch';
      case 'paused':
        return 'Tạm dừng';
      case 'archived':
        return 'Đã lưu trữ';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
}
