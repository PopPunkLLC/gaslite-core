pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {GasliteSplitterFactory} from "./../src/GasliteSplitterFactory.sol";
import {GasliteSplitter} from "./../src/GasliteSplitter.sol";
import {Token} from "./../test/utils/Token.sol";

contract GasliteSplitterFactoryTest is Test {
    GasliteSplitterFactory splitterFactory;
    GasliteSplitter splitter;
    Token token;

    uint256 constant SIZE = 5;
    uint256 private salt = 0;
    address[] recipients = new address[](SIZE);
    uint256[] shares = new uint256[](SIZE);

    address releaser = vm.addr(999);

    function setUp() public {
        splitterFactory = new GasliteSplitterFactory();

        for (uint256 i = 0; i < SIZE; i++) {
            recipients[i] = vm.addr(i + 1);
            shares[i] = 5;
        }
        token = new Token();
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, false, bytes32(salt))));
        ++salt;
    }

    function test_splitterConstructorState() public {
        uint256 total = splitter.totalShares();
        assertEq(total, SIZE * 5);
        bool releaseRoyalty = splitter.releaseRoyalty();
        assertEq(releaseRoyalty, false);
        for (uint256 i = 0; i < SIZE; i++) {
            assertEq(splitter.recipients(i), recipients[i]);
            assertEq(splitter.shares(i), shares[i]);
        }
    }

    function test_splitterSplitETH() public {
        payable(address(splitter)).transfer(10 ether);
        assertEq(address(splitter).balance, 10 ether);
        uint256 total = splitter.totalShares();
        assertEq(total, SIZE * 5);
        splitter.release();
        for (uint256 i = 0; i < SIZE; i++) {
            assertEq(recipients[i].balance, 2 ether);
        }
    }

    function test_splitterSplitETHUnevenShares() public {
        uint256[] memory _shares = new uint256[](SIZE);
        _shares[0] = 1;
        _shares[1] = 2;
        _shares[2] = 2;
        _shares[3] = 2;
        _shares[4] = 3;
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, _shares, false, bytes32(salt))));
        ++salt;
        payable(address(splitter)).transfer(10 ether);
        assertEq(address(splitter).balance, 10 ether);
        uint256 total = splitter.totalShares();
        assertEq(total, 10);
        splitter.release();
        assertEq(recipients[0].balance, 1 ether);
        assertEq(recipients[1].balance, 2 ether);
        assertEq(recipients[2].balance, 2 ether);
        assertEq(recipients[3].balance, 2 ether);
        assertEq(recipients[4].balance, 3 ether);
    }

    function test_splitterSplitETHReleaseRoyalty() public {
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
        ++salt;
        bool releaseRoyalty = splitter.releaseRoyalty();
        assertEq(releaseRoyalty, true);

        payable(address(splitter)).transfer(10 ether);
        assertEq(address(splitter).balance, 10 ether);
        uint256 total = splitter.totalShares();
        assertEq(total, SIZE * 5);
        vm.prank(releaser);
        splitter.release();
        assertEq(releaser.balance, 0.01 ether);
        for (uint256 i = 0; i < SIZE; i++) {
            assertEq(recipients[i].balance, 1.998 ether);
        }
    }

    function test_splitterSplitToken() public {
        token.approve(address(splitter), 10e18);
        token.transfer(address(splitter), 10e18);
        assertEq(token.balanceOf(address(splitter)), 10e18);
        uint256 total = splitter.totalShares();
        assertEq(total, SIZE * 5);
        splitter.release(address(token));
        for (uint256 i = 0; i < SIZE; i++) {
            assertEq(token.balanceOf(recipients[i]), 2e18);
        }
    }

    function test_splitterSplitTokenUnevenShares() public {
        uint256[] memory _shares = new uint256[](SIZE);
        _shares[0] = 1;
        _shares[1] = 2;
        _shares[2] = 2;
        _shares[3] = 2;
        _shares[4] = 3;
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, _shares, false, bytes32(salt))));
        ++salt;
        token.approve(address(splitter), 10e18);
        token.transfer(address(splitter), 10e18);
        assertEq(token.balanceOf(address(splitter)), 10e18);
        uint256 total = splitter.totalShares();
        assertEq(total, 10);
        splitter.release(address(token));
        assertEq(token.balanceOf(recipients[0]), 1e18);
        assertEq(token.balanceOf(recipients[1]), 2e18);
        assertEq(token.balanceOf(recipients[2]), 2e18);
        assertEq(token.balanceOf(recipients[3]), 2e18);
        assertEq(token.balanceOf(recipients[4]), 3e18);
    }

    function test_splitterSplitTokenReleaseRoyalty() public {
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
        ++salt;
        bool releaseRoyalty = splitter.releaseRoyalty();
        assertEq(releaseRoyalty, true);

        token.approve(address(splitter), 10e18);
        token.transfer(address(splitter), 10e18);
        assertEq(token.balanceOf(address(splitter)), 10e18);
        uint256 total = splitter.totalShares();
        assertEq(total, SIZE * 5);
        vm.prank(releaser);
        splitter.release(address(token));
        assertEq(token.balanceOf(releaser), 1e16);
        for (uint256 i = 0; i < SIZE; i++) {
            assertEq(token.balanceOf(recipients[i]), 1.998e18);
        }
    }

    function test_splitterSplitETHBalanceZero() public {
        assertEq(address(splitter).balance, 0 ether);
        vm.expectRevert(GasliteSplitter.BalanceZero.selector);
        splitter.release();
    }

    function test_splitterSplitTokenBalanceZero() public {
        assertEq(token.balanceOf(address(splitter)), 0);
        vm.expectRevert(GasliteSplitter.BalanceZero.selector);
        splitter.release(address(token));
    }

    function test_splitterFactoryDeployDuplicateWithNewSalt() public {
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
        ++salt;
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
    }

    function test_splitterFactoryDeployDuplicateWithSameSalt() public {
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
        vm.expectRevert(GasliteSplitterFactory.DeploymentFailed.selector);
        splitter = GasliteSplitter(payable(splitterFactory.deployContract(recipients, shares, true, bytes32(salt))));
    }
}
