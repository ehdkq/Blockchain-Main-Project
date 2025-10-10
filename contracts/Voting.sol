// contracts/Voting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A simple contract for on-chain voting
 */
contract Voting {
    // A mapping to store the vote count for each proposal ID.
    // The 'public' keyword automatically creates a getter function.
    mapping(uint256 => uint256) public proposalVotes;

    // An event that is emitted when a vote is successfully cast.
    // This allows client applications to listen for on-chain activity.
    event Voted(address voter, uint256 proposalId);

    /**
     * @dev Casts a vote for a given proposal ID.
     * It increments the vote count for the proposal and emits a Voted event.
     */
    function vote(uint256 _proposalId) public {
        proposalVotes[_proposalId]++;
        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @dev Retrieves the current vote count for a specific proposal.
     * This function is included for clarity, though the public mapping
     * already provides a getter.
     * @param _proposalId The ID of the proposal to check.
     * @return The total number of votes for the given proposal.
     */
    function getVoteCount(uint256 _proposalId) public view returns (uint256) {
        return proposalVotes[_proposalId];
    }
}