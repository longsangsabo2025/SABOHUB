import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token/token_models.dart';
import '../models/token/nft_achievement.dart';
import '../services/token/token_service.dart';
import '../services/token/blockchain_service.dart';
import '../core/config/blockchain_config.dart';
import 'auth_provider.dart';

// ──────────────────────────────────────────────
// Service Provider
// ──────────────────────────────────────────────

final tokenServiceProvider = Provider<TokenService>(
  (ref) => TokenService(),
);

// ──────────────────────────────────────────────
// Wallet
// ──────────────────────────────────────────────

class TokenWalletState {
  final TokenWallet? wallet;
  final bool isLoading;
  final String? error;

  const TokenWalletState({
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  TokenWalletState copyWith({
    TokenWallet? wallet,
    bool? isLoading,
    String? error,
  }) {
    return TokenWalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TokenWalletNotifier extends Notifier<TokenWalletState> {
  @override
  TokenWalletState build() {
    final user = ref.watch(currentUserProvider);
    if (user != null && user.companyId != null) {
      Future.microtask(() => loadWallet());
    }
    return const TokenWalletState(isLoading: true);
  }

  TokenService get _service => ref.read(tokenServiceProvider);
  String? get _userId => ref.read(currentUserProvider)?.id;
  String? get _companyId => ref.read(currentUserProvider)?.companyId;

  Future<void> loadWallet() async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) {
      state = const TokenWalletState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final wallet = await _service.getOrCreateWallet(userId, companyId);
      state = TokenWalletState(wallet: wallet, isLoading: false);
    } catch (e) {
      state = TokenWalletState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> earnTokens(
    double amount, {
    String sourceType = 'system',
    String? sourceId,
    String? description,
  }) async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) return;

    try {
      await _service.earnTokens(
        employeeId: userId,
        companyId: companyId,
        amount: amount,
        sourceType: sourceType,
        sourceId: sourceId,
        description: description,
      );
      // Reload wallet to reflect new balance
      await loadWallet();
      // ignore: avoid_print
      // Earned ${result.amountEarned}, new balance: ${result.newBalance}
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> spendTokens(
    double amount, {
    String sourceType = 'purchase',
    String? sourceId,
    String? description,
  }) async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) return false;

    try {
      await _service.spendTokens(
        employeeId: userId,
        companyId: companyId,
        amount: amount,
        sourceType: sourceType,
        sourceId: sourceId,
        description: description,
      );
      await loadWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> transferTokens(
    String toEmployeeId,
    double amount, {
    String? note,
  }) async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) return false;

    try {
      await _service.transferTokens(
        fromEmployeeId: userId,
        toEmployeeId: toEmployeeId,
        companyId: companyId,
        amount: amount,
        note: note,
      );
      await loadWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> refresh() async => loadWallet();
}

final tokenWalletProvider =
    NotifierProvider<TokenWalletNotifier, TokenWalletState>(
  () => TokenWalletNotifier(),
);

// ──────────────────────────────────────────────
// Transaction History
// ──────────────────────────────────────────────

class TokenHistoryState {
  final List<TokenTransaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const TokenHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  TokenHistoryState copyWith({
    List<TokenTransaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return TokenHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class TokenHistoryNotifier extends Notifier<TokenHistoryState> {
  static const _pageSize = 50;

  @override
  TokenHistoryState build() {
    return const TokenHistoryState();
  }

  TokenService get _service => ref.read(tokenServiceProvider);

  Future<void> loadHistory({String? type}) async {
    final walletId = ref.read(tokenWalletProvider).wallet?.id;
    if (walletId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _service.getTransactionHistory(
        walletId,
        type: type,
        limit: _pageSize,
        offset: 0,
      );
      state = TokenHistoryState(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length >= _pageSize,
      );
    } catch (e) {
      state = TokenHistoryState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadMore({String? type}) async {
    if (state.isLoading || !state.hasMore) return;

    final walletId = ref.read(tokenWalletProvider).wallet?.id;
    if (walletId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final newTx = await _service.getTransactionHistory(
        walletId,
        type: type,
        limit: _pageSize,
        offset: state.transactions.length,
      );
      state = state.copyWith(
        transactions: [...state.transactions, ...newTx],
        isLoading: false,
        hasMore: newTx.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final tokenHistoryProvider =
    NotifierProvider<TokenHistoryNotifier, TokenHistoryState>(
  () => TokenHistoryNotifier(),
);

// ──────────────────────────────────────────────
// Token Store
// ──────────────────────────────────────────────

class TokenStoreState {
  final List<TokenStoreItem> items;
  final List<TokenPurchase> myPurchases;
  final bool isLoading;
  final String? error;

  const TokenStoreState({
    this.items = const [],
    this.myPurchases = const [],
    this.isLoading = false,
    this.error,
  });

  TokenStoreState copyWith({
    List<TokenStoreItem>? items,
    List<TokenPurchase>? myPurchases,
    bool? isLoading,
    String? error,
  }) {
    return TokenStoreState(
      items: items ?? this.items,
      myPurchases: myPurchases ?? this.myPurchases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TokenStoreNotifier extends Notifier<TokenStoreState> {
  @override
  TokenStoreState build() {
    return const TokenStoreState();
  }

  TokenService get _service => ref.read(tokenServiceProvider);
  String? get _userId => ref.read(currentUserProvider)?.id;
  String? get _companyId => ref.read(currentUserProvider)?.companyId;

  Future<void> loadStore() async {
    final companyId = _companyId;
    if (companyId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final items = await _service.getStoreItems(companyId);

      // Load purchases if wallet exists
      List<TokenPurchase> purchases = [];
      final walletId = ref.read(tokenWalletProvider).wallet?.id;
      if (walletId != null) {
        purchases = await _service.getMyPurchases(walletId);
      }

      state = TokenStoreState(
        items: items,
        myPurchases: purchases,
        isLoading: false,
      );
    } catch (e) {
      state = TokenStoreState(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> purchaseItem(String itemId) async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) return false;

    try {
      await _service.purchaseItem(
        employeeId: userId,
        companyId: companyId,
        itemId: itemId,
      );
      // Refresh store and wallet
      await loadStore();
      ref.read(tokenWalletProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final tokenStoreProvider =
    NotifierProvider<TokenStoreNotifier, TokenStoreState>(
  () => TokenStoreNotifier(),
);

// ──────────────────────────────────────────────
// Company Token Stats (for CEO/Manager)
// ──────────────────────────────────────────────

final companyTokenStatsProvider = FutureProvider.autoDispose<
    ({
      double totalCirculating,
      int totalWallets,
      double totalEarned,
      double totalSpent,
    })>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) {
    return (
      totalCirculating: 0.0,
      totalWallets: 0,
      totalEarned: 0.0,
      totalSpent: 0.0,
    );
  }

  final service = ref.read(tokenServiceProvider);
  return service.getCompanyTokenStats(user.companyId!);
});

// ──────────────────────────────────────────────
// Leaderboard
// ──────────────────────────────────────────────

final tokenLeaderboardProvider =
    FutureProvider.autoDispose<List<TokenWallet>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(tokenServiceProvider);
  return service.getTopWallets(user.companyId!, limit: 10);
});

// ──────────────────────────────────────────────
// Rewards Config
// ──────────────────────────────────────────────

final tokenRewardsConfigProvider =
    FutureProvider.autoDispose<List<TokenRewardsConfig>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(tokenServiceProvider);
  return service.getRewardsConfig(user.companyId!);
});

// ──────────────────────────────────────────────
// Convenience Getters
// ──────────────────────────────────────────────

final currentBalanceProvider = Provider<double>((ref) {
  return ref.watch(tokenWalletProvider).wallet?.balance ?? 0;
});

final currentTotalEarnedProvider = Provider<double>((ref) {
  return ref.watch(tokenWalletProvider).wallet?.totalEarned ?? 0;
});

final currentTotalSpentProvider = Provider<double>((ref) {
  return ref.watch(tokenWalletProvider).wallet?.totalSpent ?? 0;
});

// ──────────────────────────────────────────────
// Bridge Providers
// ──────────────────────────────────────────────

class BridgeHistoryState {
  final List<BridgeRequest> requests;
  final bool isLoading;
  final String? error;

  const BridgeHistoryState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  BridgeHistoryState copyWith({
    List<BridgeRequest>? requests,
    bool? isLoading,
    String? error,
  }) =>
      BridgeHistoryState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class BridgeHistoryNotifier extends Notifier<BridgeHistoryState> {
  @override
  BridgeHistoryState build() => const BridgeHistoryState();

  TokenService get _service => ref.read(tokenServiceProvider);

  Future<void> loadHistory({String? type}) async {
    final walletId = ref.read(tokenWalletProvider).wallet?.id;
    if (walletId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final requests = await _service.getBridgeRequests(
        walletId,
        type: type,
        limit: 50,
      );
      state = BridgeHistoryState(requests: requests, isLoading: false);
    } catch (e) {
      state = BridgeHistoryState(error: e.toString(), isLoading: false);
    }
  }

  Future<BridgeRequest?> requestWithdraw({
    required double amount,
    required String walletAddress,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    final companyId = ref.read(currentUserProvider)?.companyId;
    final walletId = ref.read(tokenWalletProvider).wallet?.id;
    if (userId == null || companyId == null || walletId == null) return null;

    try {
      final request = await _service.requestWithdraw(
        employeeId: userId,
        companyId: companyId,
        walletId: walletId,
        amount: amount,
        walletAddress: walletAddress,
      );
      await loadHistory();
      ref.read(tokenWalletProvider.notifier).refresh();
      return request;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<BridgeRequest?> confirmDeposit({
    required String txHash,
    required double expectedAmount,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    final companyId = ref.read(currentUserProvider)?.companyId;
    final walletId = ref.read(tokenWalletProvider).wallet?.id;
    if (userId == null || companyId == null || walletId == null) return null;

    try {
      final request = await _service.confirmDeposit(
        employeeId: userId,
        companyId: companyId,
        walletId: walletId,
        txHash: txHash,
        expectedAmount: expectedAmount,
      );
      await loadHistory();
      ref.read(tokenWalletProvider.notifier).refresh();
      return request;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      await _service.cancelBridgeRequest(requestId);
      await loadHistory();
      ref.read(tokenWalletProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final bridgeHistoryProvider =
    NotifierProvider<BridgeHistoryNotifier, BridgeHistoryState>(
  () => BridgeHistoryNotifier(),
);

// ──────────────────────────────────────────────
// Blockchain Service Provider
// ──────────────────────────────────────────────

final blockchainServiceProvider = Provider<BlockchainService>(
  (ref) => BlockchainService(),
);

// ──────────────────────────────────────────────
// Staking Info Provider (read from chain)
// ──────────────────────────────────────────────

final stakingTiersProvider = Provider<List<StakingTierInfo>>((ref) {
  return const [
    StakingTierInfo(
      name: 'Bronze',
      minStake: 100,
      lockPeriodDays: 30,
      apyPercent: 5,
      emoji: '🥉',
    ),
    StakingTierInfo(
      name: 'Silver',
      minStake: 500,
      lockPeriodDays: 90,
      apyPercent: 12,
      emoji: '🥈',
    ),
    StakingTierInfo(
      name: 'Gold',
      minStake: 2000,
      lockPeriodDays: 180,
      apyPercent: 20,
      emoji: '🥇',
    ),
    StakingTierInfo(
      name: 'Diamond',
      minStake: 10000,
      lockPeriodDays: 365,
      apyPercent: 30,
      emoji: '💎',
    ),
  ];
});

/// Static staking tier data for UI display
class StakingTierInfo {
  final String name;
  final double minStake;
  final int lockPeriodDays;
  final double apyPercent;
  final String emoji;

  const StakingTierInfo({
    required this.name,
    required this.minStake,
    required this.lockPeriodDays,
    required this.apyPercent,
    required this.emoji,
  });
}

// ──────────────────────────────────────────────
// Bridge Live Status Provider
// ──────────────────────────────────────────────

class BridgeLiveStatus {
  final bool isOnline;
  final bool isPaused;
  final double totalLocked;
  final double totalWithdrawn;
  final double bridgeBalance;
  final String operatorBalance;
  final DateTime? lastChecked;
  final String? error;

  const BridgeLiveStatus({
    this.isOnline = false,
    this.isPaused = false,
    this.totalLocked = 0,
    this.totalWithdrawn = 0,
    this.bridgeBalance = 0,
    this.operatorBalance = '0',
    this.lastChecked,
    this.error,
  });

  BridgeLiveStatus copyWith({
    bool? isOnline,
    bool? isPaused,
    double? totalLocked,
    double? totalWithdrawn,
    double? bridgeBalance,
    String? operatorBalance,
    DateTime? lastChecked,
    String? error,
  }) =>
      BridgeLiveStatus(
        isOnline: isOnline ?? this.isOnline,
        isPaused: isPaused ?? this.isPaused,
        totalLocked: totalLocked ?? this.totalLocked,
        totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
        bridgeBalance: bridgeBalance ?? this.bridgeBalance,
        operatorBalance: operatorBalance ?? this.operatorBalance,
        lastChecked: lastChecked ?? this.lastChecked,
        error: error,
      );
}

class BridgeLiveStatusNotifier extends Notifier<BridgeLiveStatus> {
  @override
  BridgeLiveStatus build() {
    // Auto-fetch on first access
    Future.microtask(() => refresh());
    return const BridgeLiveStatus();
  }

  Future<void> refresh() async {
    final apiUrl = BlockchainConfig.bridgeApiUrl;
    if (apiUrl.isEmpty) {
      state = state.copyWith(
        isOnline: false,
        lastChecked: DateTime.now(),
        error: 'Bridge API chưa được cấu hình',
      );
      return;
    }

    try {
      final blockchain = ref.read(blockchainServiceProvider);
      final stats = await blockchain.getBridgeStats();
      state = BridgeLiveStatus(
        isOnline: true,
        isPaused: false,
        totalLocked: stats.totalDeposited,
        totalWithdrawn: stats.totalWithdrawn,
        bridgeBalance: stats.lockedBalance,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isOnline: false,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }
}

final bridgeLiveStatusProvider =
    NotifierProvider<BridgeLiveStatusNotifier, BridgeLiveStatus>(
  () => BridgeLiveStatusNotifier(),
);

// ──────────────────────────────────────────────
// Token Analytics Providers
// ──────────────────────────────────────────────

/// Earning breakdown by source type (last 30 days)
final tokenEarningBreakdownProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final auth = ref.watch(authProvider);
  final companyId = auth.user?.companyId;
  if (companyId == null) return {};

  final service = ref.watch(tokenServiceProvider);
  return service.getEarningBreakdown(companyId, days: 30);
});

/// Daily token flow (earn vs spend) for last 30 days
final tokenDailyFlowProvider = FutureProvider.autoDispose<
    List<({DateTime date, double earned, double spent})>>((ref) async {
  final auth = ref.watch(authProvider);
  final companyId = auth.user?.companyId;
  if (companyId == null) return [];

  final service = ref.watch(tokenServiceProvider);
  return service.getDailyTokenFlow(companyId, days: 30);
});

/// Top 10 earners in company
final tokenTopEarnersProvider =
    FutureProvider.autoDispose<List<TokenWallet>>((ref) async {
  final auth = ref.watch(authProvider);
  final companyId = auth.user?.companyId;
  if (companyId == null) return [];

  final service = ref.watch(tokenServiceProvider);
  return service.getTopEarners(companyId, limit: 10);
});

/// Store purchase analytics
final tokenStoreStatsProvider = FutureProvider.autoDispose<
    ({int totalPurchases, double totalRevenue, Map<String, int> byCategory})>(
  (ref) async {
    final auth = ref.watch(authProvider);
    final companyId = auth.user?.companyId;
    if (companyId == null) {
      return (totalPurchases: 0, totalRevenue: 0.0, byCategory: <String, int>{});
    }

    final service = ref.watch(tokenServiceProvider);
    return service.getStorePurchaseStats(companyId, days: 30);
  },
);

/// Recent activity feed
final tokenRecentActivityProvider =
    FutureProvider.autoDispose<List<TokenTransaction>>((ref) async {
  final auth = ref.watch(authProvider);
  final companyId = auth.user?.companyId;
  if (companyId == null) return [];

  final service = ref.watch(tokenServiceProvider);
  return service.getRecentActivity(companyId, limit: 20);
});

// ──────────────────────────────────────────────
// NFT Achievement Provider
// ──────────────────────────────────────────────

class NftAchievementState {
  final AchievementSummary summary;
  final List<AchievementType> allTypes;
  final bool isLoading;
  final String? error;

  const NftAchievementState({
    this.summary = const AchievementSummary(),
    this.allTypes = const [],
    this.isLoading = false,
    this.error,
  });

  NftAchievementState copyWith({
    AchievementSummary? summary,
    List<AchievementType>? allTypes,
    bool? isLoading,
    String? error,
  }) =>
      NftAchievementState(
        summary: summary ?? this.summary,
        allTypes: allTypes ?? this.allTypes,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class NftAchievementNotifier extends Notifier<NftAchievementState> {
  @override
  NftAchievementState build() {
    return const NftAchievementState();
  }

  BlockchainService get _blockchain => ref.read(blockchainServiceProvider);

  /// Load achievements for connected wallet address
  Future<void> loadAchievements(String walletAddress) async {
    if (walletAddress.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _blockchain.getAchievementSummary(walletAddress),
        _blockchain.getActiveAchievementTypes(),
      ]);

      state = NftAchievementState(
        summary: results[0] as AchievementSummary,
        allTypes: results[1] as List<AchievementType>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh data
  Future<void> refresh(String walletAddress) => loadAchievements(walletAddress);
}

final nftAchievementProvider =
    NotifierProvider<NftAchievementNotifier, NftAchievementState>(
  () => NftAchievementNotifier(),
);
