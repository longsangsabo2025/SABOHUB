import 'package:flutter/material.dart';

// ─── Referral Status ─────────────────────────────────────────────────────────

enum ReferralStatus {
  pending('pending', 'Đang chờ', Icons.hourglass_empty, Colors.orange),
  accepted('accepted', 'Đã chấp nhận', Icons.check_circle, Colors.green),
  rejected('rejected', 'Đã từ chối', Icons.cancel, Colors.red),
  expired('expired', 'Hết hạn', Icons.timer_off, Colors.grey);

  const ReferralStatus(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  static ReferralStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => pending);
}

// ─── Referral Model ──────────────────────────────────────────────────────────

class Referral {
  final String id;
  final String referrerId;
  final String referrerName;
  final String refereeName;
  final String refereePhone;
  final String refereeEmail;
  final String? position;
  final String? companyId;
  final ReferralStatus status;
  final int rewardAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Referral({
    required this.id,
    required this.referrerId,
    required this.referrerName,
    required this.refereeName,
    required this.refereePhone,
    required this.refereeEmail,
    this.position,
    this.companyId,
    this.status = ReferralStatus.pending,
    this.rewardAmount = 50,
    this.note,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referrerName: json['referrer_name'] as String? ?? '',
      refereeName: json['referee_name'] as String? ?? '',
      refereePhone: json['referee_phone'] as String? ?? '',
      refereeEmail: json['referee_email'] as String? ?? '',
      position: json['position'] as String?,
      companyId: json['company_id'] as String?,
      status: ReferralStatus.fromString(json['status'] as String? ?? 'pending'),
      rewardAmount: (json['reward_amount'] as num?)?.toInt() ?? 50,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referrer_name': referrerName,
      'referee_name': refereeName,
      'referee_phone': refereePhone,
      'referee_email': refereeEmail,
      'position': position,
      'company_id': companyId,
      'status': status.value,
      'reward_amount': rewardAmount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }

  Referral copyWith({
    String? id,
    String? referrerId,
    String? referrerName,
    String? refereeName,
    String? refereePhone,
    String? refereeEmail,
    String? position,
    String? companyId,
    ReferralStatus? status,
    int? rewardAmount,
    String? note,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Referral(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referrerName: referrerName ?? this.referrerName,
      refereeName: refereeName ?? this.refereeName,
      refereePhone: refereePhone ?? this.refereePhone,
      refereeEmail: refereeEmail ?? this.refereeEmail,
      position: position ?? this.position,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Human-readable relative time (Vietnamese)
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
      'Referral(id: $id, referee: $refereeName, status: ${status.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Referral && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Referral Stats ──────────────────────────────────────────────────────────

class ReferralStats {
  final int total;
  final int accepted;
  final int pending;
  final int rejected;
  final int totalRewards;

  const ReferralStats({
    this.total = 0,
    this.accepted = 0,
    this.pending = 0,
    this.rejected = 0,
    this.totalRewards = 0,
  });

  factory ReferralStats.empty() => const ReferralStats();

  @override
  String toString() =>
      'ReferralStats(total: $total, accepted: $accepted, pending: $pending, rewards: $totalRewards)';
}
