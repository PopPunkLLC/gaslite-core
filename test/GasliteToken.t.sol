// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/solady/test/utils/SoladyTest.sol";
import "../lib/solady/test/utils/InvariantTest.sol";

import {GasliteToken} from "./../src/GasliteToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";

contract GasliteTokenTest is SoladyTest {
    GasliteToken token;
    uint256 public constant _totalSupply = 525_600 ether;
    uint256 private constant _maxMint = 1 ether;

    address private admin = vm.addr(0x111);
    address private lpTokenRecipient = vm.addr(0x222);
    address private airdropper = vm.addr(0x333);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    address public constant UNISWAPV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAPV2);
    address private pairAddress;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://eth.llamarpc.com");
        vm.selectFork(mainnetFork);
        (bool transferToAdmin,) = admin.call{value: 500 ether}("");
        assertTrue(transferToAdmin);
        token = new GasliteToken(
            "GASLITE", "GAS", 525_600 ether, lpTokenRecipient, 20, 20, admin, airdropper, 50, WETH, UNISWAPV2
        );
        vm.startPrank(admin);
        uint256 valueToContract = 206.1 ether;
        (bool transferToLPRecipient,) = lpTokenRecipient.call{value: valueToContract}("");
        assertTrue(transferToLPRecipient);
        vm.stopPrank();
        //token.transferOwnership(lpTokenRecipient);
        vm.startPrank(lpTokenRecipient);
        uint256 tokenPerEth = 638;
        pairAddress = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(token), WETH);
        assertEq(IERC20(pairAddress).totalSupply(), 0);
        uint256 tokenContractBalanceStart = token.balanceOf(address(token));
        token.fundLP{value: valueToContract}(tokenPerEth);
        uint256 tokenContractBalanceEnd = token.balanceOf(address(token));
        vm.stopPrank();
        vm.prank(airdropper);
        token.transfer(admin, 262_800 ether);
        vm.startPrank(admin);
        token.transfer(address(0x5), 1);
        token.transfer(address(0x10), 1);
        vm.stopPrank();
        vm.prank(address(0x5));
        vm.expectRevert();
        token.transfer(address(0x6), 1);

        vm.prank(address(0x10));
        vm.expectRevert();
        token.transfer(address(0x6), 1);

        vm.prank(lpTokenRecipient);
        token.setAllowedDuringPause(address(0x10), true);
        vm.prank(address(0x10));
        token.transfer(address(0x6), 1);

        vm.prank(lpTokenRecipient);
        token.enableTrading();

        vm.prank(address(0x5));
        token.transfer(address(0x6), 1);
        vm.prank(address(0x6));
        token.transfer(admin, 2);

        assertEq(
            IERC20(pairAddress).balanceOf(lpTokenRecipient), (IERC20(pairAddress).totalSupply() - MINIMUM_LIQUIDITY)
        );
        assertEq(
            address(token).balance,
            valueToContract - ((tokenContractBalanceStart - tokenContractBalanceEnd) / tokenPerEth)
        );
        assertEq((tokenContractBalanceStart - tokenContractBalanceEnd), token.balanceOf(pairAddress));
        assertEq(
            ((tokenContractBalanceStart - tokenContractBalanceEnd) / tokenPerEth), IERC20(WETH).balanceOf(pairAddress)
        );
    }

    function test_uniswapSellWithFee() public {
        address from = address(0xBEEF);
        vm.prank(admin);
        token.transfer(from, 50 ether);

        vm.startPrank(from);
        token.approve(address(uniswapV2Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WETH;

        uint256 treasuryBalanceStart = token.balanceOf(admin);
        uint256 pairBalanceStart = token.balanceOf(pairAddress);
        uint256 pairWETHBalanceStart = IERC20(WETH).balanceOf(pairAddress);
        uint256 fromETHBalanceStart = from.balance;
        uint256 expectedTax = 50 ether * token.sellTotalFees() / 1000;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(50 ether, 0, path, from, block.timestamp);
        uint256 fromETHBalanceEnd = from.balance;

        assertEq((treasuryBalanceStart + expectedTax), token.balanceOf(admin));
        assertEq((pairBalanceStart + 50 ether - expectedTax), token.balanceOf(pairAddress));
        assertEq(0, token.balanceOf(from));
        assertEq((pairWETHBalanceStart + fromETHBalanceStart - fromETHBalanceEnd), IERC20(WETH).balanceOf(pairAddress));
        assertTrue(fromETHBalanceEnd > fromETHBalanceStart);
        vm.stopPrank();
    }

    function test_uniswapBuyWithFee() public {
        address from = address(0xBEEF);
        vm.prank(admin);
        (bool success,) = from.call{value: 1 ether}("");
        assertTrue(success);

        vm.startPrank(from);
        token.approve(address(uniswapV2Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[1] = address(token);
        path[0] = WETH;

        uint256 treasuryBalanceStart = token.balanceOf(admin);
        uint256 pairBalanceStart = token.balanceOf(pairAddress);
        uint256 fromBalanceStart = token.balanceOf(from);
        uint256 pairWETHBalanceStart = IERC20(WETH).balanceOf(pairAddress);
        uint256 fromETHBalanceStart = from.balance;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(
            0, path, from, block.timestamp
        );
        uint256 pairBalanceEnd = token.balanceOf(pairAddress);
        uint256 fromBalanceEnd = token.balanceOf(from);
        uint256 expectedTax =
            (fromBalanceEnd - fromBalanceStart) * 1000 / (1000 - token.buyTotalFees()) * token.buyTotalFees() / 1000;
        uint256 fromETHBalanceEnd = from.balance;

        assertEq((treasuryBalanceStart + expectedTax), token.balanceOf(admin));
        assertEq((pairBalanceStart - pairBalanceEnd - expectedTax), token.balanceOf(from));
        assertEq((pairWETHBalanceStart + fromETHBalanceStart - fromETHBalanceEnd), IERC20(WETH).balanceOf(pairAddress));
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(lpTokenRecipient);
        uint256 adminBalanceStart = admin.balance;
        uint256 contractBalanceStart = address(token).balance;
        token.withdrawETH(admin);
        assertEq(adminBalanceStart + contractBalanceStart, admin.balance);
        assertEq(address(token).balance, 0);
        vm.stopPrank();
    }

    function test_withdrawToken() public {
        vm.startPrank(lpTokenRecipient);
        uint256 adminBalanceStart = token.balanceOf(admin);
        uint256 contractBalanceStart = token.balanceOf(address(token));
        token.withdrawToken(address(token), admin);
        assertEq(adminBalanceStart + contractBalanceStart, token.balanceOf(admin));
        assertEq(token.balanceOf(address(token)), 0);
        vm.stopPrank();
    }

    function test_withdrawFail() public {
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        token.withdrawETH(admin);
        vm.stopPrank();
    }

    function test_withdrawTokenFail() public {
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        token.withdrawToken(address(token), admin);
    }

    function test_metadata() public {
        assertEq(token.name(), "GASLITE");
        assertEq(token.symbol(), "GAS");
        assertEq(token.decimals(), 18);
    }

    function test_approve() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 1e18);
        assertTrue(token.approve(address(0xBEEF), 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
    }

    function test_transfer() public {
        address from = address(this);
        vm.prank(admin);
        token.transfer(from, 1e18);

        uint256 _startBalance = token.balanceOf(address(this));
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), _totalSupply);

        assertEq(token.balanceOf(address(this)), (_startBalance - 1e18));
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function test_transferFrom() public {
        address from = address(0xABCD);

        vm.prank(admin);
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

    function test_infiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        vm.prank(admin);
        token.transfer(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), _totalSupply);

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function test_transferInsufficientBalanceReverts() public {
        address from = address(0xABCD);
        vm.prank(admin);
        token.transfer(from, 0.9e18);
        vm.expectRevert(GasliteToken.InsufficientBalance.selector);
        vm.prank(from);
        token.transfer(address(0xBEEF), 1e18);
    }

    function test_transferFromInsufficientAllowanceReverts() public {
        address from = address(0xABCD);

        vm.prank(admin);
        token.transfer(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        vm.expectRevert(GasliteToken.InsufficientAllowance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function test_transferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        vm.prank(admin);
        token.transfer(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectRevert(GasliteToken.InsufficientBalance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function test_approve(address to, uint256 amount) public {
        if (to == address(0)) {
            vm.expectRevert(GasliteToken.ZeroAddress.selector);
            token.approve(to, amount);
        } else {
            assertTrue(token.approve(to, amount));
            assertEq(token.allowance(address(this), to), amount);
        }
    }

    function test_transfer(address to, uint256 amount) public {
        if (amount > _maxMint) amount = _maxMint;
        address from = address(0xABCD);
        if (admin == to) {
            to = from;
        }

        vm.prank(admin);
        token.transfer(from, amount);

        if (to == address(0)) {
            vm.expectRevert(GasliteToken.ZeroAddress.selector);
            vm.startPrank(from);
            token.transfer(to, amount);
        } else {
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
    }

    function test_transferFrom(address spender, address from, address to, uint256 approval, uint256 amount) public {
        if (approval != type(uint256).max) {
            approval = _bound(approval, 0, _maxMint);
            amount = _bound(amount, 0, approval);
        } else {
            amount = _bound(amount, 0, _maxMint);
        }

        vm.prank(admin);
        if (from == address(0)) {
            vm.expectRevert(GasliteToken.ZeroAddress.selector);
            token.transfer(from, amount);
        } else {
            token.transfer(from, amount);
            assertEq(token.balanceOf(from), amount);

            vm.prank(from);
            if (spender == address(0)) {
                vm.expectRevert(GasliteToken.ZeroAddress.selector);
                token.approve(spender, approval);
            } else {
                token.approve(spender, approval);

                vm.startPrank(spender);
                if (to == address(0) || from == address(0)) {
                    vm.expectRevert(GasliteToken.ZeroAddress.selector);
                    token.transferFrom(from, to, amount);
                } else {
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
            }
        }
    }

    function test_transferInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 sendAmount) public {
        address from = address(0xABCD);
        if (mintAmount > _maxMint) mintAmount = _maxMint - 1;
        sendAmount = _bound(sendAmount, mintAmount + 1, _maxMint + 100);

        vm.prank(admin);
        token.transfer(from, mintAmount);

        vm.startPrank(from);
        if (to == address(0)) {
            vm.expectRevert(GasliteToken.ZeroAddress.selector);
        } else {
            vm.expectRevert(GasliteToken.InsufficientBalance.selector);
        }
        token.transfer(to, sendAmount);
        vm.stopPrank();
    }

    function test_transferFromInsufficientAllowanceReverts(address to, uint256 approval, uint256 amount) public {
        if (approval > _maxMint) approval = _maxMint - 1;
        amount = _bound(amount, approval + 1, _maxMint + 100);

        address from = address(0xABCD);

        vm.prank(admin);
        token.transfer(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        vm.expectRevert(GasliteToken.InsufficientAllowance.selector);
        token.transferFrom(from, to, amount);
    }

    function test_transferFromInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 sendAmount) public {
        if (mintAmount > _maxMint) mintAmount = _maxMint;
        sendAmount = _bound(sendAmount, mintAmount + 100, _maxMint + 500);

        address from = address(0xABCD);

        vm.prank(admin);
        token.transfer(from, mintAmount);

        vm.prank(from);
        token.approve(address(this), sendAmount);

        if (to == address(0)) {
            vm.expectRevert(GasliteToken.ZeroAddress.selector);
        } else {
            vm.expectRevert(GasliteToken.InsufficientBalance.selector);
        }
        token.transferFrom(from, to, sendAmount);
    }
}
