import '../../core/config/blockchain_config.dart';
import '../../core/services/base_service.dart';
import '../../models/token/token_models.dart';
import 'blockchain_service.dart';

// ──────────────────────────────────────────────
// Rewards Config Model
// ──────────────────────────────────────────────

class TokenRewardsConfig {
  final String id;
  final String companyId;
  final String eventType;
  final double tokenAmount;
  final double multiplier;
  final bool isActive;

  const TokenRewardsConfig({
    required this.id,
    required this.companyId,
    required this.eventType,
    this.tokenAmount = 0,
    this.multiplier = 1.0,
    this.isActive = true,
  });

  factory TokenRewardsConfig.fromJson(Map<String, dynamic> json) {
    return TokenRewardsConfig(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      eventType: json['event_type'] as String,
      tokenAmount: (json['token_amount'] as num?)?.toDouble() ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'event_type': eventType,
      'token_amount': tokenAmount,
      'multiplier': multiplier,
      'is_active': isActive,
    };
  }

  @override
  String toString() =>
      'TokenRewardsConfig(event: $eventType, amount: $tokenAmount)';
}

// ──────────────────────────────────────────────
// Token Service
// ──────────────────────────────────────────────

class TokenService extends BaseService {
  @override
  String get serviceName => 'TokenService';

  // ──────────────────────────────────────────────
  // Wallet
  // ──────────────────────────────────────────────

  Future<TokenWallet?> getWallet(String employeeId, String companyId) async {
    return safeCall(
      operation: 'getWallet',
      action: () async {
        final response = await client
            .from('token_wallets')
            .select()
            .eq('employee_id', employeeId)
            .eq('company_id', companyId)
            .maybeSingle();

        if (response == null) return null;
        return TokenWallet.fromJson(response);
      },
    );
  }

  Future<TokenWallet> getOrCreateWallet(
    String employeeId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'getOrCreateWallet',
      action: () async {
        final existing = await getWallet(employeeId, companyId);
        if (existing != null) return existing;

        final response = await client
            .from('token_wallets')
            .insert({
              'employee_id': employeeId,
              'company_id': companyId,
            })
            .select()
            .single();

        return TokenWallet.fromJson(response);
      },
    );
  }

  Future<List<TokenWallet>> getCompanyWallets(
    String companyId, {
    int limit = 50,
  }) async {
    return safeCall(
      operation: 'getCompanyWallets',
      action: () async {
        final response = await client
            .from('token_wallets')
            .select()
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('updated_at', ascending: false)
            .limit(limit);

        return (response as List)
            .map((json) => TokenWallet.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<TokenWallet>> getTopWallets(
    String companyId, {
    int limit = 10,
  }) async {
    return safeCall(
      operation: 'getTopWallets',
      action: () async {
        final response = await client
            .from('token_wallets')
            .select()
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('balance', ascending: false)
            .limit(limit);

        return (response as List)
            .map((json) => TokenWallet.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Transactions
  // ──────────────────────────────────────────────

  Future<({String walletId, double newBalance, double amountEarned})>
      earnTokens({
    required String employeeId,
    required String companyId,
    required double amount,
    String sourceType = 'system',
    String? sourceId,
    String? description,
  }) async {
    return safeCall(
      operation: 'earnTokens',
      action: () async {
        final response = await client.rpc('earn_tokens', params: {
          'p_employee_id': employeeId,
          'p_company_id': companyId,
          'p_amount': amount,
          'p_source_type': sourceType,
          'p_source_id': sourceId,
          'p_description': description,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          walletId: data['wallet_id'] as String,
          newBalance: (data['new_balance'] as num).toDouble(),
          amountEarned: (data['amount_earned'] as num).toDouble(),
        );
      },
    );
  }

  Future<({String walletId, double newBalance, double amountSpent})>
      spendTokens({
    required String employeeId,
    required String companyId,
    required double amount,
    String sourceType = 'purchase',
    String? sourceId,
    String? description,
  }) async {
    return safeCall(
      operation: 'spendTokens',
      action: () async {
        final response = await client.rpc('spend_tokens', params: {
          'p_employee_id': employeeId,
          'p_company_id': companyId,
          'p_amount': amount,
          'p_source_type': sourceType,
          'p_source_id': sourceId,
          'p_description': description,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          walletId: data['wallet_id'] as String,
          newBalance: (data['new_balance'] as num).toDouble(),
          amountSpent: (data['amount_spent'] as num).toDouble(),
        );
      },
    );
  }

  Future<({double fromBalance, double toBalance, double amountTransferred})>
      transferTokens({
    required String fromEmployeeId,
    required String toEmployeeId,
    required String companyId,
    required double amount,
    String? note,
  }) async {
    return safeCall(
      operation: 'transferTokens',
      action: () async {
        final response = await client.rpc('transfer_tokens', params: {
          'p_from_employee_id': fromEmployeeId,
          'p_to_employee_id': toEmployeeId,
          'p_company_id': companyId,
          'p_amount': amount,
          'p_note': note,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          fromBalance: (data['from_balance'] as num).toDouble(),
          toBalance: (data['to_balance'] as num).toDouble(),
          amountTransferred: (data['amount_transferred'] as num).toDouble(),
        );
      },
    );
  }

  Future<List<TokenTransaction>> getTransactionHistory(
    String walletId, {
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    return safeCall(
      operation: 'getTransactionHistory',
      action: () async {
        var query = client
            .from('token_transactions')
            .select()
            .eq('wallet_id', walletId);

        if (type != null) query = query.eq('type', type);

        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return (response as List)
            .map((json) =>
                TokenTransaction.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Rewards Config
  // ──────────────────────────────────────────────

  Future<List<TokenRewardsConfig>> getRewardsConfig(String companyId) async {
    return safeCall(
      operation: 'getRewardsConfig',
      action: () async {
        final response = await client
            .from('token_rewards_config')
            .select()
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('event_type');

        return (response as List)
            .map((json) =>
                TokenRewardsConfig.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<double> getRewardAmount(String companyId, String eventType) async {
    return safeCall(
      operation: 'getRewardAmount',
      action: () async {
        final response = await client
            .from('token_rewards_config')
            .select('token_amount')
            .eq('company_id', companyId)
            .eq('event_type', eventType)
            .eq('is_active', true)
            .maybeSingle();

        if (response == null) return 0.0;
        return (response['token_amount'] as num?)?.toDouble() ?? 0.0;
      },
    );
  }

  Future<void> updateRewardConfig(
    String companyId,
    String eventType,
    double tokenAmount,
  ) async {
    return safeCall(
      operation: 'updateRewardConfig',
      action: () async {
        await client
            .from('token_rewards_config')
            .update({'token_amount': tokenAmount})
            .eq('company_id', companyId)
            .eq('event_type', eventType);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Store
  // ──────────────────────────────────────────────

  Future<List<TokenStoreItem>> getStoreItems(
    String companyId, {
    bool activeOnly = true,
  }) async {
    return safeCall(
      operation: 'getStoreItems',
      action: () async {
        var query = client
            .from('token_store_items')
            .select()
            .eq('company_id', companyId);

        if (activeOnly) query = query.eq('is_active', true);

        final response = await query.order('price_tokens');

        return (response as List)
            .map((json) =>
                TokenStoreItem.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<TokenPurchase> purchaseItem({
    required String employeeId,
    required String companyId,
    required String itemId,
  }) async {
    return safeCall(
      operation: 'purchaseItem',
      action: () async {
        final response = await client.rpc('purchase_store_item', params: {
          'p_employee_id': employeeId,
          'p_company_id': companyId,
          'p_item_id': itemId,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return TokenPurchase.fromJson(data);
      },
    );
  }

  Future<List<TokenPurchase>> getMyPurchases(String walletId) async {
    return safeCall(
      operation: 'getMyPurchases',
      action: () async {
        final response = await client
            .from('token_purchases')
            .select('*, token_store_items(*)')
            .eq('wallet_id', walletId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) =>
                TokenPurchase.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Stats
  // ──────────────────────────────────────────────

  Future<
      ({
        double totalCirculating,
        int totalWallets,
        double totalEarned,
        double totalSpent,
      })> getCompanyTokenStats(String companyId) async {
    return safeCall(
      operation: 'getCompanyTokenStats',
      action: () async {
        final response = await client
            .from('token_wallets')
            .select('balance, total_earned, total_spent')
            .eq('company_id', companyId)
            .eq('is_active', true);

        final wallets = response as List;
        double totalCirculating = 0;
        double totalEarned = 0;
        double totalSpent = 0;

        for (final w in wallets) {
          final map = w as Map<String, dynamic>;
          totalCirculating += (map['balance'] as num?)?.toDouble() ?? 0;
          totalEarned += (map['total_earned'] as num?)?.toDouble() ?? 0;
          totalSpent += (map['total_spent'] as num?)?.toDouble() ?? 0;
        }

        return (
          totalCirculating: totalCirculating,
          totalWallets: wallets.length,
          totalEarned: totalEarned,
          totalSpent: totalSpent,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Bridge: Withdraw (Off-chain → On-chain)
  // ──────────────────────────────────────────────

  /// Request a withdrawal of SABO tokens from off-chain to on-chain wallet.
  ///
  /// Flow:
  /// 1. Validate balance & wallet address
  /// 2. Deduct from off-chain balance
  /// 3. Create bridge_request record
  /// 4. Backend service will process on-chain transfer
  Future<BridgeRequest> requestWithdraw({
    required String employeeId,
    required String companyId,
    required String walletId,
    required double amount,
    required String walletAddress,
  }) async {
    return safeCall(
      operation: 'requestWithdraw',
      action: () async {
        // Validate address format
        if (!BlockchainConfig.isValidAddress(walletAddress)) {
          throw Exception('Địa chỉ ví không hợp lệ');
        }

        // Validate amount
        if (amount < BlockchainConfig.minBridgeAmount) {
          throw Exception(
              'Số tiền tối thiểu: ${BlockchainConfig.minBridgeAmount.toInt()} SABO');
        }
        if (amount > BlockchainConfig.maxWithdrawAmount) {
          throw Exception(
              'Số tiền tối đa: ${BlockchainConfig.maxWithdrawAmount.toInt()} SABO');
        }

        // Check on-chain cooldown
        final blockchain = BlockchainService();
        final canProceed = await blockchain.canWithdraw(walletAddress);
        if (!canProceed) {
          throw Exception('Vui lòng đợi hết thời gian cooldown');
        }

        // Calculate fee
        final fee = BlockchainConfig.calculateWithdrawFee(amount);
        final netAmount = amount - fee;

        // Generate unique request ID
        final requestId =
            'wd_${DateTime.now().millisecondsSinceEpoch}_$employeeId';

        // Deduct off-chain balance first (atomic)
        await spendTokens(
          employeeId: employeeId,
          companyId: companyId,
          amount: amount,
          sourceType: 'system',
          description: 'Rút SABO lên blockchain ($walletAddress)',
        );

        // Create bridge request record
        final response = await client
            .from('bridge_requests')
            .insert({
              'employee_id': employeeId,
              'wallet_id': walletId,
              'type': 'withdraw',
              'amount': amount,
              'fee_amount': fee,
              'net_amount': netAmount,
              'wallet_address': walletAddress,
              'chain_id': BlockchainConfig.chainId,
              'status': 'pending',
              'request_id': requestId,
            })
            .select()
            .single();

        // Update wallet address if not set
        await client
            .from('token_wallets')
            .update({'wallet_address': walletAddress})
            .eq('id', walletId)
            .isFilter('wallet_address', null);

        return BridgeRequest.fromJson(response);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Bridge: Deposit (On-chain → Off-chain)
  // ──────────────────────────────────────────────

  /// Confirm a deposit of SABO tokens from on-chain to off-chain wallet.
  ///
  /// Flow:
  /// 1. User sends tokens to Bridge contract on-chain (done externally)
  /// 2. User provides txHash to this method
  /// 3. Backend verifies tx on-chain
  /// 4. Credit off-chain balance
  Future<BridgeRequest> confirmDeposit({
    required String employeeId,
    required String companyId,
    required String walletId,
    required String txHash,
    required double expectedAmount,
  }) async {
    return safeCall(
      operation: 'confirmDeposit',
      action: () async {
        // Validate txHash format
        if (!RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(txHash)) {
          throw Exception('Transaction hash không hợp lệ');
        }

        // Create pending bridge request
        final response = await client
            .from('bridge_requests')
            .insert({
              'employee_id': employeeId,
              'wallet_id': walletId,
              'type': 'deposit',
              'amount': expectedAmount,
              'fee_amount': 0,
              'net_amount': expectedAmount,
              'tx_hash': txHash,
              'chain_id': BlockchainConfig.chainId,
              'status': 'processing',
              'request_id': 'dp_${DateTime.now().millisecondsSinceEpoch}',
            })
            .select()
            .single();

        // Verify transaction on-chain
        final blockchain = BlockchainService();
        final confirmed = await blockchain.waitForConfirmation(txHash);

        if (confirmed) {
          // Credit off-chain balance
          await earnTokens(
            employeeId: employeeId,
            companyId: companyId,
            amount: expectedAmount,
            sourceType: 'system',
            description: 'Nạp SABO từ blockchain (tx: ${txHash.substring(0, 10)}...)',
          );

          // Update bridge request status
          await client.from('bridge_requests').update({
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', response['id']);

          return BridgeRequest.fromJson({
            ...response,
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          // Mark as failed
          await client.from('bridge_requests').update({
            'status': 'failed',
            'error_message': 'Transaction not confirmed on-chain',
          }).eq('id', response['id']);

          throw Exception('Transaction không được xác nhận trên blockchain');
        }
      },
    );
  }

  // ──────────────────────────────────────────────
  // Bridge: Queries
  // ──────────────────────────────────────────────

  /// Get bridge request history for a wallet
  Future<List<BridgeRequest>> getBridgeRequests(
    String walletId, {
    String? type,
    int limit = 20,
  }) async {
    return safeCall(
      operation: 'getBridgeRequests',
      action: () async {
        var query = client
            .from('bridge_requests')
            .select()
            .eq('wallet_id', walletId);

        if (type != null) query = query.eq('type', type);

        final response = await query
            .order('created_at', ascending: false)
            .limit(limit);

        return (response as List)
            .map((json) =>
                BridgeRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Get a single bridge request by ID
  Future<BridgeRequest?> getBridgeRequest(String requestId) async {
    return safeCall(
      operation: 'getBridgeRequest',
      action: () async {
        final response = await client
            .from('bridge_requests')
            .select()
            .eq('id', requestId)
            .maybeSingle();

        if (response == null) return null;
        return BridgeRequest.fromJson(response);
      },
    );
  }

  /// Cancel a pending bridge request
  Future<void> cancelBridgeRequest(String requestId) async {
    return safeCall(
      operation: 'cancelBridgeRequest',
      action: () async {
        final request = await getBridgeRequest(requestId);
        if (request == null) throw Exception('Request không tồn tại');
        if (request.status != BridgeRequestStatus.pending) {
          throw Exception('Chỉ có thể hủy request đang chờ xử lý');
        }

        // If it's a withdraw, refund the off-chain balance
        if (request.type == BridgeRequestType.withdraw) {
          // Look up employee_id from bridge request
          await client.rpc('earn_tokens', params: {
            'p_employee_id': request.employeeId,
            'p_company_id':
                (await getWallet(request.employeeId, ''))?.companyId ?? '',
            'p_amount': request.amount,
            'p_source_type': 'system',
            'p_description': 'Hoàn tiền do hủy yêu cầu rút SABO',
          });
        }

        await client.from('bridge_requests').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', requestId);
      },
    );
  }

  /// Link a blockchain wallet address to an off-chain wallet
  Future<void> linkWalletAddress(String walletId, String address) async {
    return safeCall(
      operation: 'linkWalletAddress',
      action: () async {
        if (!BlockchainConfig.isValidAddress(address)) {
          throw Exception('Địa chỉ ví không hợp lệ');
        }

        await client
            .from('token_wallets')
            .update({'wallet_address': address})
            .eq('id', walletId);
      },
    );
  }

  /// Get combined balance (off-chain + on-chain) for display
  Future<({double offChain, double onChain, double total})>
      getCombinedBalance(String employeeId, String companyId) async {
    return safeCall(
      operation: 'getCombinedBalance',
      action: () async {
        final wallet = await getWallet(employeeId, companyId);
        if (wallet == null) {
          return (offChain: 0.0, onChain: 0.0, total: 0.0);
        }

        double onChainBalance = 0;
        if (wallet.walletAddress != null &&
            wallet.walletAddress!.isNotEmpty) {
          final blockchain = BlockchainService();
          onChainBalance =
              await blockchain.getOnChainBalance(wallet.walletAddress!);
        }

        return (
          offChain: wallet.balance,
          onChain: onChainBalance,
          total: wallet.balance + onChainBalance,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Analytics Methods
  // ──────────────────────────────────────────────

  /// Get transaction breakdown by source_type for a company (earn only)
  /// Returns map: { 'task': 450.0, 'quest': 200.0, 'attendance': 100.0, ... }
  Future<Map<String, double>> getEarningBreakdown(
    String companyId, {
    int days = 30,
  }) async {
    return safeCall(
      operation: 'getEarningBreakdown',
      action: () async {
        final since =
            DateTime.now().subtract(Duration(days: days)).toIso8601String();

        final data = await client
            .from('token_transactions')
            .select('source_type, amount')
            .eq('company_id', companyId)
            .eq('type', 'earn')
            .gte('created_at', since);

        final breakdown = <String, double>{};
        for (final row in data as List) {
          final source = (row['source_type'] as String?) ?? 'system';
          final amount = (row['amount'] as num?)?.toDouble() ?? 0;
          breakdown[source] = (breakdown[source] ?? 0) + amount;
        }
        return breakdown;
      },
    );
  }

  /// Get daily token flow (earn vs spend) for the last N days
  /// Each entry: { date, earned, spent }
  Future<List<({DateTime date, double earned, double spent})>>
      getDailyTokenFlow(
    String companyId, {
    int days = 30,
  }) async {
    return safeCall(
      operation: 'getDailyTokenFlow',
      action: () async {
        final since =
            DateTime.now().subtract(Duration(days: days)).toIso8601String();

        final data = await client
            .from('token_transactions')
            .select('type, amount, created_at')
            .eq('company_id', companyId)
            .inFilter('type', ['earn', 'spend'])
            .gte('created_at', since)
            .order('created_at');

        // Group by date
        final dailyMap = <String, ({double earned, double spent})>{};
        for (final row in data as List) {
          final dt = DateTime.parse(row['created_at'] as String);
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          final amount = (row['amount'] as num?)?.toDouble() ?? 0;
          final type = row['type'] as String? ?? 'earn';

          final current = dailyMap[key] ?? (earned: 0.0, spent: 0.0);
          if (type == 'earn') {
            dailyMap[key] = (earned: current.earned + amount, spent: current.spent);
          } else {
            dailyMap[key] = (earned: current.earned, spent: current.spent + amount);
          }
        }

        // Fill in missing days
        final result = <({DateTime date, double earned, double spent})>[];
        final now = DateTime.now();
        for (int i = days - 1; i >= 0; i--) {
          final date = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: i));
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final dayData = dailyMap[key];
          result.add((
            date: date,
            earned: dayData?.earned ?? 0,
            spent: dayData?.spent ?? 0,
          ));
        }
        return result;
      },
    );
  }

  /// Get top earners for a company
  Future<List<TokenWallet>> getTopEarners(
    String companyId, {
    int limit = 10,
  }) async {
    return safeCall(
      operation: 'getTopEarners',
      action: () async {
        final data = await client
            .from('token_wallets')
            .select('*, employees!inner(full_name, avatar_url)')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('total_earned', ascending: false)
            .limit(limit);

        return (data as List).map((row) {
          final emp = row['employees'] as Map<String, dynamic>?;
          row['employee_name'] = emp?['full_name'];
          row['employee_avatar'] = emp?['avatar_url'];
          return TokenWallet.fromJson(row);
        }).toList();
      },
    );
  }

  /// Get store purchase stats for a company
  Future<({int totalPurchases, double totalRevenue, Map<String, int> byCategory})>
      getStorePurchaseStats(
    String companyId, {
    int days = 30,
  }) async {
    return safeCall(
      operation: 'getStorePurchaseStats',
      action: () async {
        final since =
            DateTime.now().subtract(Duration(days: days)).toIso8601String();

        final data = await client
            .from('token_purchases')
            .select('price_paid, token_store_items!inner(category)')
            .eq('token_store_items.company_id', companyId)
            .gte('created_at', since);

        int totalPurchases = 0;
        double totalRevenue = 0;
        final byCategory = <String, int>{};

        for (final row in data as List) {
          totalPurchases++;
          totalRevenue += (row['price_paid'] as num?)?.toDouble() ?? 0;
          final cat =
              (row['token_store_items']?['category'] as String?) ?? 'perk';
          byCategory[cat] = (byCategory[cat] ?? 0) + 1;
        }

        return (
          totalPurchases: totalPurchases,
          totalRevenue: totalRevenue,
          byCategory: byCategory,
        );
      },
    );
  }

  /// Get recent activity feed for a company (last N transactions)
  Future<List<TokenTransaction>> getRecentActivity(
    String companyId, {
    int limit = 20,
  }) async {
    return safeCall(
      operation: 'getRecentActivity',
      action: () async {
        final data = await client
            .from('token_transactions')
            .select()
            .eq('company_id', companyId)
            .order('created_at', ascending: false)
            .limit(limit);

        return (data as List)
            .map((row) => TokenTransaction.fromJson(row))
            .toList();
      },
    );
  }
}
