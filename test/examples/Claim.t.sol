pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {Claim} from "./../../src/Examples/Claim.sol";
import {Token} from "./../../test/utils/Token.sol";
import {Merkle} from "@murky/Merkle.sol";

contract ClaimTest is Test {
    Claim claim;
    Token token;

    Merkle merkle;
    bytes32 root;
    bytes32[] data = new bytes32[](100);

    address signer;
    uint256 signerKey;

    address[] recipients = new address[](100);
    uint256[] amounts = new uint256[](100);

    uint256 amount = 100e18;

    function setUp() external {
        token = new Token();

        merkle = new Merkle();
        for (uint256 i = 1; i < 100; i++) {
            recipients[i - 1] = vm.addr(i);
            data[i] = bytes32(keccak256(abi.encodePacked(vm.addr(i), amount)));
            amounts[i - 1] = amount;
        }
        root = merkle.getRoot(data);

        (signer, signerKey) = makeAddrAndKey("signer");

        claim = new Claim(signer, address(token));
        token.transfer(address(claim), 1000e18);
    }

    function test_setClaimMapping() external {
        claim.setClaimMapping(recipients, amounts);
    }

    function test_setClaimRoot() external {
        claim.setClaimRoot(root);
    }

    function test_claimWithMapping() external {
        claim.setClaimMapping(recipients, amounts);
        vm.prank(recipients[50]);
        claim.claimWithMapping();
    }

    function test_claimWithRoot() external {
        claim.setClaimRoot(root);

        bytes32[] memory proof = merkle.getProof(data, 51);

        vm.prank(recipients[50]);
        claim.claimWithRoot(proof, amount);
    }

    function test_claimWithSignature() external {
        bytes32 message = keccak256(abi.encodePacked(recipients[50], amount, address(claim)));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(recipients[50]);
        claim.claimWithSignature(amount, signature);
    }
}
