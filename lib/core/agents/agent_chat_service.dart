import 'dart:async';

import '../../utils/app_logger.dart';
import 'agent_evaluator.dart';
import 'agent_executors.dart';
import 'agent_orchestrator.dart';
import 'agent_types.dart';

/// ============================================================================
/// AGENT CHAT SERVICE — High-level API for multi-agent pipeline
/// Drop-in enhancement for the existing AIChatService.
///
/// Usage:
///   final service = AgentChatService();
///   final result = await service.processQuery('Doanh thu hôm nay?', companyId);
///   print(result.response);  // Same format as AIChatService
///   print(result.toJson());  // + trace, confidence, timing
/// ============================================================================

class AgentChatService {
  static final AgentChatService _instance = AgentChatService._internal();
  factory AgentChatService() => _instance;

  late final AgentOrchestrator _orchestrator;
  final AgentEvaluator _evaluator = AgentEvaluator();
  bool _initialized = false;

  AgentChatService._internal() {
    _orchestrator = AgentOrchestrator();
    _init();
  }

  void _init() {
    if (_initialized) return;
    AgentExecutors.registerAll(_orchestrator);
    _initialized = true;
    AppLogger.info('AgentChatService: Multi-agent pipeline initialized');
  }

  // ─── Public API ───────────────────────────────────────────────

  /// Process a query through the multi-agent pipeline.
  /// Returns full AgentResult with trace, confidence, timing.
  Future<AgentResult> processQuery(String query, String companyId) async {
    _init(); // ensure initialization
    return _orchestrator.run(query: query, companyId: companyId);
  }

  /// Simple string response (backward compatible with AIChatService)
  Future<String> chat(String query, String companyId) async {
    final result = await processQuery(query, companyId);
    return result.response;
  }

  /// Stream of execution events for real-time UI
  Stream<AgentEvent> get events => _orchestrator.events;

  /// Run evaluation suite and get report
  Future<EvalReport> runEvaluation(String companyId) async {
    final startTime = DateTime.now();
    final results = <EvalResult>[];

    for (final testCase in AgentEvaluator.standardSuite) {
      try {
        final result = await processQuery(testCase.query, companyId);
        final evalResult = _evaluator.evaluateCase(testCase, result);
        results.add(evalResult);
      } catch (e) {
        AppLogger.error('Eval failed for ${testCase.id}', e);
      }
    }

    final totalDuration = DateTime.now().difference(startTime);
    return _evaluator.generateReport(results, totalDuration);
  }

  /// Score a single result (for on-the-fly quality tracking)
  EvalScore scoreResult(AgentResult result) {
    return _evaluator.scoreResult(result);
  }

  /// Clean up
  void dispose() {
    _orchestrator.dispose();
  }
}
