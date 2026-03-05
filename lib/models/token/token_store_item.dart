import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Store Category ──────────────────────────────────────────────────────────

enum TokenStoreCategory {
  perk,
  cosmetic,
  boost,
  voucher,
  physical,
  digital,
  nft;

  String get value => switch (this) {
        perk => 'perk',
        cosmetic => 'cosmetic',
        boost => 'boost',
        voucher => 'voucher',
        physical => 'physical',
        digital => 'digital',
        nft => 'nft',
      };

  factory TokenStoreCategory.fromString(String value) {
    return switch (value) {
      'perk' => TokenStoreCategory.perk,
      'cosmetic' => TokenStoreCategory.cosmetic,
      'boost' => TokenStoreCategory.boost,
      'voucher' => TokenStoreCategory.voucher,
      'physical' => TokenStoreCategory.physical,
      'digital' => TokenStoreCategory.digital,
      'nft' => TokenStoreCategory.nft,
      _ => TokenStoreCategory.perk,
    };
  }

  String get label => switch (this) {
        perk => 'Đặc quyền',
        cosmetic => 'Trang trí',
        boost => 'Tăng cường',
        voucher => 'Phiếu giảm giá',
        physical => 'Vật phẩm',
        digital => 'Kỹ thuật số',
        nft => 'NFT',
      };

  String get icon => switch (this) {
        perk => '⭐',
        cosmetic => '🎨',
        boost => '🚀',
        voucher => '🎫',
        physical => '📦',
        digital => '💎',
        nft => '🖼️',
      };

  Color get color => switch (this) {
        perk => Color(0xFFFFD700),
        cosmetic => Color(0xFFE91E63),
        boost => Color(0xFFFF5722),
        voucher => AppColors.success,
        physical => Color(0xFF795548),
        digital => AppColors.info,
        nft => Color(0xFF9C27B0),
      };
}

// ─── Token Store Item ────────────────────────────────────────────────────────

class TokenStoreItem {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final TokenStoreCategory category;
  final double tokenCost;
  final String icon;
  final String? imageUrl;
  final int? stock; // null = unlimited
  final int? maxPerUser;
  final int minLevel;
  final bool isOneTime;
  final int? durationHours;
  final bool isActive;
  final int sortOrder;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const TokenStoreItem({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.category,
    required this.tokenCost,
    this.icon = '🎁',
    this.imageUrl,
    this.stock,
    this.maxPerUser,
    this.minLevel = 1,
    this.isOneTime = false,
    this.durationHours,
    this.isActive = true,
    this.sortOrder = 0,
    this.metadata,
    required this.createdAt,
  });

  factory TokenStoreItem.fromJson(Map<String, dynamic> json) {
    return TokenStoreItem(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: TokenStoreCategory.fromString(
          json['category'] as String? ?? 'perk'),
      tokenCost: (json['token_cost'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? '🎁',
      imageUrl: json['image_url'] as String?,
      stock: json['stock'] as int?,
      maxPerUser: json['max_per_user'] as int?,
      minLevel: json['min_level'] as int? ?? 1,
      isOneTime: json['is_one_time'] as bool? ?? false,
      durationHours: json['duration_hours'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'description': description,
      'category': category.value,
      'token_cost': tokenCost,
      'icon': icon,
      'image_url': imageUrl,
      'stock': stock,
      'max_per_user': maxPerUser,
      'min_level': minLevel,
      'is_one_time': isOneTime,
      'duration_hours': durationHours,
      'is_active': isActive,
      'sort_order': sortOrder,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether stock is unlimited (stock == null)
  bool get isUnlimited => stock == null;

  /// Emoji icon for display
  String get iconEmoji => icon.isNotEmpty ? icon : category.icon;

  /// Cost formatted with comma separators (e.g. "1,500")
  String get formattedCost {
    return NumberFormat('#,##0').format(tokenCost.toInt());
  }

  @override
  String toString() =>
      'TokenStoreItem(id: $id, name: $name, cost: $tokenCost)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenStoreItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Token Purchase ──────────────────────────────────────────────────────────

class TokenPurchase {
  final String id;
  final String walletId;
  final String companyId;
  final String itemId;
  final double tokenCost;
  final String status; // active, used, expired, refunded
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final Map<String, dynamic>? metadata;

  /// Joined store item data
  final TokenStoreItem? item;

  const TokenPurchase({
    required this.id,
    required this.walletId,
    required this.companyId,
    required this.itemId,
    required this.tokenCost,
    this.status = 'active',
    required this.purchasedAt,
    this.expiresAt,
    this.usedAt,
    this.metadata,
    this.item,
  });

  factory TokenPurchase.fromJson(Map<String, dynamic> json) {
    return TokenPurchase(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      tokenCost: (json['token_cost'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'active',
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      item: json['item'] != null
          ? TokenStoreItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'company_id': companyId,
      'item_id': itemId,
      'token_cost': tokenCost,
      'status': status,
      'purchased_at': purchasedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Whether the purchase has passed its expiration date
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Whether the purchase is currently active and usable
  bool get isActive => status == 'active' && !isExpired;

  @override
  String toString() =>
      'TokenPurchase(id: $id, item: $itemId, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPurchase &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
