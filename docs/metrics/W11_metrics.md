# Week 11 Metric (Performance)

**Objective:** Reproducible latency metric across ≥20 JSON-RPC calls.

## How to Re-Run

```bash
# start a local node (Hardhat/Anvil) or use your RPC
export RPC_URL=http://127.0.0.1:8545
export N_CALLS=25
npm run metric:perf
