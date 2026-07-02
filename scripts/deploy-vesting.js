const hre = require("hardhat");

async function main() {
  const TOKEN_ADDRESS = "0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead";
  
  console.log("Déploiement du contrat VestingVault...");
  
  const VestingVault = await hre.ethers.getContractFactory("VestingVault");
  const vault = await VestingVault.deploy(TOKEN_ADDRESS);
  await vault.waitForDeployment();
  
  const address = await vault.getAddress();
  console.log(`✅ VestingVault déployé à l'adresse : ${address}`);
  console.log(`🔗 Voir sur Polygonscan : https://amoy.polygonscan.com/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});