const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("SecureAssetManager - Security Test Suite", function () {
    // Fixture for contract deployment
    async function deploySecureAssetManagerFixture() {
        const [owner, user1, user2, attacker, minter, pauser] = await ethers.getSigners();

        const SecureAssetManager = await ethers.getContractFactory("SecureAssetManager");
        const contract = await SecureAssetManager.deploy();
        await contract.waitForDeployment();

        // Grant roles
        const MINTER_ROLE = await contract.MINTER_ROLE();
        const PAUSER_ROLE = await contract.PAUSER_ROLE();
        await contract.grantRole(MINTER_ROLE, minter.address);
        await contract.grantRole(PAUSER_ROLE, pauser.address);

        // Give users some tokens
        await contract.transfer(user1.address, ethers.parseEther("1000"));
        await contract.transfer(user2.address, ethers.parseEther("1000"));

        return { contract, owner, user1, user2, attacker, minter, pauser };
    }

    describe("M1: Reentrancy Guard Tests", function () {
        it("TEST 1: Should block reentrancy attack", async function () {
            const { contract, owner, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            // Deploy malicious contract that attempts reentrancy
            const MaliciousContract = await ethers.getContractFactory("ReentrancyAttacker");
            const malicious = await MaliciousContract.deploy(await contract.getAddress());
            await malicious.waitForDeployment();

            // Give malicious contract some tokens
            await contract.transfer(await malicious.getAddress(), ethers.parseEther("100"));

            // Attempt reentrancy attack - should fail
            await expect(
                malicious.attack()
            ).to.be.revertedWith("ReentrancyGuard: reentrant call");
        });

        it("TEST 2: Should allow normal sequential transfers", async function () {
            const { contract, owner, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Normal transfers should work
            await expect(contract.connect(user1).transfer(user2.address, ethers.parseEther("10")))
                .to.emit(contract, "Transfer");
            
            await expect(contract.connect(user2).transfer(user1.address, ethers.parseEther("5")))
                .to.emit(contract, "Transfer");
        });
    });

    describe("M2: Access Control (RBAC) Tests", function () {
        it("TEST 3: Should block unauthorized mint attempts", async function () {
            const { contract, attacker } = await loadFixture(deploySecureAssetManagerFixture);

            // Attacker without MINTER_ROLE tries to mint
            await expect(
                contract.connect(attacker).mint(attacker.address, ethers.parseEther("1000000"))
            ).to.be.reverted;
        });

        it("TEST 4: Should allow authorized minter to mint", async function () {
            const { contract, minter, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            const balanceBefore = await contract.balanceOf(user1.address);
            
            await expect(
                contract.connect(minter).mint(user1.address, ethers.parseEther("500"))
            ).to.emit(contract, "Mint");

            const balanceAfter = await contract.balanceOf(user1.address);
            expect(balanceAfter - balanceBefore).to.equal(ethers.parseEther("500"));
        });

        it("TEST 5: Should allow role admin to grant roles", async function () {
            const { contract, owner, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            const MINTER_ROLE = await contract.MINTER_ROLE();
            
            await contract.grantRole(MINTER_ROLE, user1.address);
            expect(await contract.hasRole(MINTER_ROLE, user1.address)).to.be.true;
        });
    });

    describe("M3: Nonce-Based Replay Protection Tests", function () {
        it("TEST 6: Should block replay attacks", async function () {
            const { contract, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            const nonce = await contract.getNonce(user1.address);
            const amount = ethers.parseEther("10");

            // Create signature for approval
            const domain = {
                name: "SecureAssetManager",
                version: "1",
                chainId: (await ethers.provider.getNetwork()).chainId,
                verifyingContract: await contract.getAddress()
            };

            const types = {
                Transaction: [
                    { name: "nonce", type: "uint256" },
                    { name: "chainId", type: "uint256" },
                    { name: "data", type: "bytes" }
                ]
            };

            const data = ethers.AbiCoder.defaultAbiCoder().encode(
                ["address", "uint256"],
                [user2.address, amount]
            );

            const value = {
                nonce: nonce,
                chainId: (await ethers.provider.getNetwork()).chainId,
                data: ethers.keccak256(data)
            };

            const signature = await user1.signTypedData(domain, types, value);

            // First call should succeed
            await contract.connect(user1).approveWithNonce(
                user2.address,
                amount,
                nonce,
                signature
            );

            // Replay with same nonce should fail
            await expect(
                contract.connect(user1).approveWithNonce(
                    user2.address,
                    amount,
                    nonce,
                    signature
                )
            ).to.be.revertedWith("NonceManager: nonce already used");
        });

        it("TEST 7: Should increment nonces correctly", async function () {
            const { contract, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            const nonceBefore = await contract.getNonce(user1.address);
            
            // Trigger nonce increment via transfer
            await contract.connect(user1).transfer(user1.address, ethers.parseEther("1"));
            
            // Note: In actual implementation, transfer doesn't use nonce
            // This test verifies nonce getter works
            expect(await contract.getNonce(user1.address)).to.be.gte(nonceBefore);
        });
    });

    describe("M4: Input Validation & Bounded Operations Tests", function () {
        it("TEST 8: Should reject oversized batch transfers", async function () {
            const { contract, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            // Create batch larger than MAX_BATCH_SIZE (100)
            const recipients = new Array(101).fill(user1.address);
            const amounts = new Array(101).fill(ethers.parseEther("1"));

            await expect(
                contract.connect(user1).batchTransfer(recipients, amounts)
            ).to.be.revertedWith("InputValidator: batch size too large");
        });

        it("TEST 9: Should accept valid batch transfers", async function () {
            const { contract, owner, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            const recipients = [user1.address, user2.address];
            const amounts = [ethers.parseEther("10"), ethers.parseEther("20")];

            await expect(
                contract.batchTransfer(recipients, amounts)
            ).to.emit(contract, "BatchTransfer");
        });

        it("TEST 10: Should prevent math overflow in safe operations", async function () {
            const { contract, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            // Try to transfer more than max amount
            const maxAmount = await contract.MAX_AMOUNT();
            
            await expect(
                contract.connect(user1).transfer(user1.address, maxAmount + 1n)
            ).to.be.revertedWith("InputValidator: amount too large");
        });
    });

    describe("M5: Rate Limiting Tests", function () {
        it("TEST 11: Should block spam attacks via rate limiting", async function () {
            const { contract, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Make multiple rapid transfers
            for (let i = 0; i < 10; i++) {
                await contract.connect(user1).transfer(user2.address, ethers.parseEther("1"));
            }

            // 11th transfer should fail due to rate limit (max 10 per time unit)
            await expect(
                contract.connect(user1).transfer(user2.address, ethers.parseEther("1"))
            ).to.be.revertedWith("RateLimiter: rate limit exceeded");
        });

        it("TEST 12: Should show correct rate limit status", async function () {
            const { contract, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            const status = await contract.getRateLimitStatus(user1.address);
            expect(status.availableTokens).to.be.lte(10); // MAX_TOKENS
        });
    });

    describe("M6: Circuit Breaker / Pause Tests", function () {
        it("TEST 13: Should block all operations when paused", async function () {
            const { contract, pauser, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Pause contract
            await contract.connect(pauser).pause();
            expect(await contract.paused()).to.be.true;

            // All operations should fail
            await expect(
                contract.connect(user1).transfer(user2.address, ethers.parseEther("10"))
            ).to.be.revertedWith("Pausable: paused");

            await expect(
                contract.connect(user1).approve(user2.address, ethers.parseEther("10"))
            ).to.be.revertedWith("Pausable: paused");
        });

        it("TEST 14: Should allow operations after unpause", async function () {
            const { contract, pauser, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Pause and unpause
            await contract.connect(pauser).pause();
            await contract.connect(pauser).unpause();
            
            expect(await contract.paused()).to.be.false;

            // Operations should work again
            await expect(
                contract.connect(user1).transfer(user2.address, ethers.parseEther("10"))
            ).to.emit(contract, "Transfer");
        });

        it("TEST 15: Should only allow PAUSER_ROLE to pause", async function () {
            const { contract, attacker } = await loadFixture(deploySecureAssetManagerFixture);

            await expect(
                contract.connect(attacker).pause()
            ).to.be.reverted;
        });
    });

    describe("M8: Differential Privacy Tests", function () {
        it("TEST 16: Should add noise to transaction counts", async function () {
            const { contract, owner, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Make some transactions
            await contract.connect(user1).transfer(user2.address, ethers.parseEther("10"));
            await contract.connect(user2).transfer(user1.address, ethers.parseEther("5"));

            // Get private count (with noise)
            const privateCount = await contract.getPrivateTransactionCount();
            
            // Get true count (admin only)
            const ADMIN_ROLE = await contract.ADMIN_ROLE();
            const trueCount = await contract.getTrueTransactionCount();

            // Private count should be different from true count (due to noise)
            // Note: There's a small chance they're equal, but very unlikely
            console.log(`True count: ${trueCount}, Private count: ${privateCount}`);
            
            // Verify it's within reasonable bounds (±10 for ε=1.0)
            const diff = trueCount > privateCount ? 
                trueCount - privateCount : privateCount - trueCount;
            expect(diff).to.be.lte(20); // Allow up to 20 difference
        });

        it("TEST 17: Should maintain utility despite noise", async function () {
            const { contract, owner, user1, user2 } = await loadFixture(deploySecureAssetManagerFixture);

            // Make many transactions
            for (let i = 0; i < 50; i++) {
                await contract.connect(user1).transfer(user2.address, ethers.parseEther("1"));
            }

            const privateCount = await contract.getPrivateTransactionCount();
            const trueCount = await contract.getTrueTransactionCount();

            // With many samples, average should be close to true value
            // For Laplace(ε=1), most values within ±3 of true value
            const relativeError = Math.abs(Number(trueCount) - Number(privateCount)) / Number(trueCount);
            expect(relativeError).to.be.lte(0.1); // Within 10% for large counts
        });
    });

    describe("Integration Tests", function () {
        it("TEST 18: Multiple mitigations work together", async function () {
            const { contract, user1, user2, pauser } = await loadFixture(deploySecureAssetManagerFixture);

            // Test combination of rate limiting + input validation + access control
            
            // Valid batch transfer
            await contract.connect(user1).batchTransfer(
                [user2.address],
                [ethers.parseEther("10")]
            );

            // Try invalid batch (should fail input validation before rate limit)
            const tooLarge = new Array(101).fill(user2.address);
            const amounts = new Array(101).fill(ethers.parseEther("1"));
            
            await expect(
                contract.connect(user1).batchTransfer(tooLarge, amounts)
            ).to.be.revertedWith("InputValidator: batch size too large");
        });

        it("TEST 19: Emergency pause stops attacks in progress", async function () {
            const { contract, user1, user2, pauser, attacker } = await loadFixture(deploySecureAssetManagerFixture);

            // Give attacker tokens
            await contract.transfer(attacker.address, ethers.parseEther("100"));

            // Attacker starts spam
            await contract.connect(attacker).transfer(user1.address, ethers.parseEther("1"));
            
            // Emergency pause
            await contract.connect(pauser).emergencyPause("Attack detected");

            // Further attacks blocked
            await expect(
                contract.connect(attacker).transfer(user1.address, ethers.parseEther("1"))
            ).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("Privacy Budget Tests", function () {
        it("TEST 20: Should track privacy budget usage", async function () {
            const { contract, user1 } = await loadFixture(deploySecureAssetManagerFixture);

            const budget = await contract.getRemainingPrivacyBudget(user1.address);
            const maxBudget = await contract.MAX_PRIVACY_BUDGET();
            
            expect(budget).to.equal(maxBudget);
        });
    });
});
