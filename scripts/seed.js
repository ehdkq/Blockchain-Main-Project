// scripts/seed.js
const hre = require("hardhat");

async function main() {
  // 1. Get the contract
  // CHANGE THIS to your actual deployed address if you want to seed a specific deployment
  // Otherwise, this script assumes you just deployed it and know the address.
  const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS_HERE"; 

  console.log(`Seeding data to contract at: ${CONTRACT_ADDRESS}...`);

  const AgriSensorData = await hre.ethers.getContractFactory("AgriSensorData");
  const contract = await AgriSensorData.attach(CONTRACT_ADDRESS);

  // 2. Create Dummy Data
  const sampleData = [
    { id: 101, hash: "QmHash123...", timestamp: 1625240000 },
    { id: 102, hash: "QmHash456...", timestamp: 1625245000 },
    { id: 103, hash: "QmHash789...", timestamp: 1625250000 },
  ];

  // 3. Send Transactions
  for (const item of sampleData) {
    console.log(`Adding sensor ${item.id}...`);
    const tx = await contract.addSensorData(item.id, item.hash, item.timestamp);
    await tx.wait(); // Wait for transaction to be mined
  }

  console.log("✅ Seed data added successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});