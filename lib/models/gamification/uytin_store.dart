class UytinStoreItem {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String category;
  final int cost;
  final String icon;
  final bool isOneTime;
  final int? durationHours;
  final int minLevel;
  final bool isActive;
  final int sortOrder;

  const UytinStoreItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.category,
    required this.cost,
    this.icon = 'star',
    this.isOneTime = true,
    this.durationHours,
    this.minLevel = 1,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory UytinStoreItem.fromJson(Map<String, dynamic> json) {
    return UytinStoreItem(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      cost: json['cost'] as int,
      icon: json['icon'] as String? ?? 'star',
      isOneTime: json['is_one_time'] as bool? ?? true,
      durationHours: json['duration_hours'] as int?,
      minLevel: json['min_level'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  String get iconEmoji {
    const map = {
      'shield': '🛡️', 'bolt': '⚡', 'crown': '👑', 'fire': '🔥',
      'heart': '❤️', 'moon': '🌙', 'diamond': '💎', 'target': '🎯',
      'rocket': '🚀', 'star': '⭐',
    };
    return map[icon] ?? '⭐';
  }

  String get categoryLabel {
    switch (category) {
      case 'perk': return 'Đặc quyền';
      case 'cosmetic': return 'Trang trí';
      case 'boost': return 'Tăng cường';
      case 'unlock': return 'Mở khóa';
      default: return category;
    }
  }
}

class UytinPurchase {
  final String id;
  final String userId;
  final String companyId;
  final String itemId;
  final int cost;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool isActive;

  final UytinStoreItem? item;

  const UytinPurchase({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.itemId,
    required this.cost,
    required this.purchasedAt,
    this.expiresAt,
    this.isActive = true,
    this.item,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory UytinPurchase.fromJson(Map<String, dynamic> json) {
    return UytinPurchase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      cost: json['cost'] as int,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
      item: json['uytin_store_items'] != null
          ? UytinStoreItem.fromJson(json['uytin_store_items'] as Map<String, dynamic>)
          : null,
    );
  }
}
