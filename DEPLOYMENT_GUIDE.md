# 🚀 DEPLOYMENT GUIDE - DID Lab & Testnets

## Overview

This guide covers deploying the SecureAssetManager contract to **DID Lab**, testnets, and mainnet networks.

---

## 🎯 Quick Start - Deploy to DID Lab

### Step 1: Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit .env with your details
nano .env
```

**Required Configuration for DID Lab:**
```env
# Your private key (from MetaMask or wallet)
PRIVATE_KEY=your_private_key_without_0x

# DID Lab network details (get from your lab administrator)
DIDLAB_RPC_URL=http://didlab-node.example.com:8545
DIDLAB_CHAIN_ID=9999
```

### Step 2: Deploy to DID Lab

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Deploy to DID Lab
npm run deploy:didlab
```

### Step 3: Verify Deployment

```bash
# Interact with deployed contract
npm run interact:didlab
```

**Expected Output:**
```
✅ CONTRACT DEPLOYED SUCCESSFULLY!
========================================
Contract Address: 0x1234...5678
Network: didlab (Chain ID: 9999)
Deployer: 0xabcd...efgh
Transaction Hash: 0x9876...5432
========================================
```

---

## 🌐 Supported Networks

### 1. **DID Lab** (Primary Target)
```bash
npm run deploy:didlab
```
- **Use Case**: Distributed Identity Lab environment
- **Configuration**: Custom RPC and Chain ID
- **Setup**: Contact lab admin for network details

### 2. **Ethereum Sepolia Testnet**
```bash
npm run deploy:sepolia
```
- **Use Case**: Ethereum testnet
- **Faucet**: https://sepoliafaucet.com/
- **Explorer**: https://sepolia.etherscan.io/

### 3. **Polygon Mumbai Testnet**
```bash
npm run deploy:mumbai
```
- **Use Case**: Polygon (low-cost) testnet
- **Faucet**: https://faucet.polygon.technology/
- **Explorer**: https://mumbai.polygonscan.com/

### 4. **Avalanche Fuji Testnet**
```bash
npm run deploy:fuji
```
- **Use Case**: Avalanche testnet
- **Faucet**: https://faucet.avax.network/
- **Explorer**: https://testnet.snowtrace.io/

### 5. **BNB Smart Chain Testnet**
```bash
npm run deploy:bscTestnet
```
- **Use Case**: BSC testnet
- **Faucet**: https://testnet.bnbchain.org/faucet-smart
- **Explorer**: https://testnet.bscscan.com/

### 6. **Arbitrum Sepolia**
```bash
npm run deploy:arbitrumSepolia
```
- **Use Case**: Layer 2 (Arbitrum) testnet
- **Faucet**: Use Sepolia ETH + bridge
- **Explorer**: https://sepolia.arbiscan.io/

### 7. **Base Sepolia**
```bash
npm run deploy:baseSepolia
```
- **Use Case**: Base (Coinbase) testnet
- **Faucet**: Use Sepolia ETH + bridge
- **Explorer**: https://sepolia.basescan.org/

### 8. **Hyperledger Besu**
```bash
npm run deploy:besu
```
- **Use Case**: Enterprise blockchain
- **Setup**: Local Besu node required

---

## 📋 Pre-Deployment Checklist

### Essential Steps

- [ ] **Get Private Key**
  - Export from MetaMask: Account Details → Export Private Key
  - **NEVER share or commit this key!**

- [ ] **Fund Your Account**
  - Get testnet tokens from faucets (links above)
  - For DID Lab: Contact lab admin
  - Minimum: ~0.1 ETH equivalent for deployment

- [ ] **Configure Network**
  - Edit `.env` file with correct RPC URL
  - Set chain ID if custom network
  - Test connection: `npx hardhat console --network didlab`

- [ ] **Compile Contracts**
  - Run: `npm run compile`
  - Verify: No compilation errors
  - Check: `artifacts/` directory created

- [ ] **Run Tests Locally**
  - Run: `npm test`
  - Verify: All 20 tests pass
  - Ensures code works before deployment

---

## 🔧 Detailed Deployment Steps

### Method 1: Automated Deployment Script (Recommended)

```bash
# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env with your PRIVATE_KEY and network details

# 3. Compile contracts
npm run compile

# 4. Deploy to target network
npm run deploy:didlab

# Expected output:
# ✅ Contract deployed at: 0x...
# 📄 Deployment info saved to: deployments/didlab-deployment.json
```

### Method 2: Interactive Hardhat Console

```bash
# Start console on target network
npx hardhat console --network didlab

# In console:
const SecureAssetManager = await ethers.getContractFactory("SecureAssetManager");
const contract = await SecureAssetManager.deploy();
await contract.waitForDeployment();
const address = await contract.getAddress();
console.log("Deployed to:", address);
```

### Method 3: Custom Deployment Script

```javascript
// scripts/custom-deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", await deployer.getAddress());

  const SecureAssetManager = await hre.ethers.getContractFactory("SecureAssetManager");
  const contract = await SecureAssetManager.deploy();
  await contract.waitForDeployment();

  console.log("Contract address:", await contract.getAddress());
}

main().catch(console.error);
```

Run with: `npx hardhat run scripts/custom-deploy.js --network didlab`

---

## 🔐 Security Best Practices

### Private Key Management

**❌ DON'T:**
- Commit `.env` file to git
- Share private keys
- Use mainnet keys on testnet
- Store keys in code

**✅ DO:**
- Use `.env` for local development
- Use hardware wallets for mainnet
- Use different keys for test/prod
- Add `.env` to `.gitignore`

### Deployment Safety

**Before Deployment:**
1. ✅ Run all tests: `npm test`
2. ✅ Audit code: Review all contracts
3. ✅ Check gas costs: `REPORT_GAS=true npm test`
4. ✅ Deploy to testnet first
5. ✅ Test on testnet thoroughly

**After Deployment:**
1. ✅ Verify contract on explorer
2. ✅ Test basic functions
3. ✅ Grant roles to authorized addresses
4. ✅ Document contract address
5. ✅ Set up monitoring

---

## 📊 Post-Deployment Setup

### 1. Verify Deployment

```bash
# Use interaction script
npm run interact:didlab

# Check contract info
# - Name, symbol, total supply
# - Your roles (admin, minter, pauser)
# - Rate limit status
# - Privacy statistics
```

### 2. Grant Roles

```bash
# Start console
npx hardhat console --network didlab

# Get contract
const address = "0x..."; // Your deployed address
const contract = await ethers.getContractAt("SecureAssetManager", address);

# Grant roles
const MINTER_ROLE = await contract.MINTER_ROLE();
const PAUSER_ROLE = await contract.PAUSER_ROLE();

await contract.grantRole(MINTER_ROLE, "0xMinterAddress");
await contract.grantRole(PAUSER_ROLE, "0xPauserAddress");

# Verify
console.log(await contract.hasRole(MINTER_ROLE, "0xMinterAddress"));
```

### 3. Test Basic Operations

```bash
# Transfer tokens
await contract.transfer("0xRecipient", ethers.parseEther("100"));

# Check balance
await contract.balanceOf("0xRecipient");

# Mint (if you have MINTER_ROLE)
await contract.mint("0xRecipient", ethers.parseEther("1000"));
```

### 4. Verify Contract on Block Explorer

```bash
# For supported networks (Sepolia, Mumbai, etc.)
npm run verify:sepolia -- 0xContractAddress

# Manual verification:
# 1. Go to block explorer
# 2. Find your contract
# 3. Click "Verify and Publish"
# 4. Select Solidity 0.8.20
# 5. Paste contract code
```

---

## 🧪 Testing Before Production

### Test Suite on Deployed Contract

Create `scripts/test-deployed.js`:

```javascript
const hre = require("hardhat");

async function main() {
  const address = "0xYourDeployedAddress";
  const contract = await hre.ethers.getContractAt("SecureAssetManager", address);
  
  console.log("Testing deployed contract...");
  
  // Test 1: Check basic info
  const name = await contract.name();
  console.log(`✓ Name: ${name}`);
  
  // Test 2: Check pause functionality
  const paused = await contract.paused();
  console.log(`✓ Paused: ${paused}`);
  
  // Test 3: Check rate limiting
  const [signer] = await hre.ethers.getSigners();
  const status = await contract.getRateLimitStatus(await signer.getAddress());
  console.log(`✓ Rate limit tokens: ${status.availableTokens}`);
  
  console.log("\n✅ All checks passed!");
}

main().catch(console.error);
```

Run: `npx hardhat run scripts/test-deployed.js --network didlab`

---

## 📁 Deployment Records

### Deployment Info File

After each deployment, a JSON file is created in `deployments/`:

```json
{
  "network": "didlab",
  "chainId": 9999,
  "contractAddress": "0x1234567890abcdef...",
  "deployerAddress": "0xabcdef1234567890...",
  "transactionHash": "0x9876543210fedcba...",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "blockNumber": 12345
}
```

**Use this to:**
- Track all deployments
- Reference contract addresses
- Audit deployment history
- Set up monitoring

---

## 🚨 Troubleshooting

### Common Issues

#### Issue: "Insufficient funds for gas"
```
Error: sender doesn't have enough funds to send tx
```
**Solution:** Fund your account with native tokens (ETH, AVAX, BNB, etc.)

#### Issue: "Nonce too high"
```
Error: nonce has already been used
```
**Solution:** 
```bash
# Reset account in MetaMask: Settings → Advanced → Reset Account
# Or specify nonce manually in deployment script
```

#### Issue: "Network not found"
```
Error: HH100: Network didlab doesn't exist
```
**Solution:** Check `hardhat.config.js` - ensure network is configured

#### Issue: "Cannot connect to RPC"
```
Error: could not detect network
```
**Solution:** 
- Check RPC URL in `.env`
- Verify network is running
- Test with: `curl -X POST $DIDLAB_RPC_URL -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`

#### Issue: "Private key invalid"
```
Error: invalid hexlified string
```
**Solution:** 
- Remove `0x` prefix from private key in `.env`
- Ensure no spaces or special characters
- Re-export from wallet if needed

---

## 📖 Additional Resources

### Network Documentation
- **DID Lab**: Contact your lab administrator
- **Ethereum**: https://ethereum.org/en/developers/docs/
- **Polygon**: https://wiki.polygon.technology/
- **Avalanche**: https://docs.avax.network/
- **Hardhat**: https://hardhat.org/docs

### Tools
- **Remix IDE**: https://remix.ethereum.org/ (browser-based testing)
- **Tenderly**: https://tenderly.co/ (transaction simulation)
- **OpenZeppelin Defender**: https://defender.openzeppelin.com/ (monitoring)

### Security Auditing
- **Slither**: Static analysis tool
- **Mythril**: Security analysis
- **Echidna**: Fuzzing tool

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] All tests pass locally (`npm test`)
- [ ] Contracts compile without errors
- [ ] `.env` configured with private key and RPC
- [ ] Account funded with gas tokens
- [ ] Code reviewed and audited

### Deployment
- [ ] Deploy to testnet first
- [ ] Verify deployment transaction
- [ ] Save contract address
- [ ] Document in `deployments/` folder

### Post-Deployment
- [ ] Verify contract on block explorer
- [ ] Test basic functions
- [ ] Grant necessary roles
- [ ] Set up monitoring/alerts
- [ ] Update documentation

### Production
- [ ] Full security audit completed
- [ ] Testnet testing completed
- [ ] Emergency procedures documented
- [ ] Team trained on operations
- [ ] Monitoring dashboard set up

---

## 🎯 Quick Reference

### Deployment Commands

```bash
# DID Lab (Primary)
npm run deploy:didlab

# Testnets
npm run deploy:sepolia
npm run deploy:mumbai
npm run deploy:fuji
npm run deploy:bscTestnet

# Interaction
npm run interact:didlab
npm run interact:sepolia

# Console
npm run console:didlab
```

### Essential Hardhat Commands

```bash
# Compile
npx hardhat compile

# Test
npx hardhat test

# Deploy
npx hardhat run scripts/deploy.js --network didlab

# Console
npx hardhat console --network didlab

# Verify
npx hardhat verify --network sepolia 0xContractAddress
```

---

## 📞 Support

**Need Help?**
- Check Hardhat docs: https://hardhat.org/docs
- Review error logs in terminal
- Test on local network first: `npm run node` → `npm run deploy:local`
- Contact DID Lab administrator for network-specific issues

---

**✅ You're ready to deploy to DID Lab and other networks!**

Follow this guide step-by-step for successful deployment.
