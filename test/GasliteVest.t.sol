pragma solidity 0.8.20;

import {GasliteVest} from "./../src/GasliteVest.sol";
import {Token} from "./../test/utils/Token.sol";
import "forge-std/Test.sol";

contract GasliteVestTest is Test {
    GasliteVest vest;
    Token token;

    address admin = vm.addr(0x1);
    address recipient = vm.addr(0x2);

    function setUp() external {
        vm.startPrank(admin);
        vest = new GasliteVest();
        vm.stopPrank();
        token = new Token();
        token.transfer(admin, 100e18);
    }

    function test_create() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(id, 0);
        assertEq(token.balanceOf(address(vest)), 100e18);

        (
            uint256 _amount,
            uint256 _claimed,
            address _token,
            address _recipient,
            uint32 _start,
            uint32 _end,
            uint32 _lastClaim
        ) = vest.vestings(id);

        assertEq(_amount, 100e18);
        assertEq(_claimed, 0);
        assertEq(_token, address(token));
        assertEq(_recipient, recipient);
        assertEq(_start, 10);
        assertEq(_end, 20);
        assertEq(_lastClaim, 10);
    }

    function test_claim() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(token.balanceOf(address(vest)), 100e18);

        vm.warp(15);

        vest.claim(0);

        assertEq(token.balanceOf(address(vest)), 50e18);
        assertEq(token.balanceOf(recipient), 50e18);

        (, uint256 claimed,,,,,) = vest.vestings(id);
        assertEq(claimed, 50e18);
    }

    function test_claimTwice() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(token.balanceOf(address(vest)), 100e18);

        vm.warp(15);

        vest.claim(id);

        assertEq(token.balanceOf(address(vest)), 50e18);
        assertEq(token.balanceOf(recipient), 50e18);

        (, uint256 claimed,,,,,) = vest.vestings(id);
        assertEq(claimed, 50e18);

        vm.warp(16);

        vest.claim(id);

        assertEq(token.balanceOf(address(vest)), 40e18);
        assertEq(token.balanceOf(recipient), 60e18);

        (, claimed,,,,,) = vest.vestings(id);
        assertEq(claimed, 60e18);
    }

    function test_claimFull() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(token.balanceOf(address(vest)), 100e18);

        vm.warp(20);

        vest.claim(id);

        assertEq(token.balanceOf(address(vest)), 0);
        assertEq(token.balanceOf(recipient), 100e18);

        (, uint256 claimed,,,,,) = vest.vestings(id);
        assertEq(claimed, 100e18);
    }

    function test_cancel() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(token.balanceOf(address(vest)), 100e18);

        vest.cancel(id);

        assertEq(token.balanceOf(address(vest)), 0);
        assertEq(token.balanceOf(recipient), 0);
        assertEq(token.balanceOf(admin), 100e18);
    }

    function test_cancelVested() external {
        vm.startPrank(admin);
        token.approve(address(vest), 100e18);

        uint256 id = vest.create(address(token), recipient, 100e18, 10, 20);

        assertEq(token.balanceOf(address(vest)), 100e18);

        vm.warp(15);

        vest.cancel(id);

        assertEq(token.balanceOf(address(vest)), 0);
        assertEq(token.balanceOf(recipient), 50e18);
        assertEq(token.balanceOf(admin), 50e18);
    }
}
