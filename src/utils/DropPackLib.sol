// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";

/// @author philogy <https://github.com/philogy>
library DropPackLib {
    using SafeCastLib for uint256;

    function packERC20Recipient(address recipient, uint256 amount) internal pure returns (bytes32) {
        bytes32(abi.encodePacked(recipient, amount.toUint96()));
    }

    function packETHRecipient(address recipient, uint256 amount) internal pure returns (bytes32) {
        bytes32(abi.encodePacked(amount.toUint96(), recipient));
    }
}
