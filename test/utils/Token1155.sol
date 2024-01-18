pragma solidity 0.8.20;

import "@solady/src/tokens/ERC1155.sol";
import "@solady/src/utils/LibString.sol";

contract Token1155 is ERC1155 {
    using LibString for uint256;

    constructor() ERC1155() {}

    function batchMint(address to, uint256[] calldata tokenIds, uint256[] calldata quantities) external {
        for (uint256 i; i < tokenIds.length;) {
            _mint(to, tokenIds[i], quantities[i], "");
            unchecked {
                ++i;
            }
        }
    }

    function uri(uint256 tokenId) public pure override returns (string memory) {
        return tokenId.toString();
    }
}
