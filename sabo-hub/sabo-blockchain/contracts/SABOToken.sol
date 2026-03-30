// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SABOToken
 * @notice ERC-20 utility token for the SABOHUB ecosystem.
 *
 * Features:
 *   - Capped supply: 100 000 000 SABO (100M)
 *   - Mintable by owner only (bridge / treasury operations)
 *   - Burnable by any holder
 *   - Pausable for emergency scenarios
 *   - Ownable2Step for secure ownership transfer
 *
 * @dev Deployed on Base L2 (Ethereum) for low gas costs.
 */
contract SABOToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable2Step {
    /// @notice Maximum supply that can ever exist.
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18; // 100M SABO

    /// @notice Daily mint cap per company (enforced off-chain, advisory on-chain).
    uint256 public dailyMintCap = 1_000 * 10 ** 18; // 1 000 SABO default

    /// @notice Tracks total minted today per minter address.
    mapping(address => uint256) public mintedToday;

    /// @notice Timestamp of the last mint-day reset for each address.
    mapping(address => uint256) public lastMintDay;

    /// @notice Authorized minters (Bridge, Staking contracts).
    mapping(address => bool) public minters;

    // ─── Events ──────────────────────────────────────────────────────────

    event DailyMintCapUpdated(uint256 oldCap, uint256 newCap);
    event TokensMinted(address indexed to, uint256 amount, string reason);
    event TokensBurned(address indexed from, uint256 amount);
    event MinterUpdated(address indexed account, bool status);

    // ─── Modifiers ───────────────────────────────────────────────────────

    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner(), "SABO: not a minter");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────

    constructor() ERC20("SABO Token", "SABO") Ownable(msg.sender) {
        // Mint initial liquidity pool allocation to deployer (10%)
        _mint(msg.sender, 10_000_000 * 10 ** 18);
    }

    // ─── Minter Management ──────────────────────────────────────────────

    /**
     * @notice Grant or revoke minter role (owner only).
     * @param account Address to update.
     * @param status  true = grant, false = revoke.
     */
    function setMinter(address account, bool status) external onlyOwner {
        minters[account] = status;
        emit MinterUpdated(account, status);
    }

    // ─── Minting ─────────────────────────────────────────────────────────

    /**
     * @notice Mint new tokens (owner only). Respects MAX_SUPPLY.
     * @param to      Recipient address.
     * @param amount  Amount in wei (18 decimals).
     * @param reason  Human-readable reason (e.g. "bridge_withdraw", "reward").
     */
    function mint(address to, uint256 amount, string calldata reason) external onlyMinter {
        require(totalSupply() + amount <= MAX_SUPPLY, "SABO: exceeds max supply");
        _enforceDailyCap(amount);
        _mint(to, amount);
        emit TokensMinted(to, amount, reason);
    }

    /**
     * @notice Batch mint to multiple addresses (gas-efficient for rewards).
     * @param recipients Array of addresses.
     * @param amounts    Array of amounts (must match length).
     * @param reason     Shared reason string.
     */
    function mintBatch(
        address[] calldata recipients,
        uint256[] calldata amounts,
        string calldata reason
    ) external onlyMinter {
        require(recipients.length == amounts.length, "SABO: length mismatch");
        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(totalSupply() + total <= MAX_SUPPLY, "SABO: exceeds max supply");
        _enforceDailyCap(total);

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i], reason);
        }
    }

    // ─── Daily Mint Cap ──────────────────────────────────────────────────

    /**
     * @notice Update the daily mint cap (owner only).
     */
    function setDailyMintCap(uint256 newCap) external onlyOwner {
        emit DailyMintCapUpdated(dailyMintCap, newCap);
        dailyMintCap = newCap;
    }

    function _enforceDailyCap(uint256 amount) internal {
        uint256 today = block.timestamp / 1 days;
        if (lastMintDay[msg.sender] < today) {
            mintedToday[msg.sender] = 0;
            lastMintDay[msg.sender] = today;
        }
        mintedToday[msg.sender] += amount;
        require(mintedToday[msg.sender] <= dailyMintCap, "SABO: daily mint cap exceeded");
    }

    // ─── Pausable ────────────────────────────────────────────────────────

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ─── Overrides ───────────────────────────────────────────────────────

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
