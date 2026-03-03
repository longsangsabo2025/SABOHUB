class SkillDefinition {
  final String id;
  final String branch;
  final int tier;
  final String code;
  final String name;
  final String? description;
  final String effectType;
  final Map<String, dynamic> effectValue;
  final String icon;
  final String? prerequisiteCode;

  const SkillDefinition({
    required this.id,
    required this.branch,
    required this.tier,
    required this.code,
    required this.name,
    this.description,
    required this.effectType,
    this.effectValue = const {},
    this.icon = 'star',
    this.prerequisiteCode,
  });

  factory SkillDefinition.fromJson(Map<String, dynamic> json) {
    return SkillDefinition(
      id: json['id'] as String,
      branch: json['branch'] as String,
      tier: json['tier'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      effectType: json['effect_type'] as String,
      effectValue: json['effect_value'] as Map<String, dynamic>? ?? {},
      icon: json['icon'] as String? ?? 'star',
      prerequisiteCode: json['prerequisite_code'] as String?,
    );
  }

  String get branchEmoji {
    switch (branch) {
      case 'leader': return '👥';
      case 'merchant': return '💰';
      case 'strategist': return '📊';
      default: return '⭐';
    }
  }

  String get branchName {
    switch (branch) {
      case 'leader': return 'Leader';
      case 'merchant': return 'Merchant';
      case 'strategist': return 'Strategist';
      default: return branch;
    }
  }

  String get iconEmoji {
    const map = {
      'heart': '❤️', 'star': '⭐', 'shield': '🛡️', 'sword': '⚔️',
      'crown': '👑', 'bolt': '⚡', 'diamond': '💎', 'target': '🎯',
      'fire': '🔥', 'moon': '🌙', 'rocket': '🚀',
    };
    return map[icon] ?? '⭐';
  }
}

class SkillEffect {
  final String effectType;
  final Map<String, dynamic> effectValue;
  final String skillName;

  const SkillEffect({
    required this.effectType,
    this.effectValue = const {},
    required this.skillName,
  });

  factory SkillEffect.fromJson(Map<String, dynamic> json) {
    return SkillEffect(
      effectType: json['effect_type'] as String,
      effectValue: json['effect_value'] as Map<String, dynamic>? ?? {},
      skillName: json['skill_name'] as String,
    );
  }
}
