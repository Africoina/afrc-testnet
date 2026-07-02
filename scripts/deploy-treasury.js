const hre = require("hardhat");

async function main() {
  const TOKEN_ADDRESS = "0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead";
  
  const [deployer] = await hre.ethers.getSigners();
  
  const signers = [
    deployer.address,
    "0x0000000000000000000000000000000000000002",
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005",
    "0x0000000000000000000000000000000000000006",
    "0x0000000000000000000000000000000000000007"
  ];
  
  console.log("Déploiement du AFRCTreasury...");
  
  const AFRCTreasury = await hre.ethers.getContractFactory("AFRCTreasury");
  const treasury = await AFRCTreasury.deploy(TOKEN_ADDRESS, signers, 5);
  await treasury.waitForDeployment();
  
  const address = await treasury.getAddress();
  console.log(`✅ AFRCTreasury déployé : ${address}`);
  console.log(`🔗 https://amoy.polygonscan.com/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});