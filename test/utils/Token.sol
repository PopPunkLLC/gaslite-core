pragma solidity 0.8.19;

import "@solady/tokens/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20() {
        _mint(msg.sender, 1000000000000000000000000000);
    }

    function name() public pure override returns (string memory) {
        return "Token";
    }

    function symbol() public pure override returns (string memory) {
        return "TKN";
    }
}
