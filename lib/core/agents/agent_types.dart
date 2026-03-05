// SABO AGENT FRAMEWORK — Type Definitions
// Inspired by Codebuff's multi-agent architecture (Apache 2.0)
//
// Core types for the agent orchestration system:
// - AgentRole: Defines specialized agent roles
// - AgentStep: A single step in agent execution
// - AgentResult: The final output from an agent run
// - AgentDefinition: Metadata defining an agent's capabilities
// - AgentEvent: Stream events during execution

/// Specialized roles an agent can play
enum AgentRole {
  /// Router: analyzes user intent and routes to specialist agents
  router,

  /// DataFetcher: retrieves data from Supabase/APIs
  dataFetcher,

  /// Analyzer: processes data and generates insights
  analyzer,

  /// Responder: formats final response for the user
  responder,

  /// Reviewer: validates output quality before delivery
  reviewer,

  /// Planner: creates multi-step execution plans
  planner,
}

/// Execution status of an agent step
enum StepStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}

/// A single step in the agent execution pipeline
class AgentStep {
  final String id;
  final AgentRole agent;
  final String description;
  final StepStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> input;
  final Map<String, dynamic>? output;
  final String? error;
  final int? tokenCount;

  const AgentStep({
    required this.id,
    required this.agent,
    required this.description,
    this.status = StepStatus.pending,
    required this.startedAt,
    this.completedAt,
    this.input = const {},
    this.output,
    this.error,
    this.tokenCount,
  });

  AgentStep copyWith({
    StepStatus? status,
    DateTime? completedAt,
    Map<String, dynamic>? output,
    String? error,
    int? tokenCount,
  }) {
    return AgentStep(
      id: id,
      agent: agent,
      description: description,
      status: status ?? this.status,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      input: input,
      output: output ?? this.output,
      error: error ?? this.error,
      tokenCount: tokenCount ?? this.tokenCount,
    );
  }

  Duration? get duration =>
      completedAt?.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'agent': agent.name,
        'description': description,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'durationMs': duration?.inMilliseconds,
        'tokenCount': tokenCount,
        'error': error,
      };
}

/// Final result from an agent pipeline execution
class AgentResult {
  /// The formatted response text
  final String response;

  /// Execution trace — all steps taken
  final List<AgentStep> trace;

  /// Total execution time
  final Duration totalDuration;

  /// Whether the execution completed successfully
  final bool success;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Which specialist agent was primary
  final AgentRole primaryAgent;

  /// Metadata (specialist name, tools used, etc.)
  final Map<String, dynamic> metadata;

  const AgentResult({
    required this.response,
    required this.trace,
    required this.totalDuration,
    this.success = true,
    this.confidence = 1.0,
    required this.primaryAgent,
    this.metadata = const {},
  });

  /// Total tokens used across all steps
  int get totalTokens =>
      trace.fold(0, (sum, step) => sum + (step.tokenCount ?? 0));

  /// Number of steps that completed successfully
  int get completedSteps =>
      trace.where((s) => s.status == StepStatus.completed).length;

  /// Number of failed steps
  int get failedSteps =>
      trace.where((s) => s.status == StepStatus.failed).length;

  Map<String, dynamic> toJson() => {
        'success': success,
        'confidence': confidence,
        'primaryAgent': primaryAgent.name,
        'totalDurationMs': totalDuration.inMilliseconds,
        'totalTokens': totalTokens,
        'completedSteps': completedSteps,
        'failedSteps': failedSteps,
        'trace': trace.map((s) => s.toJson()).toList(),
        'metadata': metadata,
      };
}

/// Definition of an agent's capabilities and configuration
class AgentDefinition {
  /// Unique ID for this agent
  final String id;

  /// Human-readable name
  final String displayName;

  /// What role this agent plays
  final AgentRole role;

  /// LLM model to use (e.g., 'gemini-2.0-flash')
  final String model;

  /// System prompt / instructions for this agent
  final String instructions;

  /// List of tools this agent can use
  final List<String> toolNames;

  /// Sub-agents this agent can spawn
  final List<String> subAgentIds;

  /// Max tokens for context + response
  final int maxTokens;

  /// Temperature (0.0 = deterministic, 1.0 = creative)
  final double temperature;

  const AgentDefinition({
    required this.id,
    required this.displayName,
    required this.role,
    this.model = 'gemini-2.0-flash',
    required this.instructions,
    this.toolNames = const [],
    this.subAgentIds = const [],
    this.maxTokens = 2048,
    this.temperature = 0.3,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'role': role.name,
        'model': model,
        'toolNames': toolNames,
        'subAgentIds': subAgentIds,
        'maxTokens': maxTokens,
        'temperature': temperature,
      };
}

/// Stream events emitted during agent execution
class AgentEvent {
  final AgentEventType type;
  final String message;
  final AgentRole? agent;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  AgentEvent({
    required this.type,
    required this.message,
    this.agent,
    this.data,
  }) : timestamp = DateTime.now();

  factory AgentEvent.started(AgentRole agent, String message) =>
      AgentEvent(type: AgentEventType.agentStarted, message: message, agent: agent);

  factory AgentEvent.completed(AgentRole agent, String message, {Map<String, dynamic>? data}) =>
      AgentEvent(type: AgentEventType.agentCompleted, message: message, agent: agent, data: data);

  factory AgentEvent.error(AgentRole agent, String message) =>
      AgentEvent(type: AgentEventType.error, message: message, agent: agent);

  factory AgentEvent.progress(String message, {Map<String, dynamic>? data}) =>
      AgentEvent(type: AgentEventType.progress, message: message, data: data);
}

enum AgentEventType {
  pipelineStarted,
  agentStarted,
  agentCompleted,
  progress,
  error,
  pipelineCompleted,
}
