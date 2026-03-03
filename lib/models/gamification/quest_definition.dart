enum QuestType {
  main('main', 'Nhiệm vụ chính'),
  daily('daily', 'Hàng ngày'),
  weekly('weekly', 'Hàng tuần'),
  boss('boss', 'Thử thách Boss'),
  achievement('achievement', 'Thành tựu');

  final String value;
  final String label;
  const QuestType(this.value, this.label);

  static QuestType fromString(String value) {
    return QuestType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => QuestType.main,
    );
  }

  String get icon {
    switch (this) {
      case QuestType.main:
        return '⚔️';
      case QuestType.daily:
        return '📋';
      case QuestType.weekly:
        return '🏆';
      case QuestType.boss:
        return '🏰';
      case QuestType.achievement:
        return '🎖️';
    }
  }
}

enum QuestCategory {
  operate('operate', 'Vận Hành'),
  sell('sell', 'Kinh Doanh'),
  finance('finance', 'Tài Chính');

  final String value;
  final String label;
  const QuestCategory(this.value, this.label);

  static QuestCategory? fromString(String? value) {
    if (value == null) return null;
    return QuestCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => QuestCategory.operate,
    );
  }
}

class QuestCondition {
  final String type;
  final String? table;
  final Map<String, dynamic>? filter;
  final String? operator;
  final dynamic value;
  final String? period;
  final String? metric;
  final String? compare;
  final int? percentage;
  final int? days;
  final QuestCondition? condition;

  const QuestCondition({
    required this.type,
    this.table,
    this.filter,
    this.operator,
    this.value,
    this.period,
    this.metric,
    this.compare,
    this.percentage,
    this.days,
    this.condition,
  });

  factory QuestCondition.fromJson(Map<String, dynamic> json) {
    return QuestCondition(
      type: json['type'] as String? ?? 'count',
      table: json['table'] as String?,
      filter: json['filter'] as Map<String, dynamic>?,
      operator: json['operator'] as String?,
      value: json['value'],
      period: json['period'] as String?,
      metric: json['metric'] as String?,
      compare: json['compare'] as String?,
      percentage: json['percentage'] as int?,
      days: json['days'] as int?,
      condition: json['condition'] != null
          ? QuestCondition.fromJson(json['condition'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (table != null) map['table'] = table;
    if (filter != null) map['filter'] = filter;
    if (operator != null) map['operator'] = operator;
    if (value != null) map['value'] = value;
    if (period != null) map['period'] = period;
    if (metric != null) map['metric'] = metric;
    if (compare != null) map['compare'] = compare;
    if (percentage != null) map['percentage'] = percentage;
    if (days != null) map['days'] = days;
    if (condition != null) map['condition'] = condition!.toJson();
    return map;
  }
}

class QuestDefinition {
  final String id;
  final String code;
  final String name;
  final String? description;
  final QuestType questType;
  final int? act;
  final String? businessType;
  final QuestCategory? category;
  final List<String> prerequisites;
  final QuestCondition conditions;
  final int xpReward;
  final int reputationReward;
  final String? badgeReward;
  final String? titleReward;
  final String? unlockFeature;
  final int sortOrder;
  final bool isActive;
  final bool isSecret;
  final DateTime createdAt;

  const QuestDefinition({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.questType,
    this.act,
    this.businessType,
    this.category,
    this.prerequisites = const [],
    required this.conditions,
    this.xpReward = 0,
    this.reputationReward = 0,
    this.badgeReward,
    this.titleReward,
    this.unlockFeature,
    this.sortOrder = 0,
    this.isActive = true,
    this.isSecret = false,
    required this.createdAt,
  });

  factory QuestDefinition.fromJson(Map<String, dynamic> json) {
    return QuestDefinition(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      questType: QuestType.fromString(json['quest_type'] as String),
      act: json['act'] as int?,
      businessType: json['business_type'] as String?,
      category: QuestCategory.fromString(json['category'] as String?),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conditions: json['conditions'] != null && (json['conditions'] as Map).isNotEmpty
          ? QuestCondition.fromJson(json['conditions'] as Map<String, dynamic>)
          : const QuestCondition(type: 'manual'),
      xpReward: json['xp_reward'] as int? ?? 0,
      reputationReward: json['reputation_reward'] as int? ?? 0,
      badgeReward: json['badge_reward'] as String?,
      titleReward: json['title_reward'] as String?,
      unlockFeature: json['unlock_feature'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isSecret: json['is_secret'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'quest_type': questType.value,
        'act': act,
        'business_type': businessType,
        'category': category?.value,
        'prerequisites': prerequisites,
        'conditions': conditions.toJson(),
        'xp_reward': xpReward,
        'reputation_reward': reputationReward,
        'badge_reward': badgeReward,
        'title_reward': titleReward,
        'unlock_feature': unlockFeature,
        'sort_order': sortOrder,
        'is_active': isActive,
        'is_secret': isSecret,
      };
}
