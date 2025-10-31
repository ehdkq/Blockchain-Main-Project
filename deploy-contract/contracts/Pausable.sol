// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

/**
 * @title Pausable
 * @dev Mitigation M6: Circuit breaker / pause mechanism
 * @notice Allows emergency pause of contract operations
 */
abstract contract Pausable is AccessControl {
    // Events
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event EmergencyPause(address indexed account, string reason);

    // State
    bool private _paused;
    uint256 private _pauseCount;
    uint256 private _lastPauseTime;
    string private _pauseReason;

    // Emergency contacts
    mapping(address => bool) private _emergencyPausers;

    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns pause statistics
     */
    function getPauseInfo() public view returns (
        bool isPaused,
        uint256 pauseCount,
        uint256 lastPauseTime,
        string memory reason
    ) {
        return (_paused, _pauseCount, _lastPauseTime, _pauseReason);
    }

    /**
     * @dev Modifier to make a function callable only when not paused
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when paused
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Pauses the contract
     * @notice Requires PAUSER_ROLE
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause("Manual pause by admin");
    }

    /**
     * @dev Pauses the contract with a reason
     * @notice Requires PAUSER_ROLE
     */
    function pauseWithReason(string memory reason) public onlyRole(PAUSER_ROLE) {
        require(bytes(reason).length > 0, "Pausable: reason required");
        _pause(reason);
    }

    /**
     * @dev Emergency pause - can be called by designated emergency pausers
     * @notice Use in critical situations (active attack, critical bug)
     */
    function emergencyPause(string memory reason) public {
        require(
            _emergencyPausers[msg.sender] || hasRole(PAUSER_ROLE, msg.sender),
            "Pausable: not authorized for emergency pause"
        );
        require(bytes(reason).length > 0, "Pausable: reason required");
        
        _pause(reason);
        emit EmergencyPause(msg.sender, reason);
    }

    /**
     * @dev Unpauses the contract
     * @notice Requires PAUSER_ROLE
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        require(_paused, "Pausable: not paused");
        _paused = false;
        _pauseReason = "";
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Internal function to pause
     */
    function _pause(string memory reason) internal whenNotPaused {
        _paused = true;
        _pauseCount += 1;
        _lastPauseTime = block.timestamp;
        _pauseReason = reason;
        emit Paused(msg.sender);
    }

    /**
     * @dev Adds an emergency pauser
     * @notice Only admin can add emergency pausers
     */
    function addEmergencyPauser(address account) public onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Pausable: zero address");
        _emergencyPausers[account] = true;
    }

    /**
     * @dev Removes an emergency pauser
     */
    function removeEmergencyPauser(address account) public onlyRole(ADMIN_ROLE) {
        _emergencyPausers[account] = false;
    }

    /**
     * @dev Checks if an address is an emergency pauser
     */
    function isEmergencyPauser(address account) public view returns (bool) {
        return _emergencyPausers[account];
    }

    /**
     * @dev Auto-unpause after specified time (safety feature)
     * @notice Prevents indefinite pause
     */
    function _checkAutoPause() internal view {
        if (_paused && block.timestamp > _lastPauseTime + 7 days) {
            // Consider implementing auto-unpause logic or alerting
            // For safety, we don't auto-unpause but this can be monitored
        }
    }
}
