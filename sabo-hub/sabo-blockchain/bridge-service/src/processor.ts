import { ethers } from 'ethers';
import { BlockchainService, WithdrawResult } from './blockchain.js';
import { SupabaseService, BridgeRequest } from './supabase.js';
import { logger } from './logger.js';

const MOD = 'Processor';

export class BridgeProcessor {
  private blockchain: BlockchainService;
  private supabase: SupabaseService;
  private isRunning = false;
  private pollInterval: NodeJS.Timeout | null = null;

  constructor(blockchain: BlockchainService, supabase: SupabaseService) {
    this.blockchain = blockchain;
    this.supabase = supabase;
  }

  /**
   * Start the processing loop. Polls for pending requests every `intervalMs`.
   */
  start(intervalMs = 15_000): void {
    if (this.isRunning) return;
    this.isRunning = true;
    logger.info(MOD, `Starting processor — poll every ${intervalMs / 1000}s`);

    // Process immediately on start
    this.tick();

    this.pollInterval = setInterval(() => this.tick(), intervalMs);
  }

  stop(): void {
    if (!this.isRunning) return;
    this.isRunning = false;
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
    logger.info(MOD, 'Processor stopped');
  }

  /**
   * One processing cycle — fetch pending requests and process them.
   */
  private async tick(): Promise<void> {
    try {
      await this.processWithdrawals();
      await this.verifyDeposits();
    } catch (error: any) {
      logger.error(MOD, `Tick error: ${error.message}`);
    }
  }

  /**
   * Process pending withdrawal requests.
   * Flow: pending → processing → withdraw on-chain → completed/failed
   */
  private async processWithdrawals(): Promise<void> {
    const pending = await this.supabase.getPendingWithdrawals();
    if (pending.length === 0) return;

    logger.info(MOD, `Found ${pending.length} pending withdrawal(s)`);

    for (const request of pending) {
      await this.processOneWithdrawal(request);
    }
  }

  private async processOneWithdrawal(request: BridgeRequest): Promise<void> {
    const { id, employee_id, amount, wallet_address } = request;

    if (!wallet_address) {
      await this.supabase.markFailed(id, 'No wallet address linked');
      logger.warn(MOD, `Withdrawal ${id}: no wallet address`);
      return;
    }

    // Validate amount
    if (amount <= 0) {
      await this.supabase.markFailed(id, 'Invalid amount');
      return;
    }

    // Mark as processing (optimistic lock)
    const locked = await this.supabase.markProcessing(id);
    if (!locked) {
      logger.warn(MOD, `Withdrawal ${id}: couldn't acquire lock (already processing?)`);
      return;
    }

    logger.info(MOD, `Processing withdrawal ${id}: ${amount} SABO → ${wallet_address}`);

    // Convert to wei
    const amountWei = ethers.parseEther(amount.toString());

    // Call bridge.withdraw() on-chain
    const result: WithdrawResult = await this.blockchain.processWithdraw(
      wallet_address,
      amountWei,
      id,
    );

    if (result.success) {
      const netAmount = parseFloat(result.netAmount || '0');
      const fee = parseFloat(result.fee || '0');

      await this.supabase.markCompleted(id, result.txHash!, netAmount, fee);
      logger.info(MOD, `✅ Withdrawal ${id} completed — tx: ${result.txHash}`);
    } else {
      await this.supabase.markFailed(id, result.error || 'Unknown error');
      logger.error(MOD, `❌ Withdrawal ${id} failed: ${result.error}`);
    }
  }

  /**
   * Verify pending deposit transactions.
   * These are deposits submitted by users with a tx_hash — we verify on-chain and credit off-chain.
   */
  private async verifyDeposits(): Promise<void> {
    const pending = await this.supabase.getPendingDeposits();
    if (pending.length === 0) return;

    logger.info(MOD, `Found ${pending.length} pending deposit(s) to verify`);

    for (const request of pending) {
      await this.verifyOneDeposit(request);
    }
  }

  private async verifyOneDeposit(request: BridgeRequest): Promise<void> {
    const { id, employee_id, tx_hash } = request;

    if (!tx_hash) {
      await this.supabase.markFailed(id, 'No tx_hash provided');
      return;
    }

    // Lock the request
    const locked = await this.supabase.markProcessing(id);
    if (!locked) return;

    logger.info(MOD, `Verifying deposit ${id}: tx ${tx_hash}`);

    // Verify on-chain
    const deposit = await this.blockchain.verifyDeposit(tx_hash);

    if (!deposit) {
      await this.supabase.markFailed(id, 'Transaction not found or no Deposited event');
      logger.warn(MOD, `Deposit ${id}: verification failed`);
      return;
    }

    // Credit off-chain balance
    const amountNum = parseFloat(deposit.amount);
    const credited = await this.supabase.creditOffChainTokens(
      employee_id,
      amountNum,
      `Bridge deposit — tx: ${tx_hash.slice(0, 10)}...`,
    );

    if (credited) {
      await this.supabase.markCompleted(id, tx_hash, amountNum, 0);
      logger.info(MOD, `✅ Deposit ${id} verified — ${deposit.amount} SABO credited to ${employee_id}`);
    } else {
      await this.supabase.markFailed(id, 'Failed to credit off-chain balance');
      logger.error(MOD, `❌ Deposit ${id}: on-chain verified but off-chain credit failed`);
    }
  }
}
