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
    uint256 public nextVestingId;

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
    /// @return vestingId The id of the vesting
    function create(address token, address recipient, uint256 amount, uint32 start, uint32 end)
        external
        returns (uint256 vestingId)
    {
        if (token == address(0)) revert InvalidAddress();
        if (recipient == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        if (start < block.timestamp) revert InvalidTimestamp();
        if (end <= start) revert InvalidTimestamp();

        vestingId = nextVestingId;

        unchecked {
            ++nextVestingId;
        }

        Vesting storage vesting = vestings[vestingId];
        vesting.token = token;
        vesting.recipient = recipient;
        vesting.amount = amount;
        vesting.start = start;
        vesting.end = end;
        vesting.lastClaim = start;

        ERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Claim vested tokens
    /// @param id The id of the vesting
    function claim(uint256 id) external {
        (Vesting storage vesting, uint256 vested) = _vestedAmount(id);

        if (vested == 0) return;

        vesting.lastClaim = uint32(block.timestamp);

        unchecked {
            vesting.claimed += vested;
        }

        ERC20(vesting.token).transfer(vesting.recipient, vested);
    }

    /// @notice Cancel a vesting
    /// @param id The id of the vesting
    function cancel(uint256 id) external onlyOwner {
        (Vesting storage vesting, uint256 vested) = _vestedAmount(id);

        uint256 claimed = vesting.claimed;

        ERC20(vesting.token).transfer(owner(), vesting.amount - claimed - vested);
        if (vested > 0) {
            ERC20(vesting.token).transfer(vesting.recipient, vested);
        }

        delete vestings[id];
    }

    /// @notice Get the amount vested
    /// @param id The id of the vesting
    /// @return vestedAmount amount The amount vested
    function vestedAmount(uint256 id) external view returns (uint256 vestedAmount) {
        (, vestedAmount) = _vestedAmount(id);
    }

    /// @notice Get the vesting
    /// @param id The id of the vesting
    /// @return vesting The vesting
    function getVesting(uint256 id) external view returns (Vesting memory) {
        return vestings[id];
    }

    /// @notice Internal function to get the vested amount
    /// @param id The id of the vesting
    /// @return vesting The vesting
    /// @return vestedAmount The amount vested
    function _vestedAmount(uint256 id) internal view returns (Vesting storage vesting, uint256 vestedAmount) {
        vesting = vestings[id];

        uint256 vestingStart = vesting.start;
        if (block.timestamp < vestingStart) return (vesting, 0);

        uint256 vestingEnd = vesting.end;
        uint256 vestingAmount = vesting.amount;
        uint256 vestingClaimed = vesting.claimed;
        if (block.timestamp >= vestingEnd) return (vesting, (vestingAmount - vestingClaimed));

        uint256 timeSinceLastClaim = block.timestamp - vesting.lastClaim;
        uint256 vestingPeriod = vestingEnd - vestingStart;
        vestedAmount = (vestingAmount * timeSinceLastClaim) / vestingPeriod;
    }
}
