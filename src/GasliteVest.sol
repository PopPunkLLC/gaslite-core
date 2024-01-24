pragma solidity 0.8.20;

import "@solady/src/auth/Ownable.sol";
import "@solady/src/tokens/ERC20.sol";

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

/// @title GasliteVest
/// @notice Turbo gas optimized token vesting
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
contract GasliteVest is Ownable {
    uint256 public vestingId;

    struct Vesting {
        uint256 amount;
        uint256 claimed;
        address token;
        address recipient;
        uint32 start;
        uint32 end;
        uint32 lastClaim;
    }

    mapping(uint256 => Vesting) public vestings;

    error InvalidAddress();
    error InvalidAmount();
    error InvalidTimestamp();
    error NotOwner();

    constructor() {
        _initializeOwner(msg.sender);
    }

    /// @notice Create a new vesting
    /// @param token The token to vest
    /// @param recipient The recipient of the vesting
    /// @param amount The amount to vest
    /// @param start The start of the vesting period
    /// @param end The end of the vesting period
    /// @return id The id of the vesting
    function create(address token, address recipient, uint256 amount, uint32 start, uint32 end)
        external
        returns (uint256)
    {
        if (token == address(0)) revert InvalidAddress();
        if (recipient == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        if (start < block.timestamp) revert InvalidTimestamp();
        if (end <= start) revert InvalidTimestamp();

        ERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 id = vestingId;

        Vesting storage vesting = vestings[id];
        vesting.token = token;
        vesting.recipient = recipient;
        vesting.amount = amount;
        vesting.start = start;
        vesting.end = end;
        vesting.lastClaim = start;

        unchecked {
            vestingId++;
        }

        return id;
    }

    /// @notice Claim vested tokens
    /// @param id The id of the vesting
    function claim(uint256 id) external {
        Vesting storage vesting = vestings[id];

        uint256 amount = vestedAmount(id);

        if (amount == 0) return;

        vesting.lastClaim = uint32(block.timestamp);

        unchecked {
            vesting.claimed += amount;
        }

        ERC20(vesting.token).transfer(vesting.recipient, amount);
    }

    /// @notice Cancel a vesting
    /// @param id The id of the vesting
    function cancel(uint256 id) external onlyOwner {
        Vesting storage vesting = vestings[id];

        uint256 vested = vestedAmount(id);

        ERC20(vesting.token).transfer(owner(), vesting.amount - vested);
        if (vested > 0) {
            ERC20(vesting.token).transfer(vesting.recipient, vested);
        }

        delete vestings[id];
    }

    /// @notice Get the amount vested
    /// @param id The id of the vesting
    /// @return amount The amount vested
    function vestedAmount(uint256 id) public view returns (uint256) {
        Vesting memory vesting = vestings[id];

        if (block.timestamp < vesting.start) return 0;
        if (block.timestamp >= vesting.end) return vesting.amount - vesting.claimed;

        uint256 timeSinceLastClaim = block.timestamp - vesting.lastClaim;
        uint256 vestingPeriod = vesting.end - vesting.start;

        return (vesting.amount * timeSinceLastClaim) / vestingPeriod;
    }

    /// @notice Get the vesting
    /// @param id The id of the vesting
    /// @return vesting The vesting
    function getVesting(uint256 id) external view returns (Vesting memory) {
        return vestings[id];
    }
}
