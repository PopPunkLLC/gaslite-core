pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {NFTSplitter} from "./../../src/examples/NFTSplitter.sol";
import {GasliteSplitter} from "./../../src/GasliteSplitter.sol";
import {Token} from "../utils/Token.sol";

contract NFTSplitterTest is Test {
    NFTSplitter nft;
    GasliteSplitter splitter;
    Token token;
    address[] recipients = [vm.addr(1), vm.addr(2), vm.addr(3)];
    uint256[] shares = [10, 20, 30];

    address minter = vm.addr(4);

    function setUp() external {
        splitter = new GasliteSplitter(recipients, shares, false);
        vm.prank(minter);
        token = new Token();
        nft = new NFTSplitter(address(splitter), address(token));
        payable(minter).transfer(10 ether);
    }

    function test_mintWithEth() external {
        vm.startPrank(minter);
        nft.mintWithETH{value: 5 * 0.01 ether}(5);
        nft.releaseFunds(true);
    }

    function test_mintWithToken() external {
        vm.startPrank(minter);
        token.approve(address(nft), 5 * 1000e18);
        nft.mintWithToken(5);
        nft.releaseFunds(false);
    }
}
