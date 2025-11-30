# Changelog

All notable changes to the "Blockchain-Main-Project" will be documented in this file.

## [1.0.0-MVP] - 2025-11-29

### Added
- **Smart Contracts**:
    - `AgriSensorData.sol`: Core contract for storing IoT sensor data on-chain.
    - `SupplyChain.sol`: Basic logic for supply chain tracking.
- **Analytics Dashboard**:
    - `analytics/index.html`: Real-time frontend to visualize contract events.
    - `analytics/dashboard.js`: Logic to fetch events from the blockchain.
- **Scripts**:
    - `scripts/deploy.js`: automated deployment to Localhost and DIDLab networks.
    - `scripts/seed.js`: Script to populate the contract with dummy data for testing.
- **Documentation**:
    - `RUNBOOK.md`: Comprehensive guide for installation and verification.

### Fixed
- Resolved network configuration issues for `didlab` (Chain ID 252501).
- Fixed Hardhat Toolbox dependency and import errors in deployment scripts.
- Removed deprecated `.t.sol` Foundry test files to ensure smooth Hardhat compilation.

### Security
- Implemented `.env` for managing private keys and RPC URLs (removed hardcoded secrets).