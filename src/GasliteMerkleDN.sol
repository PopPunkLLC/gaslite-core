pragma solidity 0.8.20;

// forgefmt: disable-start
/**
 *                                                           bbbbbbbb                                         dddddddd
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                            b:::::b                                         d:::::d
 *    ggggggggg   ggggg aaaaaaaaaaaaa      ssssssssss         b:::::bbbbbbbbb      aaaaaaaaaaaaa      ddddddddd:::::d
 *   g:::::::::ggg::::g a::::::::::::a   ss::::::::::s        b::::::::::::::bb    a::::::::::::a   dd::::::::::::::d
 *  g:::::::::::::::::g aaaaaaaaa:::::ass:::::::::::::s       b::::::::::::::::b   aaaaaaaaa:::::a d::::::::::::::::d
 * g::::::ggggg::::::gg          a::::as::::::ssss:::::s      b:::::bbbbb:::::::b           a::::ad:::::::ddddd:::::d
 * g:::::g     g:::::g    aaaaaaa:::::a s:::::s  ssssss       b:::::b    b::::::b    aaaaaaa:::::ad::::::d    d:::::d
 * g:::::g     g:::::g  aa::::::::::::a   s::::::s            b:::::b     b:::::b  aa::::::::::::ad:::::d     d:::::d
 * g:::::g     g:::::g a::::aaaa::::::a      s::::::s         b:::::b     b:::::b a::::aaaa::::::ad:::::d     d:::::d
 * g::::::g    g:::::ga::::a    a:::::assssss   s:::::s       b:::::b     b:::::ba::::a    a:::::ad:::::d     d:::::d
 * g:::::::ggggg:::::ga::::a    a:::::as:::::ssss::::::s      b:::::bbbbbb::::::ba::::a    a:::::ad::::::ddddd::::::dd
 *  g::::::::::::::::ga:::::aaaa::::::as::::::::::::::s       b::::::::::::::::b a:::::aaaa::::::a d:::::::::::::::::d
 *   gg::::::::::::::g a::::::::::aa:::as:::::::::::ss        b:::::::::::::::b   a::::::::::aa:::a d:::::::::ddd::::d
 *     gggggggg::::::g  aaaaaaaaaa  aaaa sssssssssss          bbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaa  ddddddddd   ddddd
 *             g:::::g
 * gggggg      g:::::g
 * g:::::gg   gg:::::g
 *  g::::::ggg:::::::g
 *   gg:::::::::::::g
 *     ggg::::::ggg
 *        gggggg
 */
// forgefmt: disable-end
import "@solady/src/auth/Ownable.sol";
import "@solady/src/utils/MerkleProofLib.sol";

/// @title GasliteMerkleDN
/// @notice Turbo gas optimized native token merkle drop contract
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
contract GasliteMerkleDN is Ownable {
    bytes32 public root;
    bool public active = false;

    mapping(address => bool) public claimed;

    error NothingToClaim();
    error NotActive();
    error InsufficientBalance();
    error TransferFailed();

    /// @param _root The merkle root of the distribution
    constructor(bytes32 _root) {
        _initializeOwner(msg.sender);
        root = _root;
    }

    /// @notice Claim your native tokens
    /// @param _proof The merkle proof
    /// @param _amount The amount of native tokens to claim
    function claim(bytes32[] calldata _proof, uint256 _amount) external payable {
        if (address(this).balance < _amount) revert InsufficientBalance();
        if (!active) revert NotActive();
        if (claimed[msg.sender]) revert NothingToClaim();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        if (!MerkleProofLib.verifyCalldata(_proof, root, leaf)) revert NothingToClaim();

        claimed[msg.sender] = true;
        (bool success,) = msg.sender.call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Update the merkle root
    /// @param _root The new merkle root
    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /// @notice Toggle the active state
    function toggleActive() external onlyOwner {
        active = !active;
    }

    /// @notice Withdraw any remaining tokens
    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    receive() external payable {}
}
