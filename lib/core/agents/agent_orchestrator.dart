import 'dart:async';

import '../../utils/app_logger.dart';
import 'agent_types.dart';

/// ============================================================================
/// AGENT ORCHESTRATOR — Multi-Agent Pipeline Engine
/// Inspired by Codebuff's multi-agent architecture.
///
/// Flow: User Query → Router → DataFetcher → Analyzer → Reviewer → Response
///
/// Key design principles:
/// 1. Each agent is responsible for ONE thing
/// 2. Agents communicate via structured data (not raw text)
/// 3. Pipeline can be interrupted/short-circuited at any step
/// 4. Full execution trace for debugging & evaluation
/// 5. Stream events for real-time UI updates
/// ============================================================================

/// Callback signature for agent execution
typedef AgentExecutor = Future<Map<String, dynamic>> Function(
  AgentStep step,
  Map<String, dynamic> context,
);

class AgentOrchestrator {
  /// Registered executors for each agent role
  final Map<AgentRole, AgentExecutor> _executors = {};

  /// Event stream controller
  final StreamController<AgentEvent> _eventController =
      StreamController<AgentEvent>.broadcast();

  /// Stream of execution events (for UI)
  Stream<AgentEvent> get events => _eventController.stream;

  // ─── Registration ─────────────────────────────────────────────

  /// Register an executor for a specific agent role
  void registerAgent(AgentRole role, AgentExecutor executor) {
    _executors[role] = executor;
    AppLogger.info('AgentOrchestrator: Registered ${role.name}');
  }

  /// Check if an agent is registered
  bool hasAgent(AgentRole role) => _executors.containsKey(role);

  // ─── Pipeline Execution ───────────────────────────────────────

  /// Execute the full multi-agent pipeline.
  ///
  /// Standard flow:
  /// 1. Router → classify intent
  /// 2. Planner → create execution plan (if complex)
  /// 3. DataFetcher → retrieve data
  /// 4. Analyzer → generate insights
  /// 5. Responder → format output
  /// 6. Reviewer → quality check
  Future<AgentResult> run({
    required String query,
    required String companyId,
    Map<String, dynamic> extraContext = const {},
  }) async {
    final startTime = DateTime.now();
    final trace = <AgentStep>[];
    var pipelineContext = <String, dynamic>{
      'query': query,
      'companyId': companyId,
      ...extraContext,
    };

    _emit(AgentEvent(
      type: AgentEventType.pipelineStarted,
      message: 'Processing: $query',
    ));

    try {
      // ── Step 1: Route ────────────────────────────────────────
      final routerStep = await _executeStep(
        role: AgentRole.router,
        description: 'Classify user intent',
        input: {'query': query},
        context: pipelineContext,
        trace: trace,
      );

      final intent = routerStep.output?['intent'] as String? ?? 'unknown';
      final isComplex = routerStep.output?['isComplex'] as bool? ?? false;
      pipelineContext['intent'] = intent;
      pipelineContext['isComplex'] = isComplex;

      // Short-circuit: unknown intent → direct Gemini
      if (intent == 'unknown' || intent == 'freeform') {
        return _directGeminiResponse(query, pipelineContext, trace, startTime);
      }

      // ── Step 2: Plan (optional, for complex queries) ─────────
      if (isComplex && hasAgent(AgentRole.planner)) {
        final planStep = await _executeStep(
          role: AgentRole.planner,
          description: 'Create execution plan',
          input: {'query': query, 'intent': intent},
          context: pipelineContext,
          trace: trace,
        );
        final plan = planStep.output?['plan'] as List?;
        if (plan != null) pipelineContext['plan'] = plan;
      }

      // ── Step 3: Fetch Data ───────────────────────────────────
      final fetchStep = await _executeStep(
        role: AgentRole.dataFetcher,
        description: 'Fetch business data for: $intent',
        input: {
          'intent': intent,
          'companyId': companyId,
          'query': query,
        },
        context: pipelineContext,
        trace: trace,
      );

      final rawData = fetchStep.output?['data'];
      final localResponse = fetchStep.output?['localResponse'] as String?;
      pipelineContext['rawData'] = rawData;
      pipelineContext['localResponse'] = localResponse;

      // ── Step 4: Analyze ──────────────────────────────────────
      AgentStep? analyzeStep;
      if (hasAgent(AgentRole.analyzer)) {
        analyzeStep = await _executeStep(
          role: AgentRole.analyzer,
          description: 'Analyze data and generate insights',
          input: {
            'query': query,
            'intent': intent,
            'data': rawData,
            'localResponse': localResponse,
          },
          context: pipelineContext,
          trace: trace,
        );
        pipelineContext['analysis'] = analyzeStep.output?['analysis'];
        pipelineContext['insights'] = analyzeStep.output?['insights'];
      }

      // ── Step 5: Format Response ──────────────────────────────
      String response;
      if (hasAgent(AgentRole.responder)) {
        final respondStep = await _executeStep(
          role: AgentRole.responder,
          description: 'Format final response',
          input: {
            'localResponse': localResponse,
            'analysis': pipelineContext['analysis'],
            'insights': pipelineContext['insights'],
          },
          context: pipelineContext,
          trace: trace,
        );
        response = respondStep.output?['response'] as String? ??
            localResponse ??
            '';
      } else {
        // Combine local + AI response
        final analysis = pipelineContext['analysis'] as String?;
        response = localResponse ?? '';
        if (analysis != null && analysis.isNotEmpty) {
          response += '\n\n---\n🧠 **AI Insights:**\n$analysis';
        }
      }

      // ── Step 6: Review ───────────────────────────────────────
      double confidence = 0.85;
      if (hasAgent(AgentRole.reviewer)) {
        final reviewStep = await _executeStep(
          role: AgentRole.reviewer,
          description: 'Quality review',
          input: {
            'response': response,
            'rawData': rawData,
            'intent': intent,
          },
          context: pipelineContext,
          trace: trace,
        );
        confidence =
            (reviewStep.output?['confidence'] as num?)?.toDouble() ?? 0.85;
        final corrected = reviewStep.output?['correctedResponse'] as String?;
        if (corrected != null && corrected.isNotEmpty) {
          response = corrected;
        }
      }

      final totalDuration = DateTime.now().difference(startTime);

      _emit(AgentEvent(
        type: AgentEventType.pipelineCompleted,
        message: 'Done in ${totalDuration.inMilliseconds}ms',
        data: {'confidence': confidence},
      ));

      return AgentResult(
        response: response,
        trace: trace,
        totalDuration: totalDuration,
        success: true,
        confidence: confidence,
        primaryAgent: _mapIntentToRole(intent),
        metadata: {
          'intent': intent,
          'isComplex': isComplex,
          'stepsCount': trace.length,
        },
      );
    } catch (e, stack) {
      AppLogger.error('Agent pipeline error', e, stack);

      _emit(AgentEvent.error(AgentRole.router, 'Pipeline failed: $e'));

      return AgentResult(
        response:
            '⚠️ Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu của bạn.\n'
            'Chi tiết: ${e.toString().substring(0, (e.toString().length).clamp(0, 200))}',
        trace: trace,
        totalDuration: DateTime.now().difference(startTime),
        success: false,
        confidence: 0.0,
        primaryAgent: AgentRole.router,
        metadata: {'error': e.toString()},
      );
    }
  }

  // ─── Internal Helpers ─────────────────────────────────────────

  /// Execute a single agent step with full tracing
  Future<AgentStep> _executeStep({
    required AgentRole role,
    required String description,
    required Map<String, dynamic> input,
    required Map<String, dynamic> context,
    required List<AgentStep> trace,
  }) async {
    final executor = _executors[role];
    var step = AgentStep(
      id: '${role.name}-${trace.length}',
      agent: role,
      description: description,
      startedAt: DateTime.now(),
      input: input,
      status: StepStatus.running,
    );

    _emit(AgentEvent.started(role, description));

    if (executor == null) {
      step = step.copyWith(
        status: StepStatus.skipped,
        completedAt: DateTime.now(),
      );
      trace.add(step);
      return step;
    }

    try {
      final output = await executor(step, context);
      step = step.copyWith(
        status: StepStatus.completed,
        completedAt: DateTime.now(),
        output: output,
        tokenCount: output['_tokenCount'] as int?,
      );

      _emit(AgentEvent.completed(role, description, data: {
        'durationMs': step.duration?.inMilliseconds,
      }));
    } catch (e) {
      step = step.copyWith(
        status: StepStatus.failed,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      _emit(AgentEvent.error(role, 'Failed: $e'));
    }

    trace.add(step);
    return step;
  }

  /// Handle unknown queries → direct to Gemini
  Future<AgentResult> _directGeminiResponse(
    String query,
    Map<String, dynamic> context,
    List<AgentStep> trace,
    DateTime startTime,
  ) async {
    // Try analyzer agent for free-form response
    if (hasAgent(AgentRole.analyzer)) {
      final step = await _executeStep(
        role: AgentRole.analyzer,
        description: 'Free-form AI response',
        input: {'query': query, 'intent': 'freeform'},
        context: context,
        trace: trace,
      );

      return AgentResult(
        response: step.output?['analysis'] as String? ??
            '🤔 Tôi chưa có đủ thông tin để trả lời câu hỏi này.',
        trace: trace,
        totalDuration: DateTime.now().difference(startTime),
        success: step.status == StepStatus.completed,
        confidence: 0.6,
        primaryAgent: AgentRole.analyzer,
        metadata: {'intent': 'freeform'},
      );
    }

    return AgentResult(
      response: '🤔 Tôi chưa hiểu câu hỏi này.',
      trace: trace,
      totalDuration: DateTime.now().difference(startTime),
      success: false,
      confidence: 0.0,
      primaryAgent: AgentRole.router,
    );
  }

  AgentRole _mapIntentToRole(String intent) {
    switch (intent) {
      case 'revenue':
      case 'orders':
      case 'inventory':
      case 'employees':
      case 'delivery':
      case 'debt':
      case 'overview':
        return AgentRole.dataFetcher;
      case 'comparison':
      case 'trend':
        return AgentRole.planner;
      default:
        return AgentRole.analyzer;
    }
  }

  void _emit(AgentEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Clean up resources
  void dispose() {
    _eventController.close();
  }
}
