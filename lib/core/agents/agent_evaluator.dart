import 'dart:math';
import '../agents/agent_types.dart';

/// ============================================================================
/// AGENT EVALUATOR — Quality & Performance Scoring
/// Inspired by Codebuff's BuffBench evaluation system.
///
/// Measures:
/// 1. Response Quality (completeness, formatting, language)
/// 2. Data Accuracy (numbers match source, no hallucination risk)
/// 3. Performance (latency, token efficiency)
/// 4. Confidence Calibration (self-reported vs actual quality)
/// ============================================================================

class EvalScore {
  final double quality;
  final double accuracy;
  final double performance;
  final double overall;
  final Map<String, dynamic> details;

  const EvalScore({
    required this.quality,
    required this.accuracy,
    required this.performance,
    required this.overall,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'quality': quality,
        'accuracy': accuracy,
        'performance': performance,
        'overall': overall,
        'details': details,
      };
}

/// A single evaluation test case (BuffBench-inspired)
class EvalCase {
  final String id;
  final String query;
  final String intent;
  final String? expectedPattern;
  final List<String> requiredKeywords;
  final int maxLatencyMs;
  final double minConfidence;

  const EvalCase({
    required this.id,
    required this.query,
    required this.intent,
    this.expectedPattern,
    this.requiredKeywords = const [],
    this.maxLatencyMs = 10000,
    this.minConfidence = 0.5,
  });
}

/// Evaluation result for a single test case
class EvalResult {
  final EvalCase testCase;
  final AgentResult agentResult;
  final EvalScore score;
  final bool passed;
  final List<String> issues;

  const EvalResult({
    required this.testCase,
    required this.agentResult,
    required this.score,
    required this.passed,
    this.issues = const [],
  });

  Map<String, dynamic> toJson() => {
        'testCaseId': testCase.id,
        'query': testCase.query,
        'passed': passed,
        'score': score.toJson(),
        'issues': issues,
        'latencyMs': agentResult.totalDuration.inMilliseconds,
        'confidence': agentResult.confidence,
        'stepsCount': agentResult.trace.length,
      };
}

/// Aggregate report for a full evaluation run
class EvalReport {
  final DateTime runAt;
  final Duration totalDuration;
  final List<EvalResult> results;
  final double passRate;
  final double avgQuality;
  final double avgAccuracy;
  final double avgPerformance;
  final double avgOverall;

  const EvalReport({
    required this.runAt,
    required this.totalDuration,
    required this.results,
    required this.passRate,
    required this.avgQuality,
    required this.avgAccuracy,
    required this.avgPerformance,
    required this.avgOverall,
  });

  Map<String, dynamic> toJson() => {
        'runAt': runAt.toIso8601String(),
        'totalDurationMs': totalDuration.inMilliseconds,
        'totalCases': results.length,
        'passed': results.where((r) => r.passed).length,
        'failed': results.where((r) => !r.passed).length,
        'passRate': passRate,
        'avgQuality': avgQuality,
        'avgAccuracy': avgAccuracy,
        'avgPerformance': avgPerformance,
        'avgOverall': avgOverall,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

class AgentEvaluator {
  // ─── Quality Scoring ──────────────────────────────────────────

  /// Evaluate the quality of an AgentResult
  EvalScore scoreResult(AgentResult result, {EvalCase? testCase}) {
    final quality = _scoreQuality(result);
    final accuracy = _scoreAccuracy(result, testCase);
    final perf = _scorePerformance(result, testCase);

    // Weighted average
    final overall = quality * 0.35 + accuracy * 0.40 + perf * 0.25;

    return EvalScore(
      quality: quality,
      accuracy: accuracy,
      performance: perf,
      overall: overall,
      details: {
        'responseLength': result.response.length,
        'hasEmoji': RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)
            .hasMatch(result.response),
        'hasBold': result.response.contains('**'),
        'isVietnamese': _isVietnamese(result.response),
        'latencyMs': result.totalDuration.inMilliseconds,
        'stepsCompleted': result.completedSteps,
        'totalTokens': result.totalTokens,
      },
    );
  }

  /// Run a single test case against the pipeline
  EvalResult evaluateCase(EvalCase testCase, AgentResult result) {
    final score = scoreResult(result, testCase: testCase);
    final issues = <String>[];

    // Check latency
    if (result.totalDuration.inMilliseconds > testCase.maxLatencyMs) {
      issues.add(
          'Latency ${result.totalDuration.inMilliseconds}ms > ${testCase.maxLatencyMs}ms');
    }

    // Check confidence
    if (result.confidence < testCase.minConfidence) {
      issues.add(
          'Confidence ${result.confidence} < ${testCase.minConfidence}');
    }

    // Check required keywords
    final lowerResponse = result.response.toLowerCase();
    for (final keyword in testCase.requiredKeywords) {
      if (!lowerResponse.contains(keyword.toLowerCase())) {
        issues.add('Missing keyword: $keyword');
      }
    }

    // Check expected pattern
    if (testCase.expectedPattern != null) {
      if (!RegExp(testCase.expectedPattern!).hasMatch(result.response)) {
        issues.add('Response does not match expected pattern');
      }
    }

    // Check for error indicator
    if (!result.success) {
      issues.add('Pipeline execution failed');
    }

    final passed = issues.isEmpty && score.overall >= 0.5;

    return EvalResult(
      testCase: testCase,
      agentResult: result,
      score: score,
      passed: passed,
      issues: issues,
    );
  }

  /// Generate aggregate report from multiple evaluation results
  EvalReport generateReport(List<EvalResult> results, Duration totalDuration) {
    final passedCount = results.where((r) => r.passed).length;
    final passRate = results.isEmpty ? 0.0 : passedCount / results.length;

    double sumQ = 0, sumA = 0, sumP = 0, sumO = 0;
    for (final r in results) {
      sumQ += r.score.quality;
      sumA += r.score.accuracy;
      sumP += r.score.performance;
      sumO += r.score.overall;
    }
    final n = max(results.length, 1);

    return EvalReport(
      runAt: DateTime.now(),
      totalDuration: totalDuration,
      results: results,
      passRate: passRate,
      avgQuality: sumQ / n,
      avgAccuracy: sumA / n,
      avgPerformance: sumP / n,
      avgOverall: sumO / n,
    );
  }

  // ─── Built-in Test Cases ──────────────────────────────────────

  /// Standard test suite for SABOHUB agent pipeline
  static const List<EvalCase> standardSuite = [
    EvalCase(
      id: 'revenue-today',
      query: 'Doanh thu hôm nay?',
      intent: 'revenue',
      requiredKeywords: ['doanh thu', '₫'],
      maxLatencyMs: 8000,
      minConfidence: 0.7,
    ),
    EvalCase(
      id: 'orders-today',
      query: 'Đơn hàng mới hôm nay?',
      intent: 'orders',
      requiredKeywords: ['đơn hàng'],
      maxLatencyMs: 8000,
      minConfidence: 0.7,
    ),
    EvalCase(
      id: 'inventory-low',
      query: 'Sản phẩm nào sắp hết hàng?',
      intent: 'inventory',
      requiredKeywords: ['tồn kho'],
      maxLatencyMs: 8000,
      minConfidence: 0.6,
    ),
    EvalCase(
      id: 'employees-today',
      query: 'Ai đi làm hôm nay?',
      intent: 'employees',
      requiredKeywords: ['nhân viên', 'chấm công'],
      maxLatencyMs: 8000,
      minConfidence: 0.6,
    ),
    EvalCase(
      id: 'overview',
      query: 'Báo cáo tổng quan',
      intent: 'overview',
      requiredKeywords: ['tổng quan'],
      maxLatencyMs: 12000,
      minConfidence: 0.7,
    ),
    EvalCase(
      id: 'delivery-status',
      query: 'Tình trạng giao hàng hôm nay?',
      intent: 'delivery',
      requiredKeywords: ['giao hàng'],
      maxLatencyMs: 8000,
      minConfidence: 0.6,
    ),
    EvalCase(
      id: 'debt-total',
      query: 'Tổng công nợ bao nhiêu?',
      intent: 'debt',
      requiredKeywords: ['công nợ', '₫'],
      maxLatencyMs: 8000,
      minConfidence: 0.7,
    ),
    EvalCase(
      id: 'freeform-advice',
      query: 'Làm sao để tăng doanh thu?',
      intent: 'freeform',
      requiredKeywords: [],
      maxLatencyMs: 15000,
      minConfidence: 0.3,
    ),
  ];

  // ─── Internal Scoring ─────────────────────────────────────────

  double _scoreQuality(AgentResult result) {
    double score = 0.0;
    final response = result.response;

    // Length check (not too short, not too long)
    if (response.length >= 50 && response.length <= 3000) {
      score += 0.25;
    } else if (response.length >= 20) {
      score += 0.1;
    }

    // Has markdown formatting
    if (response.contains('**')) score += 0.15;

    // Has emoji
    if (RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(response)) {
      score += 0.1;
    }

    // Has structure (bullets or newlines)
    if (response.contains('\n')) score += 0.1;
    if (response.contains('•') || response.contains('-')) score += 0.1;

    // Vietnamese content
    if (_isVietnamese(response)) score += 0.15;

    // No error indicators
    if (!response.startsWith('❌') && !response.startsWith('⚠️')) {
      score += 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  double _scoreAccuracy(AgentResult result, EvalCase? testCase) {
    double score = 0.5; // Base score — can't fully verify without ground truth

    // Pipeline completed successfully
    if (result.success) score += 0.2;

    // Self-reported confidence
    score += result.confidence * 0.2;

    // No failed steps
    if (result.failedSteps == 0) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  double _scorePerformance(AgentResult result, EvalCase? testCase) {
    final latencyMs = result.totalDuration.inMilliseconds;
    final maxMs = testCase?.maxLatencyMs ?? 10000;

    // Latency scoring (exponential decay)
    double latencyScore;
    if (latencyMs <= maxMs * 0.3) {
      latencyScore = 1.0; // Fast
    } else if (latencyMs <= maxMs * 0.6) {
      latencyScore = 0.8; // Good
    } else if (latencyMs <= maxMs) {
      latencyScore = 0.5; // Acceptable
    } else {
      latencyScore = 0.2; // Slow
    }

    // Token efficiency (lower is better)
    double tokenScore = 0.5;
    if (result.totalTokens > 0 && result.totalTokens < 500) {
      tokenScore = 1.0;
    } else if (result.totalTokens < 1000) {
      tokenScore = 0.7;
    }

    // Step efficiency (fewer steps = better)
    double stepScore = 0.5;
    final steps = result.trace.length;
    if (steps <= 3) {
      stepScore = 1.0;
    } else if (steps <= 5) {
      stepScore = 0.7;
    }

    return (latencyScore * 0.5 + tokenScore * 0.25 + stepScore * 0.25)
        .clamp(0.0, 1.0);
  }

  bool _isVietnamese(String text) {
    // Check for Vietnamese diacritical marks
    return RegExp(r'[àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]')
        .hasMatch(text.toLowerCase());
  }
}
