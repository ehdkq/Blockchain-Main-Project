// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./NonceManager.sol";
import "./InputValidator.sol";
import "./RateLimiter.sol";
import "./Pausable.sol";
import "./DifferentialPrivacy.sol";

/**
 * @title SecureAssetManager
 * @dev Main contract demonstrating all 8 security mitigations
 * @notice Manages digital assets with comprehensive security controls
 */
contract SecureAssetManager is
    ReentrancyGuard,
    AccessControl,
    NonceManager,
    InputValidator,
    RateLimiter,
    Pausable,
    DifferentialPrivacy
{
    // Token state
    string public name = "SecureAsset";
    string public symbol = "SASSET";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Statistics (with privacy protection)
    uint256 private _totalTransactions;
    uint256 private _totalUsers;
    mapping(address => bool) private _hasTransacted;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event BatchTransfer(address indexed from, uint256 recipientCount, uint256 totalAmount);

    constructor() {
        // Initial supply to deployer
        _mint(msg.sender, 1000000 * 10**decimals);
    }

    /**
     * @dev Returns total supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns balance of an account
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns allowance
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Standard transfer with ALL security mitigations
     * Mitigations applied: M1, M2, M4, M5, M6
     */
    function transfer(address to, uint256 amount)
        public
        nonReentrant           // M1: Reentrancy Guard
        whenNotPaused          // M6: Circuit Breaker
        rateLimited            // M5: Rate Limiting
        validAddress(to)       // M4: Input Validation
        validAmount(amount)    // M4: Input Validation
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfer from with security controls
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        nonReentrant
        whenNotPaused
        rateLimited
        validAddress(to)
        validAmount(amount)
        returns (bool)
    {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Batch transfer with bounded operations
     * Demonstrates M4: Input Validation with batch size limits
     */
    function batchTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    )
        public
        nonReentrant
        whenNotPaused
        rateLimited
        validBatchSize(recipients.length)
        returns (bool)
    {
        _validateAddressArray(recipients);
        _validateArrayLengthsMatch(recipients, amounts);
        uint256 totalAmount = _validateTotalAmount(amounts);

        require(_balances[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }

        emit BatchTransfer(msg.sender, recipients.length, totalAmount);
        return true;
    }

    /**
     * @dev Approve spender with nonce protection
     * Demonstrates M3: Replay Protection
     */
    function approveWithNonce(
        address spender,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    )
        public
        whenNotPaused
        validAddress(spender)
        validAmount(amount)
        returns (bool)
    {
        // M3: Verify signature and consume nonce
        _verifySignedTransaction(
            msg.sender,
            nonce,
            abi.encode(spender, amount),
            signature
        );
        _consumeNonce(msg.sender, nonce);

        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Standard approve
     */
    function approve(address spender, uint256 amount)
        public
        whenNotPaused
        validAddress(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Mint tokens - requires MINTER_ROLE
     * Demonstrates M2: Role-Based Access Control
     */
    function mint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)  // M2: RBAC
        whenNotPaused
        validAddress(to)
        validAmount(amount)
    {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens
     */
    function burn(uint256 amount)
        public
        whenNotPaused
        validAmount(amount)
    {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Get transaction count with differential privacy
     * Demonstrates M8: Local Differential Privacy
     */
    function getPrivateTransactionCount() public view returns (uint256) {
        // M8: Add Laplace noise for privacy
        return _reportNoisyCount(_totalTransactions);
    }

    /**
     * @dev Get user count with differential privacy
     */
    function getPrivateUserCount() public view returns (uint256) {
        return _reportNoisyCount(_totalUsers);
    }

    /**
     * @dev Get true transaction count (admin only)
     */
    function getTrueTransactionCount()
        public
        view
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        return _totalTransactions;
    }

    /**
     * @dev Emergency withdrawal (only when paused)
     * Demonstrates controlled emergency functions
     */
    function emergencyWithdraw(address to, uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
        whenPaused
        validAddress(to)
    {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount);
    }

    // Internal functions

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] = _safeSub(_balances[from], amount);
        _balances[to] = _safeAdd(_balances[to], amount);

        // Update statistics
        if (!_hasTransacted[from]) {
            _hasTransacted[from] = true;
            _totalUsers++;
        }
        if (!_hasTransacted[to]) {
            _hasTransacted[to] = true;
            _totalUsers++;
        }
        _totalTransactions++;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to zero address");
        
        _totalSupply = _safeAdd(_totalSupply, amount);
        _balances[account] = _safeAdd(_balances[account], amount);

        emit Transfer(address(0), account, amount);
        emit Mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from zero address");
        require(_balances[account] >= amount, "Burn amount exceeds balance");

        _balances[account] = _safeSub(_balances[account], amount);
        _totalSupply = _safeSub(_totalSupply, amount);

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _approve(owner, spender, _safeSub(currentAllowance, amount));
    }

    /**
     * @dev Receive function to accept ETH (if needed)
     */
    receive() external payable {
        revert("Direct ETH transfers not accepted");
    }
}
