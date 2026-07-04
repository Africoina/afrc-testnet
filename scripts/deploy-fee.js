const hre = require("hardhat");

async function main() {
  const TOKEN_ADDRESS = "0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead";
  const TREASURY_ADDRESS = "0x0Aa96e7DD38c5377b2c3179AbfdA1803Ea65c1c7";
  
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  
  console.log("Deployer:", deployer.address);
  
  const authorized = [
    deployer.address,
    "0x0000000000000000000000000000000000000002",
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005"
  ];
  
  console.log("Deploiement du FeeCollector...");
  
  const FeeCollector = await hre.ethers.getContractFactory("FeeCollector");
  const collector = await FeeCollector.deploy(TOKEN_ADDRESS, TREASURY_ADDRESS, authorized, 3);
  await collector.waitForDeployment();
  
  console.log("FeeCollector deploye a :", await collector.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
