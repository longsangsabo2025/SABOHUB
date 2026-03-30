// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./SABOToken.sol";

/**
 * @title SABOBridge
 * @notice Bridge contract between off-chain (Supabase) and on-chain (Base L2).
 *
 * Flow:
 *   DEPOSIT  : User sends SABO to this contract → tokens locked → off-chain credit
 *   WITHDRAW : Off-chain debit → owner mints SABO to user's wallet
 *
 * Security:
 *   - ReentrancyGuard on all state-changing functions
 *   - Pausable for emergency
 *   - Nonce-based replay protection for withdrawals
 *   - Minimum/maximum amount limits
 *   - Cooldown period between withdrawals
 *
 * @dev Owner is the SABOHUB backend service (or multisig).
 */
contract SABOBridge is Ownable2Step, ReentrancyGuard, Pausable {
    SABOToken public immutable saboToken;

    // ─── Configuration ───────────────────────────────────────────────────

    uint256 public minDepositAmount = 50 * 10 ** 18;     // 50 SABO minimum
    uint256 public minWithdrawAmount = 50 * 10 ** 18;    // 50 SABO minimum
    uint256 public maxWithdrawAmount = 10_000 * 10 ** 18; // 10K SABO max per tx
    uint256 public withdrawCooldown = 1 hours;            // 1 hour between withdrawals
    uint256 public withdrawFeePercent = 100;              // 1% = 100 basis points (out of 10000)

    // ─── State ───────────────────────────────────────────────────────────

    /// @notice Total tokens locked in bridge (from deposits).
    uint256 public totalLocked;

    /// @notice Total tokens minted via withdrawals.
    uint256 public totalWithdrawn;

    /// @notice Nonce per user to prevent replay attacks.
    mapping(address => uint256) public withdrawNonce;

    /// @notice Last withdrawal timestamp per user.
    mapping(address => uint256) public lastWithdrawTime;

    /// @notice Processed request IDs (from off-chain bridge_requests table).
    mapping(bytes32 => bool) public processedRequests;

    // ─── Events ──────────────────────────────────────────────────────────

    event Deposited(
        address indexed user,
        uint256 amount,
        string offchainWalletId,
        uint256 timestamp
    );

    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 fee,
        bytes32 indexed requestId,
        uint256 nonce,
        uint256 timestamp
    );

    event ConfigUpdated(string param, uint256 oldValue, uint256 newValue);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    // ─── Constructor ─────────────────────────────────────────────────────

    constructor(address _saboToken) Ownable(msg.sender) {
        saboToken = SABOToken(_saboToken);
    }

    // ─── Deposit (User → Bridge → Off-chain credit) ─────────────────────

    /**
     * @notice Deposit SABO tokens to bridge for off-chain credit.
     * @param amount          Amount of SABO to deposit.
     * @param offchainWalletId The user's off-chain wallet ID (from Supabase).
     *
     * @dev User must approve this contract to spend `amount` first.
     *      Tokens are transferred to this contract (locked).
     *      Backend listens for Deposited event and credits off-chain.
     */
    function deposit(uint256 amount, string calldata offchainWalletId) external nonReentrant whenNotPaused {
        require(amount >= minDepositAmount, "Bridge: below minimum deposit");
        require(bytes(offchainWalletId).length > 0, "Bridge: empty wallet ID");

        // Transfer tokens from user to bridge (lock)
        require(
            saboToken.transferFrom(msg.sender, address(this), amount),
            "Bridge: transfer failed"
        );

        totalLocked += amount;

        emit Deposited(msg.sender, amount, offchainWalletId, block.timestamp);
    }

    // ─── Withdraw (Off-chain debit → Bridge → User wallet) ──────────────

    /**
     * @notice Process a withdrawal request (owner/backend only).
     * @param to          User's on-chain wallet address.
     * @param amount      Gross amount (fee deducted from this).
     * @param requestId   Unique request ID from off-chain bridge_requests table.
     *
     * @dev Mints new tokens to user (withdraw from supply, not locked pool).
     *      Fee is burned to maintain deflationary pressure.
     */
    function withdraw(
        address to,
        uint256 amount,
        bytes32 requestId
    ) external onlyOwner nonReentrant whenNotPaused {
        require(amount >= minWithdrawAmount, "Bridge: below minimum withdraw");
        require(amount <= maxWithdrawAmount, "Bridge: exceeds maximum withdraw");
        require(!processedRequests[requestId], "Bridge: already processed");
        require(
            block.timestamp >= lastWithdrawTime[to] + withdrawCooldown,
            "Bridge: cooldown active"
        );

        // Mark as processed
        processedRequests[requestId] = true;
        lastWithdrawTime[to] = block.timestamp;

        // Calculate fee
        uint256 fee = (amount * withdrawFeePercent) / 10000;
        uint256 netAmount = amount - fee;

        // Mint to user (net amount)
        saboToken.mint(to, netAmount, "bridge_withdraw");

        // Burn fee amount (deflationary)
        if (fee > 0 && totalLocked >= fee) {
            saboToken.burn(fee);
            totalLocked -= fee;
        }

        uint256 nonce = withdrawNonce[to]++;
        totalWithdrawn += netAmount;

        emit Withdrawn(to, netAmount, fee, requestId, nonce, block.timestamp);
    }

    // ─── Configuration ───────────────────────────────────────────────────

    function setMinDepositAmount(uint256 amount) external onlyOwner {
        emit ConfigUpdated("minDepositAmount", minDepositAmount, amount);
        minDepositAmount = amount;
    }

    function setMinWithdrawAmount(uint256 amount) external onlyOwner {
        emit ConfigUpdated("minWithdrawAmount", minWithdrawAmount, amount);
        minWithdrawAmount = amount;
    }

    function setMaxWithdrawAmount(uint256 amount) external onlyOwner {
        emit ConfigUpdated("maxWithdrawAmount", maxWithdrawAmount, amount);
        maxWithdrawAmount = amount;
    }

    function setWithdrawCooldown(uint256 cooldown) external onlyOwner {
        emit ConfigUpdated("withdrawCooldown", withdrawCooldown, cooldown);
        withdrawCooldown = cooldown;
    }

    function setWithdrawFeePercent(uint256 bps) external onlyOwner {
        require(bps <= 1000, "Bridge: fee too high (max 10%)");
        emit ConfigUpdated("withdrawFeePercent", withdrawFeePercent, bps);
        withdrawFeePercent = bps;
    }

    // ─── Pausable ────────────────────────────────────────────────────────

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ─── Emergency ───────────────────────────────────────────────────────

    /**
     * @notice Emergency withdraw locked tokens to owner (only when paused).
     */
    function emergencyWithdrawLocked() external onlyOwner whenPaused {
        uint256 balance = saboToken.balanceOf(address(this));
        require(balance > 0, "Bridge: no locked tokens");
        require(saboToken.transfer(owner(), balance), "Bridge: transfer failed");
        totalLocked = 0;
        emit EmergencyWithdraw(owner(), balance);
    }

    // ─── View Functions ──────────────────────────────────────────────────

    /**
     * @notice Get bridge statistics.
     */
    function getStats() external view returns (
        uint256 _totalLocked,
        uint256 _totalWithdrawn,
        uint256 _bridgeBalance,
        bool _paused
    ) {
        return (
            totalLocked,
            totalWithdrawn,
            saboToken.balanceOf(address(this)),
            paused()
        );
    }

    /**
     * @notice Check if a user can withdraw (cooldown check).
     */
    function canWithdraw(address user) external view returns (bool) {
        return block.timestamp >= lastWithdrawTime[user] + withdrawCooldown;
    }
}
