import 'dart:convert';

/// AI Assistant Model
/// Represents an AI assistant instance for a company
class AIAssistant {
  final String id;
  final String companyId;
  final String? openaiAssistantId;
  final String? openaiThreadId;
  final String name;
  final String? instructions;
  final String model;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIAssistant({
    required this.id,
    required this.companyId,
    this.openaiAssistantId,
    this.openaiThreadId,
    required this.name,
    this.instructions,
    required this.model,
    required this.settings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory AIAssistant.fromJson(Map<String, dynamic> json) {
    // Handle settings field - it might be a JSON string or Map
    Map<String, dynamic> settingsMap = {};
    final settingsField = json['settings'];
    if (settingsField != null) {
      if (settingsField is String) {
        try {
          settingsMap = jsonDecode(settingsField) as Map<String, dynamic>;
        } catch (e) {
          // If JSON parsing fails, keep as empty map
          settingsMap = {};
        }
      } else if (settingsField is Map<String, dynamic>) {
        settingsMap = settingsField;
      }
    }

    return AIAssistant(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      openaiAssistantId: json['openai_assistant_id'] as String?,
      openaiThreadId: json['openai_thread_id'] as String?,
      name: json['name'] as String? ?? 'AI Trợ lý',
      instructions: json['instructions'] as String?,
      model: json['model'] as String? ?? 'gpt-4-turbo-preview',
      settings: settingsMap,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'openai_assistant_id': openaiAssistantId,
      'openai_thread_id': openaiThreadId,
      'name': name,
      'instructions': instructions,
      'model': model,
      'settings': settings,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  AIAssistant copyWith({
    String? id,
    String? companyId,
    String? openaiAssistantId,
    String? openaiThreadId,
    String? name,
    String? instructions,
    String? model,
    Map<String, dynamic>? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIAssistant(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      openaiAssistantId: openaiAssistantId ?? this.openaiAssistantId,
      openaiThreadId: openaiThreadId ?? this.openaiThreadId,
      name: name ?? this.name,
      instructions: instructions ?? this.instructions,
      model: model ?? this.model,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AIAssistant(id: $id, name: $name, companyId: $companyId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIAssistant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
