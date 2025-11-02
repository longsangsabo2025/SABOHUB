/// AI Usage Analytics Model
/// Tracks AI usage and costs for a company
class AIUsageAnalytics {
  final String id;
  final String companyId;
  final String assistantId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalMessages;
  final int userMessages;
  final int assistantMessages;
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final int totalTokens;
  final double totalCost; // in USD
  final double estimatedCostVnd; // in VND
  final int filesUploaded;
  final int imagesAnalyzed;
  final int recommendationsGenerated;
  final Map<String, dynamic> breakdown; // Cost breakdown by feature
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIUsageAnalytics({
    required this.id,
    required this.companyId,
    required this.assistantId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalMessages,
    required this.userMessages,
    required this.assistantMessages,
    required this.totalPromptTokens,
    required this.totalCompletionTokens,
    required this.totalTokens,
    required this.totalCost,
    required this.estimatedCostVnd,
    required this.filesUploaded,
    required this.imagesAnalyzed,
    required this.recommendationsGenerated,
    required this.breakdown,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory AIUsageAnalytics.fromJson(Map<String, dynamic> json) {
    return AIUsageAnalytics(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      assistantId: json['assistant_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalMessages: json['total_messages'] as int? ?? 0,
      userMessages: json['user_messages'] as int? ?? 0,
      assistantMessages: json['assistant_messages'] as int? ?? 0,
      totalPromptTokens: json['total_prompt_tokens'] as int? ?? 0,
      totalCompletionTokens: json['total_completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      estimatedCostVnd: (json['estimated_cost_vnd'] as num?)?.toDouble() ?? 0.0,
      filesUploaded: json['files_uploaded'] as int? ?? 0,
      imagesAnalyzed: json['images_analyzed'] as int? ?? 0,
      recommendationsGenerated: json['recommendations_generated'] as int? ?? 0,
      breakdown: json['breakdown'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'assistant_id': assistantId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_messages': totalMessages,
      'user_messages': userMessages,
      'assistant_messages': assistantMessages,
      'total_prompt_tokens': totalPromptTokens,
      'total_completion_tokens': totalCompletionTokens,
      'total_tokens': totalTokens,
      'total_cost': totalCost,
      'estimated_cost_vnd': estimatedCostVnd,
      'files_uploaded': filesUploaded,
      'images_analyzed': imagesAnalyzed,
      'recommendations_generated': recommendationsGenerated,
      'breakdown': breakdown,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get period duration in days
  int get periodDays => periodEnd.difference(periodStart).inDays + 1;

  /// Get average messages per day
  double get avgMessagesPerDay =>
      periodDays > 0 ? totalMessages / periodDays : 0;

  /// Get average cost per message
  double get avgCostPerMessage =>
      totalMessages > 0 ? totalCost / totalMessages : 0;

  /// Get average cost per day
  double get avgCostPerDay => periodDays > 0 ? totalCost / periodDays : 0;

  /// Get cost formatted in USD
  String get costUsdFormatted => '\$${totalCost.toStringAsFixed(2)}';

  /// Get cost formatted in VND
  String get costVndFormatted {
    if (estimatedCostVnd >= 1000000) {
      return '${(estimatedCostVnd / 1000000).toStringAsFixed(1)}M ₫';
    } else if (estimatedCostVnd >= 1000) {
      return '${(estimatedCostVnd / 1000).toStringAsFixed(0)}K ₫';
    } else {
      return '${estimatedCostVnd.toStringAsFixed(0)} ₫';
    }
  }

  /// Get total tokens formatted
  String get tokensFormatted {
    if (totalTokens >= 1000000) {
      return '${(totalTokens / 1000000).toStringAsFixed(1)}M';
    } else if (totalTokens >= 1000) {
      return '${(totalTokens / 1000).toStringAsFixed(0)}K';
    } else {
      return totalTokens.toString();
    }
  }

  /// Get period label
  String get periodLabel {
    final formatter =
        (DateTime date) => '${date.day}/${date.month}/${date.year}';
    return '${formatter(periodStart)} - ${formatter(periodEnd)}';
  }

  /// Check if period is current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return periodStart.year == now.year && periodStart.month == now.month;
  }

  /// Get breakdown by category
  double getBreakdownCost(String category) {
    return (breakdown[category] as num?)?.toDouble() ?? 0.0;
  }

  /// Get all categories in breakdown
  List<String> get breakdownCategories => breakdown.keys.toList();

  /// Get usage summary
  String get usageSummary {
    return '$totalMessages tin nhắn • $filesUploaded tệp • $recommendationsGenerated đề xuất';
  }

  AIUsageAnalytics copyWith({
    String? id,
    String? companyId,
    String? assistantId,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? totalMessages,
    int? userMessages,
    int? assistantMessages,
    int? totalPromptTokens,
    int? totalCompletionTokens,
    int? totalTokens,
    double? totalCost,
    double? estimatedCostVnd,
    int? filesUploaded,
    int? imagesAnalyzed,
    int? recommendationsGenerated,
    Map<String, dynamic>? breakdown,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIUsageAnalytics(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      assistantId: assistantId ?? this.assistantId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      totalMessages: totalMessages ?? this.totalMessages,
      userMessages: userMessages ?? this.userMessages,
      assistantMessages: assistantMessages ?? this.assistantMessages,
      totalPromptTokens: totalPromptTokens ?? this.totalPromptTokens,
      totalCompletionTokens:
          totalCompletionTokens ?? this.totalCompletionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      totalCost: totalCost ?? this.totalCost,
      estimatedCostVnd: estimatedCostVnd ?? this.estimatedCostVnd,
      filesUploaded: filesUploaded ?? this.filesUploaded,
      imagesAnalyzed: imagesAnalyzed ?? this.imagesAnalyzed,
      recommendationsGenerated:
          recommendationsGenerated ?? this.recommendationsGenerated,
      breakdown: breakdown ?? this.breakdown,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AIUsageAnalytics(id: $id, period: $periodLabel, cost: $costUsdFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIUsageAnalytics && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
