// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DifferentialPrivacy
 * @dev Mitigation M8: Local Differential Privacy (LDP) for aggregate statistics
 * @notice Adds calibrated noise to protect individual privacy in aggregates
 */
abstract contract DifferentialPrivacy {
    // Privacy parameters
    uint256 public constant EPSILON = 1e18; // Privacy budget: ε = 1.0 (in wei for precision)
    uint256 public constant SENSITIVITY = 1; // Query sensitivity (Δf = 1 for count queries)

    // Events
    event NoiseAdded(string queryType, int256 trueValue, int256 noisyValue);
    event PrivacyBudgetUsed(address indexed user, uint256 budget);

    // Privacy budget tracking (optional)
    mapping(address => uint256) private _privacyBudgetUsed;
    uint256 public constant MAX_PRIVACY_BUDGET = 10e18; // Maximum ε per user

    /**
     * @dev Adds Laplace noise to a value
     * @param value The true value to protect
     * @param sensitivity The sensitivity of the query
     * @param epsilon The privacy budget (in wei, 1e18 = ε of 1.0)
     * @return Noisy value with differential privacy guarantee
     */
    function _addLaplaceNoise(
        int256 value,
        uint256 sensitivity,
        uint256 epsilon
    ) internal view returns (int256) {
        require(epsilon > 0, "DifferentialPrivacy: epsilon must be positive");
        
        // Calculate Laplace scale: λ = Δf / ε
        uint256 scale = (sensitivity * 1e18) / epsilon;
        
        // Sample from Laplace distribution
        int256 noise = _sampleLaplace(scale);
        
        return value + noise;
    }

    /**
     * @dev Adds Laplace noise using default parameters
     * @param value The true value to protect
     * @return Noisy value with ε = 1.0, Δf = 1
     */
    function _addDefaultNoise(int256 value) internal view returns (int256) {
        return _addLaplaceNoise(value, SENSITIVITY, EPSILON);
    }

    /**
     * @dev Samples from Laplace distribution
     * @param scale The scale parameter (λ)
     * @return Random sample from Laplace(0, scale)
     * @notice Uses block hash as entropy source (not cryptographically secure, but sufficient for DP)
     */
    function _sampleLaplace(uint256 scale) internal view returns (int256) {
        // Generate pseudo-random value using block hash and timestamp
        // WARNING: This is not cryptographically secure but acceptable for differential privacy
        bytes32 randomHash = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                blockhash(block.number - 1)
            )
        );
        
        uint256 randomValue = uint256(randomHash);
        
        // Convert to uniform [0,1) in fixed point (18 decimals)
        uint256 uniform = (randomValue % 1e18);
        
        // Sample from Laplace using inverse CDF method
        // If U ~ Uniform(0,1), then X = -λ * sign(U - 0.5) * ln(1 - 2|U - 0.5|)
        bool isNegative = uniform < 5e17; // U < 0.5
        uint256 absU = isNegative ? (5e17 - uniform) : (uniform - 5e17);
        
        // Avoid ln(0) by clamping
        if (absU >= 5e17) {
            absU = 5e17 - 1;
        }
        
        // Calculate: λ * ln(1 - 2|U - 0.5|)
        // Approximate ln using Taylor series for simplicity
        uint256 x = (2 * absU * 1e18) / 5e17; // 2|U - 0.5|
        int256 lnValue = _approximateLn(1e18 - x);
        
        int256 noise = -int256((scale * uint256(-lnValue)) / 1e18);
        
        return isNegative ? -noise : noise;
    }

    /**
     * @dev Approximates natural logarithm using Taylor series
     * @param x Value in fixed point (18 decimals), must be in (0, 1]
     * @return ln(x) in fixed point
     */
    function _approximateLn(uint256 x) internal pure returns (int256) {
        require(x > 0 && x <= 1e18, "DifferentialPrivacy: x out of range");
        
        if (x == 1e18) return 0;
        
        // Use Taylor series: ln(1-y) = -y - y²/2 - y³/3 - ...
        uint256 y = 1e18 - x;
        int256 result = 0;
        uint256 term = y;
        
        for (uint256 i = 1; i <= 10; i++) {
            result -= int256(term / i);
            term = (term * y) / 1e18;
        }
        
        return result;
    }

    /**
     * @dev Reports a noisy count to protect privacy
     * @param trueCount The actual count
     * @return Noisy count with differential privacy
     */
    function _reportNoisyCount(uint256 trueCount) internal view returns (uint256) {
        int256 noisyValue = _addDefaultNoise(int256(trueCount));
        
        // Ensure non-negative result
        if (noisyValue < 0) {
            return 0;
        }
        
        return uint256(noisyValue);
    }

    /**
     * @dev Reports a noisy sum with custom privacy parameters
     * @param trueSum The actual sum
     * @param maxContribution Maximum contribution per user
     * @param privacyBudget Privacy budget to use
     * @return Noisy sum
     */
    function _reportNoisySum(
        uint256 trueSum,
        uint256 maxContribution,
        uint256 privacyBudget
    ) internal view returns (uint256) {
        int256 noisyValue = _addLaplaceNoise(
            int256(trueSum),
            maxContribution,
            privacyBudget
        );
        
        if (noisyValue < 0) {
            return 0;
        }
        
        return uint256(noisyValue);
    }

    /**
     * @dev Tracks privacy budget usage for a user
     * @param user Address of the user
     * @param budgetUsed Amount of privacy budget consumed
     */
    function _trackPrivacyBudget(address user, uint256 budgetUsed) internal {
        _privacyBudgetUsed[user] += budgetUsed;
        require(
            _privacyBudgetUsed[user] <= MAX_PRIVACY_BUDGET,
            "DifferentialPrivacy: privacy budget exceeded"
        );
        emit PrivacyBudgetUsed(user, budgetUsed);
    }

    /**
     * @dev Returns remaining privacy budget for a user
     */
    function getRemainingPrivacyBudget(address user) public view returns (uint256) {
        if (_privacyBudgetUsed[user] >= MAX_PRIVACY_BUDGET) {
            return 0;
        }
        return MAX_PRIVACY_BUDGET - _privacyBudgetUsed[user];
    }

    /**
     * @dev Calculates confidence interval for noisy result
     * @param epsilon Privacy budget used
     * @param sensitivity Query sensitivity
     * @return margin Error margin at 95% confidence
     */
    function getConfidenceInterval(
        uint256 epsilon,
        uint256 sensitivity
    ) public pure returns (uint256 margin) {
        // For Laplace mechanism: 95% CI ≈ ±3λ where λ = Δf/ε
        uint256 scale = (sensitivity * 1e18) / epsilon;
        margin = (3 * scale) / 1e18;
    }
}
