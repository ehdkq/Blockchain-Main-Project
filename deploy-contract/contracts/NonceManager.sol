// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NonceManager
 * @dev Mitigation M3: Nonce-based replay protection
 * @notice Prevents transaction replay attacks using unique nonces
 */
abstract contract NonceManager {
    // Events
    event NonceUsed(address indexed user, uint256 nonce);

    // Storage
    mapping(address => uint256) public nonces;
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // Chain ID for cross-chain replay protection
    uint256 public immutable CHAIN_ID;

    constructor() {
        CHAIN_ID = block.chainid;
    }

    /**
     * @dev Returns the current nonce for an address
     */
    function getNonce(address user) public view returns (uint256) {
        return nonces[user];
    }

    /**
     * @dev Checks if a nonce has been used
     */
    function isNonceUsed(address user, uint256 nonce) public view returns (bool) {
        return usedNonces[user][nonce];
    }

    /**
     * @dev Validates and consumes a nonce
     * @notice Reverts if nonce is invalid or already used
     */
    function _useNonce(address user) internal returns (uint256 current) {
        current = nonces[user];
        nonces[user] = current + 1;
        usedNonces[user][current] = true;
        emit NonceUsed(user, current);
    }

    /**
     * @dev Validates a specific nonce without consuming it
     * @notice Used for off-chain signed messages
     */
    function _validateNonce(address user, uint256 nonce) internal view {
        require(nonce == nonces[user], "NonceManager: invalid nonce");
        require(!usedNonces[user][nonce], "NonceManager: nonce already used");
    }

    /**
     * @dev Consumes a specific nonce
     * @notice Used after validating signed messages
     */
    function _consumeNonce(address user, uint256 nonce) internal {
        require(nonce == nonces[user], "NonceManager: invalid nonce");
        require(!usedNonces[user][nonce], "NonceManager: nonce already used");
        
        nonces[user] = nonce + 1;
        usedNonces[user][nonce] = true;
        emit NonceUsed(user, nonce);
    }

    /**
     * @dev Returns the domain separator for EIP-712
     * @notice Includes chain ID to prevent cross-chain replays
     */
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SecureAssetManager")),
                keccak256(bytes("1")),
                CHAIN_ID,
                address(this)
            )
        );
    }

    /**
     * @dev Recovers signer from a signed message
     * @param nonce The nonce used in the signature
     * @param data The data that was signed
     * @param signature The signature (r, s, v)
     */
    function _recoverSigner(
        uint256 nonce,
        bytes memory data,
        bytes memory signature
    ) internal view returns (address) {
        require(signature.length == 65, "NonceManager: invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator(),
                keccak256(abi.encode(
                    keccak256("Transaction(uint256 nonce,uint256 chainId,bytes data)"),
                    nonce,
                    CHAIN_ID,
                    keccak256(data)
                ))
            )
        );

        return ecrecover(digest, v, r, s);
    }

    /**
     * @dev Verifies a signed transaction
     * @notice Checks signature and nonce validity
     */
    function _verifySignedTransaction(
        address user,
        uint256 nonce,
        bytes memory data,
        bytes memory signature
    ) internal view {
        _validateNonce(user, nonce);
        address signer = _recoverSigner(nonce, data, signature);
        require(signer == user, "NonceManager: invalid signature");
    }
}
