pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {GasliteMerkleDrop} from "./../src/GasliteMerkleDrop.sol";
import {Token} from "./../test/utils/Token.sol";
import {Merkle} from "@murky/Merkle.sol";

contract GasliteMerkleDropTest is Test {
    GasliteMerkleDrop drop;
    Token token;

    Merkle merkle;
    bytes32 root;
    bytes32[] data = new bytes32[](100);

    address[] recipients = new address[](100);
    uint256[] amounts = new uint256[](100);

    uint256 amount = 100e18;

    address owner = vm.addr(1);

    function setUp() external {
        token = new Token();

        merkle = new Merkle();
        for (uint256 i = 1; i < 100; i++) {
            recipients[i - 1] = vm.addr(i);
            data[i] = bytes32(keccak256(abi.encodePacked(vm.addr(i), amount)));
            amounts[i - 1] = amount;
        }
        root = merkle.getRoot(data);
        vm.startPrank(owner);
        drop = new GasliteMerkleDrop(address(token), root);
        drop.toggleActive();
        vm.stopPrank();
        token.transfer(address(drop), 1000e18);
    }

    function test_claim() external {
        bytes32[] memory proof = merkle.getProof(data, 51);
        vm.prank(recipients[50]);
        drop.claim(proof, amount);
    }

    function test_claimInsufficientBalance() external {
        vm.prank(owner);
        drop.withdraw();
        bytes32[] memory proof = merkle.getProof(data, 51);
        vm.prank(recipients[50]);
        vm.expectRevert(GasliteMerkleDrop.InsufficientBalance.selector);
        drop.claim(proof, amount);
    }

    function test_updateRoot() external {
        bytes32 newRoot = bytes32(keccak256(abi.encodePacked("newRoot")));
        vm.prank(owner);
        drop.updateRoot(newRoot);
        assertEq(drop.root(), newRoot);
    }

    function test_toggleActive() external {
        bool active = drop.active();
        vm.prank(owner);
        drop.toggleActive();
        assertEq(drop.active(), !active);
    }

    function test_withdraw() external {
        vm.prank(owner);
        drop.withdraw();
        assertEq(token.balanceOf(address(drop)), 0);
    }
}
