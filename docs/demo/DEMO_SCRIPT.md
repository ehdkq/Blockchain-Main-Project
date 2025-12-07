# DEMO SCRIPT — Blockchain-Backed IoT Data Verification for Smart Farming

**Repo:** https://github.com/ehdkq/Blockchain-Main-Project  
**Duration:** 5 minutes (short clip: 2–3 minutes focusing on core flow)  
**Presenter:** Ledgers 
**Target environment:** peer laptop with Node.js, Git, MetaMask

---

## 0. Demo Goals (what we must show)

1. **Value prop + MVP**
   - Farmers & auditors can **verify IoT sensor data on-chain** instead of trusting spreadsheets.
   - MVP: a smart contract deployed to a test network + simple dashboard/CLI to:
     - Create/register an asset/batch or farm record.
     - Verify on-chain state and security controls.

2. **One metric (performance/privacy)**
   - Show **rate limit / privacy stats / gas metrics** from Hardhat scripts or contract calls.  
   - Example: `getRateLimitStatus` / privacy statistics and/or gas usage for key operations. 

3. **One live security mitigation**
   - Show **role-based access control + pause** or similar:
     - Only an admin/authorized role can pause the contract.
     - While paused, transfers/updates are blocked.

4. **Feedback → issues**
   - After peer/TA feedback, create GitHub Issues for final polish tasks and reference them in the repo.

---

## 1. Pre-demo Setup Checklist (done before you start the 5-minute talk)

**On the demo machine:**

- Prereqs (from RUNBOOK): 
  - Node.js v18+  
  - Git  
  - MetaMask installed and set up

- Clone & install:

  ```bash
  git clone https://github.com/ehdkq/Blockchain-Main-Project.git
  cd Blockchain-Main-Project

  # Install root deps (if used) or per package:
  npm install             # if root package.json exists
  # or:
  cd deploy-contract && npm install
  cd ../didlab-dapp && npm install

