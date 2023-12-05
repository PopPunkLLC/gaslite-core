pragma solidity 0.8.19;

import "@solady/auth/Ownable.sol";
import "@solady/tokens/ERC20.sol";

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
        address owner;
        uint32 start;
        uint32 end;
        uint32 lastClaim;
    }

    mapping(uint256 => Vesting) public vestings;

    error InvalidAddress();
    error InvalidAmount();
    error InvalidTimestamp();
    error NotOwner();

    event Created(
        address indexed token, address indexed recipient, uint256 id, uint256 amount, uint32 start, uint32 end
    );

    event Cancelled(address indexed token, address indexed recipient, uint256 id, uint256 amount);

    constructor() {
        _initializeOwner(msg.sender);
    }

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
        vesting.owner = msg.sender;
        vesting.amount = amount;
        vesting.start = start;
        vesting.end = end;
        vesting.lastClaim = start;

        unchecked {
            vestingId++;
        }

        emit Created(token, recipient, id, amount, start, end);

        return id;
    }

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

    function cancel(uint256 id) external {
        Vesting storage vesting = vestings[id];

        if (msg.sender != vesting.owner) revert NotOwner();

        uint256 vested = vestedAmount(id);

        ERC20(vesting.token).transfer(vesting.owner, vesting.amount - vested);
        if (vested > 0) {
            ERC20(vesting.token).transfer(vesting.recipient, vested);
        }

        emit Cancelled(vesting.token, vesting.recipient, id, vesting.amount);
        delete vestings[id];
    }

    function vestedAmount(uint256 id) public view returns (uint256) {
        Vesting memory vesting = vestings[id];

        if (block.timestamp < vesting.start) return 0;
        if (block.timestamp >= vesting.end) return vesting.amount - vesting.claimed;

        uint256 timeSinceLastClaim = block.timestamp - vesting.lastClaim;
        uint256 vestingPeriod = vesting.end - vesting.start;

        return (vesting.amount * timeSinceLastClaim) / vestingPeriod;
    }

    function getVesting(uint256 id) external view returns (Vesting memory) {
        return vestings[id];
    }

    function getVestingsByOwner(address owner) external view returns (Vesting[] memory) {
        Vesting[] memory _vestings = new Vesting[](vestingId);

        uint256 count;
        for (uint256 i; i < vestingId;) {
            if (vestings[i].owner == owner) {
                _vestings[count] = vestings[i];
                count++;
            }
            unchecked {
                i++;
            }
        }

        return _vestings;
    }
}
