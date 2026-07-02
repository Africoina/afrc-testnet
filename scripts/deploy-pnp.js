const hre = require("hardhat");

async function main() {
  const TOKEN_ADDRESS = "0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead";
  const TREASURY_ADDRESS = "0x7ec90C9397Ac1B6312C3E1768bEBAd81A140E8a3";
  
  console.log("Déploiement du PNPRegistry...");
  
  const PNPRegistry = await hre.ethers.getContractFactory("PNPRegistry");
  const pnp = await PNPRegistry.deploy(TOKEN_ADDRESS, TREASURY_ADDRESS);
  await pnp.waitForDeployment();
  
  const address = await pnp.getAddress();
  console.log(`✅ PNPRegistry déployé : ${address}`);
  console.log(`🔗 https://amoy.polygonscan.com/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});