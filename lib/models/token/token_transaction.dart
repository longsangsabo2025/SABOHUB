import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ─── Transaction Type ────────────────────────────────────────────────────────

enum TokenTransactionType {
  earn,
  spend,
  transferIn,
  transferOut,
  withdraw,
  deposit,
  reward,
  penalty;

  String get value => switch (this) {
        earn => 'earn',
        spend => 'spend',
        transferIn => 'transfer_in',
        transferOut => 'transfer_out',
        withdraw => 'withdraw',
        deposit => 'deposit',
        reward => 'reward',
        penalty => 'penalty',
      };

  factory TokenTransactionType.fromString(String value) {
    return switch (value) {
      'earn' => TokenTransactionType.earn,
      'spend' => TokenTransactionType.spend,
      'transfer_in' => TokenTransactionType.transferIn,
      'transfer_out' => TokenTransactionType.transferOut,
      'withdraw' => TokenTransactionType.withdraw,
      'deposit' => TokenTransactionType.deposit,
      'reward' => TokenTransactionType.reward,
      'penalty' => TokenTransactionType.penalty,
      _ => TokenTransactionType.earn,
    };
  }

  String get label => switch (this) {
        earn => 'Nhận token',
        spend => 'Chi tiêu',
        transferIn => 'Nhận chuyển',
        transferOut => 'Chuyển đi',
        withdraw => 'Rút token',
        deposit => 'Nạp token',
        reward => 'Phần thưởng',
        penalty => 'Phạt',
      };

  String get icon => switch (this) {
        earn => '💰',
        spend => '🛒',
        transferIn => '📥',
        transferOut => '📤',
        withdraw => '🏧',
        deposit => '💳',
        reward => '🎁',
        penalty => '⚠️',
      };

  bool get isPositive => switch (this) {
        earn || transferIn || deposit || reward => true,
        spend || transferOut || withdraw || penalty => false,
      };

  Color get color => switch (this) {
        earn => AppColors.success,
        spend => AppColors.warning,
        transferIn => AppColors.info,
        transferOut => Color(0xFF9C27B0),
        withdraw => Color(0xFF607D8B),
        deposit => Color(0xFF00BCD4),
        reward => Color(0xFFFFD700),
        penalty => AppColors.error,
      };
}

// ─── Source Type ──────────────────────────────────────────────────────────────

enum TokenSourceType {
  quest,
  achievement,
  attendance,
  task,
  bonus,
  purchase,
  transfer,
  manual,
  system,
  seasonReward,
  referral;

  String get value => switch (this) {
        quest => 'quest',
        achievement => 'achievement',
        attendance => 'attendance',
        task => 'task',
        bonus => 'bonus',
        purchase => 'purchase',
        transfer => 'transfer',
        manual => 'manual',
        system => 'system',
        seasonReward => 'season_reward',
        referral => 'referral',
      };

  factory TokenSourceType.fromString(String value) {
    return switch (value) {
      'quest' => TokenSourceType.quest,
      'achievement' => TokenSourceType.achievement,
      'attendance' => TokenSourceType.attendance,
      'task' => TokenSourceType.task,
      'bonus' => TokenSourceType.bonus,
      'purchase' => TokenSourceType.purchase,
      'transfer' => TokenSourceType.transfer,
      'manual' => TokenSourceType.manual,
      'system' => TokenSourceType.system,
      'season_reward' => TokenSourceType.seasonReward,
      'referral' => TokenSourceType.referral,
      _ => TokenSourceType.system,
    };
  }

  String get label => switch (this) {
        quest => 'Nhiệm vụ',
        achievement => 'Thành tích',
        attendance => 'Chấm công',
        task => 'Công việc',
        bonus => 'Thưởng',
        purchase => 'Mua hàng',
        transfer => 'Chuyển khoản',
        manual => 'Thủ công',
        system => 'Hệ thống',
        seasonReward => 'Thưởng mùa',
        referral => 'Giới thiệu',
      };
}

// ─── Token Transaction ───────────────────────────────────────────────────────

class TokenTransaction {
  final String id;
  final String walletId;
  final String companyId;
  final TokenTransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final TokenSourceType? sourceType;
  final String? sourceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const TokenTransaction({
    required this.id,
    required this.walletId,
    required this.companyId,
    required this.type,
    required this.amount,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.sourceType,
    this.sourceId,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    return TokenTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      companyId: json['company_id'] as String,
      type: TokenTransactionType.fromString(json['type'] as String? ?? 'earn'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      sourceType: json['source_type'] != null
          ? TokenSourceType.fromString(json['source_type'] as String)
          : null,
      sourceId: json['source_id'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'company_id': companyId,
      'type': type.value,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'source_type': sourceType?.value,
      'source_id': sourceId,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Amount formatted with +/- prefix (e.g. "+100", "-50")
  String get formattedAmount {
    final prefix = type.isPositive ? '+' : '-';
    return '$prefix${amount.toInt()}';
  }

  /// Human-readable relative time (e.g. "3 phút trước", "2 giờ trước")
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }

  @override
  String toString() =>
      'TokenTransaction(id: $id, type: ${type.value}, amount: $formattedAmount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
