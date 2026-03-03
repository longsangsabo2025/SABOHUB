class GameNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const GameNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  String get icon {
    const map = {
      'streak_warning': '🔥',
      'quest_reminder': '⚔️',
      'achievement_near': '🏅',
      'level_up': '⬆️',
      'season_ending': '⏰',
      'weekly_summary': '📊',
      'prestige_ready': '✨',
      'daily_combo': '🎯',
      'leaderboard_change': '📈',
      'store_new_item': '🛒',
    };
    return map[type] ?? '🔔';
  }

  factory GameNotification.fromJson(Map<String, dynamic> json) {
    return GameNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class WeeklySummary {
  final int xpEarned;
  final int questsCompleted;
  final int achievementsUnlocked;
  final int streakDays;
  final String levelProgress;
  final String rankChange;
  final String topSource;

  const WeeklySummary({
    this.xpEarned = 0,
    this.questsCompleted = 0,
    this.achievementsUnlocked = 0,
    this.streakDays = 0,
    this.levelProgress = '',
    this.rankChange = '',
    this.topSource = '',
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
      questsCompleted: (json['quests_completed'] as num?)?.toInt() ?? 0,
      achievementsUnlocked: (json['achievements_unlocked'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      levelProgress: json['level_progress'] as String? ?? '',
      rankChange: json['rank_change'] as String? ?? '',
      topSource: json['top_source'] as String? ?? '',
    );
  }
}

class EngagementMetric {
  final String name;
  final double value;
  final String detail;

  const EngagementMetric({
    required this.name,
    required this.value,
    required this.detail,
  });

  factory EngagementMetric.fromJson(Map<String, dynamic> json) {
    return EngagementMetric(
      name: json['metric_name'] as String,
      value: (json['metric_value'] as num?)?.toDouble() ?? 0,
      detail: json['metric_detail'] as String? ?? '',
    );
  }
}

class XpAnalytics {
  final String sourceType;
  final int totalXp;
  final int transactionCount;
  final double avgXpPerTx;
  final int uniqueUsers;
  final double percentage;

  const XpAnalytics({
    required this.sourceType,
    this.totalXp = 0,
    this.transactionCount = 0,
    this.avgXpPerTx = 0,
    this.uniqueUsers = 0,
    this.percentage = 0,
  });

  factory XpAnalytics.fromJson(Map<String, dynamic> json) {
    return XpAnalytics(
      sourceType: json['source_type'] as String,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      avgXpPerTx: (json['avg_xp_per_tx'] as num?)?.toDouble() ?? 0,
      uniqueUsers: (json['unique_users'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class QuestDropoff {
  final String questCode;
  final String questName;
  final String questType;
  final int startedCount;
  final int completedCount;
  final int abandonedCount;
  final double dropoffRate;

  const QuestDropoff({
    required this.questCode,
    required this.questName,
    required this.questType,
    this.startedCount = 0,
    this.completedCount = 0,
    this.abandonedCount = 0,
    this.dropoffRate = 0,
  });

  factory QuestDropoff.fromJson(Map<String, dynamic> json) {
    return QuestDropoff(
      questCode: json['quest_code'] as String,
      questName: json['quest_name'] as String,
      questType: json['quest_type'] as String,
      startedCount: (json['started_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      abandonedCount: (json['abandoned_count'] as num?)?.toInt() ?? 0,
      dropoffRate: (json['dropoff_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LevelDistribution {
  final String levelRange;
  final int playerCount;
  final double percentage;

  const LevelDistribution({
    required this.levelRange,
    this.playerCount = 0,
    this.percentage = 0,
  });

  factory LevelDistribution.fromJson(Map<String, dynamic> json) {
    return LevelDistribution(
      levelRange: json['level_range'] as String,
      playerCount: (json['player_count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class XpTrendPoint {
  final DateTime day;
  final int totalXp;
  final int transactionCount;
  final int uniqueUsers;

  const XpTrendPoint({
    required this.day,
    this.totalXp = 0,
    this.transactionCount = 0,
    this.uniqueUsers = 0,
  });

  factory XpTrendPoint.fromJson(Map<String, dynamic> json) {
    return XpTrendPoint(
      day: DateTime.parse(json['day'] as String),
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      uniqueUsers: (json['unique_users'] as num?)?.toInt() ?? 0,
    );
  }
}
