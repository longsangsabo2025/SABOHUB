/// Rarity tiers matching on-chain SABOAchievement contract
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  String get label => switch (this) {
        common => 'Common',
        rare => 'Rare',
        epic => 'Epic',
        legendary => 'Legendary',
        mythic => 'Mythic',
      };

  String get emoji => switch (this) {
        common => '🟢',
        rare => '🔵',
        epic => '🟣',
        legendary => '🟡',
        mythic => '🔴',
      };

  int get colorValue => switch (this) {
        common => 0xFF4CAF50,
        rare => 0xFF2196F3,
        epic => 0xFF9C27B0,
        legendary => 0xFFFF9800,
        mythic => 0xFFF44336,
      };

  static AchievementRarity fromIndex(int index) =>
      AchievementRarity.values[index.clamp(0, 4)];
}

/// An achievement type defined on-chain
class AchievementType {
  final int typeId;
  final String name;
  final AchievementRarity rarity;
  final String metadataURI;
  final int maxSupply; // 0 = unlimited
  final int minted;
  final bool active;

  const AchievementType({
    required this.typeId,
    required this.name,
    required this.rarity,
    required this.metadataURI,
    required this.maxSupply,
    required this.minted,
    required this.active,
  });

  bool get isUnlimited => maxSupply == 0;
  String get supplyText =>
      isUnlimited ? '∞' : '$minted / $maxSupply';
}

/// An achievement NFT owned by a user
class NftAchievement {
  final int tokenId;
  final int typeId;
  final String name;
  final AchievementRarity rarity;
  final DateTime mintedAt;
  final String originalOwner;
  final String tokenURI;

  const NftAchievement({
    required this.tokenId,
    required this.typeId,
    required this.name,
    required this.rarity,
    required this.mintedAt,
    required this.originalOwner,
    required this.tokenURI,
  });
}

/// Summary of a user's NFT achievement collection
class AchievementSummary {
  final int total;
  final int common;
  final int rare;
  final int epic;
  final int legendary;
  final int mythic;
  final List<NftAchievement> achievements;

  const AchievementSummary({
    this.total = 0,
    this.common = 0,
    this.rare = 0,
    this.epic = 0,
    this.legendary = 0,
    this.mythic = 0,
    this.achievements = const [],
  });

  double get completionPercent =>
      achievements.isEmpty ? 0 : (total / 10 * 100).clamp(0, 100);
}
