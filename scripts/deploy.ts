import { ethers } from "hardhat";

async function main() {
  const VotingFactory = await ethers.getContractFactory("Voting");
  console.log("Deploying contract...");
  const voting = await VotingFactory.deploy();

  await voting.deployed();

  console.log(`Voting contract deployed to: ${voting.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});