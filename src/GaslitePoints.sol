// SPDX-License-Identifier: BUSL-1.1
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

import {Ownable} from "@solady/src/auth/Ownable.sol";

/// @title GaslitePoints
/// @notice Turbo gas optimized points contract
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
contract GaslitePoints is Ownable {
    mapping(address => uint256) public points;

    constructor() {
        _initializeOwner(msg.sender);
    }

    /// @notice Add points to a user's balance
    /// @param _user The user to add points to
    /// @param _amount The amount of points to add
    function addPoints(address _user, uint256 _amount) public onlyOwner {
        points[_user] += _amount;
    }

    /// @notice Remove points from a user's balance
    /// @param _user The user to remove points from
    /// @param _amount The amount of points to remove
    function removePoints(address _user, uint256 _amount) public onlyOwner {
        points[_user] -= _amount;
    }

    /// @notice Get the points balance of a user
    /// @param _user The user to get the points balance of
    /// @return The points balance of the user
    function getPoints(address _user) public view returns (uint256) {
        return points[_user];
    }
}
