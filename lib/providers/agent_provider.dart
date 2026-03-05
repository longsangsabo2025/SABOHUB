import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/agents/agent_chat_service.dart';
import '../core/agents/agent_evaluator.dart';
import '../core/agents/agent_types.dart';

/// ============================================================================
/// AGENT PROVIDERS — Riverpod state management for multi-agent pipeline
/// ============================================================================

// ─── Service Provider (singleton) ───────────────────────────────
final agentChatServiceProvider = Provider<AgentChatService>((ref) {
  final service = AgentChatService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Event Stream ───────────────────────────────────────────────
final agentEventsProvider = StreamProvider<AgentEvent>((ref) {
  final service = ref.watch(agentChatServiceProvider);
  return service.events;
});

// ─── Query Execution ────────────────────────────────────────────

/// State for the agent pipeline
class AgentQueryState {
  final bool isLoading;
  final AgentResult? result;
  final EvalScore? evalScore;
  final String? error;
  final List<AgentEvent> events;

  const AgentQueryState({
    this.isLoading = false,
    this.result,
    this.evalScore,
    this.error,
    this.events = const [],
  });

  AgentQueryState copyWith({
    bool? isLoading,
    AgentResult? result,
    EvalScore? evalScore,
    String? error,
    List<AgentEvent>? events,
  }) {
    return AgentQueryState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      evalScore: evalScore ?? this.evalScore,
      error: error ?? this.error,
      events: events ?? this.events,
    );
  }
}

/// Main query notifier — processes queries through the agent pipeline
class AgentQueryNotifier extends Notifier<AgentQueryState> {
  StreamSubscription<AgentEvent>? _eventSub;

  @override
  AgentQueryState build() {
    final service = ref.watch(agentChatServiceProvider);
    _eventSub?.cancel();
    _eventSub = service.events.listen((event) {
      state = state.copyWith(events: [...state.events, event]);
    });
    ref.onDispose(() => _eventSub?.cancel());
    return const AgentQueryState();
  }

  /// Process a query through the multi-agent pipeline
  Future<AgentResult> processQuery(String query, String companyId) async {
    state = const AgentQueryState(isLoading: true, events: []);

    try {
      final service = ref.read(agentChatServiceProvider);
      final result = await service.processQuery(query, companyId);
      final score = service.scoreResult(result);

      state = state.copyWith(
        isLoading: false,
        result: result,
        evalScore: score,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear state
  void reset() {
    state = const AgentQueryState();
  }
}

final agentQueryProvider =
    NotifierProvider<AgentQueryNotifier, AgentQueryState>(
  AgentQueryNotifier.new,
);

// ─── Evaluation ─────────────────────────────────────────────────

/// State for evaluation runs
class AgentEvalState {
  final bool isRunning;
  final EvalReport? report;
  final String? error;

  const AgentEvalState({
    this.isRunning = false,
    this.report,
    this.error,
  });
}

class AgentEvalNotifier extends Notifier<AgentEvalState> {
  @override
  AgentEvalState build() => const AgentEvalState();

  /// Run the full evaluation suite
  Future<void> runEvaluation(String companyId) async {
    state = const AgentEvalState(isRunning: true);

    try {
      final service = ref.read(agentChatServiceProvider);
      final report = await service.runEvaluation(companyId);
      state = AgentEvalState(report: report);
    } catch (e) {
      state = AgentEvalState(error: e.toString());
    }
  }

  void reset() {
    state = const AgentEvalState();
  }
}

final agentEvalProvider =
    NotifierProvider<AgentEvalNotifier, AgentEvalState>(
  AgentEvalNotifier.new,
);

// ─── Convenience Providers ──────────────────────────────────────

/// Whether agent pipeline is currently processing
final agentIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(agentQueryProvider).isLoading;
});

/// Latest agent result
final agentResultProvider = Provider<AgentResult?>((ref) {
  return ref.watch(agentQueryProvider).result;
});

/// Latest eval score
final agentScoreProvider = Provider<EvalScore?>((ref) {
  return ref.watch(agentQueryProvider).evalScore;
});
