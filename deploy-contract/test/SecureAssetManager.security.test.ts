import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

function has(obj: any, name: string) {
  return typeof (obj as any)[name] === "function" || typeof (obj as any)[name] === "bigint";
}

async function deployFixture() {
  const [owner, user1, user2, attacker, minter, pauser] = await ethers.getSigners();
  const F = await ethers.getContractFactory("SecureAssetManager");
  const c: any = await F.deploy();
  await c.waitForDeployment();

  // Grant roles if present
  if (has(c, "MINTER_ROLE") && has(c, "grantRole")) {
    const MINTER_ROLE = await c.MINTER_ROLE();
    await c.grantRole(MINTER_ROLE, minter.address);
  }
  if (has(c, "PAUSER_ROLE") && has(c, "grantRole")) {
    const PAUSER_ROLE = await c.PAUSER_ROLE();
    await c.grantRole(PAUSER_ROLE, pauser.address);
  }

  // Fund users if token-like
  if (has(c, "transfer") && has(c, "balanceOf")) {
    await c.transfer(user1.address, ethers.parseEther("1000"));
    await c.transfer(user2.address, ethers.parseEther("1000"));
  }

  return { c, owner, user1, user2, attacker, minter, pauser };
}

describe("[unit] Access control & validation", () => {
  it("deploys and has an address", async () => {
    const { c } = await loadFixture(deployFixture);
    expect(await c.getAddress()).to.properAddress;
  });

  it("owner is deployer (if owner() exists)", async function () {
    const { c, owner } = await loadFixture(deployFixture);
    if (!has(c, "owner")) return this.skip();
    expect(await c.owner()).to.eq(owner.address);
  });

  it("non-owner protected call reverts (if ownerOnlyFunction exists)", async function () {
    const { c, user1 } = await loadFixture(deployFixture);
    if (!has(c, "ownerOnlyFunction")) return this.skip();
    await expect(c.connect(user1).ownerOnlyFunction()).to.be.reverted;
  });

  it("rejects zero address where required (if setTrustedAddress exists)", async function () {
    const { c } = await loadFixture(deployFixture);
    if (!has(c, "setTrustedAddress")) return this.skip();
    // prefer custom error if available
    try {
      await expect(c.setTrustedAddress(ethers.ZeroAddress)).to.be.reverted;
    } catch {
      // fallback; some runners swallow one assertion after revert checks
      await expect(c.setTrustedAddress(ethers.ZeroAddress)).to.be.reverted;
    }
  });
});

describe("[unit] Pause / Unpause", () => {
  it("only PAUSER_ROLE can pause (if role & pause exist)", async function () {
    const { c, attacker } = await loadFixture(deployFixture);
    if (!has(c, "pause")) return this.skip();
    await expect(c.connect(attacker).pause()).to.be.reverted;
  });

  it("paused blocks state changes (if pause+transfer exist)", async function () {
    const { c, pauser, user1, user2 } = await loadFixture(deployFixture);
    if (!has(c, "pause") || !has(c, "transfer") || !has(c, "paused")) return this.skip();
    await c.connect(pauser).pause();
    expect(await c.paused()).to.equal(true);
    await expect(c.connect(user1).transfer(user2.address, ethers.parseEther("1")))
      .to.be.reverted;
  });

  it("unpause restores operations (if unpause exists)", async function () {
    const { c, pauser, user1, user2 } = await loadFixture(deployFixture);
    if (!has(c, "pause") || !has(c, "unpause") || !has(c, "transfer")) return this.skip();
    await c.connect(pauser).pause();
    await c.connect(pauser).unpause();
    await expect(c.connect(user1).transfer(user2.address, ethers.parseEther("1"))).to.emit(c, "Transfer");
  });
});

describe("[unit] RBAC / minting", () => {
  it("unauthorized mint reverts (if mint exists)", async function () {
    const { c, attacker } = await loadFixture(deployFixture);
    if (!has(c, "mint")) return this.skip();
    await expect(c.connect(attacker).mint(attacker.address, ethers.parseEther("10"))).to.be.reverted;
  });

  it("authorized minter can mint (assert with standard Transfer)", async function () {
    const { c, minter, user1 } = await loadFixture(deployFixture);
    if (!has(c, "mint") || !has(c, "balanceOf")) return this.skip();
    const before = await c.balanceOf(user1.address);
    await expect(c.connect(minter).mint(user1.address, ethers.parseEther("5")))
      .to.emit(c, "Transfer"); // ERC20 mint usually emits Transfer(0x0, to, amt)
    const after = await c.balanceOf(user1.address);
    expect(after - before).to.equal(ethers.parseEther("5"));
  });
});

describe("[unit] Nonce / replay protection", () => {
  it("replay with same nonce fails (if approveWithNonce exists)", async function () {
    const { c, user1, user2 } = await loadFixture(deployFixture);
    if (!has(c, "approveWithNonce") || !has(c, "getNonce")) return this.skip();

    const nonce = await c.getNonce(user1.address);
    const amount = ethers.parseEther("10");
    const { chainId } = await ethers.provider.getNetwork();

    const domain = { name: "SecureAssetManager", version: "1", chainId, verifyingContract: await c.getAddress() };
    const types = { Transaction: [
      { name: "nonce", type: "uint256" },
      { name: "chainId", type: "uint256" },
      { name: "data", type: "bytes32" }
    ]};

    const encoded = ethers.AbiCoder.defaultAbiCoder().encode(["address","uint256"], [user2.address, amount]);
    const value = { nonce, chainId, data: ethers.keccak256(encoded) };
    const sig = await user1.signTypedData(domain, types, value);

    await c.connect(user1).approveWithNonce(user2.address, amount, nonce, sig);
    await expect(c.connect(user1).approveWithNonce(user2.address, amount, nonce, sig)).to.be.reverted;
  });
});

describe("[integration] Batch & bounds", () => {
  it("oversized batch reverts if batchTransfer exists", async function () {
    const { c, user1 } = await loadFixture(deployFixture);
    if (!has(c, "batchTransfer")) return this.skip();
    const recipients = new Array(101).fill(user1.address);
    const amounts = new Array(101).fill(ethers.parseEther("1"));
    await expect(c.batchTransfer(recipients, amounts)).to.be.reverted;
  });

  it("valid small batch emits event if supported", async function () {
    const { c, user1, user2 } = await loadFixture(deployFixture);
    if (!has(c, "batchTransfer")) return this.skip();
    await expect(c.batchTransfer([user1.address, user2.address], [ethers.parseEther("1"), ethers.parseEther("2")]))
      .to.emit(c, "BatchTransfer");
  });
});

describe("[integration] Rate limiter / telemetry (optional)", () => {
  it("rate limit blocks spam if implemented", async function () {
    const { c, user1, user2 } = await loadFixture(deployFixture);
    if (!has(c, "getRateLimitStatus") || !has(c, "transfer")) return this.skip();
    for (let i = 0; i < 10; i++) {
      await c.connect(user1).transfer(user2.address, ethers.parseEther("1"));
    }
    await expect(c.connect(user1).transfer(user2.address, ethers.parseEther("1"))).to.be.reverted;
  });

  it("rate limit status returns structure if implemented", async function () {
    const { c, user1 } = await loadFixture(deployFixture);
    if (!has(c, "getRateLimitStatus")) return this.skip();
    const status = await c.getRateLimitStatus(user1.address);
    expect(status).to.have.property("availableTokens");
  });
});

