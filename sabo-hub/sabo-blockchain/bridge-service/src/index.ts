import express from 'express';
import cors from 'cors';
import { config, validateConfig } from './config.js';
import { logger } from './logger.js';
import { BlockchainService } from './blockchain.js';
import { SupabaseService } from './supabase.js';
import { BridgeProcessor } from './processor.js';

const MOD = 'Server';

async function main() {
  logger.info(MOD, '🚀 SABO Bridge Service starting...');

  // Validate environment — throws if required vars are missing
  validateConfig();

  // Initialize services
  const blockchain = new BlockchainService();
  const supabase = new SupabaseService();
  const processor = new BridgeProcessor(blockchain, supabase);

  // Create Express app
  const app = express();
  app.use(cors());
  app.use(express.json());

  // ── Health endpoint ──────────────────────────────────────────
  app.get('/health', async (_req, res) => {
    try {
      const stats = await blockchain.getStats();
      const operatorBalance = await blockchain.getOperatorBalance();

      res.json({
        status: 'ok',
        service: 'sabo-bridge',
        timestamp: new Date().toISOString(),
        operator: blockchain.operatorAddress,
        operatorBalance,
        bridge: {
          totalLocked: stats.totalLocked,
          totalWithdrawn: stats.totalWithdrawn,
          bridgeBalance: stats.bridgeBalance,
          isPaused: stats.isPaused,
        },
      });
    } catch (error: any) {
      res.status(503).json({
        status: 'error',
        error: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  });

  // ── Bridge stats endpoint ────────────────────────────────────
  app.get('/api/bridge/stats', async (_req, res) => {
    try {
      const stats = await blockchain.getStats();
      res.json({ success: true, data: stats });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // ── Verify deposit endpoint (called by Flutter app) ─────────
  app.post('/api/bridge/verify-deposit', async (req, res) => {
    const { txHash } = req.body;
    if (!txHash) {
      res.status(400).json({ success: false, error: 'txHash is required' });
      return;
    }

    try {
      const deposit = await blockchain.verifyDeposit(txHash);
      if (deposit) {
        res.json({ success: true, data: deposit });
      } else {
        res.status(404).json({ success: false, error: 'Deposit not found or not confirmed' });
      }
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // ── Start processor ──────────────────────────────────────────
  const pollInterval = parseInt(process.env.POLL_INTERVAL_MS || '15000');
  processor.start(pollInterval);

  // ── Start HTTP server ────────────────────────────────────────
  const port = config.port;
  app.listen(port, () => {
    logger.info(MOD, `🌐 HTTP server listening on port ${port}`);
    logger.info(MOD, `   Health: http://localhost:${port}/health`);
    logger.info(MOD, `   Stats:  http://localhost:${port}/api/bridge/stats`);
  });

  // ── Graceful shutdown ────────────────────────────────────────
  const shutdown = () => {
    logger.info(MOD, 'Shutting down...');
    processor.stop();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((error) => {
  logger.error(MOD, `Fatal: ${error.message}`);
  process.exit(1);
});
