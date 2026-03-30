import 'dotenv/config';

export const config = {
  // Supabase
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY || '',

  // Blockchain
  rpcUrl: process.env.RPC_URL || 'https://sepolia.base.org',
  chainId: parseInt(process.env.CHAIN_ID || '84532'),
  deployerPrivateKey: process.env.DEPLOYER_PRIVATE_KEY || '',

  // Contract Addresses
  saboTokenAddress: process.env.SABO_TOKEN_ADDRESS || '',
  saboBridgeAddress: process.env.SABO_BRIDGE_ADDRESS || '',

  // Service
  port: parseInt(process.env.PORT || '3001'),
  pollIntervalMs: parseInt(process.env.POLL_INTERVAL_MS || '15000'),
  maxRetries: parseInt(process.env.MAX_RETRIES || '3'),

  // Limits
  maxDailyWithdrawTotal: parseFloat(process.env.MAX_DAILY_WITHDRAW_TOTAL || '50000'),
  maxSingleWithdraw: parseFloat(process.env.MAX_SINGLE_WITHDRAW || '10000'),
} as const;

export function validateConfig(): void {
  const required = [
    ['SUPABASE_URL', config.supabaseUrl],
    ['SUPABASE_SERVICE_KEY', config.supabaseServiceKey],
    ['DEPLOYER_PRIVATE_KEY', config.deployerPrivateKey],
    ['SABO_TOKEN_ADDRESS', config.saboTokenAddress],
    ['SABO_BRIDGE_ADDRESS', config.saboBridgeAddress],
  ] as const;

  const missing = required.filter(([, v]) => !v).map(([k]) => k);
  if (missing.length > 0) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
}
