import { expect } from "chai";
import { ethers } from "hardhat";
import { SABOToken, SABOBridge } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SABOBridge", () => {
  let saboToken: SABOToken;
  let saboBridge: SABOBridge;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  const DEPOSIT_AMOUNT = ethers.parseEther("500");
  const WITHDRAW_AMOUNT = ethers.parseEther("200");

  // Helper: convert string to bytes32
  function toBytes32(str: string): string {
    return ethers.encodeBytes32String(str);
  }

  beforeEach(async () => {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy token (owner = deployer, initial supply 10M to deployer)
    const SABOToken = await ethers.getContractFactory("SABOToken");
    saboToken = await SABOToken.deploy();
    await saboToken.waitForDeployment();

    // Set high daily mint cap for testing
    await saboToken.setDailyMintCap(ethers.parseEther("1000000"));

    // Deploy bridge
    const SABOBridge = await ethers.getContractFactory("SABOBridge");
    saboBridge = await SABOBridge.deploy(await saboToken.getAddress());
    await saboBridge.waitForDeployment();

    // Grant minter role to bridge so it can mint on withdraw
    await saboToken.setMinter(await saboBridge.getAddress(), true);

    // Transfer tokens to user1 for testing deposits
    await saboToken.transfer(user1.address, ethers.parseEther("10000"));
  });

  describe("Deployment", () => {
    it("Should set correct token address", async () => {
      expect(await saboBridge.saboToken()).to.equal(
        await saboToken.getAddress()
      );
    });

    it("Should set deployer as owner", async () => {
      expect(await saboBridge.owner()).to.equal(owner.address);
    });

    it("Should have default limits", async () => {
      expect(await saboBridge.minDepositAmount()).to.equal(
        ethers.parseEther("50")
      );
      expect(await saboBridge.minWithdrawAmount()).to.equal(
        ethers.parseEther("50")
      );
      expect(await saboBridge.maxWithdrawAmount()).to.equal(
        ethers.parseEther("10000")
      );
    });

    it("Should have default cooldown of 1 hour", async () => {
      expect(await saboBridge.withdrawCooldown()).to.equal(3600);
    });

    it("Should have default fee of 1% (100 bps)", async () => {
      expect(await saboBridge.withdrawFeePercent()).to.equal(100);
    });
  });

  describe("Deposit (On-chain → Off-chain)", () => {
    it("Should allow user to deposit tokens", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);

      const offchainWalletId = "wallet_abc123";
      await expect(
        saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, offchainWalletId)
      ).to.emit(saboBridge, "Deposited");
    });

    it("Should transfer tokens to bridge contract on deposit", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);

      await saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_123");

      expect(
        await saboToken.balanceOf(await saboBridge.getAddress())
      ).to.equal(DEPOSIT_AMOUNT);
    });

    it("Should update totalLocked stats", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);

      await saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_123");

      expect(await saboBridge.totalLocked()).to.equal(DEPOSIT_AMOUNT);
    });

    it("Should reject deposit below minimum", async () => {
      const tooSmall = ethers.parseEther("10");
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), tooSmall);

      await expect(
        saboBridge.connect(user1).deposit(tooSmall, "wallet_123")
      ).to.be.revertedWith("Bridge: below minimum deposit");
    });

    it("Should reject deposit with empty wallet ID", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);

      await expect(
        saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "")
      ).to.be.revertedWith("Bridge: empty wallet ID");
    });

    it("Should reject deposit when paused", async () => {
      await saboBridge.pause();
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);

      await expect(
        saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_123")
      ).to.be.revertedWithCustomError(saboBridge, "EnforcedPause");
    });
  });

  describe("Withdraw (Off-chain → On-chain)", () => {
    it("Should process withdrawal successfully", async () => {
      const requestId = toBytes32("req_ok_001");
      const grossAmount = ethers.parseEther("200");
      const fee = grossAmount * 100n / 10000n; // 1%
      const netAmount = grossAmount - fee;

      const balBefore = await saboToken.balanceOf(user1.address);

      await expect(saboBridge.withdraw(user1.address, grossAmount, requestId))
        .to.emit(saboBridge, "Withdrawn");

      // User received net amount
      expect(await saboToken.balanceOf(user1.address)).to.equal(balBefore + netAmount);

      // Request marked as processed
      expect(await saboBridge.processedRequests(requestId)).to.be.true;

      // Nonce incremented
      expect(await saboBridge.withdrawNonce(user1.address)).to.equal(1);

      // Total withdrawn tracked
      expect(await saboBridge.totalWithdrawn()).to.equal(netAmount);
    });

    it("Should reject duplicate request ID", async () => {
      const requestId = toBytes32("req_dup");
      await saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, requestId);

      await ethers.provider.send("evm_increaseTime", [3601]);
      await ethers.provider.send("evm_mine", []);

      await expect(
        saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, requestId)
      ).to.be.revertedWith("Bridge: already processed");
    });

    it("Should enforce cooldown between withdrawals", async () => {
      const req1 = toBytes32("req_cool_1");
      const req2 = toBytes32("req_cool_2");

      await saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, req1);

      // Immediately try another withdrawal
      await expect(
        saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, req2)
      ).to.be.revertedWith("Bridge: cooldown active");
    });

    it("Should allow withdrawal after cooldown expires", async () => {
      const req1 = toBytes32("req_cd_1");
      const req2 = toBytes32("req_cd_2");

      await saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, req1);

      // Advance time past cooldown (1 hour + 1 second)
      await ethers.provider.send("evm_increaseTime", [3601]);
      await ethers.provider.send("evm_mine", []);

      await expect(
        saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, req2)
      ).to.not.be.reverted;

      expect(await saboBridge.withdrawNonce(user1.address)).to.equal(2);
    });

    it("Should correctly calculate and deduct fees", async () => {
      const requestId = toBytes32("req_fee");
      const amount = ethers.parseEther("1000");
      const expectedFee = ethers.parseEther("10"); // 1%
      const expectedNet = ethers.parseEther("990");

      const balBefore = await saboToken.balanceOf(user1.address);
      await saboBridge.withdraw(user1.address, amount, requestId);
      const balAfter = await saboToken.balanceOf(user1.address);

      expect(balAfter - balBefore).to.equal(expectedNet);
    });

    it("Should handle withdrawal to different users", async () => {
      const req1 = toBytes32("req_u1");
      const req2 = toBytes32("req_u2");

      await saboBridge.withdraw(user1.address, WITHDRAW_AMOUNT, req1);
      await saboBridge.withdraw(user2.address, WITHDRAW_AMOUNT, req2);

      expect(await saboBridge.withdrawNonce(user1.address)).to.equal(1);
      expect(await saboBridge.withdrawNonce(user2.address)).to.equal(1);
    });
  });

  // Helper to get current block timestamp
  async function getBlockTimestamp(): Promise<number> {
    const block = await ethers.provider.getBlock("latest");
    return block!.timestamp;
  }

  describe("Withdraw Validations", () => {
    it("Should reject withdraw from non-owner", async () => {
      const requestId = toBytes32("req_001");
      await expect(
        saboBridge
          .connect(user1)
          .withdraw(user1.address, WITHDRAW_AMOUNT, requestId)
      ).to.be.revertedWithCustomError(saboBridge, "OwnableUnauthorizedAccount");
    });

    it("Should reject withdraw below minimum", async () => {
      const requestId = toBytes32("req_small");
      await expect(
        saboBridge.withdraw(
          user1.address,
          ethers.parseEther("10"),
          requestId
        )
      ).to.be.revertedWith("Bridge: below minimum withdraw");
    });

    it("Should reject withdraw above maximum", async () => {
      const requestId = toBytes32("req_big");
      await expect(
        saboBridge.withdraw(
          user1.address,
          ethers.parseEther("20000"),
          requestId
        )
      ).to.be.revertedWith("Bridge: exceeds maximum withdraw");
    });
  });

  describe("Configuration", () => {
    it("Should allow owner to update min deposit amount", async () => {
      const newMin = ethers.parseEther("100");
      await expect(saboBridge.setMinDepositAmount(newMin))
        .to.emit(saboBridge, "ConfigUpdated")
        .withArgs("minDepositAmount", ethers.parseEther("50"), newMin);
      expect(await saboBridge.minDepositAmount()).to.equal(newMin);
    });

    it("Should allow owner to update min withdraw amount", async () => {
      const newMin = ethers.parseEther("100");
      await saboBridge.setMinWithdrawAmount(newMin);
      expect(await saboBridge.minWithdrawAmount()).to.equal(newMin);
    });

    it("Should allow owner to update max withdraw amount", async () => {
      const newMax = ethers.parseEther("50000");
      await saboBridge.setMaxWithdrawAmount(newMax);
      expect(await saboBridge.maxWithdrawAmount()).to.equal(newMax);
    });

    it("Should allow owner to update cooldown", async () => {
      await saboBridge.setWithdrawCooldown(7200);
      expect(await saboBridge.withdrawCooldown()).to.equal(7200);
    });

    it("Should allow owner to update withdraw fee", async () => {
      await saboBridge.setWithdrawFeePercent(200);
      expect(await saboBridge.withdrawFeePercent()).to.equal(200);
    });

    it("Should reject fee above 10%", async () => {
      await expect(
        saboBridge.setWithdrawFeePercent(1100)
      ).to.be.revertedWith("Bridge: fee too high (max 10%)");
    });

    it("Should reject config changes from non-owner", async () => {
      await expect(
        saboBridge
          .connect(user1)
          .setMinDepositAmount(ethers.parseEther("1"))
      ).to.be.revertedWithCustomError(saboBridge, "OwnableUnauthorizedAccount");
    });
  });

  describe("Emergency", () => {
    it("Should allow emergency withdraw when paused", async () => {
      // Deposit some tokens first
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);
      await saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_emg");

      await saboBridge.pause();

      const ownerBalBefore = await saboToken.balanceOf(owner.address);
      await saboBridge.emergencyWithdrawLocked();

      expect(
        await saboToken.balanceOf(await saboBridge.getAddress())
      ).to.equal(0);
      expect(await saboToken.balanceOf(owner.address)).to.be.gt(
        ownerBalBefore
      );
      expect(await saboBridge.totalLocked()).to.equal(0);
    });

    it("Should reject emergency withdraw when not paused", async () => {
      await expect(
        saboBridge.emergencyWithdrawLocked()
      ).to.be.revertedWithCustomError(saboBridge, "ExpectedPause");
    });

    it("Should reject emergency withdraw with no balance", async () => {
      await saboBridge.pause();
      await expect(
        saboBridge.emergencyWithdrawLocked()
      ).to.be.revertedWith("Bridge: no locked tokens");
    });
  });

  describe("Pausable", () => {
    it("Should allow owner to pause and unpause", async () => {
      await saboBridge.pause();
      expect(await saboBridge.paused()).to.be.true;
      await saboBridge.unpause();
      expect(await saboBridge.paused()).to.be.false;
    });

    it("Should reject pause from non-owner", async () => {
      await expect(
        saboBridge.connect(user1).pause()
      ).to.be.revertedWithCustomError(saboBridge, "OwnableUnauthorizedAccount");
    });
  });

  describe("Stats & Views", () => {
    it("Should track deposit totals through getStats", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);
      await saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_stat");

      const stats = await saboBridge.getStats();
      expect(stats[0]).to.equal(DEPOSIT_AMOUNT); // totalLocked
      expect(stats[3]).to.be.false; // not paused
    });

    it("Should report bridge balance correctly", async () => {
      await saboToken
        .connect(user1)
        .approve(await saboBridge.getAddress(), DEPOSIT_AMOUNT);
      await saboBridge.connect(user1).deposit(DEPOSIT_AMOUNT, "wallet_bal");

      const stats = await saboBridge.getStats();
      expect(stats[2]).to.equal(DEPOSIT_AMOUNT); // bridgeBalance
    });

    it("Should report canWithdraw = true initially", async () => {
      expect(await saboBridge.canWithdraw(user1.address)).to.be.true;
    });

    it("Should track nonces per user", async () => {
      expect(await saboBridge.withdrawNonce(user1.address)).to.equal(0);
    });

    it("Should track processed requests", async () => {
      const requestId = toBytes32("req_check");
      expect(await saboBridge.processedRequests(requestId)).to.be.false;
    });
  });
});
