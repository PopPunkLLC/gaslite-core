// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@solady/src/tokens/ERC721.sol";
import "@solady/src/utils/LibString.sol";
import "@solady/src/auth/Ownable.sol";

contract KingOfTheFrame is ERC721, Ownable {
    using LibString for uint256;

    uint256 public lastStolenTimestamp;

    struct Thief {
        uint256 score;
        bool isThief;
    }

    struct TopThief {
        address thiefAddress;
        uint256 score;
    }

    TopThief private topThief;
    bool public live = false;
    mapping(address => Thief) private thieves;

    error ZeroAddress();
    error AlreadyOwner();
    error NotLive();

    constructor() ERC721() {
        _initializeOwner(msg.sender);
        _mint(msg.sender, 0);
        lastStolenTimestamp = block.timestamp;
        thieves[msg.sender] = Thief(0, true);
        topThief = TopThief(msg.sender, 0);
    }

    function setLive() public onlyOwner {
        live = !live;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        if (to == address(0)) revert ZeroAddress();
        if (!live) revert NotLive();

        address _currentHolder = ownerOf(tokenId);
        if (_currentHolder == msg.sender) revert AlreadyOwner();

        if (thieves[_currentHolder].isThief) {
            unchecked {
                thieves[_currentHolder].score += block.timestamp - lastStolenTimestamp;
            }
        } else {
            thieves[_currentHolder] = Thief(block.timestamp - lastStolenTimestamp, true);
        }

        if (thieves[_currentHolder].score > topThief.score) {
            topThief = TopThief(_currentHolder, thieves[_currentHolder].score);
        }

        _transfer(_currentHolder, msg.sender, tokenId);
        lastStolenTimestamp = block.timestamp;
    }

    function getTopThief() public view returns (address, uint256) {
        return (topThief.thiefAddress, topThief.score);
    }

    function getScore(address thief) public view returns (uint256) {
        return thieves[thief].score;
    }

    function name() public pure override returns (string memory) {
        return "King of the Frame";
    }

    function symbol() public pure override returns (string memory) {
        return "KOTF";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        return "ipfs://bafybeidq6hpvm5ph6qycbzeerqtzwd3dogdp5hlmxt5cefbypa7i4esaae/";
    }
}
