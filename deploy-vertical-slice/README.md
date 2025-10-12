# Assignment 3 ERC-20 Token

## Configuration
- RPC URL: https://hh-02.didlab.org
- Chain ID: 31338
- Token Address: 0x71c95911e9a5d330f4d621842ec243ee1343292e
- Run the provided scripts with your '.env' configuration.

## Running Scripts

### Environment must use:
- Node.js: v22.x (even-major LTS).
- Hardhat: v3 (ESM project).
- Client libs: Viem (for wallet/public client).
- Contracts lib: OpenZeppelin v5.
- Do not install: hardhat-gas-reporter (incompatible with HH v3).  
1. Copy `.env.example` to `.env` and fill in your keys.    
2. Run scripts using Hardhat.  
3. Example commands:  
   - `npx hardhat run scripts/deploy.ts --network didlab`  
   - `npx hardhat run scripts/transfer-approve.ts --network didlab`  
   - `npx hardhat run scripts/batch-airdrop.ts --network didlab`  
   - `npx hardhat run scripts/logs-events.ts --network didlab`  

### Deploy
```
Deploying CampusCreditV2…
Deploy tx: 0x583da6bd136f7a3e16a8eb4d2eb0ad69e87444698f0905
b5e75a47b38eb9f37b
Deployed at: 0x71c95911e9a5d330f4d621842ec243ee1343292e
Block: 2n

Add this to .env:
TOKEN_ADDRESS=${rcpt.contractAddress}
```
### Transfer+Approve

```
Before | Me: 1000000 CAMP | You: 1000000 CAMP
transfer tx: 0x79c69bec6c151d3616137b17a7b7392e719b0d7d3f5d
50e82c6b9767da15b91c gasUsed: 29223
approve tx: 0x464f6035ff2f2167236b9632c6ff17f06d18253bdbacd
3cb662e105cfe408899 gasUsed: 46408
allowance: 50 CAMP

After | Me: 1000000 CAMP | You: 1000000 CAMP
```
### Airdrop
```
Airdrop: 0x74de2b054e02c1291d69bc53344528e9299a2e0bfd764ebaff677711310c064 gasUsed: 40783 fee(wei): 95982417294767
Singles total gasUsed: 29211 fee(wei): 67460602866930
Batch saved ≈ -39.62% gas vs singles
```
### Logs-Query
```
[2] RoleGranted {
    role: '0x0000000000000000000000000000000000000000000000000000000000000000',
    account: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    sender: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
}
[2] RoleGranted {
    role: '0x9f2df0ed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceef8d981c8956a6',
    account: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    sender: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
}
[2] RoleGranted {
    role: '0x65d7a28e3265b37a6474929f336521b332c1681b933f6cbf3376673440d862a',
    account: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    sender: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
}
[2] Transfer {
    from: '0x0000000000000000000000000000000000000000',
    to: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    value: 1000000000000000000n
}
[4] Transfer {
    from: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    to: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    value: 1000000000000000000n
}
[5] Approval {
    owner: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    spender: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    value: 500000000000000000n
}
[8] Transfer {
    from: '0x0000000000000000000000000000000000000000',
    to: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    value: 1000000000000000000n
}
[9] Transfer {
    from: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    to: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    value: 1000000000000000000n
}
```
## MetaMask Screenshots

![network config](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/8networkconfig.png)

![MetaMask Transaction](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/6metamasktransaction.png)

![MetaMask Balance](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/9metamaskbalance.png)

![MetaMask Balance 2](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/9metamaskbalance2.png)

![Transaction hash](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/7txhash.png)

# Project Short Write-up

## a. Where you enforced: cap, pause, roles
- **Cap enforcement:**  
  In `CampusCreditV2.sol`, minting is capped using OpenZeppelin’s `ERC20Capped`.  
  The `airdrop()` function calculates the total of all mint amounts and reverts with the
  custom error `CapExceeded` if the new total supply would exceed the cap.
- **Pause enforcement:**  
  The contract inherits `ERC20Pausable`.  
  Functions `pause()` and `unpause()` can only be called by accounts with the
  `PAUSER_ROLE` to halt or resume all token transfers.
- **Role enforcement:**  
  Using `AccessControl`, the contract defines:
  - `DEFAULT_ADMIN_ROLE` for role management,
  - `MINTER_ROLE` required by `mint()` and `airdrop()`,
  - `PAUSER_ROLE` required by `pause()`/`unpause()`.  
  The `onlyRole` modifier ensures that only authorized accounts can call these functions.

## b. Why batch airdrop saved (or didn’t save) gas in your data

- The airdrop.ts script uses `writeContract` in a loop to send tokens to multiple recipients, calling the `airdrop()` function in the CampusCreditV2 contract for each one. 
  It compares this to sending individual transfers, where the same tokens are sent one by one, incurring higher gas costs. 
  By batching the transfers in a single loop, the script saves gas by avoiding repeated transaction costs and signature checks.

<br>

![airdrop.ts output](https://github.com/jsb58p/blockchain-assignment3-biddinger/blob/main/screenshots/3airdrop.ts.png)

<br>

## c. Issues encountered
- No deployment or runtime issues were encountered during testing.
- The scripts (`deploy.ts`, `transfer-approve.ts`, `airdrop.ts`, `logs-query.ts`) executed successfully when correct environment variables were provided with the .env file.
- The `transfer-approve.ts` and `airdrop`  scripts by default send the transfer to their own address, making the balance after the transfer the same as before. 
- In order to send to a recipient address using `transfer-approve.ts`, the RECIPIENT variable must be set with a valid address in the .env file.
- In order to send to recipient address(es) using`airdrop.ts`, the address(es) must be set in the script in the **recipients** array.
---



<br><br><br><br><br>


# Sample Hardhat 3 Beta Project (`node:test` and `viem`)

This project showcases a Hardhat 3 Beta project using the native Node.js test runner (`node:test`) and the `viem` library for Ethereum interactions.

To learn more about the Hardhat 3 Beta, please visit the [Getting Started guide](https://hardhat.org/docs/getting-started#getting-started-with-hardhat-3). To share your feedback, join our [Hardhat 3 Beta](https://hardhat.org/hardhat3-beta-telegram-group) Telegram group or [open an issue](https://github.com/NomicFoundation/hardhat/issues/new) in our GitHub issue tracker.

## Project Overview

This example project includes:

- A simple Hardhat configuration file.
- Foundry-compatible Solidity unit tests.
- TypeScript integration tests using [`node:test`](nodejs.org/api/test.html), the new Node.js native test runner, and [`viem`](https://viem.sh/).
- Examples demonstrating how to connect to different types of networks, including locally simulating OP mainnet.

## Usage

### Running Tests

To run all the tests in the project, execute the following command:

```shell
npx hardhat test
```

You can also selectively run the Solidity or `node:test` tests:

```shell
npx hardhat test solidity
npx hardhat test nodejs
```

### Make a deployment to Sepolia

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
npx hardhat ignition deploy ignition/modules/Counter.ts
```

To run the deployment to Sepolia, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `SEPOLIA_PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `SEPOLIA_PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `SEPOLIA_PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
npx hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```
