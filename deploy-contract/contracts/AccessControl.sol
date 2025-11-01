// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AccessControl
 * @dev Mitigation M2: Role-Based Access Control (RBAC)
 * @notice Manages roles and permissions for contract functions
 */
abstract contract AccessControl {
    // Role definitions
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Events
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    // Storage
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    /**
     * @dev Modifier that checks if caller has the specified role
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    constructor() {
        // Grant default admin role to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        // Set up role hierarchy
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Returns true if account has been granted role
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls role
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants role to account
     * @notice Caller must have the role's admin role
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes role from account
     * @notice Caller must have the role's admin role
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Renounces role from caller
     * @notice Useful for accidentally granted roles
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    /**
     * @dev Internal function to check role
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        _toHexString(uint160(account), 20),
                        " is missing role ",
                        _toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Internal function to grant role
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Internal function to revoke role
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /**
     * @dev Internal function to set role admin
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Converts uint to hex string
     */
    function _toHexString(uint256 value, uint256 length) private pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Hex length insufficient");
        return string(buffer);
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
}
