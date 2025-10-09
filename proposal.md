1.	Title and One-Line Value Proposition

 “Blockchain-Backed IoT Data Verification System for Smart Farming”
Value Proposition: an immutable and verifiable record for agricultural sensor data, ensuring transparency and trust in environmental monitoring using blockchain technology.

2.	Problem and Stakeholders (2–4 sentences)
 Who hurts today? What’s broken? Who benefits if you solve it (end-users, operators, auditors, regulators)?

Current agricultural systems may lack a trustworthy yet simple mechanism for ensuring the integrity of environmental data. Some of these data points may be temperature, humidity, and PH levels. Without a tamper-proof log of this data, it can be altered or lost, which can hurt farmers who need that valuable information for operations of even audits of their yearly profits or net gain. It benefits farmers by providing a reliable data record, which will benefit consumers by increasing the transparency between farmers and the consumer, which in turn increases trust in the food supply chain.

3.	Research Alignment (1–2 sentences)
 Name which theme you’re extending:
a.	IoT + blockchain (signed telemetry, gateway verification, on-chain attestations)

We will be extending IoT devices with the blockchain into farmers and their data they need, such as data logging.

4.	Platform and Rationale (pick one)

a.	Ethereum (Hardhat local, optional testnet) (public EVM, event-driven UI, wallets, ERC-standards).
 Briefly justify why your choice fits your problem (privacy, policy, ecosystem, tooling).

Etherum is well-suited for our project due to the smart contract capabilities with Solidity and the ecosystem of dev tools like Hardhat, Web3.js, and MetaMask. For the system focused on a transparent, immutable public log of data, Ethereum’s architecture fits the problem and project perfectly. If we use Hardhat or a local testing environment, it can allow for low cost development and testing as well.

5.	MVP Features (must-have) + Stretch
 List 2–4 MVP features you will demo by Week 10, and 1–2 Stretch targets if time allows.

Simulated IoT Data Generation: A python or node.js script that generates fake sensor data (temperature, humidity, or pH) and it’ll simulate IoT devices

On-Chain Data Hashing: A backend service hashes the sensor data using SHA-256 and stores the resulting hash along with metadata (such as timestamps) on the Ethereum blockchain.

Basic Data Logging Smart Contract: A Solidity smart contract to receive and log data hashes from authorized sources

Blockchain Interaction: A script using either web3.js or ethers.js to interact with the deployed smart contract on local or testnet blockchains.

Stretch targets:
Role-based access control: enhance the smart contract to include RBAC, which ensures only registered farmers can write data and manipulate it.

Data Visualization Dashboard: A basic web app for data visualization, using either React or Flask.

6.	Architecture Sketch (diagram)
 Show smart contracts/chaincode, backend/gateway, UI, data sources (and where identity/VCs sit). Label which events/transactions flow on-chain.
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/55c78ea3-774f-4f2e-adbf-c94d17ed88cc" />

 
8.	Security and Privacy Requirements
 One paragraph on how you’ll protect data and operations (e.g., VC-gated write APIs, endorsement policy, private data collections, input validation, rate limiting, DP noise in analytics).

The primary goal is to ensure the data integrity. We can achieve this by hashing the sensor data before committing it to the blockchain, since it’s immutable. Doing this can create a tamper-proof audit trail. To protect operations, the system will implement access control within the smart contract. One of our stretch goals includes role based access where only authorized farmers and manipulate and change the data. All the data written to the chain will be hashes of the original data, not the raw data itself, which provides an additional layer of privacy.

8.	Milestones (Weeks 6–14)
 Use week labels and concrete deliverables (e.g., “W7: vertical slice UI→contract state change”, “W10: threat model + 3 mitigations implemented”, “W12: LLM-assisted audit or analytics dashboard”).
•	W6: Env up; skeleton contract/chaincode; first unit test; vertical slice planned.
•	W7: Vertical slice demo (UI/CLI → contract → state change/event).
•	W8: Feature 1 complete (Data simulation and hashing) + events consumed by client.
•	W9: Feature 2 complete (On-chain data logging via smart contract) + basic authZ (owner-only write access).
•	W10: Threat model; 3 mitigations implemented (e.g., input validation in contract, access control modifiers).
•	W11: ≥10 tests for the smart contract; metrics captured (e.g., transaction latency).
•	W12: LLM assist (audit/test) or analytics dashboard for visualizing data.
•	W13: Freeze & polish; doc pass (README/runbook).
•	W14: Dry-run poster/pitch; fix feedback.

9.	Team and Roles + Logistics
 PM/Scrum • Contract/Chaincode • Backend/API • Frontend/UX • DevOps/Test.
 Weekly standup time + comms channel. Repo URL.
Emily: PM/Scrum & Frontend/UX
Jacob: Contract/chaincode
Jason: Backend/API
Madeline: DevOps/Test
Weekly Standup Time/Comms Channel: The weekend prior to due date on Discord
Github: https://github.com/ehdkq/Blockchain-Main-Project.git

10.	Top Risks (3) and Mitigations
 Example: “Data realism → use synthetic generator and public seed dataset; Policy complexity → start with allow-list; Chaincode bugs → unit tests + event assertions.”

Risk 1: Smart Contract Vulnerabilities → Mitigation: A bug in the Solidity code could allow unauthorized data logging or fail under certain conditions. We will mitigate this by implementing a comprehensive test suite using Hardhat to cover all contract functions and by using static analysis tools to check for common security vulnerabilities.

Risk 2: Unrealistic Data Simulation → Mitigation: The simulated sensor data may not accurately reflect real-world agricultural conditions, which could limit the demo's impact. We will research public agricultural data sets to inform our synthetic data generator, ensuring the values and patterns are as realistic as possible for the MVP.

Risk 3: Blockchain Scalability and Cost → Mitigation: Logging every sensor reading individually to a public blockchain would be slow and expensive. For this project, we will use a local Hardhat testnet to eliminate cost and latency concerns. A potential stretch goal is to explore batching techniques, where a single Merkle root is committed on-chain to represent many readings, drastically reducing transaction volume.
 
What you must have by end of Week 5
•	PROPOSAL.md committed, public repo initialized, project board with ≥6 stories, roles set, and timeboxed weekly updates scheduled (Week 6–14).

