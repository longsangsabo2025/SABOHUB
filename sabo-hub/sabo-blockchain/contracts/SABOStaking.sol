// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./SABOToken.sol";

/**
 * @title SABOStaking
 * @notice Staking contract for SABO tokens. Lock tokens to earn rewards.
 *
 * Tiers:
 *   Bronze  : 30 days  →  5% APY
 *   Silver  : 90 days  → 12% APY
 *   Gold    : 180 days → 20% APY
 *   Diamond : 365 days → 30% APY
 *
 * @dev Rewards are minted from remaining supply (not from locked pool).
 */
contract SABOStaking is Ownable2Step, ReentrancyGuard, Pausable {
    SABOToken public immutable saboToken;

    // ─── Staking Tiers ───────────────────────────────────────────────────

    struct StakingTier {
        string name;
        uint256 lockDuration;   // seconds
        uint256 apyBasisPoints; // basis points (500 = 5%)
        uint256 minAmount;      // minimum stake amount
        bool isActive;
    }

    struct Stake {
        uint256 amount;
        uint256 tierId;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardsClaimed;
        bool isActive;
    }

    // ─── State ───────────────────────────────────────────────────────────

    StakingTier[] public tiers;
    mapping(address => Stake[]) public userStakes;
    uint256 public totalStaked;
    uint256 public totalRewardsPaid;

    // ─── Events ──────────────────────────────────────────────────────────

    event Staked(address indexed user, uint256 indexed stakeIndex, uint256 amount, uint256 tierId);
    event Unstaked(address indexed user, uint256 indexed stakeIndex, uint256 amount, uint256 rewards);
    event RewardsClaimed(address indexed user, uint256 indexed stakeIndex, uint256 rewards);
    event TierAdded(uint256 indexed tierId, string name, uint256 lockDuration, uint256 apyBps);
    event TierUpdated(uint256 indexed tierId, bool isActive);

    // ─── Constructor ─────────────────────────────────────────────────────

    constructor(address _saboToken) Ownable(msg.sender) {
        saboToken = SABOToken(_saboToken);

        // Default tiers
        tiers.push(StakingTier("Bronze",  30 days,   500, 100 * 10**18, true));   //  5% APY, min 100
        tiers.push(StakingTier("Silver",  90 days,  1200, 500 * 10**18, true));   // 12% APY, min 500
        tiers.push(StakingTier("Gold",   180 days,  2000, 1000 * 10**18, true));  // 20% APY, min 1000
        tiers.push(StakingTier("Diamond", 365 days, 3000, 5000 * 10**18, true));  // 30% APY, min 5000
    }

    // ─── Staking ─────────────────────────────────────────────────────────

    /**
     * @notice Stake SABO tokens in a specific tier.
     * @param tierId Index of the staking tier.
     * @param amount Amount of SABO to stake.
     */
    function stake(uint256 tierId, uint256 amount) external nonReentrant whenNotPaused {
        require(tierId < tiers.length, "Staking: invalid tier");
        StakingTier memory tier = tiers[tierId];
        require(tier.isActive, "Staking: tier not active");
        require(amount >= tier.minAmount, "Staking: below minimum");

        require(
            saboToken.transferFrom(msg.sender, address(this), amount),
            "Staking: transfer failed"
        );

        userStakes[msg.sender].push(Stake({
            amount: amount,
            tierId: tierId,
            startTime: block.timestamp,
            endTime: block.timestamp + tier.lockDuration,
            rewardsClaimed: 0,
            isActive: true
        }));

        totalStaked += amount;
        uint256 stakeIndex = userStakes[msg.sender].length - 1;

        emit Staked(msg.sender, stakeIndex, amount, tierId);
    }

    /**
     * @notice Unstake tokens after lock period ends. Claims pending rewards.
     * @param stakeIndex Index of the stake in user's stakes array.
     */
    function unstake(uint256 stakeIndex) external nonReentrant {
        Stake storage s = userStakes[msg.sender][stakeIndex];
        require(s.isActive, "Staking: not active");
        require(block.timestamp >= s.endTime, "Staking: still locked");

        // Calculate & pay rewards
        uint256 pendingRewards = _calculateRewards(msg.sender, stakeIndex);
        s.isActive = false;
        s.rewardsClaimed += pendingRewards;
        totalStaked -= s.amount;

        // Return staked tokens
        require(saboToken.transfer(msg.sender, s.amount), "Staking: return failed");

        // Mint rewards
        if (pendingRewards > 0) {
            saboToken.mint(msg.sender, pendingRewards, "staking_reward");
            totalRewardsPaid += pendingRewards;
        }

        emit Unstaked(msg.sender, stakeIndex, s.amount, pendingRewards);
    }

    /**
     * @notice Claim accrued rewards without unstaking (for long-term stakers).
     * @param stakeIndex Index of the stake.
     */
    function claimRewards(uint256 stakeIndex) external nonReentrant whenNotPaused {
        Stake storage s = userStakes[msg.sender][stakeIndex];
        require(s.isActive, "Staking: not active");

        uint256 pendingRewards = _calculateRewards(msg.sender, stakeIndex);
        require(pendingRewards > 0, "Staking: no rewards");

        s.rewardsClaimed += pendingRewards;

        saboToken.mint(msg.sender, pendingRewards, "staking_reward_claim");
        totalRewardsPaid += pendingRewards;

        emit RewardsClaimed(msg.sender, stakeIndex, pendingRewards);
    }

    // ─── View Functions ──────────────────────────────────────────────────

    function _calculateRewards(address user, uint256 stakeIndex) internal view returns (uint256) {
        Stake memory s = userStakes[user][stakeIndex];
        if (!s.isActive) return 0;

        StakingTier memory tier = tiers[s.tierId];
        uint256 elapsed = block.timestamp - s.startTime;
        if (elapsed > tier.lockDuration) elapsed = tier.lockDuration;

        // reward = amount * APY * elapsed / 365 days / 10000 (basis points)
        uint256 totalReward = (s.amount * tier.apyBasisPoints * elapsed) / (365 days * 10000);
        return totalReward > s.rewardsClaimed ? totalReward - s.rewardsClaimed : 0;
    }

    function getPendingRewards(address user, uint256 stakeIndex) external view returns (uint256) {
        return _calculateRewards(user, stakeIndex);
    }

    function getUserStakeCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }

    function getUserStake(address user, uint256 index) external view returns (
        uint256 amount, uint256 tierId, uint256 startTime,
        uint256 endTime, uint256 rewardsClaimed, bool isActive
    ) {
        Stake memory s = userStakes[user][index];
        return (s.amount, s.tierId, s.startTime, s.endTime, s.rewardsClaimed, s.isActive);
    }

    function getTierCount() external view returns (uint256) {
        return tiers.length;
    }

    // ─── Admin ───────────────────────────────────────────────────────────

    function addTier(
        string calldata name,
        uint256 lockDuration,
        uint256 apyBps,
        uint256 minAmount
    ) external onlyOwner {
        tiers.push(StakingTier(name, lockDuration, apyBps, minAmount, true));
        emit TierAdded(tiers.length - 1, name, lockDuration, apyBps);
    }

    function setTierActive(uint256 tierId, bool active) external onlyOwner {
        require(tierId < tiers.length, "Staking: invalid tier");
        tiers[tierId].isActive = active;
        emit TierUpdated(tierId, active);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
