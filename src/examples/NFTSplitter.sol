pragma solidity 0.8.19;

import '@solady/tokens/ERC721.sol';
import '@solady/utils/LibString.sol';

interface GasliteSplitter {
    function release() external;
    function release(address) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract NFTSplitter is ERC721 {
    using LibString for uint256;

    address public splitter;
    address public mintToken;

    uint256 priceETH = 0.01 ether;
    uint256 priceTokens = 1000e18;

    error InsufficientFunds();

    constructor(address _splitter, address _mintToken) ERC721() {
        splitter = _splitter;
        mintToken = _mintToken;
    }

    function mintWithETH(uint256 quantity) external payable {
        if (msg.value != priceETH * quantity) revert InsufficientFunds();
        _mint(msg.sender, quantity);
        payable(splitter).transfer(msg.value);
    }

    function mintWithToken(uint256 quantity) external payable {
        uint256 cost = priceTokens * quantity;
        if (IERC20(mintToken).transferFrom(msg.sender, address(splitter), cost)) {
            _mint(msg.sender, quantity);
        } else {
            revert InsufficientFunds();
        }
    }

    function releaseFunds(bool isETH) external {
        if (isETH) {
            GasliteSplitter(splitter).release();
        } else {
            GasliteSplitter(splitter).release(mintToken);
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