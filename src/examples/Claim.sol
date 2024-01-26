// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@solady/src/tokens/ERC20.sol";
import "@solady/src/utils/MerkleProofLib.sol";
import "@solady/src/utils/ECDSA.sol";

/**
 * All examples are for demonstration purposes only.
 *     They have not been reviewed for security.
 *     Use at your own risk.
 *
 *     This example is a contract that allows users to claim tokens in 3 different ways:
 *     - Mapping
 *     - Merkle Tree
 *     - Signature
 *
 *     The test (test/examples/Claim.t.sol) shows how to interact with the contract.
 *     The test assumes 100 accounts are whitelisted to claim tokens.
 *
 *     Benchmarks:
 *     | src/Examples/Claim.sol:Claim contract |                 |         |         |         |         |
 *     |---------------------------------------|-----------------|---------|---------|---------|---------|
 *     | Deployment Cost                       | Deployment Size |         |         |         |         |
 *     | 716318                                | 3609            |         |         |         |         |
 *     | Function Name                         | min             | avg     | median  | max     | # calls |
 *     | claimWithMapping                      | 35054           | 35054   | 35054   | 35054   | 1       |
 *     | claimWithRoot                         | 58901           | 58901   | 58901   | 58901   | 1       |
 *     | claimWithSignature                    | 63068           | 63068   | 63068   | 63068   | 1       |
 *     | setClaimMapping                       | 2226450         | 2226450 | 2226450 | 2226450 | 2       |
 *     | setClaimRoot                          | 22358           | 22358   | 22358   | 22358   | 2       |
 *
 *         Observations:
 *         - Setup:
 *             1. Signature is the cheapest, as there is nothing to set in the contract.
 *                The admin signs a message offchain and it is verified onchain.
 *             2. Merkle is the second cheapest as the bytes32 root is set once.
 *             3. Mapping is the most expensive as the admin must set the mapping for each address.
 *         - Claim:
 *             1. Mapping is the cheapest as it's a direct mapping lookup.
 *             2. Merkle is the second cheapest as it requires a merkle proof to be verified.
 *             3. Signature is the most expensive.
 */

/// @title Claim
/// @notice Example contract for 3 different ways to claim tokens
/// @notice Mapping, Merkle Tree, and Signature
/// @author Harrison (@PopPunkOnChain)
contract Claim {
    // token that will be claimed
    address public token;
    // address that can sign messages
    address public signer;
    // root of the merkle tree
    bytes32 public claimRoot;
    // mapping of addresses to amounts
    mapping(address => uint256) public claimMapping;
    // mapping of addresses to whether they have claimed
    mapping(address => bool) public claimed;

    // errors
    error NothingToClaim();
    error AlreadyClaimed();

    /// @notice Construct a new Claim contract
    /// @param _signer address that can sign messages
    /// @param _token address of the token that will be claimed
    constructor(address _signer, address _token) {
        signer = _signer;
        token = _token;
    }

    /// @notice Set the claim mapping
    /// @param _recipients array of addresses that will be able to claim
    /// @param _amounts array of amounts that each recipient will be able to claim
    function setClaimMapping(address[] calldata _recipients, uint256[] calldata _amounts) external {
        for (uint256 i; i < _recipients.length;) {
            claimMapping[_recipients[i]] = _amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set the claim root
    /// @param _claimRoot root of the merkle tree
    function setClaimRoot(bytes32 _claimRoot) external {
        claimRoot = _claimRoot;
    }

    /// @notice Claim tokens using the claim mapping
    function claimWithMapping() external {
        uint256 amount = claimMapping[msg.sender];
        if (amount == 0) revert NothingToClaim();

        claimMapping[msg.sender] = 0;
        ERC20(token).transfer(msg.sender, amount);
    }

    /// @notice Claim tokens using the merkle tree
    /// @param _proof merkle proof of the claim
    /// @param _amount amount of tokens to claim
    function claimWithRoot(bytes32[] calldata _proof, uint256 _amount) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        if (!MerkleProofLib.verify(_proof, claimRoot, leaf)) revert NothingToClaim();

        claimed[msg.sender] = true;
        ERC20(token).transfer(msg.sender, _amount);
    }

    /// @notice Claim tokens using a signature
    /// @param _amount amount of tokens to claim
    /// @param _signature signature of the claim
    function claimWithSignature(uint256 _amount, bytes calldata _signature) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _amount, address(this)));
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(messageHash);
        address recoveredSigner = ECDSA.recoverCalldata(prefixedHash, _signature);

        if (recoveredSigner != signer) revert NothingToClaim();

        claimed[msg.sender] = true;

        ERC20(token).transfer(msg.sender, _amount);
    }
}
