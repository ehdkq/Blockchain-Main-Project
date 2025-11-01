// scripts/deploy.js
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("========================================");
  console.log("  SECURE ASSET MANAGER DEPLOYMENT");
  console.log("========================================\n");

  // Get network information
  const network = hre.network.name;
  const chainId = hre.network.config.chainId;
  
  console.log(`Network: ${network}`);
  console.log(`Chain ID: ${chainId}`);
  
  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  const balance = await hre.ethers.provider.getBalance(deployerAddress);
  
  console.log(`Deployer: ${deployerAddress}`);
  console.log(`Balance: ${hre.ethers.formatEther(balance)} ETH\n`);

  // Check if deployer has sufficient balance
  if (balance === 0n) {
    console.error("❌ Error: Deployer account has zero balance!");
    console.error("Please fund the account before deploying.\n");
    process.exit(1);
  }

  console.log("Deploying SecureAssetManager contract...\n");

  // Deploy the contract
  const SecureAssetManager = await hre.ethers.getContractFactory("SecureAssetManager");
  
  console.log("⏳ Deployment in progress...");
  const contract = await SecureAssetManager.deploy();
  
  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log("\n✅ CONTRACT DEPLOYED SUCCESSFULLY!\n");
  console.log("========================================");
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Network: ${network} (Chain ID: ${chainId})`);
  console.log(`Deployer: ${deployerAddress}`);
  console.log(`Transaction Hash: ${contract.deploymentTransaction().hash}`);
  console.log("========================================\n");

  // Save deployment information
  const deploymentInfo = {
    network: network,
    chainId: chainId,
    contractAddress: contractAddress,
    deployerAddress: deployerAddress,
    transactionHash: contract.deploymentTransaction().hash,
    timestamp: new Date().toISOString(),
    blockNumber: contract.deploymentTransaction().blockNumber
  };

  // Create deployments directory if it doesn't exist
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  // Save deployment info to file
  const deploymentFile = path.join(deploymentsDir, `${network}-deployment.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  console.log(`📄 Deployment info saved to: ${deploymentFile}\n`);

  // Verify contract details
  console.log("Verifying contract deployment...");
  const name = await contract.name();
  const symbol = await contract.symbol();
  const totalSupply = await contract.totalSupply();
  
  console.log(`✓ Token Name: ${name}`);
  console.log(`✓ Token Symbol: ${symbol}`);
  console.log(`✓ Total Supply: ${hre.ethers.formatEther(totalSupply)} tokens\n`);

  // Check roles
  const ADMIN_ROLE = await contract.ADMIN_ROLE();
  const MINTER_ROLE = await contract.MINTER_ROLE();
  const PAUSER_ROLE = await contract.PAUSER_ROLE();
  
  const hasAdminRole = await contract.hasRole(ADMIN_ROLE, deployerAddress);
  console.log(`✓ Deployer has ADMIN_ROLE: ${hasAdminRole}\n`);

  // Wait for block confirmations on non-local networks
  if (network !== "hardhat" && network !== "localhost") {
    console.log("⏳ Waiting for block confirmations...");
    await contract.deploymentTransaction().wait(3);
    console.log("✅ Transaction confirmed (3 blocks)\n");

    // Attempt to verify on block explorer
    if (process.env[`${network.toUpperCase()}_API_KEY`] || 
        process.env.ETHERSCAN_API_KEY ||
        process.env.POLYGONSCAN_API_KEY) {
      console.log("📝 Attempting to verify contract on block explorer...");
      try {
        await hre.run("verify:verify", {
          address: contractAddress,
          constructorArguments: [],
        });
        console.log("✅ Contract verified on block explorer\n");
      } catch (error) {
        console.log("⚠️  Verification failed (manual verification may be required)");
        console.log(`Error: ${error.message}\n`);
      }
    }
  }

  // Print next steps
  console.log("========================================");
  console.log("  NEXT STEPS");
  console.log("========================================");
  console.log("1. Save the contract address for your records");
  console.log("2. Grant roles to authorized addresses:");
  console.log(`   await contract.grantRole(MINTER_ROLE, minterAddress)`);
  console.log(`   await contract.grantRole(PAUSER_ROLE, pauserAddress)`);
  console.log("3. Test basic functionality:");
  console.log(`   await contract.transfer(recipientAddress, amount)`);
  console.log("4. Set up monitoring and alerting");
  console.log("5. Document the deployment in your records\n");

  // Print interaction commands
  console.log("========================================");
  console.log("  INTERACT WITH CONTRACT");
  console.log("========================================");
  console.log("Using Hardhat console:");
  console.log(`  npx hardhat console --network ${network}`);
  console.log(`  const contract = await ethers.getContractAt("SecureAssetManager", "${contractAddress}")`);
  console.log(`  await contract.balanceOf(yourAddress)`);
  console.log("\nUsing scripts:");
  console.log(`  npx hardhat run scripts/interact.js --network ${network}\n`);

  console.log("========================================\n");
  console.log("✅ DEPLOYMENT COMPLETE!\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ DEPLOYMENT FAILED\n");
    console.error(error);
    process.exit(1);
  });
