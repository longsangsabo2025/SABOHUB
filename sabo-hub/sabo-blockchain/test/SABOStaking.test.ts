import { expect } from "chai";
import { ethers } from "hardhat";
import { SABOToken, SABOStaking } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SABOStaking", () => {
  let saboToken: SABOToken;
  let saboStaking: SABOStaking;
  let owner: SignerWithAddress;
  let staker1: SignerWithAddress;
  let staker2: SignerWithAddress;

  const STAKE_AMOUNT = ethers.parseEther("1000");

  beforeEach(async () => {
    [owner, staker1, staker2] = await ethers.getSigners();

    // Deploy token
    const SABOToken = await ethers.getContractFactory("SABOToken");
    saboToken = await SABOToken.deploy();
    await saboToken.waitForDeployment();

    // Set high daily mint cap for testing
    await saboToken.setDailyMintCap(ethers.parseEther("1000000"));

    // Deploy staking
    const SABOStaking = await ethers.getContractFactory("SABOStaking");
    saboStaking = await SABOStaking.deploy(await saboToken.getAddress());
    await saboStaking.waitForDeployment();

    // Grant minter role to staking so it can mint rewards
    await saboToken.setMinter(await saboStaking.getAddress(), true);

    // Transfer tokens to stakers for testing
    await saboToken.transfer(staker1.address, ethers.parseEther("50000"));
    await saboToken.transfer(staker2.address, ethers.parseEther("50000"));

    // Fund staking contract with reward tokens (for principal return)
    await saboToken.transfer(
      await saboStaking.getAddress(),
      ethers.parseEther("100000")
    );
  });

  describe("Deployment", () => {
    it("Should have 4 default tiers", async () => {
      expect(await saboStaking.getTierCount()).to.equal(4);
    });

    it("Should set correct Bronze tier", async () => {
      const bronze = await saboStaking.tiers(0);
      expect(bronze.name).to.equal("Bronze");
      expect(bronze.lockDuration).to.equal(30 * 86400); // 30 days in seconds
      expect(bronze.apyBasisPoints).to.equal(500); // 5%
      expect(bronze.minAmount).to.equal(ethers.parseEther("100"));
      expect(bronze.isActive).to.be.true;
    });

    it("Should set correct Diamond tier", async () => {
      const diamond = await saboStaking.tiers(3);
      expect(diamond.name).to.equal("Diamond");
      expect(diamond.lockDuration).to.equal(365 * 86400); // 365 days
      expect(diamond.apyBasisPoints).to.equal(3000); // 30%
      expect(diamond.minAmount).to.equal(ethers.parseEther("5000"));
    });

    it("Should set deployer as owner", async () => {
      expect(await saboStaking.owner()).to.equal(owner.address);
    });
  });

  describe("Staking", () => {
    it("Should allow user to stake tokens in Bronze tier", async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);

      await expect(saboStaking.connect(staker1).stake(0, STAKE_AMOUNT))
        .to.emit(saboStaking, "Staked");
    });

    it("Should transfer tokens to staking contract", async () => {
      const balanceBefore = await saboToken.balanceOf(
        await saboStaking.getAddress()
      );

      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);
      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT);

      const balanceAfter = await saboToken.balanceOf(
        await saboStaking.getAddress()
      );
      expect(balanceAfter - balanceBefore).to.equal(STAKE_AMOUNT);
    });

    it("Should update totalStaked", async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);
      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT);

      expect(await saboStaking.totalStaked()).to.equal(STAKE_AMOUNT);
    });

    it("Should reject stake below tier minimum", async () => {
      const tooSmall = ethers.parseEther("50"); // Bronze min is 100
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), tooSmall);

      await expect(
        saboStaking.connect(staker1).stake(0, tooSmall)
      ).to.be.revertedWith("Staking: below minimum");
    });

    it("Should reject stake with invalid tier", async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);

      await expect(
        saboStaking.connect(staker1).stake(99, STAKE_AMOUNT)
      ).to.be.revertedWith("Staking: invalid tier");
    });

    it("Should reject stake in inactive tier", async () => {
      await saboStaking.setTierActive(0, false);

      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);

      await expect(
        saboStaking.connect(staker1).stake(0, STAKE_AMOUNT)
      ).to.be.revertedWith("Staking: tier not active");
    });

    it("Should track user stakes via getUserStake", async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);
      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT);

      expect(await saboStaking.getUserStakeCount(staker1.address)).to.equal(1);

      const stake = await saboStaking.getUserStake(staker1.address, 0);
      expect(stake.amount).to.equal(STAKE_AMOUNT);
      expect(stake.tierId).to.equal(0);
      expect(stake.isActive).to.be.true;
    });

    it("Should allow multiple stakes", async () => {
      const amount2 = ethers.parseEther("500"); // Silver min is 500
      await saboToken
        .connect(staker1)
        .approve(
          await saboStaking.getAddress(),
          STAKE_AMOUNT + amount2
        );

      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT); // Bronze
      await saboStaking.connect(staker1).stake(1, amount2); // Silver

      expect(await saboStaking.getUserStakeCount(staker1.address)).to.equal(2);
      expect(await saboStaking.totalStaked()).to.equal(
        STAKE_AMOUNT + amount2
      );
    });

    it("Should reject staking when paused", async () => {
      await saboStaking.pause();
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);

      await expect(
        saboStaking.connect(staker1).stake(0, STAKE_AMOUNT)
      ).to.be.revertedWithCustomError(saboStaking, "EnforcedPause");
    });
  });

  describe("Unstaking", () => {
    beforeEach(async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);
      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT); // Bronze (30 days)
    });

    it("Should reject unstake before lock period", async () => {
      await expect(
        saboStaking.connect(staker1).unstake(0)
      ).to.be.revertedWith("Staking: still locked");
    });

    // Now that staking has minter role, unstake+rewards should work

    it("Should unstake after lock period and pay rewards", async () => {
      // Advance 31 days past Bronze lock
      await ethers.provider.send("evm_increaseTime", [31 * 86400]);
      await ethers.provider.send("evm_mine", []);

      const balBefore = await saboToken.balanceOf(staker1.address);

      await expect(saboStaking.connect(staker1).unstake(0))
        .to.emit(saboStaking, "Unstaked");

      const balAfter = await saboToken.balanceOf(staker1.address);
      const received = balAfter - balBefore;

      // Should receive staked amount + rewards
      // 1000 SABO principal + ~4.1 SABO rewards (5% APY * 30/365)
      expect(received).to.be.gt(STAKE_AMOUNT);
      expect(received).to.be.lt(STAKE_AMOUNT + ethers.parseEther("5"));

      // Stake should be inactive
      const stake = await saboStaking.getUserStake(staker1.address, 0);
      expect(stake.isActive).to.be.false;

      // Total staked should decrease
      expect(await saboStaking.totalStaked()).to.equal(0);
    });

    it("Should revert unstake from non-minter staking contract", async () => {
      // Revoke minter role from staking
      await saboToken.setMinter(await saboStaking.getAddress(), false);

      // Advance 31 days past lock
      await ethers.provider.send("evm_increaseTime", [31 * 86400]);
      await ethers.provider.send("evm_mine", []);

      // Unstake should fail because staking can't mint rewards
      await expect(
        saboStaking.connect(staker1).unstake(0)
      ).to.be.revertedWith("SABO: not a minter");
    });
  });

  describe("Rewards Calculation", () => {
    beforeEach(async () => {
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);
      await saboStaking.connect(staker1).stake(0, STAKE_AMOUNT); // Bronze 5% APY
    });

    it("Should calculate pending rewards over time", async () => {
      // Advance half the lock period (15 days)
      await ethers.provider.send("evm_increaseTime", [15 * 86400]);
      await ethers.provider.send("evm_mine", []);

      const pending = await saboStaking.getPendingRewards(
        staker1.address,
        0
      );

      // 1000 SABO * 5% APY * (15/365) ≈ 2.054 SABO
      expect(pending).to.be.gt(ethers.parseEther("1.5"));
      expect(pending).to.be.lt(ethers.parseEther("3"));
    });

    it("Should cap rewards at lock duration", async () => {
      // Advance 365 days (way past 30-day Bronze lock)
      await ethers.provider.send("evm_increaseTime", [365 * 86400]);
      await ethers.provider.send("evm_mine", []);

      const pending = await saboStaking.getPendingRewards(
        staker1.address,
        0
      );

      // Rewards capped at 30 days: 1000 * 5% * (30/365) ≈ 4.109 SABO
      const expectedMax = ethers.parseEther("4.2");
      expect(pending).to.be.lt(expectedMax);
    });

    it("Should return 0 rewards at start", async () => {
      // Don't advance time
      const pending = await saboStaking.getPendingRewards(
        staker1.address,
        0
      );
      // Should be near zero (just 1 block time)
      expect(pending).to.be.lt(ethers.parseEther("0.01"));
    });
  });

  describe("Tier Management", () => {
    it("Should allow owner to add new tier", async () => {
      const lockDuration = 540 * 86400; // 540 days in seconds
      await expect(
        saboStaking.addTier(
          "Platinum",
          lockDuration,
          2500,
          ethers.parseEther("10000")
        )
      )
        .to.emit(saboStaking, "TierAdded")
        .withArgs(4, "Platinum", lockDuration, 2500);

      expect(await saboStaking.getTierCount()).to.equal(5);

      const tier = await saboStaking.tiers(4);
      expect(tier.name).to.equal("Platinum");
      expect(tier.lockDuration).to.equal(lockDuration);
      expect(tier.apyBasisPoints).to.equal(2500);
      expect(tier.isActive).to.be.true;
    });

    it("Should allow owner to toggle tier active status", async () => {
      await saboStaking.setTierActive(0, false);
      const tier = await saboStaking.tiers(0);
      expect(tier.isActive).to.be.false;
    });

    it("Should reject tier management from non-owner", async () => {
      await expect(
        saboStaking
          .connect(staker1)
          .addTier("Hack", 86400, 10000, ethers.parseEther("1"))
      ).to.be.revertedWithCustomError(saboStaking, "OwnableUnauthorizedAccount");
    });

    it("Should reject setTierActive on invalid tier", async () => {
      await expect(
        saboStaking.setTierActive(99, false)
      ).to.be.revertedWith("Staking: invalid tier");
    });
  });

  describe("Pause / Unpause", () => {
    it("Should allow owner to pause and unpause", async () => {
      await saboStaking.pause();
      expect(await saboStaking.paused()).to.be.true;
      await saboStaking.unpause();
      expect(await saboStaking.paused()).to.be.false;
    });

    it("Should prevent staking when paused", async () => {
      await saboStaking.pause();
      await saboToken
        .connect(staker1)
        .approve(await saboStaking.getAddress(), STAKE_AMOUNT);

      await expect(
        saboStaking.connect(staker1).stake(0, STAKE_AMOUNT)
      ).to.be.revertedWithCustomError(saboStaking, "EnforcedPause");
    });

    it("Should reject pause from non-owner", async () => {
      await expect(
        saboStaking.connect(staker1).pause()
      ).to.be.revertedWithCustomError(saboStaking, "OwnableUnauthorizedAccount");
    });
  });
});
