import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const achievementAddress = "0xA245e4Eb8d5814436a295b7dF104aF541E2a8BFb";

  console.log("🎖️  Seeding achievement types...");
  console.log(`  Deployer: ${deployer.address}`);
  console.log(`  Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} ETH`);

  const SABOAchievement = await ethers.getContractAt("SABOAchievement", achievementAddress);

  // Check how many already exist
  let existingCount = 0;
  try {
    // Try to get achievement type count
    for (let i = 1; i <= 10; i++) {
      try {
        await SABOAchievement.achievementTypes(i);
        existingCount = i;
      } catch {
        break;
      }
    }
  } catch {
    // ignore
  }
  console.log(`  Existing achievement types: ${existingCount}`);

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

  // Skip already seeded ones
  const toSeed = achievementSeeds.slice(existingCount);
  console.log(`  Remaining to seed: ${toSeed.length}`);

  for (let i = 0; i < toSeed.length; i++) {
    const seed = toSeed[i];
    console.log(`  Creating [${existingCount + i + 1}] ${seed.name}...`);
    const tx = await SABOAchievement.createAchievementType(
      seed.name, seed.rarity, seed.uri, seed.maxSupply
    );
    await tx.wait(); // Wait for confirmation before next tx
    console.log(`    ✅ Done (tx: ${tx.hash})`);
  }

  console.log(`\n✅ All ${achievementSeeds.length} achievement types seeded!`);

  // Save deployments.json
  const fs = await import("fs");
  const deployInfo = {
    network: "base-sepolia",
    chainId: 84532,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      SABOToken: "0x7a0CCE4109b0c593f42F6DA3F4b120ad4677b472",
      SABOBridge: "0x0D32577079a54f36e99b9E8ff79ed3208dB3Fb30",
      SABOStaking: "0xA548119EB79Be531B122AB543c92F340aceD8886",
      SABOAchievement: achievementAddress,
    },
  };
  fs.writeFileSync("deployments.json", JSON.stringify(deployInfo, null, 2));
  console.log("💾 deployments.json updated");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Failed:", error);
    process.exit(1);
  });
