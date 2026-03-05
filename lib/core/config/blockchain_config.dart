/// Blockchain configuration for SABO Token on Base L2
///
/// Contains contract addresses, chain configs, and ABI definitions
/// for interacting with on-chain SABO Token ecosystem.
class BlockchainConfig {
  BlockchainConfig._();

  // ─── Network ──────────────────────────────────────────

  /// Current environment: 'testnet' or 'mainnet'
  static const String environment = 'testnet';

  /// Whether we're on testnet
  static bool get isTestnet => environment == 'testnet';

  // ─── Chain Config ─────────────────────────────────────

  /// Base Sepolia (Testnet)
  static const int testnetChainId = 84532;
  static const String testnetRpcUrl = 'https://sepolia.base.org';
  static const String testnetExplorerUrl = 'https://sepolia.basescan.org';

  /// Base Mainnet
  static const int mainnetChainId = 8453;
  static const String mainnetRpcUrl = 'https://mainnet.base.org';
  static const String mainnetExplorerUrl = 'https://basescan.org';

  /// Active chain config based on environment
  static int get chainId => isTestnet ? testnetChainId : mainnetChainId;
  static String get rpcUrl => isTestnet ? testnetRpcUrl : mainnetRpcUrl;
  static String get explorerUrl =>
      isTestnet ? testnetExplorerUrl : mainnetExplorerUrl;

  static String get chainName => isTestnet ? 'Base Sepolia' : 'Base';
  static String get nativeCurrency => 'ETH';

  // ─── Contract Addresses ───────────────────────────────
  // NOTE: Update these after deploying to testnet/mainnet

  /// SABOToken ERC-20 contract address
  static const String testnetTokenAddress =
      '0x7a0CCE4109b0c593f42F6DA3F4b120ad4677b472'; // Deployed 2026-03-04

  static const String mainnetTokenAddress =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy & update

  /// SABOBridge contract address
  static const String testnetBridgeAddress =
      '0x0D32577079a54f36e99b9E8ff79ed3208dB3Fb30'; // Deployed 2026-03-04

  static const String mainnetBridgeAddress =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy & update

  /// SABOStaking contract address
  static const String testnetStakingAddress =
      '0xA548119EB79Be531B122AB543c92F340aceD8886'; // Deployed 2026-03-04

  static const String mainnetStakingAddress =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy & update

  /// SABOAchievement (Soulbound NFT) contract address
  static const String testnetAchievementAddress =
      '0xA245e4Eb8d5814436a295b7dF104aF541E2a8BFb'; // Deployed 2026-03-04

  static const String mainnetAchievementAddress =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy & update

  /// Active contract addresses based on environment
  static String get tokenAddress =>
      isTestnet ? testnetTokenAddress : mainnetTokenAddress;
  static String get bridgeAddress =>
      isTestnet ? testnetBridgeAddress : mainnetBridgeAddress;
  static String get stakingAddress =>
      isTestnet ? testnetStakingAddress : mainnetStakingAddress;
  static String get achievementAddress =>
      isTestnet ? testnetAchievementAddress : mainnetAchievementAddress;

  // ─── Bridge Config ────────────────────────────────────

  /// Minimum amount for bridge operations (matching on-chain limits)
  static const double minBridgeAmount = 50.0;

  /// Maximum withdraw amount per transaction
  static const double maxWithdrawAmount = 10000.0;

  /// Withdraw fee in basis points (100 = 1%)
  static const int withdrawFeeBps = 100;

  /// Cooldown period between withdrawals (seconds)
  static const int withdrawCooldown = 3600; // 1 hour

  /// Required confirmations for deposit verification
  static const int requiredConfirmations = 12;

  // ─── Token Info ───────────────────────────────────────

  static const String tokenName = 'SABO Token';
  static const String tokenSymbol = 'SABO';
  static const int tokenDecimals = 18;
  static const double maxSupply = 100000000; // 100M

  // ─── Bridge API ───────────────────────────────────────
  // NOTE: Will be configured when Bridge Backend is deployed

  static const String bridgeApiUrl = ''; // TODO: Set bridge API endpoint

  // ─── Helpers ──────────────────────────────────────────

  /// Calculate withdraw fee for a given amount
  static double calculateWithdrawFee(double amount) {
    return amount * withdrawFeeBps / 10000;
  }

  /// Calculate net amount after withdraw fee
  static double calculateNetWithdraw(double amount) {
    return amount - calculateWithdrawFee(amount);
  }

  /// Get block explorer URL for a transaction hash
  static String getTxUrl(String txHash) {
    return '$explorerUrl/tx/$txHash';
  }

  /// Get block explorer URL for an address
  static String getAddressUrl(String address) {
    return '$explorerUrl/address/$address';
  }

  /// Get block explorer URL for the token contract
  static String get tokenUrl => getAddressUrl(tokenAddress);

  /// Validate Ethereum address format
  static bool isValidAddress(String address) {
    return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
  }

  // ─── Additional Getters for Wallet Page ───────────────

  /// Network name for display
  static String get networkName => chainName;

  /// Withdraw fee as percentage (for display)
  static double get withdrawFeePercent => withdrawFeeBps / 100;

  /// Bridge contract address (alias for bridgeAddress)
  static String get bridgeContract => bridgeAddress;
}
