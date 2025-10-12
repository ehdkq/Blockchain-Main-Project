import { expect } from "chai";
import { ethers } from "hardhat";
import { Voting } from "../typechain-types";

describe("Voting Contract", function () {
  let voting: Voting;
  let owner: any; // We'll let TypeScript infer the type

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0]; // Assign the first signer to the owner variable

    const VotingFactory = await ethers.getContractFactory("Voting");
    voting = await VotingFactory.deploy();
    await voting.deployed();
  });

  it("Should cast a vote and increment the vote count", async function () {
    await voting.vote(1);
    const voteCount = await voting.getVoteCount(1);
    expect(voteCount).to.equal(1);
  });

  it("Should emit a Voted event when a vote is cast", async function () {
    const proposalId = 1;
    await expect(voting.vote(proposalId))
      .to.emit(voting, "Voted")
      .withArgs(owner.address, proposalId);
  });
});