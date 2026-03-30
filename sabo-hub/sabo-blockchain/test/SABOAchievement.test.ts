import { expect } from "chai";
import { ethers } from "hardhat";
import { SABOAchievement } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("SABOAchievement", () => {
  let nft: SABOAchievement;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async () => {
    [owner, minter, user1, user2] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("SABOAchievement");
    nft = await factory.deploy();

    // Grant minter role
    await nft.setMinter(minter.address, true);

    // Create some achievement types
    // Type 0: Common — Founder (unlimited)
    await nft.createAchievementType("Founder", 0, "ipfs://founder-meta", 0);
    // Type 1: Rare — Speed Demon (max 100)
    await nft.createAchievementType("Speed Demon", 1, "ipfs://speed-meta", 100);
    // Type 2: Epic — Sắt Đá (max 10)
    await nft.createAchievementType("Sắt Đá", 2, "ipfs://satda-meta", 10);
    // Type 3: Legendary — Vua Doanh Thu (max 1)
    await nft.createAchievementType("Vua Doanh Thu", 3, "ipfs://vuadoanhthu-meta", 1);
    // Type 4: Mythic — Người Sắt (max 1)
    await nft.createAchievementType("Người Sắt", 4, "ipfs://nguoisat-meta", 1);
  });

  describe("Deployment", () => {
    it("Should have correct name and symbol", async () => {
      expect(await nft.name()).to.equal("SABO Achievement");
      expect(await nft.symbol()).to.equal("SABOACH");
    });

    it("Should set deployer as owner", async () => {
      expect(await nft.owner()).to.equal(owner.address);
    });

    it("Should have 5 achievement types", async () => {
      expect(await nft.achievementTypeCount()).to.equal(5);
    });
  });

  describe("Achievement Type Management", () => {
    it("Should create achievement types with correct data", async () => {
      const type0 = await nft.achievementTypes(0);
      expect(type0.name).to.equal("Founder");
      expect(type0.rarity).to.equal(0); // Common
      expect(type0.metadataURI).to.equal("ipfs://founder-meta");
      expect(type0.maxSupply).to.equal(0); // unlimited
      expect(type0.minted).to.equal(0);
      expect(type0.active).to.equal(true);
    });

    it("Should emit AchievementTypeCreated event", async () => {
      await expect(nft.createAchievementType("Test Badge", 1, "ipfs://test", 50))
        .to.emit(nft, "AchievementTypeCreated")
        .withArgs(5, "Test Badge", 1, 50);
    });

    it("Should allow owner to deactivate achievement type", async () => {
      await nft.setAchievementTypeActive(0, false);
      const type0 = await nft.achievementTypes(0);
      expect(type0.active).to.equal(false);
    });

    it("Should allow owner to update metadata URI", async () => {
      await nft.setAchievementTypeURI(0, "ipfs://new-founder-meta");
      const type0 = await nft.achievementTypes(0);
      expect(type0.metadataURI).to.equal("ipfs://new-founder-meta");
    });

    it("Should reject type management from non-owner", async () => {
      await expect(
        nft.connect(user1).createAchievementType("Hack", 0, "ipfs://hack", 0)
      ).to.be.revertedWithCustomError(nft, "OwnableUnauthorizedAccount");
    });
  });

  describe("Minter Role", () => {
    it("Should allow owner to grant minter role", async () => {
      expect(await nft.minters(minter.address)).to.equal(true);
    });

    it("Should emit MinterUpdated event", async () => {
      await expect(nft.setMinter(user1.address, true))
        .to.emit(nft, "MinterUpdated")
        .withArgs(user1.address, true);
    });

    it("Should reject setMinter from non-owner", async () => {
      await expect(
        nft.connect(user1).setMinter(user2.address, true)
      ).to.be.revertedWithCustomError(nft, "OwnableUnauthorizedAccount");
    });
  });

  describe("Minting", () => {
    it("Should mint achievement to user", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      expect(await nft.balanceOf(user1.address)).to.equal(1);
      expect(await nft.hasAchievement(user1.address, 0)).to.equal(true);
    });

    it("Should emit AchievementMinted event", async () => {
      await expect(nft.connect(minter).mint(user1.address, 0))
        .to.emit(nft, "AchievementMinted")
        .withArgs(user1.address, 1, 0, 0); // tokenId=1, typeId=0, rarity=Common
    });

    it("Should set correct token URI", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      expect(await nft.tokenURI(1)).to.equal("ipfs://founder-meta");
    });

    it("Should track achievement details", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      const detail = await nft.getAchievementDetail(1);
      expect(detail.typeId).to.equal(0);
      expect(detail.name).to.equal("Founder");
      expect(detail.rarity).to.equal(0);
      expect(detail.originalOwner).to.equal(user1.address);
    });

    it("Should reject duplicate achievement for same user", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      await expect(
        nft.connect(minter).mint(user1.address, 0)
      ).to.be.revertedWith("SABO-NFT: already has this achievement");
    });

    it("Should allow same achievement type for different users", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      await nft.connect(minter).mint(user2.address, 0);
      expect(await nft.hasAchievement(user1.address, 0)).to.equal(true);
      expect(await nft.hasAchievement(user2.address, 0)).to.equal(true);
    });

    it("Should reject mint from non-minter", async () => {
      await expect(
        nft.connect(user1).mint(user2.address, 0)
      ).to.be.revertedWith("SABO-NFT: not a minter");
    });

    it("Should reject mint of inactive type", async () => {
      await nft.setAchievementTypeActive(0, false);
      await expect(
        nft.connect(minter).mint(user1.address, 0)
      ).to.be.revertedWith("SABO-NFT: type is not active");
    });

    it("Should reject mint of nonexistent type", async () => {
      await expect(
        nft.connect(minter).mint(user1.address, 99)
      ).to.be.revertedWith("SABO-NFT: type does not exist");
    });

    it("Should enforce maxSupply", async () => {
      // Type 3 has maxSupply = 1 (Legendary)
      await nft.connect(minter).mint(user1.address, 3);
      await expect(
        nft.connect(minter).mint(user2.address, 3)
      ).to.be.revertedWith("SABO-NFT: max supply reached");
    });

    it("Should increment minted count", async () => {
      await nft.connect(minter).mint(user1.address, 1);
      const type1 = await nft.achievementTypes(1);
      expect(type1.minted).to.equal(1);
    });

    it("Owner should be able to mint (implicit minter)", async () => {
      await nft.connect(owner).mint(user1.address, 0);
      expect(await nft.balanceOf(user1.address)).to.equal(1);
    });
  });

  describe("Batch Minting", () => {
    it("Should batch mint multiple types to user", async () => {
      await nft.connect(minter).mintBatch(user1.address, [0, 1, 2]);
      expect(await nft.balanceOf(user1.address)).to.equal(3);
      expect(await nft.hasAchievement(user1.address, 0)).to.equal(true);
      expect(await nft.hasAchievement(user1.address, 1)).to.equal(true);
      expect(await nft.hasAchievement(user1.address, 2)).to.equal(true);
    });

    it("Should skip already owned achievements in batch (no revert)", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      // Batch includes type 0 which is already owned — should skip it
      await nft.connect(minter).mintBatch(user1.address, [0, 1, 2]);
      expect(await nft.balanceOf(user1.address)).to.equal(3); // 1 existing + 2 new
    });

    it("Should skip inactive types in batch", async () => {
      await nft.setAchievementTypeActive(1, false);
      await nft.connect(minter).mintBatch(user1.address, [0, 1, 2]);
      expect(await nft.balanceOf(user1.address)).to.equal(2); // type 1 skipped
      expect(await nft.hasAchievement(user1.address, 1)).to.equal(false);
    });
  });

  describe("Soulbound (Non-transferable)", () => {
    it("Should revert on transferFrom", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      await expect(
        nft.connect(user1).transferFrom(user1.address, user2.address, 1)
      ).to.be.revertedWith("SABO-NFT: soulbound, cannot transfer");
    });

    it("Should revert on safeTransferFrom", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      await expect(
        nft.connect(user1)["safeTransferFrom(address,address,uint256,bytes)"](
          user1.address, user2.address, 1, "0x"
        )
      ).to.be.revertedWith("SABO-NFT: soulbound, cannot transfer");
    });
  });

  describe("View Functions", () => {
    beforeEach(async () => {
      // Mint several achievements to user1
      await nft.connect(minter).mintBatch(user1.address, [0, 1, 2, 3, 4]);
    });

    it("Should return all achievement token IDs for user", async () => {
      const ids = await nft.getAchievements(user1.address);
      expect(ids.length).to.equal(5);
    });

    it("Should return achievement count by rarity", async () => {
      const counts = await nft.getAchievementCountByRarity(user1.address);
      expect(counts.common).to.equal(1);   // Founder
      expect(counts.rare).to.equal(1);      // Speed Demon
      expect(counts.epic).to.equal(1);      // Sắt Đá
      expect(counts.legendary).to.equal(1); // Vua Doanh Thu
      expect(counts.mythic).to.equal(1);    // Người Sắt
    });

    it("Should return active types", async () => {
      const result = await nft.getActiveTypes();
      expect(result.ids.length).to.equal(5);
      expect(result.names[0]).to.equal("Founder");
      expect(result.rarities[4]).to.equal(4); // Mythic
    });

    it("Should exclude inactive types from getActiveTypes", async () => {
      await nft.setAchievementTypeActive(2, false);
      const result = await nft.getActiveTypes();
      expect(result.ids.length).to.equal(4);
    });
  });

  describe("ERC721 Standard", () => {
    it("Should support ERC721 interface", async () => {
      expect(await nft.supportsInterface("0x80ac58cd")).to.equal(true); // ERC721
    });

    it("Should support ERC721Enumerable interface", async () => {
      expect(await nft.supportsInterface("0x780e9d63")).to.equal(true); // ERC721Enumerable
    });

    it("Should track totalSupply", async () => {
      await nft.connect(minter).mint(user1.address, 0);
      await nft.connect(minter).mint(user2.address, 0);
      await nft.connect(minter).mint(user1.address, 1);
      expect(await nft.totalSupply()).to.equal(3);
    });
  });
});
