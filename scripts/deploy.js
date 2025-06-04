const hre = require("hardhat");

async function main() {
  // Get the ContractFactory for TrustX
  const TrustX = await hre.ethers.getContractFactory("TrustX");
  // Deploy the contract
  const trustX = await TrustX.deploy();
  // Wait for the deployment transaction to be mined
  await trustX.waitForDeployment();
  // Get the deployed contract address
  const address = await trustX.getAddress();
  console.log("TrustX deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});