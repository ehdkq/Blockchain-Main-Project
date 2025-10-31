// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InputValidator
 * @dev Mitigation M4: Input validation and bounded operations
 * @notice Prevents DoS attacks via gas exhaustion and overflow
 */
abstract contract InputValidator {
    // Constants for bounds
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant MIN_BATCH_SIZE = 1;
    uint256 public constant MAX_AMOUNT = 1e12 * 1e18; // 1 trillion tokens with 18 decimals
    uint256 public constant MIN_AMOUNT = 1;
    uint256 public constant MAX_STRING_LENGTH = 256;

    // Events
    event ValidationFailed(string reason, uint256 value);

    /**
     * @dev Validates batch size is within bounds
     */
    modifier validBatchSize(uint256 size) {
        require(size >= MIN_BATCH_SIZE, "InputValidator: batch size too small");
        require(size <= MAX_BATCH_SIZE, "InputValidator: batch size too large");
        _;
    }

    /**
     * @dev Validates amount is within bounds
     */
    modifier validAmount(uint256 amount) {
        require(amount >= MIN_AMOUNT, "InputValidator: amount too small");
        require(amount <= MAX_AMOUNT, "InputValidator: amount too large");
        _;
    }

    /**
     * @dev Validates address is not zero
     */
    modifier validAddress(address addr) {
        require(addr != address(0), "InputValidator: zero address");
        _;
    }

    /**
     * @dev Validates string length
     */
    modifier validStringLength(string memory str) {
        require(bytes(str).length <= MAX_STRING_LENGTH, "InputValidator: string too long");
        _;
    }

    /**
     * @dev Validates array has no zero addresses
     */
    function _validateAddressArray(address[] memory addresses) internal pure {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "InputValidator: zero address in array");
        }
    }

    /**
     * @dev Validates amounts array matches addresses array length
     */
    function _validateArrayLengthsMatch(
        address[] memory addresses,
        uint256[] memory amounts
    ) internal pure {
        require(
            addresses.length == amounts.length,
            "InputValidator: array length mismatch"
        );
    }

    /**
     * @dev Validates total amount doesn't overflow
     */
    function _validateTotalAmount(uint256[] memory amounts) internal pure returns (uint256 total) {
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] <= MAX_AMOUNT, "InputValidator: amount too large");
            total += amounts[i];
            require(total >= amounts[i], "InputValidator: total overflow");
        }
        require(total <= MAX_AMOUNT, "InputValidator: total too large");
    }

    /**
     * @dev Safe addition with overflow check
     */
    function _safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "InputValidator: addition overflow");
        return c;
    }

    /**
     * @dev Safe subtraction with underflow check
     */
    function _safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "InputValidator: subtraction underflow");
        return a - b;
    }

    /**
     * @dev Safe multiplication with overflow check
     */
    function _safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "InputValidator: multiplication overflow");
        return c;
    }

    /**
     * @dev Safe division with zero check
     */
    function _safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "InputValidator: division by zero");
        return a / b;
    }

    /**
     * @dev Validates percentage is within 0-100 range
     */
    function _validatePercentage(uint256 percentage) internal pure {
        require(percentage <= 100, "InputValidator: percentage > 100");
    }

    /**
     * @dev Validates timestamp is not in the past
     */
    function _validateFutureTimestamp(uint256 timestamp) internal view {
        require(timestamp > block.timestamp, "InputValidator: timestamp in past");
    }

    /**
     * @dev Validates timestamp is not too far in the future (max 1 year)
     */
    function _validateReasonableTimestamp(uint256 timestamp) internal view {
        require(
            timestamp <= block.timestamp + 365 days,
            "InputValidator: timestamp too far in future"
        );
    }
}
