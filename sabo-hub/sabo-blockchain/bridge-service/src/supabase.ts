import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from './config.js';
import { logger } from './logger.js';

const MOD = 'Supabase';

export interface BridgeRequest {
  id: string;
  employee_id: string;
  request_type: 'deposit' | 'withdraw';
  amount: number;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled';
  wallet_address: string | null;
  tx_hash: string | null;
  on_chain_amount: number | null;
  fee_amount: number | null;
  error_message: string | null;
  created_at: string;
  processed_at: string | null;
}

export interface WalletLink {
  employee_id: string;
  wallet_address: string;
}

export class SupabaseService {
  private client: SupabaseClient;

  constructor() {
    this.client = createClient(config.supabaseUrl, config.supabaseServiceKey);
    logger.info(MOD, 'Initialized Supabase client');
  }

  /**
   * Get all pending withdrawal requests ordered by creation time.
   */
  async getPendingWithdrawals(): Promise<BridgeRequest[]> {
    const { data, error } = await this.client
      .from('bridge_requests')
      .select('*')
      .eq('request_type', 'withdraw')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(10); // Process up to 10 at a time

    if (error) {
      logger.error(MOD, `getPendingWithdrawals failed: ${error.message}`);
      return [];
    }

    return data || [];
  }

  /**
   * Get pending deposit verifications (deposits submitted from the app with a tx_hash).
   */
  async getPendingDeposits(): Promise<BridgeRequest[]> {
    const { data, error } = await this.client
      .from('bridge_requests')
      .select('*')
      .eq('request_type', 'deposit')
      .eq('status', 'pending')
      .not('tx_hash', 'is', null)
      .order('created_at', { ascending: true })
      .limit(10);

    if (error) {
      logger.error(MOD, `getPendingDeposits failed: ${error.message}`);
      return [];
    }

    return data || [];
  }

  /**
   * Mark a request as processing (being sent to blockchain).
   */
  async markProcessing(requestId: string): Promise<boolean> {
    const { error } = await this.client
      .from('bridge_requests')
      .update({ status: 'processing' })
      .eq('id', requestId)
      .eq('status', 'pending'); // Optimistic lock

    if (error) {
      logger.error(MOD, `markProcessing(${requestId}) failed: ${error.message}`);
      return false;
    }
    return true;
  }

  /**
   * Mark a request as completed with on-chain details.
   */
  async markCompleted(
    requestId: string,
    txHash: string,
    onChainAmount: number,
    feeAmount: number,
  ): Promise<boolean> {
    const { error } = await this.client
      .from('bridge_requests')
      .update({
        status: 'completed',
        tx_hash: txHash,
        on_chain_amount: onChainAmount,
        fee_amount: feeAmount,
        processed_at: new Date().toISOString(),
      })
      .eq('id', requestId);

    if (error) {
      logger.error(MOD, `markCompleted(${requestId}) failed: ${error.message}`);
      return false;
    }
    return true;
  }

  /**
   * Mark a request as failed with error message.
   */
  async markFailed(requestId: string, errorMessage: string): Promise<boolean> {
    const { error } = await this.client
      .from('bridge_requests')
      .update({
        status: 'failed',
        error_message: errorMessage,
        processed_at: new Date().toISOString(),
      })
      .eq('id', requestId);

    if (error) {
      logger.error(MOD, `markFailed(${requestId}) failed: ${error.message}`);
      return false;
    }
    return true;
  }

  /**
   * Credit tokens to employee's off-chain balance (for verified deposits).
   * Calls the earn_tokens Supabase RPC.
   */
  async creditOffChainTokens(
    employeeId: string,
    amount: number,
    description: string,
  ): Promise<boolean> {
    const { error } = await this.client.rpc('earn_tokens', {
      p_employee_id: employeeId,
      p_amount: amount,
      p_source: 'bridge_deposit',
      p_description: description,
    });

    if (error) {
      logger.error(MOD, `creditOffChainTokens(${employeeId}) failed: ${error.message}`);
      return false;
    }
    return true;
  }

  /**
   * Get wallet link for an employee.
   */
  async getWalletLink(employeeId: string): Promise<WalletLink | null> {
    const { data, error } = await this.client
      .from('wallet_links')
      .select('employee_id, wallet_address')
      .eq('employee_id', employeeId)
      .single();

    if (error) {
      return null;
    }
    return data;
  }

  /**
   * Find employee by wallet address (for deposit → off-chain credit).
   */
  async findEmployeeByWallet(walletAddress: string): Promise<string | null> {
    const { data, error } = await this.client
      .from('wallet_links')
      .select('employee_id')
      .eq('wallet_address', walletAddress.toLowerCase())
      .single();

    if (error) {
      return null;
    }
    return data?.employee_id || null;
  }
}
