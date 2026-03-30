# SABO Token Bridge Architecture

## Tổng quan

Bridge Architecture mô tả cách SABO Token chuyển đổi giữa hệ thống off-chain (Supabase) và on-chain (Base L2 Ethereum).

```
┌─────────────────────────────────────────────────────────────────┐
│                     SABOHUB Flutter App                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  Token UI     │  │  Bridge UI   │  │  Staking UI           │ │
│  │  (balance,    │  │  (withdraw,  │  │  (stake, unstake,     │ │
│  │   history)    │  │   deposit)   │  │   rewards)            │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────┘ │
│         │                 │                       │             │
│  ┌──────┴─────────────────┴───────────────────────┴───────────┐ │
│  │                   TokenService (Dart)                       │ │
│  │  - getBalance()    - requestWithdraw()                      │ │
│  │  - getHistory()    - confirmDeposit()                       │ │
│  │  - purchaseItem()  - getBridgeStatus()                      │ │
│  └──────┬─────────────────┬───────────────────────┬───────────┘ │
│         │                 │                       │             │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌───────────┴───────────┐ │
│  │  Supabase    │  │ BlockchainSvc│  │  Web3Provider         │ │
│  │  Client      │  │ (REST API)   │  │  (ethers.js/wagmi)    │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────┘ │
└─────────┼─────────────────┼───────────────────────┼─────────────┘
          │                 │                       │
          ▼                 ▼                       ▼
┌─────────────────┐ ┌──────────────┐  ┌───────────────────────────┐
│   Supabase DB   │ │ Bridge API   │  │     Base L2 Blockchain    │
│                 │ │  (Backend)   │  │                           │
│ token_wallets   │ │              │  │  SABOToken.sol            │
│ token_txns      │ │ Validates &  │  │  SABOBridge.sol           │
│ bridge_requests │ │ signs txns   │  │  SABOStaking.sol          │
│ token_store     │ │              │  │                           │
└─────────────────┘ └──────────────┘  └───────────────────────────┘
```

---

## Flow 1: Withdraw (Off-chain → On-chain)

Người dùng muốn chuyển SABO từ app sang ví blockchain.

```
User                    Flutter App             Supabase              Bridge API           Blockchain
 │                         │                      │                      │                    │
 │  1. Request Withdraw    │                      │                      │                    │
 │  (amount, walletAddr)   │                      │                      │                    │
 │────────────────────────▶│                      │                      │                    │
 │                         │  2. Validate balance  │                      │                    │
 │                         │─────────────────────▶│                      │                    │
 │                         │  3. balance >= amount │                      │                    │
 │                         │◀─────────────────────│                      │                    │
 │                         │                      │                      │                    │
 │                         │  4. Create bridge_request                   │                    │
 │                         │     (status: pending) │                      │                    │
 │                         │─────────────────────▶│                      │                    │
 │                         │  5. request_id        │                      │                    │
 │                         │◀─────────────────────│                      │                    │
 │                         │                      │                      │                    │
 │                         │  6. Deduct off-chain balance               │                    │
 │                         │─────────────────────▶│                      │                    │
 │                         │                      │                      │                    │
 │                         │  7. POST /bridge/withdraw                  │                    │
 │                         │     {requestId, to, amount}                │                    │
 │                         │─────────────────────────────────────────── ▶│                    │
 │                         │                      │                      │                    │
 │                         │                      │                      │  8. SABOBridge      │
 │                         │                      │                      │     .withdraw()     │
 │                         │                      │                      │───────────────────▶│
 │                         │                      │                      │  9. Tokens minted   │
 │                         │                      │                      │◀───────────────────│
 │                         │                      │                      │                    │
 │                         │  10. Update bridge_request                 │                    │
 │                         │      (status: completed, txHash)           │                    │
 │                         │◀──────────────────────────────────────────│                    │
 │                         │                      │                      │                    │
 │  11. Success + txHash   │                      │                      │                    │
 │◀────────────────────────│                      │                      │                    │
```

### Withdraw Rules
| Rule | Value | Mô tả |
|------|-------|-------|
| Minimum | 50 SABO | Không cho withdraw dưới 50 |
| Maximum | 10,000 SABO | Giới hạn 1 lần withdraw |
| Cooldown | 1 giờ | Sau mỗi lần withdraw |
| Fee | 1% (burned) | Giảm phát, fee bị đốt |
| KYC | Required | Phải verify trước khi withdraw |

---

## Flow 2: Deposit (On-chain → Off-chain)

Người dùng muốn chuyển SABO từ ví blockchain vào app.

```
User                    Flutter App             Blockchain            Bridge API           Supabase
 │                         │                      │                      │                    │
 │  1. Initiate Deposit    │                      │                      │                    │
 │  (amount)               │                      │                      │                    │
 │────────────────────────▶│                      │                      │                    │
 │                         │  2. Approve Bridge    │                      │                    │
 │                         │─────────────────────▶│                      │                    │
 │                         │  3. Call deposit()    │                      │                    │
 │                         │─────────────────────▶│                      │                    │
 │                         │  4. Tokens locked +   │                      │                    │
 │                         │     Deposited event   │                      │                    │
 │                         │◀─────────────────────│                      │                    │
 │                         │                      │                      │                    │
 │                         │  5. POST /bridge/deposit                   │                    │
 │                         │     {txHash, amount, walletId}             │                    │
 │                         │─────────────────────────────────────────── ▶│                    │
 │                         │                      │                      │                    │
 │                         │                      │                      │  6. Verify txHash   │
 │                         │                      │◀─────────────────────│                    │
 │                         │                      │  7. Confirmed        │                    │
 │                         │                      │─────────────────────▶│                    │
 │                         │                      │                      │                    │
 │                         │                      │                      │  8. Credit off-chain│
 │                         │                      │                      │     balance         │
 │                         │                      │                      │───────────────────▶│
 │                         │                      │                      │                    │
 │                         │  9. Update bridge_request (completed)       │                    │
 │                         │◀──────────────────────────────────────────│                    │
 │                         │                      │                      │                    │
 │  10. Deposit confirmed  │                      │                      │                    │
 │◀────────────────────────│                      │                      │                    │
```

### Deposit Rules
| Rule | Value | Mô tả |
|------|-------|-------|
| Minimum | 50 SABO | Không cho deposit dưới 50 |
| Confirmations | 12 blocks | Chờ ~24 giây trên Base |
| Fee | 0% | Khuyến khích deposit |

---

## Database Schema: bridge_requests

```sql
CREATE TABLE bridge_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id),
  wallet_id UUID NOT NULL REFERENCES token_wallets(id),
  
  -- Request details
  type TEXT NOT NULL CHECK (type IN ('withdraw', 'deposit')),
  amount DECIMAL(18,4) NOT NULL,
  fee_amount DECIMAL(18,4) NOT NULL DEFAULT 0,
  net_amount DECIMAL(18,4) NOT NULL,
  
  -- Blockchain info
  wallet_address TEXT,
  tx_hash TEXT,
  block_number BIGINT,
  chain_id INTEGER DEFAULT 8453,
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  error_message TEXT,
  
  -- Metadata
  request_id TEXT UNIQUE, -- For replay protection
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  -- Business context
  business_id UUID REFERENCES businesses(id),
  branch_id UUID REFERENCES branches(id)
);

-- Indexes
CREATE INDEX idx_bridge_requests_employee ON bridge_requests(employee_id);
CREATE INDEX idx_bridge_requests_status ON bridge_requests(status);
CREATE INDEX idx_bridge_requests_type ON bridge_requests(type);
CREATE INDEX idx_bridge_requests_tx_hash ON bridge_requests(tx_hash);

-- RLS
ALTER TABLE bridge_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bridge requests" ON bridge_requests
  FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "Users can create own bridge requests" ON bridge_requests
  FOR INSERT WITH CHECK (employee_id = auth.uid());

-- Trigger: auto update updated_at
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON bridge_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## Security Architecture

### Multi-Layer Security

```
┌───────────────────────────────────────────────────────────┐
│                   Security Layers                          │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  Layer 1: Client Validation                               │
│  ├── Input validation (amount, address format)            │
│  ├── Balance check before request                         │
│  └── Rate limiting (UI-level cooldown)                    │
│                                                           │
│  Layer 2: Backend Validation (Bridge API)                 │
│  ├── JWT authentication                                   │
│  ├── Double-check balance from Supabase                   │
│  ├── KYC verification status                              │
│  ├── Daily withdrawal limit per user                      │
│  └── Fraud detection (unusual patterns)                   │
│                                                           │
│  Layer 3: Smart Contract Security                         │
│  ├── Replay protection (request ID uniqueness)            │
│  ├── Cooldown period enforcement                          │
│  ├── Min/Max withdrawal limits                            │
│  ├── Reentrancy guard                                     │
│  ├── Pausable (emergency stop)                            │
│  └── Ownable2Step (no accidental ownership transfer)      │
│                                                           │
│  Layer 4: Monitoring & Alerting                           │
│  ├── Large transaction alerts (> 5000 SABO)               │
│  ├── Unusual pattern detection                            │
│  ├── Bridge balance monitoring                            │
│  └── Failed transaction tracking                          │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Key Security Measures

| Measure | Implementation | Mục đích |
|---------|---------------|----------|
| Replay Protection | `processedRequests` mapping + unique `requestId` | Chống double-withdraw |
| Cooldown | 1 hour between withdrawals | Chống drain attack |
| Daily Limit | Max 10,000 SABO/withdraw | Giới hạn thiệt hại |
| 2-Step Ownership | `Ownable2Step` | Chống mất ownership |
| Emergency Pause | `Pausable` | Dừng khẩn cấp |
| Reentrancy Guard | `ReentrancyGuard` | Chống reentrancy |
| Fee Burning | 1% withdraw fee burned | Giảm phát + anti-gaming |

---

## State Machine: Bridge Request

```
                    ┌──────────┐
         create     │          │
        ────────▶   │ PENDING  │
                    │          │
                    └────┬─────┘
                         │
                    pick up by
                    bridge worker
                         │
                    ┌────▼─────┐
                    │          │
                    │PROCESSING│
                    │          │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         tx success   tx fail   timeout
              │          │          │
        ┌─────▼────┐ ┌──▼───┐ ┌───▼──────┐
        │          │ │      │ │          │
        │COMPLETED │ │FAILED│ │CANCELLED │
        │          │ │      │ │          │
        └──────────┘ └──────┘ └──────────┘
```

### Status Descriptions

| Status | Mô tả | Next States |
|--------|--------|-------------|
| `pending` | Request mới tạo, chờ xử lý | processing, cancelled |
| `processing` | Đang gửi transaction lên blockchain | completed, failed |
| `completed` | Transaction confirmed on-chain | (terminal) |
| `failed` | Transaction bị lỗi, balance refunded | pending (retry) |
| `cancelled` | User hoặc admin hủy request | (terminal) |

---

## Bridge API Endpoints (Future)

### POST /api/bridge/withdraw
```json
{
  "requestId": "req_abc123",
  "employeeId": "uuid",
  "walletAddress": "0x...",
  "amount": 500,
  "signature": "jwt_token"
}
```

### POST /api/bridge/deposit/verify
```json
{
  "txHash": "0x...",
  "walletId": "uuid",
  "expectedAmount": 500
}
```

### GET /api/bridge/status/:requestId
```json
{
  "requestId": "req_abc123",
  "status": "completed",
  "txHash": "0xabc...",
  "amount": 500,
  "fee": 5,
  "netAmount": 495,
  "completedAt": "2024-01-15T10:30:00Z"
}
```

---

## Gas Cost Estimates (Base L2)

| Operation | Estimated Gas | Cost (ETH) | Cost (USD ~$3500/ETH) |
|-----------|--------------|------------|----------------------|
| Withdraw | ~65,000 | ~0.000001 | < $0.01 |
| Deposit | ~80,000 | ~0.0000013 | < $0.01 |
| Stake | ~120,000 | ~0.000002 | < $0.01 |
| Unstake + Claim | ~95,000 | ~0.0000015 | < $0.01 |

> Base L2 gas costs là cực kỳ thấp, phù hợp cho micro-transactions trong hệ thống gamification.

---

## Implementation Phases

### Phase 2A: Bridge Backend (Current)
- [x] Smart contracts (SABOToken, SABOBridge, SABOStaking)
- [x] Deploy scripts + tests
- [ ] Bridge API service (Node.js/Bun)
- [ ] Database migration (bridge_requests table)
- [ ] Webhook for deposit event listening

### Phase 2B: Flutter Integration
- [x] Blockchain config (contract addresses, ABIs)
- [x] BlockchainService (Web3 interaction layer)
- [x] Withdraw/Deposit methods in TokenService
- [ ] Bridge UI components
- [ ] Transaction status polling

### Phase 2C: Testing & Audit
- [ ] Deploy to Base Sepolia testnet
- [ ] End-to-end bridge testing
- [ ] Security audit (internal)
- [ ] Load testing
- [ ] External audit (optional for Phase 2)
