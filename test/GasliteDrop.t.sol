pragma solidity 0.8.19;

import {GasliteDrop} from "./../src/GasliteDrop.sol";
import {NFT} from "./../test/utils/NFT.sol";
import {Token} from "./../test/utils/Token.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {DropPackLib} from "../src/utils/DropPackLib.sol";
import "forge-std/Test.sol";

contract GasliteDropTest is Test {
    using LibPRNG for LibPRNG.PRNG;

    GasliteDrop gasliteDrop;
    NFT nft;
    Token token;
    address immutable sender = makeAddr("sender");
    uint256 quantity = 1000;
    uint256 value = quantity * 0.001 ether;

    uint256 internal constant MAX_ERC20_BATCH_DROP = 1000;

    function setUp() public {
        nft = new NFT();
        token = new Token();
        gasliteDrop = new GasliteDrop();
    }

    function test_airdropERC721() public {
        vm.startPrank(sender);
        nft.batchMint(address(sender), quantity);

        uint256[] memory tokenIds = new uint256[](quantity);
        address[] memory recipients = new address[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = i;
            recipients[i] = vm.addr(2);
        }

        nft.setApprovalForAll(address(gasliteDrop), true);
        gasliteDrop.airdropERC721(address(nft), recipients, tokenIds);

        vm.stopPrank();
    }

    function test_airdropERC20() public {
        // Fixed inputs for gas comparison.
        test_fuzzedAirdropERC20(quantity, uint256(keccak256("gas bad")));
    }

    function test_fuzzedAirdropERC20(uint256 totalRecipients, uint256 initialRng) public {
        vm.pauseGasMetering();
        totalRecipients = bound(totalRecipients, 0, MAX_ERC20_BATCH_DROP);
        LibPRNG.PRNG memory rng = LibPRNG.PRNG({state: initialRng});

        // Setup.
        uint256 total = 0;
        address[] memory recipients = new address[](totalRecipients);
        uint256[] memory amounts = new uint256[](totalRecipients);
        bytes32[] memory packedRecipients = new bytes32[] (totalRecipients);
        for (uint256 i = 0; i < totalRecipients; i++) {
            address recipient = address(uint160(rng.next()));
            recipients[i] = recipient;
            // Constrain to 96-bits for packing.
            uint256 amount = uint96(rng.next());
            total += amount;
            amounts[i] = amount;
            packedRecipients[i] = DropPackLib.packERC20Recipient(recipient, amount);
        }
        deal(address(token), sender, total);

        // Interaction.
        vm.startPrank(sender);
        token.approve(address(gasliteDrop), type(uint256).max);

        vm.resumeGasMetering();
        gasliteDrop.airdropERC20(address(token), packedRecipients, total);
        vm.pauseGasMetering();

        vm.stopPrank();

        // Checks.
        for (uint256 i = 0; i < totalRecipients; i++) {
            assertEq(token.balanceOf(recipients[i]), amounts[i]);
        }
        vm.resumeGasMetering();
    }

    function test_airdropETH() public {
        payable(sender).transfer(value);
        vm.startPrank(sender);

        address[] memory recipients = new address[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            recipients[i] = vm.addr(2);
            amounts[i] = 0.001 ether;
        }

        gasliteDrop.airdropETH{value: value}(recipients, amounts);
        vm.stopPrank();
    }
}
