import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/blockchain_config.dart';
import '../../models/token/nft_achievement.dart';

/// Service for interacting with SABO Token smart contracts on Base L2.
///
/// This service handles:
/// - Reading on-chain data (balances, staking info)
/// - Preparing transactions for bridge operations
/// - Verifying transaction confirmations
///
/// NOTE: Actual transaction signing is done via wallet connect / external wallet.
/// This service prepares the data and verifies results.
class BlockchainService {
  static final BlockchainService _instance = BlockchainService._();
  factory BlockchainService() => _instance;
  BlockchainService._();

  final http.Client _httpClient = http.Client();

  // ──────────────────────────────────────────────
  // JSON-RPC Helpers
  // ──────────────────────────────────────────────

  /// Call an Ethereum JSON-RPC method
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(BlockchainConfig.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': DateTime.now().millisecondsSinceEpoch,
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode != 200) {
        throw BlockchainException('RPC call failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        throw BlockchainException(
            'RPC error: ${data['error']['message'] ?? 'Unknown'}');
      }

      return data['result'];
    } catch (e) {
      if (e is BlockchainException) rethrow;
      throw BlockchainException('Network error: $e');
    }
  }

  /// Call a read-only contract function (eth_call)
  Future<String> _contractCall(
    String contractAddress,
    String functionSelector, [
    String data = '',
  ]) async {
    final callData = functionSelector + data;
    final result = await _rpcCall('eth_call', [
      {'to': contractAddress, 'data': callData},
      'latest',
    ]);
    return result as String;
  }

  // ──────────────────────────────────────────────
  // Token Read Operations
  // ──────────────────────────────────────────────

  /// Get SABO token balance for an address (on-chain)
  /// Returns balance in token units (not wei)
  Future<double> getOnChainBalance(String walletAddress) async {
    try {
      // balanceOf(address) = 0x70a08231
      final paddedAddress = _padAddress(walletAddress);
      final result = await _contractCall(
        BlockchainConfig.tokenAddress,
        '0x70a08231',
        paddedAddress,
      );

      return _parseTokenAmount(result);
    } catch (e) {
      _log('getOnChainBalance error: $e');
      return 0;
    }
  }

  /// Get total supply of SABO token
  Future<double> getTotalSupply() async {
    try {
      // totalSupply() = 0x18160ddd
      final result = await _contractCall(
        BlockchainConfig.tokenAddress,
        '0x18160ddd',
      );
      return _parseTokenAmount(result);
    } catch (e) {
      _log('getTotalSupply error: $e');
      return 0;
    }
  }

  /// Get daily minted amount today
  Future<double> getDailyMintCap() async {
    try {
      // dailyMintCap() = selector
      final result = await _contractCall(
        BlockchainConfig.tokenAddress,
        '0x11e2729f', // dailyMintCap()
      );
      return _parseTokenAmount(result);
    } catch (e) {
      _log('getDailyMintCap error: $e');
      return 0;
    }
  }

  // ──────────────────────────────────────────────
  // Bridge Operations
  // ──────────────────────────────────────────────

  /// Check if a withdrawal can proceed for an address
  Future<bool> canWithdraw(String walletAddress) async {
    try {
      // canWithdraw(address) selector
      final paddedAddress = _padAddress(walletAddress);
      final result = await _contractCall(
        BlockchainConfig.bridgeAddress,
        '0xcc3c0f06', // canWithdraw(address)
        paddedAddress,
      );

      // Returns bool (0x...01 = true, 0x...00 = false)
      return result.endsWith('1');
    } catch (e) {
      _log('canWithdraw error: $e');
      return false;
    }
  }

  /// Get bridge statistics (totalDeposited, totalWithdrawn, lockedBalance)
  Future<BridgeStats> getBridgeStats() async {
    try {
      // getStats() = selector
      final result = await _contractCall(
        BlockchainConfig.bridgeAddress,
        '0xc59d4847', // getStats()
      );

      // Decode tuple (uint256, uint256, uint256)
      if (result.length >= 194) {
        // 0x + 3*64
        final hex = result.substring(2); // remove 0x
        final deposited = _hexToDouble(hex.substring(0, 64));
        final withdrawn = _hexToDouble(hex.substring(64, 128));
        final locked = _hexToDouble(hex.substring(128, 192));

        return BridgeStats(
          totalDeposited: deposited,
          totalWithdrawn: withdrawn,
          lockedBalance: locked,
        );
      }

      return BridgeStats.empty();
    } catch (e) {
      _log('getBridgeStats error: $e');
      return BridgeStats.empty();
    }
  }

  // ──────────────────────────────────────────────
  // Staking Operations (Read)
  // ──────────────────────────────────────────────

  /// Get staking tier information
  Future<List<StakingTier>> getStakingTiers() async {
    // For MVP, return hardcoded tier info matching contract
    // Full implementation will decode from contract
    return const [
      StakingTier(
        id: 0,
        name: 'Bronze',
        lockDays: 30,
        apyPercent: 5.0,
        minStake: 100,
      ),
      StakingTier(
        id: 1,
        name: 'Silver',
        lockDays: 90,
        apyPercent: 12.0,
        minStake: 500,
      ),
      StakingTier(
        id: 2,
        name: 'Gold',
        lockDays: 180,
        apyPercent: 20.0,
        minStake: 1000,
      ),
      StakingTier(
        id: 3,
        name: 'Diamond',
        lockDays: 365,
        apyPercent: 30.0,
        minStake: 5000,
      ),
    ];
  }

  // ──────────────────────────────────────────────
  // NFT Achievement Operations (Read)
  // ──────────────────────────────────────────────

  /// Get all achievement NFTs owned by an address.
  /// Returns an [AchievementSummary] containing the list + rarity counts.
  Future<AchievementSummary> getAchievementSummary(
      String walletAddress) async {
    try {
      final achievementAddr = BlockchainConfig.achievementAddress;
      if (achievementAddr.isEmpty ||
          achievementAddr == '0x0000000000000000000000000000000000000000') {
        return const AchievementSummary();
      }

      // 1. Get rarity counts: getAchievementCountByRarity(address) => 0x6735dce5
      final countsRaw = await _contractCall(
        achievementAddr,
        '0x6735dce5',
        _padAddress(walletAddress),
      );

      int common = 0, rare = 0, epic = 0, legendary = 0, mythic = 0;
      if (countsRaw.length >= 322) {
        // 0x + 5*64
        final hex = countsRaw.substring(2);
        common = _hexToInt('0x${hex.substring(0, 64)}');
        rare = _hexToInt('0x${hex.substring(64, 128)}');
        epic = _hexToInt('0x${hex.substring(128, 192)}');
        legendary = _hexToInt('0x${hex.substring(192, 256)}');
        mythic = _hexToInt('0x${hex.substring(256, 320)}');
      }

      final total = common + rare + epic + legendary + mythic;
      if (total == 0) {
        return const AchievementSummary();
      }

      // 2. Get token list: getAchievements(address) => 0x8ef578f6
      final achRaw = await _contractCall(
        achievementAddr,
        '0x8ef578f6',
        _padAddress(walletAddress),
      );

      // Decode dynamic array of structs – each struct has 5 fields:
      //   (uint256 tokenId, uint256 typeId, string name, uint8 rarity, uint256 mintedAt)
      // ABI-encoded: offset, length, then each struct is ABI-packed.
      final achievements = _decodeAchievements(achRaw, achievementAddr);

      return AchievementSummary(
        total: total,
        common: common,
        rare: rare,
        epic: epic,
        legendary: legendary,
        mythic: mythic,
        achievements: achievements,
      );
    } catch (e) {
      _log('getAchievementSummary error: $e');
      return const AchievementSummary();
    }
  }

  /// Get all active achievement types from the contract.
  Future<List<AchievementType>> getActiveAchievementTypes() async {
    try {
      final achievementAddr = BlockchainConfig.achievementAddress;
      if (achievementAddr.isEmpty ||
          achievementAddr == '0x0000000000000000000000000000000000000000') {
        return [];
      }

      // getActiveTypes() => 0xfa55b726
      final raw = await _contractCall(achievementAddr, '0xfa55b726');
      return _decodeAchievementTypes(raw);
    } catch (e) {
      _log('getActiveAchievementTypes error: $e');
      return [];
    }
  }

  /// Decode the return value of getAchievements(address).
  /// Returns `AchievementInfo[]` where each struct is:
  ///   (uint256 tokenId, uint256 typeId, string name, uint8 rarity, uint256 mintedAt)
  List<NftAchievement> _decodeAchievements(String raw, String contract) {
    if (raw.length < 66) return []; // 0x + offset
    try {
      final hex = raw.substring(2);
      // First 32 bytes = offset to dynamic data
      final dataOffset = _hexToInt('0x${hex.substring(0, 64)}') * 2;
      // Next 32 bytes at that offset = array length
      final arrayLen = _hexToInt('0x${hex.substring(dataOffset, dataOffset + 64)}');
      if (arrayLen == 0) return [];

      // For each element, there's an offset (relative to array start)
      final arrayStart = dataOffset + 64; // after length
      final List<NftAchievement> items = [];

      for (var i = 0; i < arrayLen && i < 200; i++) {
        try {
          // Each element offset is at arrayStart + i*64
          final elemOffsetHex = hex.substring(arrayStart + i * 64, arrayStart + (i + 1) * 64);
          final elemOffset = _hexToInt('0x$elemOffsetHex') * 2 + arrayStart;

          // Read fixed fields
          final tokenId = _hexToInt('0x${hex.substring(elemOffset, elemOffset + 64)}');
          final typeId = _hexToInt('0x${hex.substring(elemOffset + 64, elemOffset + 128)}');

          // name (string): offset at elemOffset + 128
          final nameOffset = _hexToInt('0x${hex.substring(elemOffset + 128, elemOffset + 192)}') * 2 + elemOffset;
          final nameLen = _hexToInt('0x${hex.substring(nameOffset, nameOffset + 64)}');
          final nameHex = hex.substring(nameOffset + 64, nameOffset + 64 + nameLen * 2);
          final name = _hexToString(nameHex);

          // rarity (uint8) at elemOffset + 192
          final rarityIdx = _hexToInt('0x${hex.substring(elemOffset + 192, elemOffset + 256)}');

          // mintedAt (uint256) at elemOffset + 256
          final mintedAt = _hexToInt('0x${hex.substring(elemOffset + 256, elemOffset + 320)}');

          items.add(NftAchievement(
            tokenId: tokenId,
            typeId: typeId,
            name: name,
            rarity: AchievementRarity.fromIndex(rarityIdx),
            mintedAt: DateTime.fromMillisecondsSinceEpoch(mintedAt * 1000),
            originalOwner: '', // not returned in this struct
            tokenURI: '',
          ));
        } catch (_) {
          // Skip malformed entries
          continue;
        }
      }

      return items;
    } catch (e) {
      _log('_decodeAchievements error: $e');
      return [];
    }
  }

  /// Decode the return value of getActiveTypes().
  /// Returns `AchievementTypeInfo[]` where each struct is:
  ///   (uint256 typeId, string name, uint8 rarity, string metadataURI, uint256 maxSupply, uint256 minted, bool active)
  List<AchievementType> _decodeAchievementTypes(String raw) {
    if (raw.length < 66) return [];
    try {
      final hex = raw.substring(2);
      final dataOffset = _hexToInt('0x${hex.substring(0, 64)}') * 2;
      final arrayLen = _hexToInt('0x${hex.substring(dataOffset, dataOffset + 64)}');
      if (arrayLen == 0) return [];
      final arrayStart = dataOffset + 64;

      final List<AchievementType> types = [];
      for (var i = 0; i < arrayLen && i < 200; i++) {
        try {
          final elemOffsetHex = hex.substring(arrayStart + i * 64, arrayStart + (i + 1) * 64);
          final elemOffset = _hexToInt('0x$elemOffsetHex') * 2 + arrayStart;

          final typeId = _hexToInt('0x${hex.substring(elemOffset, elemOffset + 64)}');

          // name string at offset
          final nameOffset = _hexToInt('0x${hex.substring(elemOffset + 64, elemOffset + 128)}') * 2 + elemOffset;
          final nameLen = _hexToInt('0x${hex.substring(nameOffset, nameOffset + 64)}');
          final nameHex = hex.substring(nameOffset + 64, nameOffset + 64 + nameLen * 2);
          final name = _hexToString(nameHex);

          final rarityIdx = _hexToInt('0x${hex.substring(elemOffset + 128, elemOffset + 192)}');

          // metadataURI string at offset
          final uriOffset = _hexToInt('0x${hex.substring(elemOffset + 192, elemOffset + 256)}') * 2 + elemOffset;
          final uriLen = _hexToInt('0x${hex.substring(uriOffset, uriOffset + 64)}');
          final uri = uriLen > 0
              ? _hexToString(hex.substring(uriOffset + 64, uriOffset + 64 + uriLen * 2))
              : '';

          final maxSupply = _hexToInt('0x${hex.substring(elemOffset + 256, elemOffset + 320)}');
          final minted = _hexToInt('0x${hex.substring(elemOffset + 320, elemOffset + 384)}');
          final active = _hexToInt('0x${hex.substring(elemOffset + 384, elemOffset + 448)}') == 1;

          types.add(AchievementType(
            typeId: typeId,
            name: name,
            rarity: AchievementRarity.fromIndex(rarityIdx),
            metadataURI: uri,
            maxSupply: maxSupply,
            minted: minted,
            active: active,
          ));
        } catch (_) {
          continue;
        }
      }
      return types;
    } catch (e) {
      _log('_decodeAchievementTypes error: $e');
      return [];
    }
  }

  /// Convert hex-encoded bytes to UTF-8 string
  String _hexToString(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes, allowMalformed: true).replaceAll('\x00', '');
  }

  // ──────────────────────────────────────────────
  // Transaction Verification
  // ──────────────────────────────────────────────

  /// Get transaction receipt by hash
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      final result = await _rpcCall('eth_getTransactionReceipt', [txHash]);
      if (result == null) return null;

      final data = result as Map<String, dynamic>;
      return TransactionReceipt(
        txHash: data['transactionHash'] as String,
        blockNumber: _hexToInt(data['blockNumber'] as String),
        status: data['status'] == '0x1',
        gasUsed: _hexToInt(data['gasUsed'] as String),
      );
    } catch (e) {
      _log('getTransactionReceipt error: $e');
      return null;
    }
  }

  /// Wait for transaction to be confirmed with required confirmations
  Future<bool> waitForConfirmation(
    String txHash, {
    int maxAttempts = 30,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      final receipt = await getTransactionReceipt(txHash);
      if (receipt != null) {
        // Check confirmations
        final currentBlock = await _getCurrentBlockNumber();
        final confirmations = currentBlock - receipt.blockNumber;

        if (confirmations >= BlockchainConfig.requiredConfirmations) {
          return receipt.status;
        }
      }
      await Future.delayed(pollInterval);
    }
    return false;
  }

  /// Get current block number
  Future<int> _getCurrentBlockNumber() async {
    try {
      final result = await _rpcCall('eth_blockNumber', []);
      return _hexToInt(result as String);
    } catch (e) {
      return 0;
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  /// Pad an address to 32 bytes for ABI encoding
  String _padAddress(String address) {
    final clean = address.toLowerCase().replaceFirst('0x', '');
    return clean.padLeft(64, '0');
  }

  /// Parse a hex result to a token amount (divide by 10^18)
  double _parseTokenAmount(String hex) {
    if (hex == '0x' || hex == '0x0') return 0;
    final clean = hex.replaceFirst('0x', '');
    final value = BigInt.parse(clean, radix: 16);
    return value / BigInt.from(10).pow(BlockchainConfig.tokenDecimals);
  }

  /// Convert hex string to double (for token amounts with 18 decimals)
  double _hexToDouble(String hex) {
    if (hex.isEmpty) return 0;
    final value = BigInt.parse(hex, radix: 16);
    return value / BigInt.from(10).pow(BlockchainConfig.tokenDecimals);
  }

  /// Convert hex to int
  int _hexToInt(String hex) {
    final clean = hex.replaceFirst('0x', '');
    return int.parse(clean, radix: 16);
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log('[BlockchainService] $message');
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }
}

// ──────────────────────────────────────────────
// Supporting Models
// ──────────────────────────────────────────────

class BridgeStats {
  final double totalDeposited;
  final double totalWithdrawn;
  final double lockedBalance;

  const BridgeStats({
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.lockedBalance,
  });

  factory BridgeStats.empty() => const BridgeStats(
        totalDeposited: 0,
        totalWithdrawn: 0,
        lockedBalance: 0,
      );
}

class StakingTier {
  final int id;
  final String name;
  final int lockDays;
  final double apyPercent;
  final double minStake;

  const StakingTier({
    required this.id,
    required this.name,
    required this.lockDays,
    required this.apyPercent,
    required this.minStake,
  });
}

class TransactionReceipt {
  final String txHash;
  final int blockNumber;
  final bool status;
  final int gasUsed;

  const TransactionReceipt({
    required this.txHash,
    required this.blockNumber,
    required this.status,
    required this.gasUsed,
  });
}

class BlockchainException implements Exception {
  final String message;
  const BlockchainException(this.message);

  @override
  String toString() => 'BlockchainException: $message';
}

/// Extension on BigInt for token math
extension BigIntDivision on BigInt {
  double operator /(BigInt other) {
    return toDouble() / other.toDouble();
  }
}
