import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/app_logger.dart';
import '../models/tournament.dart';

/// Service for tournament management — SABO Billiard Tournaments
class TournamentService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // TOURNAMENTS
  // ============================================================

  /// Get all tournaments for a company
  Future<List<Tournament>> getTournaments(String companyId) async {
    try {
      final data = await _supabase
          .from('tournaments')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return data.map((e) => Tournament.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('TournamentService.getTournaments', e);
      rethrow;
    }
  }

  /// Get tournaments by status
  Future<List<Tournament>> getTournamentsByStatus(
      String companyId, TournamentStatus status) async {
    try {
      final data = await _supabase
          .from('tournaments')
          .select()
          .eq('company_id', companyId)
          .eq('status', status.value)
          .eq('is_active', true)
          .order('start_date');
      return data.map((e) => Tournament.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('TournamentService.getTournamentsByStatus', e);
      rethrow;
    }
  }

  /// Get single tournament
  Future<Tournament> getTournament(String id) async {
    try {
      final data = await _supabase
          .from('tournaments')
          .select()
          .eq('id', id)
          .single();
      return Tournament.fromJson(data);
    } catch (e) {
      AppLogger.error('TournamentService.getTournament', e);
      rethrow;
    }
  }

  /// Create tournament
  Future<Tournament> createTournament(Tournament tournament) async {
    try {
      final data = await _supabase
          .from('tournaments')
          .insert(tournament.toJson())
          .select()
          .single();
      return Tournament.fromJson(data);
    } catch (e) {
      AppLogger.error('TournamentService.createTournament', e);
      rethrow;
    }
  }

  /// Update tournament
  Future<Tournament> updateTournament(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('tournaments')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Tournament.fromJson(data);
    } catch (e) {
      AppLogger.error('TournamentService.updateTournament', e);
      rethrow;
    }
  }

  /// Update tournament status
  Future<void> updateStatus(String id, TournamentStatus status) async {
    await updateTournament(id, {'status': status.value});
  }

  /// Delete tournament (soft)
  Future<void> deleteTournament(String id) async {
    try {
      await _supabase
          .from('tournaments')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('TournamentService.deleteTournament', e);
      rethrow;
    }
  }

  /// Get tournament stats for a company
  Future<Map<String, dynamic>> getTournamentStats(String companyId) async {
    try {
      final tournaments = await getTournaments(companyId);

      int total = tournaments.length;
      int active = 0;
      int upcoming = 0;
      int completed = 0;
      double totalRevenue = 0;
      double totalPrize = 0;
      int totalPlayers = 0;

      for (final t in tournaments) {
        switch (t.status) {
          case TournamentStatus.inProgress:
            active++;
            break;
          case TournamentStatus.registrationOpen:
          case TournamentStatus.registrationClosed:
          case TournamentStatus.draft:
            upcoming++;
            break;
          case TournamentStatus.completed:
            completed++;
            break;
          default:
            break;
        }
        totalRevenue += t.totalRevenue;
        totalPrize += t.prizePool;
        totalPlayers += t.currentParticipants;
      }

      return {
        'total': total,
        'active': active,
        'upcoming': upcoming,
        'completed': completed,
        'total_revenue': totalRevenue,
        'total_prize': totalPrize,
        'total_players': totalPlayers,
      };
    } catch (e) {
      AppLogger.error('TournamentService.getTournamentStats', e);
      rethrow;
    }
  }

  // ============================================================
  // REGISTRATIONS
  // ============================================================

  /// Get registrations for a tournament
  Future<List<TournamentRegistration>> getRegistrations(
      String tournamentId) async {
    try {
      final data = await _supabase
          .from('tournament_registrations')
          .select()
          .eq('tournament_id', tournamentId)
          .order('registration_number');
      return data
          .map((e) => TournamentRegistration.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error('TournamentService.getRegistrations', e);
      rethrow;
    }
  }

  /// Register player
  Future<TournamentRegistration> registerPlayer(
      TournamentRegistration reg) async {
    try {
      // Get current count for registration number
      final countData = await _supabase
          .from('tournament_registrations')
          .select('id')
          .eq('tournament_id', reg.tournamentId);
      final nextNumber = countData.length + 1;

      final json = reg.toJson();
      json['registration_number'] = nextNumber;

      final data = await _supabase
          .from('tournament_registrations')
          .insert(json)
          .select()
          .single();

      // Update participant count
      await _supabase
          .from('tournaments')
          .update({
            'current_participants': nextNumber,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reg.tournamentId);

      return TournamentRegistration.fromJson(data);
    } catch (e) {
      AppLogger.error('TournamentService.registerPlayer', e);
      rethrow;
    }
  }

  /// Update registration status
  Future<void> updateRegistrationStatus(
      String id, RegistrationStatus status) async {
    try {
      await _supabase
          .from('tournament_registrations')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('TournamentService.updateRegistrationStatus', e);
      rethrow;
    }
  }

  // ============================================================
  // MATCHES
  // ============================================================

  /// Get matches for a tournament
  Future<List<TournamentMatch>> getMatches(String tournamentId) async {
    try {
      final data = await _supabase
          .from('tournament_matches')
          .select()
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');
      return data.map((e) => TournamentMatch.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('TournamentService.getMatches', e);
      rethrow;
    }
  }

  /// Get matches by round
  Future<List<TournamentMatch>> getMatchesByRound(
      String tournamentId, int round) async {
    try {
      final data = await _supabase
          .from('tournament_matches')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('round_number', round)
          .order('match_number');
      return data.map((e) => TournamentMatch.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('TournamentService.getMatchesByRound', e);
      rethrow;
    }
  }

  /// Create match
  Future<TournamentMatch> createMatch(TournamentMatch match) async {
    try {
      final data = await _supabase
          .from('tournament_matches')
          .insert(match.toJson())
          .select()
          .single();
      return TournamentMatch.fromJson(data);
    } catch (e) {
      AppLogger.error('TournamentService.createMatch', e);
      rethrow;
    }
  }

  /// Update match result
  Future<void> updateMatchResult(String id, {
    required int player1Score,
    required int player2Score,
    required String winnerId,
  }) async {
    try {
      await _supabase
          .from('tournament_matches')
          .update({
            'player1_score': player1Score,
            'player2_score': player2Score,
            'winner_id': winnerId,
            'status': 'completed',
            'ended_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('TournamentService.updateMatchResult', e);
      rethrow;
    }
  }

  /// Start match
  Future<void> startMatch(String id) async {
    try {
      await _supabase
          .from('tournament_matches')
          .update({
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('TournamentService.startMatch', e);
      rethrow;
    }
  }

  /// Generate bracket for single elimination
  Future<List<TournamentMatch>> generateBracket(
      String tournamentId, String companyId) async {
    try {
      final regs = await getRegistrations(tournamentId);
      final players =
          regs.where((r) => r.status != RegistrationStatus.withdrawn).toList();
      players.shuffle(); // Random seeding

      final matches = <TournamentMatch>[];
      int matchNum = 1;

      // First round matches
      for (int i = 0; i < players.length - 1; i += 2) {
        final match = TournamentMatch(
          id: '',
          tournamentId: tournamentId,
          companyId: companyId,
          matchNumber: matchNum,
          roundNumber: 1,
          roundName: 'Vòng 1',
          player1Id: players[i].id,
          player2Id: i + 1 < players.length ? players[i + 1].id : null,
          player1Name: players[i].playerName,
          player2Name:
              i + 1 < players.length ? players[i + 1].playerName : 'BYE',
        );
        final created = await createMatch(match);
        matches.add(created);
        matchNum++;
      }

      return matches;
    } catch (e) {
      AppLogger.error('TournamentService.generateBracket', e);
      rethrow;
    }
  }
}
