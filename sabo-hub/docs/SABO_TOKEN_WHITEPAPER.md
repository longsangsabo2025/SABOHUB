# SABO Token — Whitepaper v1.0

> **"Work. Earn. Own."**
> Biến hiệu suất công việc thành tài sản số thực sự.

---

## 1. Tổng Quan (Executive Summary)

**SABO Token** là utility token của hệ sinh thái SABOHUB — nền tảng quản lý doanh nghiệp đa ngành (distribution, entertainment, manufacturing). Token được thiết kế theo mô hình **hybrid: off-chain speed + on-chain ownership**, cho phép nhân viên kiếm token thông qua hiệu suất làm việc và sở hữu chúng như tài sản số thật sự trên blockchain.

### Thông tin Token

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên** | SABO Token |
| **Symbol** | SABO |
| **Standard** | ERC-20 |
| **Blockchain** | Base (Ethereum L2) |
| **Total Supply** | 100,000,000 SABO (100M) |
| **Decimals** | 18 |
| **Contract** | TBD (sau khi deploy) |

---

## 2. Vấn Đề Giải Quyết (Problem Statement)

### Doanh nghiệp truyền thống
- Nhân viên làm việc → lương cố định, không phản ánh đóng góp thực tế
- Phần thưởng hiệu suất → chỉ là lời nói, không minh bạch
- Engagement thấp → nhân viên không có động lực vượt KPI
- Không có cơ chế peer-to-peer recognition

### SABO Token giải quyết
- **Monetize hiệu suất**: Mỗi hành động tốt = token thật, có giá trị
- **Minh bạch on-chain**: Mọi giao dịch được ghi lại, không thể sửa đổi
- **Ownership thật sự**: Nhân viên sở hữu tài sản, không phải "điểm thưởng"
- **Ecosystem economy**: Token dùng được trong cửa hàng, chuyển nhượng, staking

---

## 3. Tokenomics

### 3.1 Phân bổ Token (Allocation)

| Danh mục | % | Số lượng | Vesting |
|----------|---|----------|---------|
| **Employee Rewards Pool** | 40% | 40,000,000 | Phát dần qua earn events |
| **Company Treasury** | 20% | 20,000,000 | Locked 6 tháng, unlock linear 2 năm |
| **Ecosystem Fund** | 15% | 15,000,000 | Dùng cho partnerships, marketing |
| **Team & Founders** | 10% | 10,000,000 | Locked 12 tháng, unlock linear 3 năm |
| **Liquidity Pool** | 10% | 10,000,000 | DEX listing, market making |
| **Community Airdrop** | 5% | 5,000,000 | Early adopters, beta testers |

### 3.2 Earning Mechanics (Cách kiếm SABO)

| Hành động | SABO/lần | Tần suất | Source Type |
|-----------|----------|----------|-------------|
| Check-in đúng giờ | 5 | Daily | attendance |
| Hoàn thành quest | 20 | Per quest | quest |
| Hoàn thành task | 10-50 | Per task | task |
| Level up | 100 | Per level | bonus |
| Achievement unlock | 50 | Per achievement | achievement |
| Season tier claim | 30 × tier | Per season | season_reward |
| Prestige reset | 500 × level | Per prestige | bonus |
| Referral (giới thiệu NV) | 200 | Per referral | referral |
| Daily combo | 30 | Daily | quest |
| Perfect week | 100 | Weekly | bonus |
| Premium pass | 200 | One-time | bonus |

### 3.3 Spending Mechanics (Cách tiêu SABO)

| Mục đích | Phạm vi SABO | Cơ chế |
|----------|-------------|--------|
| Store items (voucher, perks) | 50-1,000 | Off-chain instant |
| NFT badges/achievements | 100-500 | On-chain mint |
| Gift cards | 200-2,000 | Off-chain + redemption |
| Staking (lock để earn thêm) | Tối thiểu 100 | On-chain smart contract |
| P2P transfer | Bất kỳ | Off-chain hoặc on-chain |
| Withdraw to wallet | Tối thiểu 50 | Off→On-chain bridge |

### 3.4 Deflationary Mechanisms

1. **Burn on purchase**: 2% token bị burn khi mua store items
2. **Transfer fee**: 1% fee khi chuyển on-chain (→ burn)
3. **Inactive penalty**: Wallet không hoạt động >90 ngày → 5% balance burn/quarter
4. **Event burns**: Seasonal events đốt token theo milestone

### 3.5 Inflation Controls

- **Daily mint cap**: Mỗi company tối đa mint 1,000 SABO/ngày cho rewards
- **Halving**: Reward amounts giảm 20% mỗi 6 tháng
- **Supply cap**: Tuyệt đối không vượt 100M total supply

---

## 4. Kiến Trúc Kỹ Thuật

### 4.1 Hybrid Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SABOHUB Flutter App                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Token Wallet  │  │ Token Store  │  │ Token Bridge │  │
│  │   (UI)       │  │   (UI)       │  │   (UI)       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│  ┌──────┴──────────────────┴──────────────────┴───────┐  │
│  │              Token Service Layer                    │  │
│  │  ┌─────────────────┐  ┌──────────────────────┐    │  │
│  │  │  Off-chain Ops   │  │   On-chain Ops       │    │  │
│  │  │  (Supabase RPC)  │  │   (Web3 Provider)    │    │  │
│  │  └────────┬─────────┘  └──────────┬───────────┘    │  │
│  └───────────┼───────────────────────┼────────────────┘  │
└──────────────┼───────────────────────┼──────────────────┘
               │                       │
    ┌──────────▼──────────┐  ┌────────▼──────────────┐
    │   Supabase Backend  │  │   Base L2 Blockchain   │
    │  ┌───────────────┐  │  │  ┌─────────────────┐  │
    │  │ token_wallets  │  │  │  │ SABOToken.sol   │  │
    │  │ token_txns     │◄─┼──┼─►│ (ERC-20)        │  │
    │  │ token_store    │  │  │  │                 │  │
    │  │ bridge_requests│  │  │  │ SABOBridge.sol  │  │
    │  └───────────────┘  │  │  │ (Lock/Mint)     │  │
    └─────────────────────┘  │  └─────────────────┘  │
                              └──────────────────────┘
```

### 4.2 Bridge Flow

#### Withdraw (Off-chain → On-chain)
```
User requests withdraw (Flutter)
    → Create bridge_request (status: pending)
    → Admin approves (or auto-approve < threshold)
    → Bridge Service calls SABOBridge.mint(address, amount)
    → On-chain tx confirmed
    → Update bridge_request (status: completed, tx_hash)
    → Deduct off-chain balance
```

#### Deposit (On-chain → Off-chain)
```
User sends SABO to SABOBridge contract
    → Contract emits Deposit event
    → Bridge Listener detects event
    → Create bridge_request (status: processing)
    → Credit off-chain balance via earn_tokens RPC
    → Update bridge_request (status: completed)
```

### 4.3 Smart Contract Architecture

```
contracts/
├── SABOToken.sol        — ERC-20 token (mint/burn/transfer)
├── SABOBridge.sol       — Bridge contract (deposit/withdraw)
├── SABOStaking.sol      — Staking rewards (lock/unlock/claim)
└── SABOGovernance.sol   — Future: voting & proposals
```

---

## 5. Roadmap

### Phase 0: Off-Chain Economy ✅ DONE
- [x] 6 DB tables + 3 RPCs
- [x] Token models, service, providers
- [x] Wallet page, Store page
- [x] Gamification hooks (7 earn events)
- [x] 45 store items seeded

### Phase 1: Production Ready ✅ DONE
- [x] All gamification→token hooks wired
- [x] Navigation for all roles
- [x] Celebration overlay with token display

### Phase 2: Smart Contract & Bridge (Current)
- [ ] ERC-20 smart contract (SABOToken.sol)
- [ ] Bridge contract (SABOBridge.sol)
- [ ] Hardhat project setup with tests
- [ ] Deploy to Base Sepolia testnet
- [ ] Flutter Web3 service layer
- [ ] Withdraw/deposit service methods
- [ ] Bridge request UI
- [ ] Wallet address linking (MetaMask/WalletConnect)

### Phase 3: DeFi Lite
- [ ] Staking contract (SABOStaking.sol)
- [ ] NFT achievements (ERC-721)
- [ ] DEX liquidity pool (SABO/USDC on Uniswap V3)
- [ ] Token analytics dashboard

### Phase 4: Governance
- [ ] DAO voting (company proposals)
- [ ] Multi-sig treasury management
- [ ] Cross-company token trading
- [ ] Full on-chain migration option

---

## 6. Pháp Lý & Compliance

### Phân loại: Utility Token
SABO Token được phân loại là **utility token** vì:
- Dùng để truy cập và sử dụng dịch vụ trong hệ sinh thái SABOHUB
- Không hứa hẹn lợi nhuận (not a security)
- Không phải payment token (không dùng thanh toán hàng hóa bên ngoài)

### Quy định Việt Nam
- Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân → cần consent
- Chưa có khung pháp lý rõ ràng cho utility token → operate as loyalty points
- Không quảng cáo như đầu tư tài chính
- KYC cho withdraw > threshold

### Biện pháp bảo vệ
- Rate limiting trên earn/spend/transfer
- Admin approval cho withdrawal lớn
- Audit trail đầy đủ (token_transactions)
- Không cho phép mua bán SABO lấy VND trong app

---

## 7. Security

### Smart Contract
- OpenZeppelin contracts (audited standards)
- Ownable2Step (2-step ownership transfer)
- Pausable (emergency stop)
- ReentrancyGuard trên bridge functions
- Multisig wallet cho admin operations

### Off-chain
- Supabase RLS (Row Level Security) trên tất cả token tables
- Server-side RPCs (SECURITY DEFINER) cho mutations
- Rate limiting: max 100 earn calls/user/day
- Balance snapshot before/after mỗi transaction

---

## 8. Tài Liệu Tham Khảo

- [ERC-20 Standard](https://eips.ethereum.org/EIPS/eip-20)
- [Base Documentation](https://docs.base.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Hardhat Documentation](https://hardhat.org/docs)
- [SABOHUB PROGRESS.md](../sabohub-app/SABOHUB/docs/PROGRESS.md)
- [Quest System Design](./QUEST_SYSTEM_DESIGN.md)

---

*Document Version: 1.0*
*Created: 2026-03-04*
*Last Updated: 2026-03-04*
*Author: SABOHUB Team*
