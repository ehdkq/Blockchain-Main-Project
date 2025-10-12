import { ethers } from "hardhat";

async function main() {
  // ❗ PASTE YOUR DEPLOYED CONTRACT ADDRESS HERE
  const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const proposalId = 1;

  console.log(`Attaching to contract at address: ${contractAddress}`);
  const voting = await ethers.getContractAt("Voting", contractAddress);

  // 1. Read the initial state
  const initialCount = await voting.getVoteCount(proposalId);
  console.log(`Initial vote count for proposal #${proposalId}: ${initialCount}`);

  // 2. Trigger the action (cast a vote)
  console.log(`Casting a vote for proposal #${proposalId}...`);
  const tx = await voting.vote(proposalId);
  await tx.wait(); // Wait for the transaction to be mined
  console.log("Transaction mined!");

  // 3. Read the state again to verify the change
  const finalCount = await voting.getVoteCount(proposalId);
  console.log(`Final vote count for proposal #${proposalId}: ${finalCount}`);
  console.log("State change verified successfully! 🎉");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});