// SABO Corporation — Content Calendar & Content Item Models

enum ContentType {
  video('video', 'Video'),
  short('short', 'Short/Reel'),
  reel('reel', 'Reel'),
  story('story', 'Story'),
  article('article', 'Bài viết'),
  post('post', 'Bài đăng'),
  livestream('livestream', 'Livestream'),
  podcast('podcast', 'Podcast'),
  other('other', 'Khác');

  final String value;
  final String label;
  const ContentType(this.value, this.label);

  static ContentType fromString(String s) {
    return ContentType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ContentType.other,
    );
  }
}

enum ContentStatus {
  idea('idea', 'Ý tưởng'),
  planned('planned', 'Lên kế hoạch'),
  scripting('scripting', 'Viết kịch bản'),
  filming('filming', 'Quay/Chụp'),
  editing('editing', 'Chỉnh sửa'),
  review('review', 'Duyệt'),
  scheduled('scheduled', 'Đã lên lịch'),
  published('published', 'Đã đăng'),
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String label;
  const ContentStatus(this.value, this.label);

  static ContentStatus fromString(String s) {
    return ContentStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ContentStatus.idea,
    );
  }

  /// Pipeline step index (0-7)
  int get stepIndex => ContentStatus.values.indexOf(this);
}

class ContentCalendar {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final ContentType contentType;
  final String? channelId;
  final String? platform;
  final DateTime plannedDate;
  final DateTime? publishDate;
  final DateTime? deadline;
  final ContentStatus status;
  final String? assignedTo;
  final String? reviewerId;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final double revenue;
  final String? thumbnailUrl;
  final String? contentUrl;
  final String? scriptUrl;
  final String? notes;
  final List<String>? tags;
  final bool isActive;
  final DateTime? createdAt;

  // Joined fields
  final String? channelName;
  final String? assignedToName;

  ContentCalendar({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.contentType = ContentType.video,
    this.channelId,
    this.platform,
    required this.plannedDate,
    this.publishDate,
    this.deadline,
    this.status = ContentStatus.idea,
    this.assignedTo,
    this.reviewerId,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.revenue = 0,
    this.thumbnailUrl,
    this.contentUrl,
    this.scriptUrl,
    this.notes,
    this.tags,
    this.isActive = true,
    this.createdAt,
    this.channelName,
    this.assignedToName,
  });

  factory ContentCalendar.fromJson(Map<String, dynamic> json) {
    return ContentCalendar(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      contentType: ContentType.fromString(json['content_type'] ?? ''),
      channelId: json['channel_id'],
      platform: json['platform'],
      plannedDate: DateTime.tryParse(json['planned_date'] ?? '') ?? DateTime.now(),
      publishDate: json['publish_date'] != null
          ? DateTime.tryParse(json['publish_date'])
          : null,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'])
          : null,
      status: ContentStatus.fromString(json['status'] ?? ''),
      assignedTo: json['assigned_to'],
      reviewerId: json['reviewer_id'],
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      thumbnailUrl: json['thumbnail_url'],
      contentUrl: json['content_url'],
      scriptUrl: json['script_url'],
      notes: json['notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      channelName: json['media_channels'] is Map
          ? json['media_channels']['name']
          : null,
      assignedToName: json['employees'] is Map
          ? json['employees']['full_name']
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'title': title,
        'description': description,
        'content_type': contentType.value,
        'channel_id': channelId,
        'platform': platform,
        'planned_date': plannedDate.toIso8601String().split('T').first,
        'publish_date': publishDate?.toIso8601String(),
        'deadline': deadline?.toIso8601String().split('T').first,
        'status': status.value,
        'assigned_to': assignedTo,
        'reviewer_id': reviewerId,
        'thumbnail_url': thumbnailUrl,
        'content_url': contentUrl,
        'script_url': scriptUrl,
        'notes': notes,
        'tags': tags,
      };

  /// Total engagement
  int get totalEngagement =>
      likesCount + commentsCount + sharesCount;

  /// Is overdue?
  bool get isOverdue {
    if (deadline == null) return false;
    if (status == ContentStatus.published ||
        status == ContentStatus.cancelled) { return false; }
    return DateTime.now().isAfter(deadline!);
  }

  /// Pipeline progress (0.0 - 1.0)
  double get pipelineProgress {
    if (status == ContentStatus.cancelled) return 0;
    return (status.stepIndex / 7.0).clamp(0.0, 1.0);
  }
}
