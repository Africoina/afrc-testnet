const hre = require("hardhat");

async function main() {
  console.log("Deploiement du contrat AFRCToken sur Polygon Amoy...");
  
  const AFRCToken = await hre.ethers.getContractFactory("AFRCToken");
  const token = await AFRCToken.deploy();
  await token.waitForDeployment();
  
  const address = await token.getAddress();
  console.log(`AFRCToken deploye a l'adresse : ${address}`);
  console.log(`Voir sur Polygonscan : https://amoy.polygonscan.com/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
