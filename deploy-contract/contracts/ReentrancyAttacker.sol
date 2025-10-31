// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISecureAssetManager {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title ReentrancyAttacker
 * @dev Malicious contract to test reentrancy guard
 * @notice This contract attempts to exploit reentrancy vulnerability
 */
contract ReentrancyAttacker {
    ISecureAssetManager public target;
    address public owner;
    uint256 public attackCount;
    uint256 public constant MAX_ATTACKS = 5;

    event AttackAttempt(uint256 count);

    constructor(address _target) {
        target = ISecureAssetManager(_target);
        owner = msg.sender;
    }

    /**
     * @dev Initiates the reentrancy attack
     */
    function attack() external {
        require(msg.sender == owner, "Only owner can attack");
        
        uint256 balance = target.balanceOf(address(this));
        require(balance > 0, "No balance to attack with");

        attackCount = 0;
        // Start the attack by transferring to ourselves
        // This will trigger the receive function
        target.transfer(address(this), balance);
    }

    /**
     * @dev Receive function that attempts reentrancy
     * @notice This will be called when contract receives tokens
     * It tries to call transfer again before first call completes
     */
    receive() external payable {
        attackCount++;
        emit AttackAttempt(attackCount);

        if (attackCount < MAX_ATTACKS) {
            uint256 balance = target.balanceOf(address(this));
            if (balance > 0) {
                // Try to reenter - this should fail with reentrancy guard
                target.transfer(owner, balance);
            }
        }
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        revert("Fallback not supported");
    }
}
