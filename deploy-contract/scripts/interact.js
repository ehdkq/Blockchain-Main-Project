// scripts/interact.js
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("========================================");
  console.log("  CONTRACT INTERACTION SCRIPT");
  console.log("========================================\n");

  const network = hre.network.name;
  
  // Load deployment info
  const deploymentFile = path.join(__dirname, `../deployments/${network}-deployment.json`);
  
  if (!fs.existsSync(deploymentFile)) {
    console.error(`❌ No deployment found for network: ${network}`);
    console.error(`Please deploy first: npx hardhat run scripts/deploy.js --network ${network}\n`);
    process.exit(1);
  }

  const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  const contractAddress = deploymentInfo.contractAddress;
  
  console.log(`Network: ${network}`);
  console.log(`Contract Address: ${contractAddress}\n`);

  // Get signer
  const [signer] = await hre.ethers.getSigners();
  const signerAddress = await signer.getAddress();
  console.log(`Interacting as: ${signerAddress}\n`);

  // Get contract instance
  const contract = await hre.ethers.getContractAt("SecureAssetManager", contractAddress);

  console.log("========================================");
  console.log("  CONTRACT INFORMATION");
  console.log("========================================\n");

  // Get basic info
  const name = await contract.name();
  const symbol = await contract.symbol();
  const totalSupply = await contract.totalSupply();
  const balance = await contract.balanceOf(signerAddress);
  const paused = await contract.paused();

  console.log(`Token Name: ${name}`);
  console.log(`Token Symbol: ${symbol}`);
  console.log(`Total Supply: ${hre.ethers.formatEther(totalSupply)} ${symbol}`);
  console.log(`Your Balance: ${hre.ethers.formatEther(balance)} ${symbol}`);
  console.log(`Contract Paused: ${paused}\n`);

  // Check roles
  console.log("========================================");
  console.log("  YOUR ROLES");
  console.log("========================================\n");

  const ADMIN_ROLE = await contract.ADMIN_ROLE();
  const MINTER_ROLE = await contract.MINTER_ROLE();
  const PAUSER_ROLE = await contract.PAUSER_ROLE();

  const hasAdminRole = await contract.hasRole(ADMIN_ROLE, signerAddress);
  const hasMinterRole = await contract.hasRole(MINTER_ROLE, signerAddress);
  const hasPauserRole = await contract.hasRole(PAUSER_ROLE, signerAddress);

  console.log(`ADMIN_ROLE: ${hasAdminRole ? "✅" : "❌"}`);
  console.log(`MINTER_ROLE: ${hasMinterRole ? "✅" : "❌"}`);
  console.log(`PAUSER_ROLE: ${hasPauserRole ? "✅" : "❌"}\n`);

  // Get privacy statistics (with differential privacy)
  console.log("========================================");
  console.log("  PRIVACY-PROTECTED STATISTICS");
  console.log("========================================\n");

  const privateTransactionCount = await contract.getPrivateTransactionCount();
  const privateUserCount = await contract.getPrivateUserCount();

  console.log(`Transaction Count (with noise): ${privateTransactionCount}`);
  console.log(`User Count (with noise): ${privateUserCount}`);
  
  if (hasAdminRole) {
    const trueTransactionCount = await contract.getTrueTransactionCount();
    console.log(`\nTrue Transaction Count (admin only): ${trueTransactionCount}`);
    console.log(`Noise added: ${Math.abs(Number(privateTransactionCount) - Number(trueTransactionCount))}`);
  }
  console.log();

  // Rate limit status
  console.log("========================================");
  console.log("  RATE LIMIT STATUS");
  console.log("========================================\n");

  const rateLimitStatus = await contract.getRateLimitStatus(signerAddress);
  console.log(`Available Tokens: ${rateLimitStatus.availableTokens}/10`);
  console.log(`Total Requests: ${rateLimitStatus.totalRequests}`);
  console.log(`Next Refill: ${new Date(Number(rateLimitStatus.nextRefillTime) * 1000).toLocaleString()}\n`);

  // Pause info
  console.log("========================================");
  console.log("  CIRCUIT BREAKER STATUS");
  console.log("========================================\n");

  const pauseInfo = await contract.getPauseInfo();
  console.log(`Currently Paused: ${pauseInfo.isPaused}`);
  console.log(`Total Pause Count: ${pauseInfo.pauseCount}`);
  
  if (pauseInfo.lastPauseTime > 0) {
    console.log(`Last Pause: ${new Date(Number(pauseInfo.lastPauseTime) * 1000).toLocaleString()}`);
    console.log(`Reason: ${pauseInfo.reason || "N/A"}`);
  }
  console.log();

  // Example interactions
  console.log("========================================");
  console.log("  EXAMPLE INTERACTIONS");
  console.log("========================================\n");

  console.log("Transfer tokens:");
  console.log(`  await contract.transfer(recipientAddress, ethers.parseEther("100"))\n`);

  console.log("Approve spending:");
  console.log(`  await contract.approve(spenderAddress, ethers.parseEther("50"))\n`);

  if (hasMinterRole) {
    console.log("Mint tokens (requires MINTER_ROLE):");
    console.log(`  await contract.mint(recipientAddress, ethers.parseEther("1000"))\n`);
  }

  if (hasPauserRole) {
    console.log("Pause contract (requires PAUSER_ROLE):");
    console.log(`  await contract.pause()\n`);
    
    console.log("Unpause contract:");
    console.log(`  await contract.unpause()\n`);
  }

  if (hasAdminRole) {
    console.log("Grant roles (requires ADMIN_ROLE):");
    console.log(`  await contract.grantRole(MINTER_ROLE, newMinterAddress)`);
    console.log(`  await contract.grantRole(PAUSER_ROLE, newPauserAddress)\n`);
  }

  console.log("Check nonce:");
  console.log(`  await contract.getNonce(yourAddress)\n`);

  console.log("========================================\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
