import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("══════════════════════════════════════════════════════");
  console.log("  SABO Token Deployment");
  console.log("══════════════════════════════════════════════════════");
  console.log(`  Deployer : ${deployer.address}`);
  console.log(`  Balance  : ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} ETH`);
  console.log("──────────────────────────────────────────────────────");

  // 1. Deploy SABOToken
  console.log("\n📦 Deploying SABOToken...");
  const SABOToken = await ethers.getContractFactory("SABOToken");
  const saboToken = await SABOToken.deploy();
  await saboToken.waitForDeployment();
  const tokenAddress = await saboToken.getAddress();
  console.log(`  ✅ SABOToken deployed: ${tokenAddress}`);
  console.log(`  📊 Initial supply: ${ethers.formatEther(await saboToken.totalSupply())} SABO`);

  // 2. Deploy SABOBridge
  console.log("\n📦 Deploying SABOBridge...");
  const SABOBridge = await ethers.getContractFactory("SABOBridge");
  const saboBridge = await SABOBridge.deploy(tokenAddress);
  await saboBridge.waitForDeployment();
  const bridgeAddress = await saboBridge.getAddress();
  console.log(`  ✅ SABOBridge deployed: ${bridgeAddress}`);

  // 3. Deploy SABOStaking
  console.log("\n📦 Deploying SABOStaking...");
  const SABOStaking = await ethers.getContractFactory("SABOStaking");
  const saboStaking = await SABOStaking.deploy(tokenAddress);
  await saboStaking.waitForDeployment();
  const stakingAddress = await saboStaking.getAddress();
  console.log(`  ✅ SABOStaking deployed: ${stakingAddress}`);

  // 4. Deploy SABOAchievement (Soulbound NFTs)
  console.log("\n📦 Deploying SABOAchievement...");
  const SABOAchievement = await ethers.getContractFactory("SABOAchievement");
  const saboAchievement = await SABOAchievement.deploy();
  await saboAchievement.waitForDeployment();
  const achievementAddress = await saboAchievement.getAddress();
  console.log(`  ✅ SABOAchievement deployed: ${achievementAddress}`);

  // 5. Post-deployment setup
  console.log("\n⚙️  Setting up roles...");

  // Grant MINTER_ROLE to Bridge and Staking contracts
  await saboToken.setMinter(bridgeAddress, true);
  console.log(`  ✅ Granted minter role to SABOBridge`);

  await saboToken.setMinter(stakingAddress, true);
  console.log(`  ✅ Granted minter role to SABOStaking`);

  // Increase daily mint cap for bridge operations (10K SABO/day)
  await saboToken.setDailyMintCap(ethers.parseEther("10000"));
  console.log(`  ✅ Daily mint cap set to 10,000 SABO`);

  // Seed default achievement types (matching gamification badges)
  console.log("\n🎖️  Seeding achievement types...");
  const achievementSeeds = [
    { name: "Founder",          rarity: 0, uri: "ipfs://sabo-achievements/founder",       maxSupply: 0 },
    { name: "Commander",        rarity: 0, uri: "ipfs://sabo-achievements/commander",     maxSupply: 0 },
    { name: "Speed Demon",      rarity: 1, uri: "ipfs://sabo-achievements/speed-demon",   maxSupply: 0 },
    { name: "Recruiter",        rarity: 1, uri: "ipfs://sabo-achievements/recruiter",     maxSupply: 0 },
    { name: "Zero Defect",      rarity: 2, uri: "ipfs://sabo-achievements/zero-defect",   maxSupply: 0 },
    { name: "Sắt Đá",           rarity: 2, uri: "ipfs://sabo-achievements/sat-da",        maxSupply: 0 },
    { name: "Đa Nhân Cách",     rarity: 2, uri: "ipfs://sabo-achievements/da-nhan-cach",  maxSupply: 0 },
    { name: "Vua Doanh Thu",    rarity: 3, uri: "ipfs://sabo-achievements/vua-doanh-thu", maxSupply: 0 },
    { name: "Phượng Hoàng",     rarity: 3, uri: "ipfs://sabo-achievements/phuong-hoang",  maxSupply: 0 },
    { name: "Người Sắt",        rarity: 4, uri: "ipfs://sabo-achievements/nguoi-sat",     maxSupply: 1 },
  ];
  for (const seed of achievementSeeds) {
    await saboAchievement.createAchievementType(seed.name, seed.rarity, seed.uri, seed.maxSupply);
  }
  console.log(`  ✅ Seeded ${achievementSeeds.length} achievement types`);

  // 6. Summary
  console.log("\n══════════════════════════════════════════════════════");
  console.log("  DEPLOYMENT COMPLETE");
  console.log("══════════════════════════════════════════════════════");
  console.log(`  SABOToken       : ${tokenAddress}`);
  console.log(`  SABOBridge      : ${bridgeAddress}`);
  console.log(`  SABOStaking     : ${stakingAddress}`);
  console.log(`  SABOAchievement : ${achievementAddress}`);
  console.log("──────────────────────────────────────────────────────");
  console.log(`  Minter: Bridge  ✅`);
  console.log(`  Minter: Staking ✅`);
  console.log(`  Achievement Types: ${achievementSeeds.length} seeded`);
  console.log("──────────────────────────────────────────────────────");
  console.log("\n🔗 Save these addresses in your .env and Flutter config!");

  // 7. Write deployment info to file
  const fs = await import("fs");
  const deployInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: Number((await ethers.provider.getNetwork()).chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      SABOToken: tokenAddress,
      SABOBridge: bridgeAddress,
      SABOStaking: stakingAddress,
      SABOAchievement: achievementAddress,
    },
  };

  fs.writeFileSync(
    "deployments.json",
    JSON.stringify(deployInfo, null, 2)
  );
  console.log("\n💾 Deployment info saved to deployments.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
