const hre = require("hardhat");

async function main() {
  const TOKEN_ADDRESS = "0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead";
  
  const [deployer] = await hre.ethers.getSigners();
  console.log("Déploiement de la gouvernance...");
  
  // 1. Déployer le Timelock
  const TimelockController = await hre.ethers.getContractFactory("TimelockController");
  const minDelay = 48 * 60 * 60; // 48 heures
  const proposers = [deployer.address];
  const executors = [deployer.address];
  const admin = deployer.address;
  
  const timelock = await TimelockController.deploy(minDelay, proposers, executors, admin);
  await timelock.waitForDeployment();
  const timelockAddress = await timelock.getAddress();
  console.log(`✅ Timelock déployé : ${timelockAddress}`);
  
  // 2. Déployer le Governor
  const AFRCGovernor = await hre.ethers.getContractFactory("AFRCGovernor");
  const initialVotingDelay = 7 * 24 * 60 * 60; // 7 jours
  const initialVotingPeriod = 5 * 24 * 60 * 60; // 5 jours
  const initialProposalThreshold = hre.ethers.parseEther("1000"); // 1000 AFRC
  
  const governor = await AFRCGovernor.deploy(
    TOKEN_ADDRESS,
    timelockAddress,
    initialVotingDelay,
    initialVotingPeriod,
    initialProposalThreshold
  );
  await governor.waitForDeployment();
  const governorAddress = await governor.getAddress();
  
  console.log(`✅ Governor déployé : ${governorAddress}`);
  console.log(`🔗 https://amoy.polygonscan.com/address/${governorAddress}`);
  console.log(`🔗 https://amoy.polygonscan.com/address/${timelockAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});