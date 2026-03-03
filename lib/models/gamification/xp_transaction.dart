enum XpSourceType {
  quest('quest', 'Nhiệm vụ'),
  daily('daily', 'Hàng ngày'),
  weekly('weekly', 'Hàng tuần'),
  boss('boss', 'Boss Challenge'),
  achievement('achievement', 'Thành tựu'),
  login('login', 'Đăng nhập'),
  bonus('bonus', 'Thưởng'),
  multiplier('multiplier', 'Nhân bội');

  final String value;
  final String label;
  const XpSourceType(this.value, this.label);

  static XpSourceType fromString(String value) {
    return XpSourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => XpSourceType.bonus,
    );
  }
}

class XpTransaction {
  final String id;
  final String userId;
  final String companyId;
  final int amount;
  final double multiplier;
  final int finalAmount;
  final XpSourceType sourceType;
  final String? sourceId;
  final String? description;
  final DateTime createdAt;

  const XpTransaction({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.amount,
    this.multiplier = 1.0,
    required this.finalAmount,
    required this.sourceType,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  factory XpTransaction.fromJson(Map<String, dynamic> json) {
    return XpTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      amount: json['amount'] as int,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      finalAmount: json['final_amount'] as int,
      sourceType: XpSourceType.fromString(json['source_type'] as String),
      sourceId: json['source_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DailyQuestLog {
  final String id;
  final String userId;
  final String companyId;
  final DateTime logDate;
  final List<String> questsCompleted;
  final bool comboCompleted;
  final int xpEarned;
  final int streakCount;
  final bool loggedIn;

  const DailyQuestLog({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.logDate,
    this.questsCompleted = const [],
    this.comboCompleted = false,
    this.xpEarned = 0,
    this.streakCount = 0,
    this.loggedIn = false,
  });

  factory DailyQuestLog.fromJson(Map<String, dynamic> json) {
    return DailyQuestLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      questsCompleted: (json['quests_completed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      comboCompleted: json['combo_completed'] as bool? ?? false,
      xpEarned: json['xp_earned'] as int? ?? 0,
      streakCount: json['streak_count'] as int? ?? 0,
      loggedIn: json['logged_in'] as bool? ?? false,
    );
  }
}
