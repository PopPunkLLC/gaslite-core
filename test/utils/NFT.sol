pragma solidity 0.8.20;

import "@solady/src//tokens/ERC721.sol";
import "@solady/src/utils/LibString.sol";

contract NFT is ERC721 {
    using LibString for uint256;

    constructor() ERC721() {}

    function batchMint(address to, uint256 quantity) external {
        for (uint256 i; i < quantity;) {
            _mint(to, i);
            unchecked {
                ++i;
            }
        }
    }

    function name() public pure override returns (string memory) {
        return "NFT";
    }

    function symbol() public pure override returns (string memory) {
        return "NFT";
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return tokenId.toString();
    }
}
