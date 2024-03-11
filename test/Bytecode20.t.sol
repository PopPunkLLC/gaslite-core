// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {Bytecode20} from "../src/Bytecode20.sol";

contract Bytecode20Test is SoladyTest {
    Bytecode20 token;
    uint256 private constant _totalSupply = 6942069420000000000000000000;
    uint256 private constant _maxMint = 100000000;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    struct _TestTemps {
        address owner;
        address to;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 privateKey;
        uint256 nonce;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        (t.owner, t.privateKey) = _randomSigner();
        t.to = _randomNonZeroAddress();
        t.amount = _random();
        t.deadline = _random();
    }

    function setUp() public {
        token = new Bytecode20(_totalSupply, 18, "Token", "1", "TKN");
    }

    function testMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 1e18);
        assertTrue(token.approve(address(0xBEEF), 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
    }

    function testTransfer() public {
        uint256 _startBalance = token.balanceOf(address(this));
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), _totalSupply);

        assertEq(token.balanceOf(address(this)), (_startBalance - 1e18));
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.transfer(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), _totalSupply);

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.transfer(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), _totalSupply);

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testPermit() public {
        _TestTemps memory t = _testTemps();
        t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);

        _checkAllowanceAndNonce(t);
    }

    function testTransferInsufficientBalanceReverts() public {
        address from = address(0xABCD);
        token.transfer(from, 0.9e18);
        vm.expectRevert(Bytecode20.InsufficientBalance.selector);
        vm.prank(from);
        token.transfer(address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientAllowanceReverts() public {
        address from = address(0xABCD);

        token.transfer(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        vm.expectRevert(Bytecode20.InsufficientApproval.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        token.transfer(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectRevert(Bytecode20.InsufficientBalance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testApprove(address to, uint256 amount) public {
        assertTrue(token.approve(to, amount));

        assertEq(token.allowance(address(this), to), amount);
    }

    function testTransfer(address to, uint256 amount) public {
        if (amount > _maxMint) amount = _maxMint;
        address from = address(0xABCD);
        if (address(this) == to) {
            to = from;
        }

        token.transfer(from, amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, amount);
        vm.startPrank(from);
        assertTrue(token.transfer(to, amount));
        assertEq(token.totalSupply(), _totalSupply);
        vm.stopPrank();

        if (from == to) {
            assertEq(token.balanceOf(from), amount);
        } else {
            assertEq(token.balanceOf(from), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testTransferFrom(address spender, address from, address to, uint256 approval, uint256 amount) public {
        if (approval != type(uint256).max) {
            approval = _bound(approval, 0, _maxMint);
            amount = _bound(amount, 0, approval);
        } else {
            amount = _bound(amount, 0, _maxMint);
        }

        token.transfer(from, amount);
        assertEq(token.balanceOf(from), amount);

        vm.prank(from);
        token.approve(spender, approval);

        vm.startPrank(spender);
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, amount);
        assertTrue(token.transferFrom(from, to, amount));
        assertEq(token.totalSupply(), _totalSupply);
        vm.stopPrank();

        if (approval == type(uint256).max) {
            assertEq(token.allowance(from, spender), approval);
        } else {
            assertEq(token.allowance(from, spender), approval - amount);
        }

        if (from == to) {
            assertEq(token.balanceOf(from), amount);
        } else {
            assertEq(token.balanceOf(from), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testPermit(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);

        _checkAllowanceAndNonce(t);
    }

    function _checkAllowanceAndNonce(_TestTemps memory t) internal {
        assertEq(token.allowance(t.owner, t.to), t.amount);
        assertEq(token.nonces(t.owner), t.nonce + 1);
    }

    function testTransferInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 sendAmount) public {
        address from = address(0xABCD);
        if (mintAmount > _maxMint) mintAmount = _maxMint - 1;
        sendAmount = _bound(sendAmount, mintAmount + 1, _maxMint + 100);

        token.transfer(from, mintAmount);

        vm.startPrank(from);
        vm.expectRevert(Bytecode20.InsufficientBalance.selector);
        token.transfer(to, sendAmount);
        vm.stopPrank();
    }

    function testTransferFromInsufficientAllowanceReverts(address to, uint256 approval, uint256 amount) public {
        if (approval > _maxMint) approval = _maxMint - 1;
        amount = _bound(amount, approval + 1, _maxMint + 100);

        address from = address(0xABCD);

        token.transfer(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        vm.expectRevert(Bytecode20.InsufficientApproval.selector);
        token.transferFrom(from, to, amount);
    }

    function testTransferFromInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 sendAmount) public {
        if (mintAmount > _maxMint) mintAmount = _maxMint;
        sendAmount = _bound(sendAmount, mintAmount + 100, _maxMint + 500);

        address from = address(0xABCD);

        token.transfer(from, mintAmount);

        vm.prank(from);
        token.approve(address(this), sendAmount);

        vm.expectRevert(Bytecode20.InsufficientBalance.selector);
        token.transferFrom(from, to, sendAmount);
    }

    function testPermitBadNonceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;
        while (t.nonce == 0) t.nonce = _random();

        _signPermit(t);

        vm.expectRevert(Bytecode20.InvalidSignature.selector);
        _permit(t);
    }

    function testPermitBadDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline == type(uint256).max) t.deadline--;
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        vm.expectRevert(Bytecode20.InvalidSignature.selector);
        t.deadline += 1;
        _permit(t);
    }

    function testPermitPastDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.deadline = _bound(t.deadline, 0, block.timestamp - 1);

        _signPermit(t);

        vm.expectRevert(Bytecode20.DeadlineExpired.selector);
        _permit(t);
    }

    function testPermitReplayReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);
        vm.expectRevert(Bytecode20.InvalidSignature.selector);
        _permit(t);
    }

    function _signPermit(_TestTemps memory t) internal view {
        bytes32 innerHash = keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, t.nonce, t.deadline));
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 outerHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, innerHash));
        (t.v, t.r, t.s) = vm.sign(t.privateKey, outerHash);
    }

    function _expectPermitEmitApproval(_TestTemps memory t) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(t.owner, t.to, t.amount);
    }

    function _permit(_TestTemps memory t) internal {
        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);

        /*address token_ = address(token);
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(sub(t, 0x20))
            mstore(sub(t, 0x20), 0xd505accf)
            pop(call(gas(), token_, 0, sub(t, 0x04), 0xe4, 0x00, 0x00))
            mstore(sub(t, 0x20), m)
        }*/
    }
}
