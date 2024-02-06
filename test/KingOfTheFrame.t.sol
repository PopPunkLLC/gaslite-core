pragma solidity 0.8.20;

import {KingOfTheFrame} from "./../src/KingOfTheFrame.sol";
import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract KingOfTheFrameTest is Test {
    KingOfTheFrame game;

    address userOne = address(1);
    address userTwo = address(2);

    function setUp() external {
        vm.startPrank(userOne);
        game = new KingOfTheFrame();
        game.setLive();
        vm.stopPrank();
        vm.prank(userTwo);
        (address topThief, uint256 score) = game.getTopThief();
        assertEq(topThief, userOne);
    }

    function test_steal() external {
        vm.startPrank(userTwo);
        vm.warp(10);
        game.transferFrom(userOne, userTwo, 0);
        (address topThief, uint256 score) = game.getTopThief();
        assertEq(topThief, userOne);
        assertEq(score, 9);
        vm.stopPrank();

        vm.startPrank(userOne);
        vm.warp(20);
        game.transferFrom(userTwo, userOne, 0);
        (topThief, score) = game.getTopThief();
        assertEq(topThief, userTwo);
        assertEq(score, 10);
        vm.stopPrank();

        vm.startPrank(userTwo);
        vm.warp(100);
        game.transferFrom(userOne, userTwo, 0);
        (topThief, score) = game.getTopThief();
        assertEq(topThief, userOne);
        assertEq(score, 89);
        vm.stopPrank();
        
        vm.startPrank(userOne);
        game.setLive();
        vm.expectRevert(KingOfTheFrame.NotLive.selector);
        game.transferFrom(userTwo, userOne, 0);
    }
}
