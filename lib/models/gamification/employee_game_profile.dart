class StaffLevel {
  static const int maxLevel = 50;

  static int xpForLevel(int level) => 50 * level * level;

  static int levelFromXp(int totalXp) {
    int lvl = 1;
    while (lvl < maxLevel && xpForLevel(lvl + 1) <= totalXp) {
      lvl++;
    }
    return lvl;
  }

  static String titleForLevel(int level) {
    if (level >= 50) return 'Huyền Thoại';
    if (level >= 40) return 'Kim Cương';
    if (level >= 30) return 'Bạch Kim';
    if (level >= 20) return 'Vàng';
    if (level >= 15) return 'Bạc';
    if (level >= 10) return 'Đồng';
    if (level >= 5) return 'Sắt';
    return 'Tân Binh';
  }

  static String titleEnglish(int level) {
    if (level >= 50) return 'Legend';
    if (level >= 40) return 'Diamond';
    if (level >= 30) return 'Platinum';
    if (level >= 20) return 'Gold';
    if (level >= 15) return 'Silver';
    if (level >= 10) return 'Bronze';
    if (level >= 5) return 'Iron';
    return 'Recruit';
  }
}

class EmployeeGameProfile {
  final String id;
  final String employeeId;
  final String companyId;
  final int level;
  final int totalXp;
  final String currentTitle;
  final double attendanceScore;
  final double taskScore;
  final double punctualityScore;
  final double overallRating;
  final int streakDays;
  final int longestStreak;
  final DateTime? lastCheckinDate;
  final List<String> badges;
  final int monthlyXp;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? employeeName;

  const EmployeeGameProfile({
    required this.id,
    required this.employeeId,
    required this.companyId,
    this.level = 1,
    this.totalXp = 0,
    this.currentTitle = 'Tân Binh',
    this.attendanceScore = 0,
    this.taskScore = 0,
    this.punctualityScore = 0,
    this.overallRating = 0,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.lastCheckinDate,
    this.badges = const [],
    this.monthlyXp = 0,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  int get xpForCurrentLevel => StaffLevel.xpForLevel(level);
  int get xpForNextLevel => level >= StaffLevel.maxLevel ? totalXp : StaffLevel.xpForLevel(level + 1);
  double get levelProgress {
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return ((totalXp - xpForCurrentLevel) / needed).clamp(0.0, 1.0);
  }

  factory EmployeeGameProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeGameProfile(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      companyId: json['company_id'] as String,
      level: json['level'] as int? ?? 1,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentTitle: json['current_title'] as String? ?? 'Tân Binh',
      attendanceScore: (json['attendance_score'] as num?)?.toDouble() ?? 0,
      taskScore: (json['task_score'] as num?)?.toDouble() ?? 0,
      punctualityScore: (json['punctuality_score'] as num?)?.toDouble() ?? 0,
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCheckinDate: json['last_checkin_date'] != null
          ? DateTime.tryParse(json['last_checkin_date'] as String)
          : null,
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      monthlyXp: json['monthly_xp'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: (json['employees'] as Map<String, dynamic>?)?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'company_id': companyId,
        'level': level,
        'total_xp': totalXp,
        'current_title': currentTitle,
        'attendance_score': attendanceScore,
        'task_score': taskScore,
        'punctuality_score': punctualityScore,
        'overall_rating': overallRating,
        'streak_days': streakDays,
        'longest_streak': longestStreak,
        'badges': badges,
        'monthly_xp': monthlyXp,
      };
}

class StaffLeaderboardEntry {
  final int rank;
  final String employeeId;
  final String fullName;
  final int level;
  final int totalXp;
  final String currentTitle;
  final double attendanceScore;
  final double taskScore;
  final double overallRating;
  final int streakDays;

  const StaffLeaderboardEntry({
    required this.rank,
    required this.employeeId,
    required this.fullName,
    required this.level,
    required this.totalXp,
    required this.currentTitle,
    this.attendanceScore = 0,
    this.taskScore = 0,
    this.overallRating = 0,
    this.streakDays = 0,
  });

  factory StaffLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return StaffLeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String? ?? 'Nhân viên',
      level: json['level'] as int? ?? 1,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentTitle: json['current_title'] as String? ?? 'Tân Binh',
      attendanceScore: (json['attendance_score'] as num?)?.toDouble() ?? 0,
      taskScore: (json['task_score'] as num?)?.toDouble() ?? 0,
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
    );
  }
}
