const { ethers } = require("hardhat");

async function main() {
  const Decentradonate = await ethers.getContractFactory("Decentradonate");
  const contract = await Decentradonate.deploy();
  await contract.waitForDeployment();
  console.log(`Decentradonate deployed to: ${contract.target}`);
  console.log(`Network: localhost (chainId: 31337)`);
  console.log(`Block number: ${await ethers.provider.getBlockNumber()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
