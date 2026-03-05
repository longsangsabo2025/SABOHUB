// SABO Corporation — Tournament Model
// Quản lý giải đấu billiard

enum TournamentType {
  singleElimination('single_elimination', 'Loại trực tiếp'),
  doubleElimination('double_elimination', 'Loại kép'),
  roundRobin('round_robin', 'Vòng tròn'),
  swiss('swiss', 'Hệ Swiss'),
  league('league', 'Giải đấu dài hạn');

  final String value;
  final String label;
  const TournamentType(this.value, this.label);

  static TournamentType fromString(String s) {
    return TournamentType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => TournamentType.singleElimination,
    );
  }
}

enum GameType {
  pool('pool', 'Pool'),
  carom('carom', 'Carom'),
  snooker('snooker', 'Snooker'),
  lo('lo', 'Lỗ'),
  mixed('mixed', 'Hỗn hợp');

  final String value;
  final String label;
  const GameType(this.value, this.label);

  static GameType fromString(String s) {
    return GameType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => GameType.pool,
    );
  }
}

enum TournamentStatus {
  draft('draft', 'Nháp'),
  registrationOpen('registration_open', 'Đang đăng ký'),
  registrationClosed('registration_closed', 'Đóng đăng ký'),
  inProgress('in_progress', 'Đang thi đấu'),
  completed('completed', 'Hoàn thành'),
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String label;
  const TournamentStatus(this.value, this.label);

  static TournamentStatus fromString(String s) {
    return TournamentStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => TournamentStatus.draft,
    );
  }
}

class Tournament {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final TournamentType tournamentType;
  final GameType gameType;
  final TournamentStatus status;

  // Schedule
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;

  // Venue
  final String? venueName;
  final String? venueAddress;

  // Capacity
  final int maxParticipants;
  final int currentParticipants;
  final double entryFee;
  final double prizePool;
  final Map<String, dynamic>? prizeBreakdown;

  // Sponsor & Revenue
  final String? sponsorName;
  final double sponsorAmount;
  final double totalRevenue;
  final double totalExpenses;

  // Rules & Media
  final String? rulesText;
  final int tableCount;
  final String? bannerUrl;
  final String? livestreamUrl;

  // Management
  final String? organizerId;
  final String? createdBy;
  final bool isActive;
  final DateTime? createdAt;

  Tournament({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.tournamentType = TournamentType.singleElimination,
    this.gameType = GameType.pool,
    this.status = TournamentStatus.draft,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.venueName,
    this.venueAddress,
    this.maxParticipants = 32,
    this.currentParticipants = 0,
    this.entryFee = 0,
    this.prizePool = 0,
    this.prizeBreakdown,
    this.sponsorName,
    this.sponsorAmount = 0,
    this.totalRevenue = 0,
    this.totalExpenses = 0,
    this.rulesText,
    this.tableCount = 1,
    this.bannerUrl,
    this.livestreamUrl,
    this.organizerId,
    this.createdBy,
    this.isActive = true,
    this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      tournamentType: TournamentType.fromString(json['tournament_type'] ?? ''),
      gameType: GameType.fromString(json['game_type'] ?? ''),
      status: TournamentStatus.fromString(json['status'] ?? ''),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.tryParse(json['registration_deadline'])
          : null,
      venueName: json['venue_name'],
      venueAddress: json['venue_address'],
      maxParticipants: json['max_participants'] ?? 32,
      currentParticipants: json['current_participants'] ?? 0,
      entryFee: (json['entry_fee'] ?? 0).toDouble(),
      prizePool: (json['prize_pool'] ?? 0).toDouble(),
      prizeBreakdown: json['prize_breakdown'],
      sponsorName: json['sponsor_name'],
      sponsorAmount: (json['sponsor_amount'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      rulesText: json['rules_text'],
      tableCount: json['table_count'] ?? 1,
      bannerUrl: json['banner_url'],
      livestreamUrl: json['livestream_url'],
      organizerId: json['organizer_id'],
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'name': name,
        'description': description,
        'tournament_type': tournamentType.value,
        'game_type': gameType.value,
        'status': status.value,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'registration_deadline': registrationDeadline?.toIso8601String(),
        'venue_name': venueName,
        'venue_address': venueAddress,
        'max_participants': maxParticipants,
        'entry_fee': entryFee,
        'prize_pool': prizePool,
        'prize_breakdown': prizeBreakdown,
        'sponsor_name': sponsorName,
        'sponsor_amount': sponsorAmount,
        'rules_text': rulesText,
        'table_count': tableCount,
        'banner_url': bannerUrl,
        'livestream_url': livestreamUrl,
        'organizer_id': organizerId,
      };

  /// Profit
  double get profit => totalRevenue - totalExpenses;

  /// Registration slots remaining
  int get slotsRemaining => maxParticipants - currentParticipants;

  /// Is registration still open?
  bool get canRegister =>
      status == TournamentStatus.registrationOpen && slotsRemaining > 0;

  /// Fill rate (0.0 - 1.0)
  double get fillRate {
    if (maxParticipants == 0) return 0;
    return (currentParticipants / maxParticipants).clamp(0.0, 1.0);
  }
}

/// Tournament Registration (player entry)
enum RegistrationStatus {
  registered('registered', 'Đã đăng ký'),
  confirmed('confirmed', 'Xác nhận'),
  checkedIn('checked_in', 'Đã check-in'),
  eliminated('eliminated', 'Bị loại'),
  winner('winner', 'Thắng'),
  withdrawn('withdrawn', 'Rút lui'),
  noShow('no_show', 'Không đến');

  final String value;
  final String label;
  const RegistrationStatus(this.value, this.label);

  static RegistrationStatus fromString(String s) {
    return RegistrationStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => RegistrationStatus.registered,
    );
  }
}

class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String companyId;
  final String playerName;
  final String? playerPhone;
  final String? playerEmail;
  final String? playerAvatarUrl;
  final int? registrationNumber;
  final int? seedNumber;
  final RegistrationStatus status;
  final bool feePaid;
  final String? paymentMethod;
  final DateTime? paidAt;
  final int wins;
  final int losses;
  final int draws;
  final int points;
  final String? notes;
  final String? registeredBy;
  final DateTime? createdAt;

  TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.companyId,
    required this.playerName,
    this.playerPhone,
    this.playerEmail,
    this.playerAvatarUrl,
    this.registrationNumber,
    this.seedNumber,
    this.status = RegistrationStatus.registered,
    this.feePaid = false,
    this.paymentMethod,
    this.paidAt,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.points = 0,
    this.notes,
    this.registeredBy,
    this.createdAt,
  });

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) {
    return TournamentRegistration(
      id: json['id'] ?? '',
      tournamentId: json['tournament_id'] ?? '',
      companyId: json['company_id'] ?? '',
      playerName: json['player_name'] ?? '',
      playerPhone: json['player_phone'],
      playerEmail: json['player_email'],
      playerAvatarUrl: json['player_avatar_url'],
      registrationNumber: json['registration_number'],
      seedNumber: json['seed_number'],
      status: RegistrationStatus.fromString(json['status'] ?? ''),
      feePaid: json['fee_paid'] ?? false,
      paymentMethod: json['payment_method'],
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'])
          : null,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      points: json['points'] ?? 0,
      notes: json['notes'],
      registeredBy: json['registered_by'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tournament_id': tournamentId,
        'company_id': companyId,
        'player_name': playerName,
        'player_phone': playerPhone,
        'player_email': playerEmail,
        'player_avatar_url': playerAvatarUrl,
        'registration_number': registrationNumber,
        'seed_number': seedNumber,
        'status': status.value,
        'fee_paid': feePaid,
        'payment_method': paymentMethod,
        'notes': notes,
      };

  /// Win rate
  double get winRate {
    final total = wins + losses + draws;
    if (total == 0) return 0;
    return wins / total;
  }
}

/// Tournament Match
enum MatchStatus {
  scheduled('scheduled', 'Sắp diễn ra'),
  inProgress('in_progress', 'Đang thi đấu'),
  completed('completed', 'Hoàn thành'),
  walkover('walkover', 'Bỏ cuộc'),
  cancelled('cancelled', 'Đã hủy'),
  postponed('postponed', 'Hoãn');

  final String value;
  final String label;
  const MatchStatus(this.value, this.label);

  static MatchStatus fromString(String s) {
    return MatchStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => MatchStatus.scheduled,
    );
  }
}

class TournamentMatch {
  final String id;
  final String tournamentId;
  final String companyId;
  final int matchNumber;
  final int roundNumber;
  final String? roundName;
  final String? player1Id;
  final String? player2Id;
  final String? player1Name;
  final String? player2Name;
  final String? tableId;
  final String? tableName;
  final int player1Score;
  final int player2Score;
  final String? winnerId;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final MatchStatus status;
  final int? bracketPosition;
  final String? nextMatchId;
  final String? livestreamUrl;
  final String? highlightsUrl;
  final String? notes;
  final String? refereeId;
  final DateTime? createdAt;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.companyId,
    required this.matchNumber,
    this.roundNumber = 1,
    this.roundName,
    this.player1Id,
    this.player2Id,
    this.player1Name,
    this.player2Name,
    this.tableId,
    this.tableName,
    this.player1Score = 0,
    this.player2Score = 0,
    this.winnerId,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.status = MatchStatus.scheduled,
    this.bracketPosition,
    this.nextMatchId,
    this.livestreamUrl,
    this.highlightsUrl,
    this.notes,
    this.refereeId,
    this.createdAt,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] ?? '',
      tournamentId: json['tournament_id'] ?? '',
      companyId: json['company_id'] ?? '',
      matchNumber: json['match_number'] ?? 0,
      roundNumber: json['round_number'] ?? 1,
      roundName: json['round_name'],
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      player1Name: json['player1_name'],
      player2Name: json['player2_name'],
      tableId: json['table_id'],
      tableName: json['table_name'],
      player1Score: json['player1_score'] ?? 0,
      player2Score: json['player2_score'] ?? 0,
      winnerId: json['winner_id'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'])
          : null,
      durationMinutes: json['duration_minutes'],
      status: MatchStatus.fromString(json['status'] ?? ''),
      bracketPosition: json['bracket_position'],
      nextMatchId: json['next_match_id'],
      livestreamUrl: json['livestream_url'],
      highlightsUrl: json['highlights_url'],
      notes: json['notes'],
      refereeId: json['referee_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tournament_id': tournamentId,
        'company_id': companyId,
        'match_number': matchNumber,
        'round_number': roundNumber,
        'round_name': roundName,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'player1_name': player1Name,
        'player2_name': player2Name,
        'table_id': tableId,
        'table_name': tableName,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'status': status.value,
        'referee_id': refereeId,
        'notes': notes,
      };

  /// Score display
  String get scoreDisplay => '$player1Score - $player2Score';

  /// Is match live?
  bool get isLive => status == MatchStatus.inProgress;
}
