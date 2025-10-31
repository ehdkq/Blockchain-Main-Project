// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RateLimiter
 * @dev Mitigation M5: Rate limiting using token bucket algorithm
 * @notice Prevents DoS attacks via transaction spam
 */
abstract contract RateLimiter {
    // Rate limit configuration
    uint256 public constant MAX_TOKENS = 10; // Max transactions in bucket
    uint256 public constant REFILL_RATE = 1; // Tokens per time unit
    uint256 public constant TIME_UNIT = 1 minutes;

    // Events
    event RateLimitExceeded(address indexed user, uint256 timestamp);
    event RateLimitReset(address indexed user);

    // Storage
    struct RateLimit {
        uint256 tokens;
        uint256 lastRefill;
        uint256 totalRequests;
    }

    mapping(address => RateLimit) private _rateLimits;

    // Global rate limit for contract
    uint256 private _globalTokens = 1000;
    uint256 private _globalLastRefill;
    uint256 public constant GLOBAL_MAX_TOKENS = 1000;
    uint256 public constant GLOBAL_REFILL_RATE = 10;

    constructor() {
        _globalLastRefill = block.timestamp;
    }

    /**
     * @dev Modifier to enforce rate limiting
     */
    modifier rateLimited() {
        _checkRateLimit(msg.sender);
        _;
    }

    /**
     * @dev Modifier to enforce global rate limiting
     */
    modifier globalRateLimited() {
        _checkGlobalRateLimit();
        _;
    }

    /**
     * @dev Checks and updates rate limit for a user
     */
    function _checkRateLimit(address user) internal {
        RateLimit storage limit = _rateLimits[user];

        // Initialize if first request
        if (limit.lastRefill == 0) {
            limit.tokens = MAX_TOKENS;
            limit.lastRefill = block.timestamp;
        }

        // Calculate tokens to add based on elapsed time
        uint256 elapsed = block.timestamp - limit.lastRefill;
        uint256 tokensToAdd = (elapsed / TIME_UNIT) * REFILL_RATE;

        if (tokensToAdd > 0) {
            limit.tokens = _min(limit.tokens + tokensToAdd, MAX_TOKENS);
            limit.lastRefill = block.timestamp;
        }

        // Check if user has tokens available
        if (limit.tokens < 1) {
            emit RateLimitExceeded(user, block.timestamp);
            revert("RateLimiter: rate limit exceeded");
        }

        // Consume a token
        limit.tokens -= 1;
        limit.totalRequests += 1;
    }

    /**
     * @dev Checks and updates global rate limit
     */
    function _checkGlobalRateLimit() internal {
        uint256 elapsed = block.timestamp - _globalLastRefill;
        uint256 tokensToAdd = (elapsed / TIME_UNIT) * GLOBAL_REFILL_RATE;

        if (tokensToAdd > 0) {
            _globalTokens = _min(_globalTokens + tokensToAdd, GLOBAL_MAX_TOKENS);
            _globalLastRefill = block.timestamp;
        }

        require(_globalTokens >= 1, "RateLimiter: global rate limit exceeded");
        _globalTokens -= 1;
    }

    /**
     * @dev Returns the current rate limit status for a user
     */
    function getRateLimitStatus(address user) public view returns (
        uint256 availableTokens,
        uint256 totalRequests,
        uint256 nextRefillTime
    ) {
        RateLimit storage limit = _rateLimits[user];

        if (limit.lastRefill == 0) {
            return (MAX_TOKENS, 0, block.timestamp);
        }

        uint256 elapsed = block.timestamp - limit.lastRefill;
        uint256 tokensToAdd = (elapsed / TIME_UNIT) * REFILL_RATE;
        availableTokens = _min(limit.tokens + tokensToAdd, MAX_TOKENS);
        totalRequests = limit.totalRequests;

        // Calculate next refill time
        uint256 tokensUntilFull = MAX_TOKENS - limit.tokens;
        uint256 timeToFull = (tokensUntilFull * TIME_UNIT) / REFILL_RATE;
        nextRefillTime = limit.lastRefill + timeToFull;
    }

    /**
     * @dev Returns global rate limit status
     */
    function getGlobalRateLimitStatus() public view returns (
        uint256 availableTokens,
        uint256 nextRefillTime
    ) {
        uint256 elapsed = block.timestamp - _globalLastRefill;
        uint256 tokensToAdd = (elapsed / TIME_UNIT) * GLOBAL_REFILL_RATE;
        availableTokens = _min(_globalTokens + tokensToAdd, GLOBAL_MAX_TOKENS);

        uint256 tokensUntilFull = GLOBAL_MAX_TOKENS - _globalTokens;
        uint256 timeToFull = (tokensUntilFull * TIME_UNIT) / GLOBAL_REFILL_RATE;
        nextRefillTime = _globalLastRefill + timeToFull;
    }

    /**
     * @dev Admin function to reset user rate limit (emergency use)
     */
    function _resetRateLimit(address user) internal {
        RateLimit storage limit = _rateLimits[user];
        limit.tokens = MAX_TOKENS;
        limit.lastRefill = block.timestamp;
        emit RateLimitReset(user);
    }

    /**
     * @dev Returns minimum of two values
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Checks if user would be rate limited (view function)
     */
    function wouldBeRateLimited(address user) public view returns (bool) {
        RateLimit storage limit = _rateLimits[user];

        if (limit.lastRefill == 0) {
            return false; // First request is never limited
        }

        uint256 elapsed = block.timestamp - limit.lastRefill;
        uint256 tokensToAdd = (elapsed / TIME_UNIT) * REFILL_RATE;
        uint256 availableTokens = _min(limit.tokens + tokensToAdd, MAX_TOKENS);

        return availableTokens < 1;
    }
}
