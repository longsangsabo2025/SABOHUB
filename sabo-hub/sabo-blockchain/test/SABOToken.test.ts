import { expect } from "chai";
import { ethers } from "hardhat";
import { SABOToken } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SABOToken", () => {
  let saboToken: SABOToken;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;

  const MAX_SUPPLY = ethers.parseEther("100000000"); // 100M
  const INITIAL_SUPPLY = ethers.parseEther("10000000"); // 10M
  const DEFAULT_DAILY_CAP = ethers.parseEther("1000"); // 1K

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const SABOToken = await ethers.getContractFactory("SABOToken");
    saboToken = await SABOToken.deploy();
    await saboToken.waitForDeployment();
  });

  describe("Deployment", () => {
    it("Should set the correct name and symbol", async () => {
      expect(await saboToken.name()).to.equal("SABO Token");
      expect(await saboToken.symbol()).to.equal("SABO");
    });

    it("Should mint initial supply to deployer", async () => {
      expect(await saboToken.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY);
    });

    it("Should set correct MAX_SUPPLY", async () => {
      expect(await saboToken.MAX_SUPPLY()).to.equal(MAX_SUPPLY);
    });

    it("Should set deployer as owner", async () => {
      expect(await saboToken.owner()).to.equal(owner.address);
    });

    it("Should set default daily mint cap", async () => {
      expect(await saboToken.dailyMintCap()).to.equal(DEFAULT_DAILY_CAP);
    });
  });

  describe("Minting", () => {
    it("Should allow owner to mint tokens", async () => {
      const amount = ethers.parseEther("100");
      await saboToken.mint(addr1.address, amount, "task_completion");
      expect(await saboToken.balanceOf(addr1.address)).to.equal(amount);
    });

    it("Should reject mint from non-minter", async () => {
      const amount = ethers.parseEther("100");
      await expect(
        saboToken.connect(addr1).mint(addr2.address, amount, "hack")
      ).to.be.revertedWith("SABO: not a minter");
    });

    it("Should enforce daily mint cap", async () => {
      const overCap = ethers.parseEther("1001");
      await expect(
        saboToken.mint(addr1.address, overCap, "exceeds_cap")
      ).to.be.revertedWith("SABO: daily mint cap exceeded");
    });

    it("Should track daily minted amount", async () => {
      const amount = ethers.parseEther("500");
      await saboToken.mint(addr1.address, amount, "batch1");
      await saboToken.mint(addr2.address, amount, "batch2");

      // Third mint should fail (1000 already minted)
      await expect(
        saboToken.mint(addr3.address, ethers.parseEther("1"), "over")
      ).to.be.revertedWith("SABO: daily mint cap exceeded");
    });

    it("Should not exceed MAX_SUPPLY", async () => {
      // Set a very high daily cap for this test
      await saboToken.setDailyMintCap(MAX_SUPPLY);
      
      // Try to mint remaining + 1
      const remaining = MAX_SUPPLY - INITIAL_SUPPLY;
      const overMax = remaining + ethers.parseEther("1");
      await expect(
        saboToken.mint(addr1.address, overMax, "over_max")
      ).to.be.revertedWith("SABO: exceeds max supply");
    });

    it("Should emit TokensMinted event", async () => {
      const amount = ethers.parseEther("50");
      await expect(saboToken.mint(addr1.address, amount, "event_test"))
        .to.emit(saboToken, "TokensMinted")
        .withArgs(addr1.address, amount, "event_test");
    });
  });

  describe("Batch Minting", () => {
    it("Should mint to multiple recipients in one tx", async () => {
      const recipients = [addr1.address, addr2.address, addr3.address];
      const amounts = [
        ethers.parseEther("100"),
        ethers.parseEther("200"),
        ethers.parseEther("300"),
      ];

      await saboToken.mintBatch(recipients, amounts, "batch_rewards");

      expect(await saboToken.balanceOf(addr1.address)).to.equal(amounts[0]);
      expect(await saboToken.balanceOf(addr2.address)).to.equal(amounts[1]);
      expect(await saboToken.balanceOf(addr3.address)).to.equal(amounts[2]);
    });

    it("Should reject mismatched arrays", async () => {
      const recipients = [addr1.address, addr2.address];
      const amounts = [ethers.parseEther("100")];

      await expect(
        saboToken.mintBatch(recipients, amounts, "mismatch")
      ).to.be.revertedWith("SABO: length mismatch");
    });

    it("Should enforce daily cap across batch", async () => {
      const recipients = [addr1.address, addr2.address];
      const amounts = [ethers.parseEther("600"), ethers.parseEther("500")];

      await expect(
        saboToken.mintBatch(recipients, amounts, "over_cap_batch")
      ).to.be.revertedWith("SABO: daily mint cap exceeded");
    });
  });

  describe("Daily Cap Management", () => {
    it("Should allow owner to update daily mint cap", async () => {
      const newCap = ethers.parseEther("5000");
      await saboToken.setDailyMintCap(newCap);
      expect(await saboToken.dailyMintCap()).to.equal(newCap);
    });

    it("Should emit DailyMintCapUpdated event", async () => {
      const newCap = ethers.parseEther("2000");
      await expect(saboToken.setDailyMintCap(newCap))
        .to.emit(saboToken, "DailyMintCapUpdated")
        .withArgs(DEFAULT_DAILY_CAP, newCap);
    });

    it("Should reset daily counter after 24 hours", async () => {
      // Mint up to cap
      await saboToken.mint(addr1.address, DEFAULT_DAILY_CAP, "day1");

      // Advance time by 24 hours
      await ethers.provider.send("evm_increaseTime", [86401]);
      await ethers.provider.send("evm_mine", []);

      // Should be able to mint again
      await expect(
        saboToken.mint(addr1.address, ethers.parseEther("100"), "day2")
      ).to.not.be.reverted;
    });
  });

  describe("Pause / Unpause", () => {
    it("Should allow owner to pause", async () => {
      await saboToken.pause();
      expect(await saboToken.paused()).to.be.true;
    });

    it("Should prevent transfers when paused", async () => {
      await saboToken.transfer(addr1.address, ethers.parseEther("100"));
      await saboToken.pause();

      await expect(
        saboToken.connect(addr1).transfer(addr2.address, ethers.parseEther("50"))
      ).to.be.revertedWithCustomError(saboToken, "EnforcedPause");
    });

    it("Should allow transfers after unpause", async () => {
      await saboToken.transfer(addr1.address, ethers.parseEther("100"));
      await saboToken.pause();
      await saboToken.unpause();

      await expect(
        saboToken.connect(addr1).transfer(addr2.address, ethers.parseEther("50"))
      ).to.not.be.reverted;
    });
  });

  describe("Burning", () => {
    it("Should allow token holders to burn their tokens", async () => {
      const burnAmount = ethers.parseEther("1000");
      await saboToken.burn(burnAmount);
      expect(await saboToken.balanceOf(owner.address)).to.equal(
        INITIAL_SUPPLY - burnAmount
      );
    });

    it("Should reduce total supply on burn", async () => {
      const burnAmount = ethers.parseEther("1000");
      await saboToken.burn(burnAmount);
      expect(await saboToken.totalSupply()).to.equal(INITIAL_SUPPLY - burnAmount);
    });
  });

  describe("Ownership Transfer (2-step)", () => {
    it("Should initiate ownership transfer", async () => {
      await saboToken.transferOwnership(addr1.address);
      // Owner should still be original until accepted
      expect(await saboToken.owner()).to.equal(owner.address);
    });

    it("Should complete ownership transfer on accept", async () => {
      await saboToken.transferOwnership(addr1.address);
      await saboToken.connect(addr1).acceptOwnership();
      expect(await saboToken.owner()).to.equal(addr1.address);
    });
  });

  describe("Minter Role", () => {
    it("Should allow owner to grant minter role", async () => {
      await saboToken.setMinter(addr1.address, true);
      expect(await saboToken.minters(addr1.address)).to.be.true;
    });

    it("Should emit MinterUpdated event", async () => {
      await expect(saboToken.setMinter(addr1.address, true))
        .to.emit(saboToken, "MinterUpdated")
        .withArgs(addr1.address, true);
    });

    it("Should allow minter to mint tokens", async () => {
      await saboToken.setMinter(addr1.address, true);
      // Increase cap for this test
      await saboToken.setDailyMintCap(ethers.parseEther("10000"));
      const amount = ethers.parseEther("100");
      await saboToken.connect(addr1).mint(addr2.address, amount, "minter_test");
      expect(await saboToken.balanceOf(addr2.address)).to.equal(amount);
    });

    it("Should allow owner to revoke minter role", async () => {
      await saboToken.setMinter(addr1.address, true);
      await saboToken.setMinter(addr1.address, false);
      expect(await saboToken.minters(addr1.address)).to.be.false;
    });

    it("Should reject minting after revocation", async () => {
      await saboToken.setMinter(addr1.address, true);
      await saboToken.setMinter(addr1.address, false);
      await expect(
        saboToken.connect(addr1).mint(addr2.address, ethers.parseEther("10"), "revoked")
      ).to.be.revertedWith("SABO: not a minter");
    });

    it("Should reject setMinter from non-owner", async () => {
      await expect(
        saboToken.connect(addr1).setMinter(addr2.address, true)
      ).to.be.revertedWithCustomError(saboToken, "OwnableUnauthorizedAccount");
    });

    it("Owner should still be able to mint (implicit minter)", async () => {
      const amount = ethers.parseEther("100");
      await saboToken.mint(addr1.address, amount, "owner_mint");
      expect(await saboToken.balanceOf(addr1.address)).to.equal(amount);
    });
  });
});
