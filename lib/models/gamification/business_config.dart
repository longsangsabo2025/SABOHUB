class BusinessTypeMapping {
  final String concept;
  final String? tableName;
  final Map<String, dynamic> filter;
  final String displayName;
  final String? displayNamePlural;
  final String icon;
  final Map<String, dynamic> metadata;

  const BusinessTypeMapping({
    required this.concept,
    this.tableName,
    this.filter = const {},
    required this.displayName,
    this.displayNamePlural,
    this.icon = 'star',
    this.metadata = const {},
  });

  int? get threshold => (metadata['threshold'] as num?)?.toInt();
  int? get peakStart => (metadata['start'] as num?)?.toInt();
  int? get peakEnd => (metadata['end'] as num?)?.toInt();

  factory BusinessTypeMapping.fromJson(Map<String, dynamic> json) {
    return BusinessTypeMapping(
      concept: json['concept'] as String,
      tableName: json['table_name'] as String?,
      filter: json['filter'] as Map<String, dynamic>? ?? {},
      displayName: json['display_name'] as String,
      displayNamePlural: json['display_name_plural'] as String?,
      icon: json['icon'] as String? ?? 'star',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class BusinessConfig {
  final String businessType;
  final Map<String, BusinessTypeMapping> mappings;

  const BusinessConfig({required this.businessType, required this.mappings});

  BusinessTypeMapping? operator [](String concept) => mappings[concept];

  String transactionName({String fallback = 'giao dịch'}) =>
      mappings['primary_transaction']?.displayName ?? fallback;

  String inventoryName({String fallback = 'sản phẩm'}) =>
      mappings['inventory_object']?.displayName ?? fallback;

  String customerName({String fallback = 'khách hàng'}) =>
      mappings['customer_object']?.displayName ?? fallback;

  String workspaceName({String fallback = 'cơ sở'}) =>
      mappings['workspace_object']?.displayName ?? fallback;

  int dailyTarget({int fallback = 3}) =>
      mappings['daily_transaction_target']?.threshold ?? fallback;

  factory BusinessConfig.fromList(String businessType, List<BusinessTypeMapping> list) {
    return BusinessConfig(
      businessType: businessType,
      mappings: {for (final m in list) m.concept: m},
    );
  }

  static BusinessConfig empty(String type) => BusinessConfig(businessType: type, mappings: {});
}

class AiGeneratedConfig {
  final String id;
  final String companyId;
  final String businessType;
  final List<Map<String, dynamic>> generatedConfig;
  final List<Map<String, dynamic>> generatedQuests;
  final String aiModel;
  final String status;
  final DateTime createdAt;

  const AiGeneratedConfig({
    required this.id,
    required this.companyId,
    required this.businessType,
    this.generatedConfig = const [],
    this.generatedQuests = const [],
    this.aiModel = 'gemini-2.0-flash',
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApplied => status == 'applied';
  int get configCount => generatedConfig.length;
  int get questCount => generatedQuests.length;

  factory AiGeneratedConfig.fromJson(Map<String, dynamic> json) {
    return AiGeneratedConfig(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      businessType: json['business_type'] as String,
      generatedConfig: (json['generated_config'] as List?)
          ?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      generatedQuests: (json['generated_quests'] as List?)
          ?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      aiModel: json['ai_model'] as String? ?? 'gemini-2.0-flash',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
