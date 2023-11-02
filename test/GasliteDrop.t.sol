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

    uint256 internal constant MAX_ERC20_BATCH_DROP = 1000;
    uint256 internal constant MAX_ETH_BATCH_DROP = 1000;
    uint256 internal constant MAX_ERC721_BATCH_DROP = 1000;

    function setUp() public {
        nft = new NFT();
        token = new Token();
        gasliteDrop = new GasliteDrop();
    }

    function test_airdropERC721() public {
        vm.startPrank(sender);
        nft.batchMint(address(sender), MAX_ERC721_BATCH_DROP);

        uint256[] memory tokenIds = new uint256[](MAX_ERC721_BATCH_DROP);
        address[] memory recipients = new address[](MAX_ERC721_BATCH_DROP);
        for (uint256 i = 0; i < MAX_ERC721_BATCH_DROP; i++) {
            tokenIds[i] = i;
            recipients[i] = vm.addr(2);
        }

        nft.setApprovalForAll(address(gasliteDrop), true);
        gasliteDrop.airdropERC721(address(nft), recipients, tokenIds);

        vm.stopPrank();
    }

    function test_airdropERC20() public {
        vm.pauseGasMetering();
        LibPRNG.PRNG memory rng = LibPRNG.PRNG({state: uint(keccak256("gas bad (erc20 test)"))});

        // Setup.
        uint256 total = 0;
        address[] memory recipients = new address[](MAX_ERC20_BATCH_DROP);
        uint256[] memory amounts = new uint256[](MAX_ERC20_BATCH_DROP);
        bytes32[] memory packedRecipients = new bytes32[] (MAX_ERC20_BATCH_DROP);
        for (uint256 i = 0; i < MAX_ERC20_BATCH_DROP; i++) {
            address recipient = address(uint160(rng.next()));
            recipients[i] = recipient;
            // Constrain to 96-bits for packing.
            uint256 amount = uint96(rng.next());
            total += amount;
            amounts[i] = amount;
            packedRecipients[i] = DropPackLib.packERC20Recipient(recipient, amount);
        }
        deal(address(token), sender, total);

        vm.startPrank(sender);
        token.approve(address(gasliteDrop), type(uint256).max);

        // Interaction.
        vm.resumeGasMetering();
        gasliteDrop.airdropERC20(address(token), packedRecipients, total);

        vm.pauseGasMetering();
        vm.stopPrank();
        // Checks.
        for (uint256 i = 0; i < MAX_ERC20_BATCH_DROP; i++) {
            assertEq(token.balanceOf(recipients[i]), amounts[i]);
        }
        vm.resumeGasMetering();
    }

    function test_airdropETH() public {
        vm.pauseGasMetering();
        LibPRNG.PRNG memory rng = LibPRNG.PRNG({state: uint(keccak256("gas bad (erc20 test)"))});

        // Setup.
        uint256 total = 0;
        address[] memory recipients = new address[](MAX_ETH_BATCH_DROP);
        uint256[] memory amounts = new uint256[](MAX_ETH_BATCH_DROP);
        bytes32[] memory packedRecipients = new bytes32[] (MAX_ETH_BATCH_DROP);
        for (uint256 i = 0; i < MAX_ETH_BATCH_DROP; i++) {
            address recipient = address(uint160(rng.next()));
            recipients[i] = recipient;
            // Constrain to 96-bits for packing.
            uint256 amount = uint96(rng.next());
            total += amount;
            amounts[i] = amount;
            packedRecipients[i] = DropPackLib.packETHRecipient(recipient, amount);
        }
        startHoax(sender, total);
        vm.resumeGasMetering();

        // Interaction
        gasliteDrop.airdropETH{value: total}(packedRecipients);

        vm.pauseGasMetering();
        vm.stopPrank();

        // Checks.
        for (uint256 i = 0; i < MAX_ETH_BATCH_DROP; i++) {
            assertEq(recipients[i].balance, amounts[i]);
        }
        vm.resumeGasMetering();
    }
}
