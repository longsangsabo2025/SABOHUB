import { ethers } from 'ethers';
import { config } from './config.js';
import { logger } from './logger.js';

// Minimal ABI for SABOBridge — only the functions we need
const BRIDGE_ABI = [
  'function withdraw(address to, uint256 amount, bytes32 requestId) external',
  'function processedRequests(bytes32) view returns (bool)',
  'function canWithdraw(address) view returns (bool)',
  'function getStats() view returns (uint256 totalLocked, uint256 totalWithdrawn, uint256 bridgeBalance, bool paused)',
  'function withdrawFeePercent() view returns (uint256)',
  'function minWithdrawAmount() view returns (uint256)',
  'function maxWithdrawAmount() view returns (uint256)',
  'function paused() view returns (bool)',
  'event Withdrawn(address indexed user, uint256 amount, uint256 fee, bytes32 indexed requestId, uint256 nonce, uint256 timestamp)',
  'event Deposited(address indexed user, uint256 amount, string offchainWalletId, uint256 timestamp)',
];

const TOKEN_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function totalSupply() view returns (uint256)',
];

export interface WithdrawResult {
  success: boolean;
  txHash?: string;
  netAmount?: string;
  fee?: string;
  error?: string;
}

export interface BridgeStats {
  totalLocked: string;
  totalWithdrawn: string;
  bridgeBalance: string;
  isPaused: boolean;
  operatorBalance: string;
}

export interface DepositEvent {
  user: string;
  amount: string;
  offchainWalletId: string;
  timestamp: number;
  txHash: string;
  blockNumber: number;
}

const MOD = 'Blockchain';

export class BlockchainService {
  private provider: ethers.JsonRpcProvider;
  private wallet: ethers.Wallet;
  private bridgeContract: ethers.Contract;
  private tokenContract: ethers.Contract;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    this.wallet = new ethers.Wallet(config.deployerPrivateKey, this.provider);
    this.bridgeContract = new ethers.Contract(config.saboBridgeAddress, BRIDGE_ABI, this.wallet);
    this.tokenContract = new ethers.Contract(config.saboTokenAddress, TOKEN_ABI, this.provider);

    logger.info(MOD, `Initialized — Operator: ${this.wallet.address}`);
    logger.info(MOD, `Bridge: ${config.saboBridgeAddress}`);
    logger.info(MOD, `Token: ${config.saboTokenAddress}`);
  }

  /**
   * Process a withdrawal: call bridge.withdraw() on-chain.
   * The bridge contract mints SABO tokens to the user's wallet.
   */
  async processWithdraw(
    userAddress: string,
    amount: bigint,
    requestId: string, // UUID from Supabase
  ): Promise<WithdrawResult> {
    try {
      // Convert request ID to bytes32
      const requestIdBytes32 = ethers.encodeBytes32String(requestId.slice(0, 31));

      // Pre-flight checks
      const isPaused = await this.bridgeContract.paused();
      if (isPaused) {
        return { success: false, error: 'Bridge is paused' };
      }

      const isProcessed = await this.bridgeContract.processedRequests(requestIdBytes32);
      if (isProcessed) {
        return { success: false, error: 'Request already processed on-chain' };
      }

      const canWithdrawResult = await this.bridgeContract.canWithdraw(userAddress);
      if (!canWithdrawResult) {
        return { success: false, error: 'Cooldown active for this address' };
      }

      logger.info(MOD, `Processing withdraw: ${ethers.formatEther(amount)} SABO → ${userAddress}`);

      // Send transaction
      const tx = await this.bridgeContract.withdraw(userAddress, amount, requestIdBytes32);
      logger.info(MOD, `Tx sent: ${tx.hash}`);

      // Wait for confirmation (2 blocks)
      const receipt = await tx.wait(2);
      logger.info(MOD, `Tx confirmed in block ${receipt.blockNumber}`);

      // Parse Withdrawn event to get net amount and fee
      const withdrawnEvent = receipt.logs
        .map((log: ethers.Log) => {
          try { return this.bridgeContract.interface.parseLog(log); } catch { return null; }
        })
        .find((e: ethers.LogDescription | null) => e?.name === 'Withdrawn');

      const netAmount = withdrawnEvent ? ethers.formatEther(withdrawnEvent.args[1]) : ethers.formatEther(amount);
      const fee = withdrawnEvent ? ethers.formatEther(withdrawnEvent.args[2]) : '0';

      return {
        success: true,
        txHash: tx.hash,
        netAmount,
        fee,
      };
    } catch (error: any) {
      logger.error(MOD, `Withdraw failed: ${error.message}`);
      return { success: false, error: error.message || 'Unknown error' };
    }
  }

  /**
   * Verify a deposit transaction on-chain.
   * Checks that the tx exists, was confirmed, and emitted a Deposited event.
   */
  async verifyDeposit(txHash: string): Promise<DepositEvent | null> {
    try {
      const receipt = await this.provider.getTransactionReceipt(txHash);
      if (!receipt || receipt.status !== 1) {
        logger.warn(MOD, `Deposit tx ${txHash} not found or failed`);
        return null;
      }

      // Parse Deposited event
      for (const log of receipt.logs) {
        try {
          const parsed = this.bridgeContract.interface.parseLog(log);
          if (parsed?.name === 'Deposited') {
            return {
              user: parsed.args[0],
              amount: ethers.formatEther(parsed.args[1]),
              offchainWalletId: parsed.args[2],
              timestamp: Number(parsed.args[3]),
              txHash,
              blockNumber: receipt.blockNumber,
            };
          }
        } catch {
          // Not our event, skip
        }
      }

      logger.warn(MOD, `No Deposited event found in tx ${txHash}`);
      return null;
    } catch (error: any) {
      logger.error(MOD, `verifyDeposit failed: ${error.message}`);
      return null;
    }
  }

  /**
   * Get bridge statistics from on-chain contract.
   */
  async getStats(): Promise<BridgeStats> {
    const [totalLocked, totalWithdrawn, bridgeBalance, isPaused] = await this.bridgeContract.getStats();
    const operatorBalance = await this.provider.getBalance(this.wallet.address);

    return {
      totalLocked: ethers.formatEther(totalLocked),
      totalWithdrawn: ethers.formatEther(totalWithdrawn),
      bridgeBalance: ethers.formatEther(bridgeBalance),
      isPaused,
      operatorBalance: ethers.formatEther(operatorBalance),
    };
  }

  /**
   * Check operator (deployer) wallet ETH balance for gas.
   */
  async getOperatorBalance(): Promise<string> {
    const balance = await this.provider.getBalance(this.wallet.address);
    return ethers.formatEther(balance);
  }

  get operatorAddress(): string {
    return this.wallet.address;
  }
}
