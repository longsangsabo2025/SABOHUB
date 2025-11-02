/// AI Recommendation Model
/// Represents an AI-generated recommendation for a company
class AIRecommendation {
  final String id;
  final String assistantId;
  final String companyId;
  final String
      category; // 'feature', 'process', 'growth', 'technology', 'finance', 'operations'
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final double? confidence; // 0.00 to 1.00
  final String? reasoning;
  final String? implementationPlan;
  final String? estimatedEffort; // 'low', 'medium', 'high'
  final String? expectedImpact;
  final String
      status; // 'pending', 'reviewing', 'accepted', 'rejected', 'implemented'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIRecommendation({
    required this.id,
    required this.assistantId,
    required this.companyId,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    this.confidence,
    this.reasoning,
    this.implementationPlan,
    this.estimatedEffort,
    this.expectedImpact,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'] as String,
      assistantId: json['assistant_id'] as String,
      companyId: json['company_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble(),
      reasoning: json['reasoning'] as String?,
      implementationPlan: json['implementation_plan'] as String?,
      estimatedEffort: json['estimated_effort'] as String?,
      expectedImpact: json['expected_impact'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistant_id': assistantId,
      'company_id': companyId,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'confidence': confidence,
      'reasoning': reasoning,
      'implementation_plan': implementationPlan,
      'estimated_effort': estimatedEffort,
      'expected_impact': expectedImpact,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get category display name in Vietnamese
  String get categoryLabel {
    switch (category) {
      case 'feature':
        return 'Tính năng';
      case 'process':
        return 'Quy trình';
      case 'growth':
        return 'Phát triển';
      case 'technology':
        return 'Công nghệ';
      case 'finance':
        return 'Tài chính';
      case 'operations':
        return 'Vận hành';
      default:
        return category;
    }
  }

  /// Get priority display name in Vietnamese
  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      case 'critical':
        return 'Khẩn cấp';
      default:
        return priority;
    }
  }

  /// Get status display name in Vietnamese
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'reviewing':
        return 'Đang xem xét';
      case 'accepted':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Đã từ chối';
      case 'implemented':
        return 'Đã triển khai';
      default:
        return status;
    }
  }

  /// Get effort display name in Vietnamese
  String? get effortLabel {
    if (estimatedEffort == null) return null;
    switch (estimatedEffort) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return estimatedEffort;
    }
  }

  /// Get confidence percentage
  String get confidencePercentage {
    if (confidence == null) return 'N/A';
    return '${(confidence! * 100).toInt()}%';
  }

  /// Check if recommendation is pending review
  bool get isPending => status == 'pending';

  /// Check if recommendation is accepted
  bool get isAccepted => status == 'accepted';

  /// Check if recommendation is rejected
  bool get isRejected => status == 'rejected';

  /// Check if recommendation is implemented
  bool get isImplemented => status == 'implemented';

  AIRecommendation copyWith({
    String? id,
    String? assistantId,
    String? companyId,
    String? category,
    String? title,
    String? description,
    String? priority,
    double? confidence,
    String? reasoning,
    String? implementationPlan,
    String? estimatedEffort,
    String? expectedImpact,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      assistantId: assistantId ?? this.assistantId,
      companyId: companyId ?? this.companyId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      reasoning: reasoning ?? this.reasoning,
      implementationPlan: implementationPlan ?? this.implementationPlan,
      estimatedEffort: estimatedEffort ?? this.estimatedEffort,
      expectedImpact: expectedImpact ?? this.expectedImpact,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AIRecommendation(id: $id, title: $title, priority: $priority, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIRecommendation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
