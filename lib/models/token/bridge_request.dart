/// Bridge request model for tracking withdraw/deposit between
/// off-chain (Supabase) and on-chain (Base L2) SABO Token.
library;

enum BridgeRequestType {
  withdraw,
  deposit;

  String get value => switch (this) {
        withdraw => 'withdraw',
        deposit => 'deposit',
      };

  factory BridgeRequestType.fromString(String value) => switch (value) {
        'withdraw' => BridgeRequestType.withdraw,
        'deposit' => BridgeRequestType.deposit,
        _ => BridgeRequestType.withdraw,
      };

  String get label => switch (this) {
        withdraw => 'Rút lên blockchain',
        deposit => 'Nạp từ blockchain',
      };

  String get icon => switch (this) {
        withdraw => '🔼',
        deposit => '🔽',
      };
}

enum BridgeRequestStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled;

  String get value => switch (this) {
        pending => 'pending',
        processing => 'processing',
        completed => 'completed',
        failed => 'failed',
        cancelled => 'cancelled',
      };

  factory BridgeRequestStatus.fromString(String value) => switch (value) {
        'pending' => BridgeRequestStatus.pending,
        'processing' => BridgeRequestStatus.processing,
        'completed' => BridgeRequestStatus.completed,
        'failed' => BridgeRequestStatus.failed,
        'cancelled' => BridgeRequestStatus.cancelled,
        _ => BridgeRequestStatus.pending,
      };

  String get label => switch (this) {
        pending => 'Chờ xử lý',
        processing => 'Đang xử lý',
        completed => 'Hoàn thành',
        failed => 'Thất bại',
        cancelled => 'Đã hủy',
      };

  bool get isTerminal => this == completed || this == cancelled;
  bool get isSuccess => this == completed;
}

class BridgeRequest {
  final String id;
  final String employeeId;
  final String walletId;
  final BridgeRequestType type;
  final double amount;
  final double feeAmount;
  final double netAmount;
  final String? walletAddress;
  final String? txHash;
  final int? blockNumber;
  final int chainId;
  final BridgeRequestStatus status;
  final String? errorMessage;
  final String? requestId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? businessId;
  final String? branchId;

  const BridgeRequest({
    required this.id,
    required this.employeeId,
    required this.walletId,
    required this.type,
    required this.amount,
    this.feeAmount = 0,
    required this.netAmount,
    this.walletAddress,
    this.txHash,
    this.blockNumber,
    this.chainId = 8453,
    this.status = BridgeRequestStatus.pending,
    this.errorMessage,
    this.requestId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.businessId,
    this.branchId,
  });

  factory BridgeRequest.fromJson(Map<String, dynamic> json) {
    return BridgeRequest(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      walletId: json['wallet_id'] as String,
      type: BridgeRequestType.fromString(json['type'] as String? ?? 'withdraw'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
      walletAddress: json['wallet_address'] as String?,
      txHash: json['tx_hash'] as String?,
      blockNumber: json['block_number'] as int?,
      chainId: json['chain_id'] as int? ?? 8453,
      status: BridgeRequestStatus.fromString(
          json['status'] as String? ?? 'pending'),
      errorMessage: json['error_message'] as String?,
      requestId: json['request_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      businessId: json['business_id'] as String?,
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'wallet_id': walletId,
      'type': type.value,
      'amount': amount,
      'fee_amount': feeAmount,
      'net_amount': netAmount,
      'wallet_address': walletAddress,
      'tx_hash': txHash,
      'block_number': blockNumber,
      'chain_id': chainId,
      'status': status.value,
      'error_message': errorMessage,
      'request_id': requestId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'business_id': businessId,
      'branch_id': branchId,
    };
  }

  BridgeRequest copyWith({
    String? id,
    String? employeeId,
    String? walletId,
    BridgeRequestType? type,
    double? amount,
    double? feeAmount,
    double? netAmount,
    String? walletAddress,
    String? txHash,
    int? blockNumber,
    int? chainId,
    BridgeRequestStatus? status,
    String? errorMessage,
    String? requestId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? businessId,
    String? branchId,
  }) {
    return BridgeRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      feeAmount: feeAmount ?? this.feeAmount,
      netAmount: netAmount ?? this.netAmount,
      walletAddress: walletAddress ?? this.walletAddress,
      txHash: txHash ?? this.txHash,
      blockNumber: blockNumber ?? this.blockNumber,
      chainId: chainId ?? this.chainId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      requestId: requestId ?? this.requestId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
    );
  }

  /// Short tx hash for display: 0x1234...abcd
  String get shortTxHash {
    if (txHash == null || txHash!.length < 12) return txHash ?? '';
    return '${txHash!.substring(0, 6)}...${txHash!.substring(txHash!.length - 4)}';
  }

  /// BaseScan URL
  String get explorerUrl {
    final baseUrl = chainId == 84532
        ? 'https://sepolia.basescan.org'
        : 'https://basescan.org';
    return '$baseUrl/tx/$txHash';
  }

  /// Duration since request was created
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  String toString() =>
      'BridgeRequest(id: $id, type: ${type.value}, amount: $amount, status: ${status.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeRequest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
