import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tournament.dart';
import '../services/tournament_service.dart';

final tournamentServiceProvider = Provider((ref) => TournamentService());

/// All tournaments for a company
final tournamentsProvider =
    FutureProvider.autoDispose.family<List<Tournament>, String>(
  (ref, companyId) async {
    final service = ref.read(tournamentServiceProvider);
    return service.getTournaments(companyId);
  },
);

/// Tournament stats
final tournamentStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    final service = ref.read(tournamentServiceProvider);
    return service.getTournamentStats(companyId);
  },
);

/// Registrations for a tournament
final tournamentRegistrationsProvider =
    FutureProvider.autoDispose.family<List<TournamentRegistration>, String>(
  (ref, tournamentId) async {
    final service = ref.read(tournamentServiceProvider);
    return service.getRegistrations(tournamentId);
  },
);

/// Matches for a tournament
final tournamentMatchesProvider =
    FutureProvider.autoDispose.family<List<TournamentMatch>, String>(
  (ref, tournamentId) async {
    final service = ref.read(tournamentServiceProvider);
    return service.getMatches(tournamentId);
  },
);

/// Actions for tournaments
class TournamentActions {
  final Ref _ref;
  final TournamentService _service;

  TournamentActions(this._ref)
      : _service = _ref.read(tournamentServiceProvider);

  Future<Tournament> createTournament(Tournament tournament) async {
    final created = await _service.createTournament(tournament);
    _ref.invalidate(tournamentsProvider);
    _ref.invalidate(tournamentStatsProvider);
    return created;
  }

  Future<Tournament> updateTournament(
      String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateTournament(id, updates);
    _ref.invalidate(tournamentsProvider);
    _ref.invalidate(tournamentStatsProvider);
    return updated;
  }

  Future<void> updateStatus(String id, TournamentStatus status) async {
    await _service.updateStatus(id, status);
    _ref.invalidate(tournamentsProvider);
    _ref.invalidate(tournamentStatsProvider);
  }

  Future<void> deleteTournament(String id) async {
    await _service.deleteTournament(id);
    _ref.invalidate(tournamentsProvider);
    _ref.invalidate(tournamentStatsProvider);
  }

  Future<TournamentRegistration> registerPlayer(
      TournamentRegistration reg) async {
    final created = await _service.registerPlayer(reg);
    _ref.invalidate(tournamentRegistrationsProvider);
    _ref.invalidate(tournamentsProvider);
    return created;
  }

  Future<void> updateRegistrationStatus(
      String id, RegistrationStatus status) async {
    await _service.updateRegistrationStatus(id, status);
    _ref.invalidate(tournamentRegistrationsProvider);
  }

  Future<TournamentMatch> createMatch(TournamentMatch match) async {
    final created = await _service.createMatch(match);
    _ref.invalidate(tournamentMatchesProvider);
    return created;
  }

  Future<void> updateMatchResult(String id, {
    required int player1Score,
    required int player2Score,
    required String winnerId,
  }) async {
    await _service.updateMatchResult(id,
        player1Score: player1Score,
        player2Score: player2Score,
        winnerId: winnerId);
    _ref.invalidate(tournamentMatchesProvider);
  }

  Future<void> startMatch(String id) async {
    await _service.startMatch(id);
    _ref.invalidate(tournamentMatchesProvider);
  }

  Future<List<TournamentMatch>> generateBracket(
      String tournamentId, String companyId) async {
    final matches = await _service.generateBracket(tournamentId, companyId);
    _ref.invalidate(tournamentMatchesProvider);
    return matches;
  }
}

final tournamentActionsProvider = Provider((ref) => TournamentActions(ref));
